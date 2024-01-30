#include "rawreceiver.h"

#include <common/StringHelper.hpp>
#include "QOpenHDVideoHelper.hpp"
#include "decodingstatistcs.h"

RawReceiver::RawReceiver(int port,std::string ip,bool is_h265,bool unused):
        is_h265(is_h265)
{
    m_keyframe_finder=std::make_unique<CodecConfigFinder>();
    auto udp_config=UDPReceiver::Configuration{std::nullopt,port};
    udp_config.opt_os_receive_buff_size=UDPReceiver::BIG_UDP_RECEIVE_BUFFER_SIZE;
    udp_config.set_sched_param_max_realtime=true;
    udp_config.enable_nonblocking=false;
    m_udp_receiver=std::make_unique<UDPReceiver>("V_REC",udp_config,[this](const uint8_t *payload, const std::size_t payloadSize){
        this->udp_raw_data_callback(payload,payloadSize);
    });
    m_udp_receiver->startReceiving();
}

RawReceiver::~RawReceiver()
{
    if(m_udp_receiver){
        m_udp_receiver->stopReceiving();
    }
}

std::shared_ptr<NALUBuffer> RawReceiver::get_next_frame(std::optional<std::chrono::microseconds> timeout)
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

std::shared_ptr<std::vector<uint8_t> > RawReceiver::get_config_data()
{
    std::lock_guard<std::mutex> lock(m_data_mutex);
    if(m_keyframe_finder->all_config_available(is_h265)){
        return m_keyframe_finder->get_config_data(is_h265);
    }
    return nullptr;
}

std::array<int, 2> RawReceiver::sps_get_width_height()
{
    std::lock_guard<std::mutex> lock(m_data_mutex);
    return m_keyframe_finder->sps_get_width_height();
}

static std::string bytes_as_string(const uint8_t* data, int data_len) {
    std::stringstream ss;
    ss << "[";
    for(int i=0;i<data_len;i++){
        ss << (int)data[i];
        //ss<<v[i];
        if(i!=data_len-1){
            ss<<",";
        }
    }
    ss << "]";
    return ss.str();
}

void RawReceiver::udp_raw_data_callback(const uint8_t *data, const std::size_t data_length)
{
    uint8_t* nalu_data=m_curr_nalu.data();
    int& nalu_data_position=m_nalu_data_length;

    for (size_t i = 0; i < data_length; ++i) {
            nalu_data[nalu_data_position++] = data[i];
            if (nalu_data_position >= NALU::NALU_MAXLEN - 1) {
                qDebug()<<"Exceeded nal size";
                // This should never happen, but rather continue parsing than
                // possibly raising an 'memory access' exception
                nalu_data_position = 0;
            }
            // Handles 0,0,1 and 0,0,0,1 start codes, as well as basic stream corruption errors.
            int parsed_prefix_len;
            switch (nalu_search_state) {
                case 0:
                case 1:
                    if (data[i] == 0)
                        nalu_search_state++;
                    else
                        nalu_search_state = 0;
                    break;    
                case 2:
                case 3:
                    if (data[i]==0){
                        if(nalu_search_state==3){
                            // Ignore this 0
                            nalu_data_position--;
                        }
                        // as long as only zeroes come in, we don't have to do anything - I don't think 0000001 should ever happen, but could be a valid start code
                        nalu_search_state=3;
                    }else if(data[i]==1){
                        parsed_prefix_len = nalu_search_state==3 ? 4 : 3;
                        if(NALU::has_valid_prefix(nalu_data) && nalu_data_position>4){
                            raw_nalu_callback(nalu_data,nalu_data_position-parsed_prefix_len);
                        }else{
                            //qDebug()<<"Not a valid NALU";
                        }
                        // move the read prefix to the beginning of the nalu buffer
                        NALU::write_prefix(nalu_data,parsed_prefix_len==4);
                        nalu_data_position = parsed_prefix_len;
                        //nalu_data[0] = 0;
                        //nalu_data[1] = 0;
                        //nalu_data[2] = 0;
                        //nalu_data[3] = 1;
                        // Forward NALU only if it has enough data
                        //raw_nalu_callback(nalu_data,nalu_data_position-4);
                        //nalu_data_position = 4;
                        nalu_search_state = 0;
                    }else{
                        nalu_search_state = 0;
                    }
                    break;
                default:
                    break;
            }
    }
}

void RawReceiver::raw_nalu_callback(const uint8_t *data, int len)
{
    //qDebug()<<"Got NAL "<<len;
    //qDebug()<<bytes_as_string(data,len).c_str();
    if(len<6){
        return;
    }
    queue_data(data,len);
}

void RawReceiver::queue_data(const uint8_t *nalu_data, const std::size_t nalu_data_len)
{
    std::lock_guard<std::mutex> lock(m_data_mutex);
    // we discard any data in this state
    // TODO fixme
    //if(config_has_changed_during_decode)return;
    //qDebug()<<"Got frame2";
    NALU nalu(nalu_data,nalu_data_len,is_h265);
    qDebug()<<"Got NAL:"<<nalu_data_len<<" :"<<nalu.get_nal_unit_type_as_string().c_str();
    if(nalu.is_aud()){
        return;
    }
    if(nalu.is_sei()){
        return;
    }
    // hacky way to estimate keyframe interval
    if(nalu.is_frame_but_not_keyframe()){
        n_frames_non_idr++;
    }
    if(nalu.is_keyframe()){
        n_frames_idr++;
    }
    if(n_frames_idr>=3){
        DecodingStatistcs::instance().util_set_estimate_keyframe_interval_int((n_frames_non_idr+n_frames_idr)/n_frames_idr);
        n_frames_idr=0;
        n_frames_non_idr=0;
    }
    if(m_keyframe_finder->all_config_available(is_h265)){
        if(!m_keyframe_finder->check_is_still_same_config_data(nalu)){
            // We neither queue on new data nor call the callback - upper level needs to reconfigure the decoder
            qDebug()<<"config_has_changed_during_decode";
            config_has_changed_during_decode=true;
            qDebug()<<nalu_data_len;
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

            // Use the queue approach
        if(!m_data_queue.try_enqueue(std::make_shared<NALUBuffer>(nalu))){
            // If we cannot push a frame onto this queue, it means the decoder cannot keep up what we want to provide to it
            n_dropped_frames++;
            qDebug()<<"Dropping incoming frame, total:"<<n_dropped_frames;
            DecodingStatistcs::instance().set_n_decoder_dropped_frames(n_dropped_frames);
        }
    }else{
        // We don't have all config data yet, drop anything that is not config data.
        m_keyframe_finder->save_if_config(nalu);
    }
}
