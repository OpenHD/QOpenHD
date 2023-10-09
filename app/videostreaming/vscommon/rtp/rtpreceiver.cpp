#include "rtpreceiver.h"

#include <qdebug.h>

#include "common/StringHelper.hpp"
#include "common/openhd-util.hpp"

#include "QOpenHDVideoHelper.hpp"
#include "decodingstatistcs.h"
#include "common/openhd-util.hpp"
#include "../../logging/hudlogmessagesmodel.h"


#ifdef OPENHD_USE_LIB_UVGRTP
void rtp_receive_hook(void *arg, uvgrtp::frame::rtp_frame *frame){
    RTPReceiver* self=(RTPReceiver*) arg;
    self->uvgrtp_rtp_receive_hook(arg,frame);
}
#endif

RTPReceiver::RTPReceiver(const int port,const std::string ip,bool is_h265,bool feed_incomplete_frames):
    is_h265(is_h265)
{
    if(ip!=std::string(QOpenHDVideoHelper::kDefault_udp_rtp_input_ip_address)){
        qWarning()<<"Using non-default dev_stream0_udp_rtp_input_ip_address";
    }
    if(port!=QOpenHDVideoHelper::kDefault_udp_rtp_input_port_primary){
        qWarning()<<"Using non-default udp_rtp_input_port";
    }
    if(false){
        // Debug write raw data to file
        std::stringstream ss;
        ss<<"/tmp/received_rtp.";
        if(is_h265){
            ss<<"h265";
        }else{
            ss<<"h264";
        }
        m_out_file=std::make_unique<std::ofstream>(ss.str());
    }
    m_keyframe_finder=std::make_unique<KeyFrameFinder>();
#ifdef OPENHD_USE_LIB_UVGRTP
    m_session = m_ctx.create_session(ip.c_str());
    int flags = RCE_RECEIVE_ONLY;
    m_receiver = m_session->create_stream(port, is_h265 ? RTP_FORMAT_H265 : RTP_FORMAT_H264, flags);
    if (!m_receiver || m_receiver->install_receive_hook(this, rtp_receive_hook) != RTP_OK){
        qDebug() << "Failed to install RTP reception hook";
    }
#else
    m_rtp_decoder=std::make_unique<RTPDecoder>([this](const std::chrono::steady_clock::time_point creation_time,const uint8_t *nalu_data, const int nalu_data_size){
        this->nalu_data_callback(creation_time,nalu_data,nalu_data_size);
    },feed_incomplete_frames);
    // Increase the OS max UDP buffer size (only works as root) such that the UDP receiver
    // doesn't fail when requesting a bigger UDP buffer size
    OHDUtil::run_command("sysctl ",{"-w","net.core.rmem_max=26214400"});
    auto udp_config=UDPReceiver::Configuration{std::nullopt,port};
    udp_config.opt_os_receive_buff_size=UDPReceiver::BIG_UDP_RECEIVE_BUFFER_SIZE;
    udp_config.set_sched_param_max_realtime=true;
    udp_config.enable_nonblocking=false;
    m_udp_receiver=std::make_unique<UDPReceiver>("V_REC",udp_config,[this](const uint8_t *payload, const std::size_t payloadSize){
        this->udp_raw_data_callback(payload,payloadSize);
        DecodingStatistcs::instance().set_n_missing_rtp_video_packets(m_rtp_decoder->m_n_gaps);
    });
    m_udp_receiver->startReceiving();
#endif
}

RTPReceiver::~RTPReceiver()
{
   if(m_udp_receiver){
       m_udp_receiver->stopReceiving();
   }
#ifdef OPENHD_USE_LIB_UVGRTP
   if (m_receiver){
       m_session->destroy_stream(m_receiver);
   }
   if (m_session){
       // Session must be destroyed manually
       m_ctx.destroy_session(m_session);
   }
#endif
}


std::shared_ptr<NALUBuffer> RTPReceiver::get_next_frame(std::optional<std::chrono::microseconds> timeout)
{
    std::shared_ptr<NALUBuffer> ret=nullptr;
    //qDebug()<<"get_data size_estimate:"<<m_data_queue.size_approx();
    if(timeout!=std::nullopt){
        m_data_queue.wait_dequeue_timed(ret,timeout.value());
    }else{
        m_data_queue.try_dequeue(ret);
    }
    return ret;
 }

void RTPReceiver::register_new_nalu_callback(NEW_NALU_CALLBACK cb){
    std::lock_guard<std::mutex> lock(m_new_nalu_data_cb_mutex);
    m_new_nalu_cb=cb;
}

std::shared_ptr<std::vector<uint8_t>> RTPReceiver::get_config_data()
{
     std::lock_guard<std::mutex> lock(m_data_mutex);
     if(m_keyframe_finder->allKeyFramesAvailable(is_h265)){
         return m_keyframe_finder->get_keyframe_data(is_h265);
     }
     return nullptr;
}

std::array<int, 2> RTPReceiver::sps_get_width_height(){
    std::lock_guard<std::mutex> lock(m_data_mutex);
    return m_keyframe_finder->sps_get_width_height();
}

void RTPReceiver::queue_data(const uint8_t* nalu_data,const std::size_t nalu_data_len)
{
    std::lock_guard<std::mutex> lock(m_data_mutex);
    // we discard any data in this state
    // TODO fixme
    //if(config_has_changed_during_decode)return;
    //qDebug()<<"Got frame2";
    NALU nalu(nalu_data,nalu_data_len,is_h265);
    //qDebug()<<"Got frame:"<<nalu.get_nal_unit_type_as_string().c_str();
    // hacky way to estimate keyframe interval
    if(nalu.is_frame_but_not_keyframe()){
        n_frames_non_idr++;
    }
    if(nalu.is_keyframe()){
        n_frames_idr++;
    }
    if(n_frames_idr>=3){
        DecodingStatistcs::instance().set_estimate_keyframe_interval((n_frames_non_idr+n_frames_idr)/n_frames_idr);
        n_frames_idr=0;
        n_frames_non_idr=0;
    }
    if(m_keyframe_finder->allKeyFramesAvailable(is_h265)){
        if(!m_keyframe_finder->check_is_still_same_config_data(nalu)){
            // We neither queue on new data nor call the callback - upper level needs to reconfigure the decoder
            qDebug()<<"config_has_changed_during_decode";
            config_has_changed_during_decode=true;
            return;
        }
        // If we have all config data, start storing video frames
        // We can drop things we don't need for decoding frames though
        if(nalu.is_config())return;
        if(nalu.is_aud())return;
        if(nalu.is_sei())return;
        if(nalu.is_dps())return;
        // recalculate rough fps in X seconds intervalls:
        m_estimate_fps_calculator.on_new_frame();
        if(m_estimate_fps_calculator.time_since_last_recalculation()>std::chrono::seconds(2)){
            const auto fps=m_estimate_fps_calculator.recalculate_fps_and_clear();
            const auto fps_as_string=StringHelper::to_string_with_precision(fps,2)+"fps";
            DecodingStatistcs::instance().set_estimate_rtp_fps({fps_as_string.c_str()});
        }
        //qDebug()<<"Queue size:"<<m_data_queue.size_approx();
        if(m_new_nalu_cb){
            // Use the cb approach
            m_new_nalu_cb(nalu);
        }else{
            // Use the queue approach
            if(!m_data_queue.try_enqueue(std::make_shared<NALUBuffer>(nalu))){
                // If we cannot push a frame onto this queue, it means the decoder cannot keep up what we want to provide to it
                n_dropped_frames++;
                qDebug()<<"Dropping incoming frame, total:"<<n_dropped_frames;
                DecodingStatistcs::instance().set_n_decoder_dropped_frames(n_dropped_frames);
                const auto elapsed=std::chrono::steady_clock::now()-m_last_log_hud_dropped_frame;
                if(elapsed>std::chrono::seconds(3)){
                    HUDLogMessagesModel::instance().add_message_warning("Decoder unhealthy-reduce load");
                    m_last_log_hud_dropped_frame=std::chrono::steady_clock::now();
                }
            }
        }
    }else{
        // We don't have all config data yet, drop anything that is not config data.
        m_keyframe_finder->saveIfKeyFrame(nalu);
    }
}

#ifdef OPENHD_USE_LIB_UVGRTP
void RTPReceiver::uvgrtp_rtp_receive_hook(void *arg, uvgrtp::frame::rtp_frame *frame)
{
    qDebug()<<"Got uvg data:"<<frame->payload_len-frame->padding_len<<" padding:"<<frame->padding_len;
    nalu_data_callback(std::chrono::steady_clock::now(),frame->payload,frame->payload_len-frame->padding_len);
    (void)uvgrtp::frame::dealloc_frame(frame);
}
#endif

void RTPReceiver::udp_raw_data_callback(const uint8_t *payload, const std::size_t payloadSize)
{
    //qDebug()<<"Got UDP data "<<payloadSize;
    m_rtp_bitrate.addBytes(payloadSize,[](std::string bitrate){
        DecodingStatistcs::instance().set_rtp_measured_bitrate(bitrate.c_str());
    });
    if(is_h265){
        m_rtp_decoder->parseRTPH265toNALU(payload,payloadSize);
        //m_rtp_decoder->parse_rtp_mjpeg(payload,payloadSize);
    }else{
        m_rtp_decoder->parseRTPH264toNALU(payload,payloadSize);
    }
}

void RTPReceiver::nalu_data_callback(const std::chrono::steady_clock::time_point creation_time,const uint8_t *nalu_data, const int nalu_data_size)
{
    //qDebug()<<"Got NALU "<<nalu_data_size;
    {
        //std::vector<uint8_t> tmp(nalu_data,nalu_data+nalu_data_size);
        //qDebug()<<StringHelper::vectorAsString(tmp).c_str()<<"\n";
    }
    if(m_out_file!=nullptr){
        m_out_file->write((const char*)nalu_data,nalu_data_size);
        m_out_file->flush();
    }
    /*int random=rand();
    if(random % 10 == 0){
        qDebug()<<"Dropping frame";
        return;
    }*/
    queue_data(nalu_data,nalu_data_size);
}

