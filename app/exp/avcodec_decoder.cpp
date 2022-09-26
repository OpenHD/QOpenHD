#include "avcodec_decoder.h"
#include "qdebug.h"
#include <QFileInfo>
#include <iostream>
#include <sstream>

#include "avcodec_helper.hpp"
#include "../common_consti/TimeHelper.hpp"

#include "texturerenderer.h"
#include "../videostreaming/decodingstatistcs.h"

static enum AVPixelFormat wanted_hw_pix_fmt;

static int hw_decoder_init(AVCodecContext *ctx, const enum AVHWDeviceType type){
    int err = 0;
    ctx->hw_frames_ctx = NULL;
    // ctx->hw_device_ctx gets freed when we call avcodec_free_context
    if ((err = av_hwdevice_ctx_create(&ctx->hw_device_ctx, type,
                                      NULL, NULL, 0)) < 0) {
        fprintf(stderr, "Failed to create specified HW device.\n");
        return err;
    }
    return err;
}

static enum AVPixelFormat get_hw_format(AVCodecContext *ctx,const enum AVPixelFormat *pix_fmts){
    const enum AVPixelFormat *p;
    AVPixelFormat ret=AV_PIX_FMT_NONE;
    std::stringstream supported_formats;
    for (p = pix_fmts; *p != -1; p++) {
        const int tmp=(int)*p;
        supported_formats<<safe_av_get_pix_fmt_name(*p)<<"("<<tmp<<"),";
        if (*p == wanted_hw_pix_fmt){
          // matches what we want
          ret=*p;
        }
    }
    qDebug()<<"Supported (HW) pixel formats: "<<supported_formats.str().c_str();
    if(ret==AV_PIX_FMT_NONE){
      fprintf(stderr, "Failed to get HW surface format. Wanted: %s\n", av_get_pix_fmt_name(wanted_hw_pix_fmt));
    }
    return ret;
}

// For SW decode, we support YUV420 | YUV422 and their (mjpeg) abbreviates since
// we can always copy and render these formats via OpenGL - and when we are doing SW decode
// we most likely are on a (fast) x86 platform where we can copy those formats via CPU
// relatively easily, at least the resolutions common in OpenHD
static enum AVPixelFormat get_sw_format(AVCodecContext *ctx,const enum AVPixelFormat *pix_fmts){
    const enum AVPixelFormat *p;
    qDebug()<<"All (SW) pixel formats:"<<all_formats_to_string(pix_fmts).c_str();
    for (p = pix_fmts; *p != -1; p++) {
        const AVPixelFormat tmp=*p;
        if(tmp==AV_PIX_FMT_YUV420P || tmp==AV_PIX_FMT_YUV422P || tmp==AV_PIX_FMT_YUVJ422P || tmp==AV_PIX_FMT_YUVJ422P){
            return tmp;
        }
    }
    qDebug()<<"Weird, we should be able to do SW decoding on all platforms";
    return AV_PIX_FMT_NONE;
}

// FFMPEG needs a ".sdp" file to do rtp udp h264,h265 or mjpeg
// For MJPEG we map mjpeg to 26 (mjpeg), for h264/5 we map h264/5 to 96 (general)
static std::string create_udp_rtp_sdp_file(const QOpenHDVideoHelper::VideoCodec& video_codec){
    std::stringstream ss;
    ss<<"c=IN IP4 127.0.0.1\n";
    //ss<<"v=0\n";
    //ss<<"t=0 0\n";
    //ss<<"width=1280\n";
    //ss<<"height=720\n";
    if(video_codec==QOpenHDVideoHelper::VideoCodec::VideoCodecMJPEG){
         ss<<"m=video 5600 RTP/UDP 26\n";
        ss<<"a=rtpmap:26 JPEG/90000\n";
    }else{
        ss<<"m=video 5600 RTP/UDP 96\n";
        if(video_codec==QOpenHDVideoHelper::VideoCodec::VideoCodecH264){
            ss<<"a=rtpmap:96 H264/90000\n";
        }else{
            assert(video_codec==QOpenHDVideoHelper::VideoCodec::VideoCodecH265);
            ss<<"a=rtpmap:96 H265/90000\n";
        }
    }
    return ss.str();
}
static void write_file_to_tmp(const std::string filename,const std::string content){
    std::ofstream _t(filename);
     _t << content;
     _t.close();
}

static void write_udp_rtp_sdp_files_to_tmp(){
    if(QFileInfo::exists("/tmp/rtp_h264.sdp")&&QFileInfo::exists("/tmp/rtp_h265.sdp")&&QFileInfo::exists("/tmp/rtp_mjpeg.sdp"))return;
    write_file_to_tmp("/tmp/rtp_h264.sdp",create_udp_rtp_sdp_file(QOpenHDVideoHelper::VideoCodec::VideoCodecH264));
    write_file_to_tmp("/tmp/rtp_h265.sdp",create_udp_rtp_sdp_file(QOpenHDVideoHelper::VideoCodec::VideoCodecH265));
    write_file_to_tmp("/tmp/rtp_mjpeg.sdp",create_udp_rtp_sdp_file(QOpenHDVideoHelper::VideoCodec::VideoCodecMJPEG));
}

static std::string get_udp_rtp_sdp_filename(const QOpenHDVideoHelper::VideoCodec& video_codec){
    write_udp_rtp_sdp_files_to_tmp();
    if(video_codec==QOpenHDVideoHelper::VideoCodec::VideoCodecH264)return "/tmp/rtp_h264.sdp";
    if(video_codec==QOpenHDVideoHelper::VideoCodec::VideoCodecH265)return "/tmp/rtp_h265.sdp";
    return "/tmp/rtp_mjpeg.sdp";
}


AVCodecDecoder::AVCodecDecoder(QObject *parent):
    QObject(parent)
{
    //drm_prime_out=std::make_unique<DRMPrimeOut>(1,false,false);
    //RpiMMALDisplay::instance().init();
#ifdef HAVE_MMAL
    RpiMMALDisplay::instance().init();
#endif
}

void AVCodecDecoder::init(bool primaryStream)
{
    m_rtp_reciever=std::make_unique<RTPReceiver>(5600,false);
    if(true)return;
    qDebug() << "AVCodecDecoder::init()";
    m_last_video_settings=QOpenHDVideoHelper::read_from_settings();
    decode_thread = std::make_unique<std::thread>([this]{this->constant_decode();} );
    timer_check_settings_changed=std::make_unique<QTimer>();
    QObject::connect(timer_check_settings_changed.get(), &QTimer::timeout, this, &AVCodecDecoder::timer_check_settings_changed_callback);
    timer_check_settings_changed->start(1000);
}

void AVCodecDecoder::cancel()
{
    has_been_canceled=true;
}

void AVCodecDecoder::timer_check_settings_changed_callback()
{
    const auto new_settings=QOpenHDVideoHelper::read_from_settings();
    if(m_last_video_settings!=new_settings){
        // We just request a restart from the video (break out of the current constant_decode() loop,
        // and restart with the new settings.
        request_restart=true;
        m_last_video_settings=new_settings;
    }
}

void AVCodecDecoder::dequeue_frames_test()
{
    while(test_dequeue_fames){
        //qDebug()<<"XXX";
        AVFrame* frame= av_frame_alloc();
        assert(frame);
        //m_ffmpeg_dequeue_or_queue_mutex.lock();
        const int ret = avcodec_receive_frame(decoder_ctx, frame);
        //m_ffmpeg_dequeue_or_queue_mutex.unlock();
        if(ret==0){
            qDebug()<<"XXX got frame";
            on_new_frame(frame);
        }
        av_frame_free(&frame);
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }
}

void AVCodecDecoder::constant_decode()
{
    while(true){
        qDebug()<<"Start decode";
        open_and_decode_until_error();
        qDebug()<<"Decode stopped,restarting";
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
}



int AVCodecDecoder::decode_and_wait_for_frame(AVPacket *packet)
{
    AVFrame *frame = nullptr;
    //qDebug()<<"Decode packet:"<<packet->pos<<" size:"<<packet->size<<" B";
    const auto beforeFeedFrame=std::chrono::steady_clock::now();
    const auto beforeFeedFrameUs=getTimeUs();
    packet->pts=beforeFeedFrameUs;
    add_fed_timestamp(packet->pts);

    //m_ffmpeg_dequeue_or_queue_mutex.lock();
    const int ret_avcodec_send_packet = avcodec_send_packet(decoder_ctx, packet);
    //m_ffmpeg_dequeue_or_queue_mutex.unlock();
    if (ret_avcodec_send_packet < 0) {
        fprintf(stderr, "Error during decoding\n");
        return ret_avcodec_send_packet;
    }
    // alloc output frame(s)
    if (!(frame = av_frame_alloc())) {
        // NOTE: It is a common practice to not care about OOM, and this is the best approach in my opinion.
        // but ffmpeg uses malloc and returns error codes, so we keep this practice here.
        qDebug()<<"can not alloc frame";
        av_frame_free(&frame);
        return AVERROR(ENOMEM);
    }
    int ret=0;
    // Poll until we get the frame out
    const auto loopUntilFrameBegin=std::chrono::steady_clock::now();
    bool gotFrame=false;
    int n_times_we_tried_getting_a_frame_this_time=0;
    while (!gotFrame){
        //m_ffmpeg_dequeue_or_queue_mutex.lock();
        ret = avcodec_receive_frame(decoder_ctx, frame);
        //m_ffmpeg_dequeue_or_queue_mutex.unlock();
        if(ret == AVERROR_EOF){
            qDebug()<<"Got EOF";
            break;
        }else if(ret==0){
            //debug_is_valid_timestamp(frame->pts);
            // we got a new frame
            if(!use_frame_timestamps_for_latency){
                const auto x_delay=std::chrono::steady_clock::now()-beforeFeedFrame;
                //qDebug()<<"(True) decode delay(wait):"<<((float)std::chrono::duration_cast<std::chrono::microseconds>(x_delay).count()/1000.0f)<<" ms";
                avg_decode_time.add(x_delay);
            }else{
                const auto now_us=getTimeUs();
                const auto delay_us=now_us-frame->pts;
                //qDebug()<<"(True) decode delay(nowait):"<<((float)delay_us/1000.0f)<<" ms";
                //MLOGD<<"Frame pts:"<<frame->pts<<" Set to:"<<now<<"\n";
                //frame->pts=now;
                avg_decode_time.add(std::chrono::microseconds(delay_us));
            }
            gotFrame=true;
            frame->pts=beforeFeedFrameUs;
            // display frame
            on_new_frame(frame);
            if(avg_decode_time.time_since_last_log()>std::chrono::seconds(3)){
                qDebug()<<"Avg Decode time:"<<avg_decode_time.getAvgReadable().c_str();
                DecodingStatistcs::instance().set_decode_time(avg_decode_time.getAvgReadable().c_str());
                avg_decode_time.set_last_log();
                avg_decode_time.reset();
            }
        }else if(ret==AVERROR(EAGAIN)){
            if(n_no_output_frame_after_x_seconds>=2){
                // note decode latency is now wrong
                qDebug()<<"Skipping decode lockstep due to no frame for more than X seconds\n";
                DecodingStatistcs::instance().set_doing_wait_for_frame_decode("No");
                if(n_times_we_tried_getting_a_frame_this_time>4){
                    break;
                }
            }
            //std::cout<<"avcodec_receive_frame returned:"<<ret<<"\n";
            // for some video files, the decoder does not output a frame every time a h264 frame has been fed
            // In this case, I unblock after X seconds, but we cannot measure the decode delay by using the before-after
            // approach. We can still measure it using the pts timestamp from av, but this one cannot necessarily be trusted 100%
            if(std::chrono::steady_clock::now()-loopUntilFrameBegin > std::chrono::seconds(2)){
              qDebug()<<"Got no frame after X seconds. Break, but decode delay will be reported wrong";
              n_no_output_frame_after_x_seconds++;
              use_frame_timestamps_for_latency=true;
              break;
            }
            // sleep a bit to not hog the CPU too much
            std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }else{
            qDebug()<<"Got unlikely / weird error:"<<ret;
        }
        n_times_we_tried_getting_a_frame_this_time++;
    }
    av_frame_free(&frame);
    return 0;
}


void AVCodecDecoder::fetch_frame_or_feed_input_packet(){
    while(keep_fetching_frames_or_input_packets){
        AVFrame* frame= av_frame_alloc();
        assert(frame);
        const int ret = avcodec_receive_frame(decoder_ctx, frame);
        //m_ffmpeg_dequeue_or_queue_mutex.unlock();
        if(ret == AVERROR_EOF){
            qDebug()<<"Got EOF";
            keep_fetching_frames_or_input_packets=false;
        }else if(ret==0){
            debug_is_valid_timestamp(frame->pts);
            // we got a new frame
            const auto now_us=getTimeUs();
            const auto delay_us=now_us-frame->pts;
            //qDebug()<<"(True) decode delay(nowait):"<<((float)delay_us/1000.0f)<<" ms";
            //MLOGD<<"Frame pts:"<<frame->pts<<" Set to:"<<now<<"\n";
            //frame->pts=now;
            avg_decode_time.add(std::chrono::microseconds(delay_us));
            // display frame
            on_new_frame(frame);

            if(avg_decode_time.time_since_last_log()>std::chrono::seconds(3)){
                qDebug()<<"Avg Decode time:"<<avg_decode_time.getAvgReadable().c_str();
                DecodingStatistcs::instance().set_decode_time(avg_decode_time.getAvgReadable().c_str());
                avg_decode_time.set_last_log();
                avg_decode_time.reset();
            }
            av_frame_free(&frame);
            frame= av_frame_alloc();
        }else if(ret==AVERROR(EAGAIN)){
            qDebug()<<"Needs more data";
            // Get more encoded data
            auto packet=fetch_av_packet_if_available();
            if(packet!=std::nullopt){
                const int ret_avcodec_send_packet = avcodec_send_packet(decoder_ctx, &packet.value());
                if (ret_avcodec_send_packet < 0) {
                    qDebug()<<"Error during send packet";
                }
                av_packet_unref(&packet.value());
            }else{
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
            }
        }else{
            qDebug()<<"Weird decoder error:"<<ret;
            keep_fetching_frames_or_input_packets=false;
        }
    }
}

void AVCodecDecoder::enqueue_av_packet(AVPacket packet)
{
     std::lock_guard<std::mutex> lock(m_av_packet_queue_mutex);
     m_av_packet_queue.push(packet);
}

std::optional<AVPacket> AVCodecDecoder::fetch_av_packet_if_available()
{
     std::lock_guard<std::mutex> lock(m_av_packet_queue_mutex);
     if(m_av_packet_queue.size()>=1){
         AVPacket packet=m_av_packet_queue.front();
         const auto beforeFeedFrameUs=getTimeUs();
         packet.pts=beforeFeedFrameUs;
         m_av_packet_queue.pop();
         return packet;
     }
     return std::nullopt;
}

void AVCodecDecoder::parse_rtp_test()
{
    if(m_pCodecPaser==nullptr){
        m_pCodecPaser = av_parser_init(AV_CODEC_ID_H265);
        assert(m_pCodecPaser);
    }
    //const int ret = av_parser_parse2(m_pCodecPaser, m_codec_ctx, &pkt->data,&pkt->size,
    //                                       m_packet.data,m_packet.size, AV_NOPTS_VALUE, AV_NOPTS_VALUE, 0);
}

void AVCodecDecoder::on_new_frame(AVFrame *frame)
{
    {
        std::stringstream ss;
        ss<<safe_av_get_pix_fmt_name((AVPixelFormat)frame->format)<<" "<<frame->width<<"x"<<frame->height;
        DecodingStatistcs::instance().set_primary_stream_frame_format(QString(ss.str().c_str()));
        //qDebug()<<"Got frame:"<<ss.str().c_str();
    }
    if(frame->format==AV_PIX_FMT_MMAL){
#ifdef HAVE_MMAL
        TextureRenderer::instance().clear_all_video_textures_next_frame();
        RpiMMALDisplay::instance().display_frame(frame);
        return;
#else
        qDebug()<<"WARNING do not configure the decoder with mmal without the mmal renderer";
#endif
    }
    TextureRenderer::instance().queue_new_frame_for_display(frame);
    if(last_frame_width==-1 || last_frame_height==-1){
        last_frame_width=frame->width;
        last_frame_height=frame->height;
    }else{
        if(last_frame_width!=frame->width || last_frame_height!=frame->height){
            // PI and SW decoer will just slently start outputting garbage frames
            // if the width/ height changes during RTP streaming
            qDebug()<<"Need to restart the decoder, width / heght changed";
            request_restart=true;
        }
    }
    //drm_prime_out->queue_new_frame_for_display(frame);
}


int AVCodecDecoder::open_and_decode_until_error()
{
    const auto settings = QOpenHDVideoHelper::read_from_settings();
    std::string in_filename="";
    if(settings.dev_test_video_mode==QOpenHDVideoHelper::VideoTestMode::DISABLED){
        in_filename=get_udp_rtp_sdp_filename(settings.video_codec);
        //in_filename="rtp://192.168.0.1:5600";
    }else{
        if(settings.dev_enable_custom_pipeline){
            in_filename=settings.dev_custom_pipeline;
        }else{
            // For testing, I regulary change the filename(s) and recompile
            const bool consti_testing=true;
            if(consti_testing){
                if(settings.video_codec==QOpenHDVideoHelper::VideoCodecH264){
                     in_filename="/tmp/x_raw_h264.h264";
                    //in_filename="/home/consti10/Desktop/hello_drmprime/in/rpi_1080.h264";
                    //in_filename="/home/consti10/Desktop/hello_drmprime/in/rv_1280x720_green_white.h264";
                    //in_filename="/home/consti10/Desktop/hello_drmprime/in/Big_Buck_Bunny_1080_10s_1MB_h264.mp4";
                }else if(settings.video_codec==QOpenHDVideoHelper::VideoCodecH265){
                      in_filename="/tmp/x_raw_h265.h265";
                    //in_filename="/home/consti10/Desktop/hello_drmprime/in/jetson_test.h265";
                    //in_filename="/home/consti10/Desktop/hello_drmprime/in/Big_Buck_Bunny_1080_10s_1MB_h265.mp4";
                }else{
                   in_filename="/home/consti10/Desktop/hello_drmprime/in/uv_640x480.mjpeg";
                   //in_filename="/home/consti10/Desktop/hello_drmprime/in/Big_Buck_Bunny_1080.mjpeg";
                }
            }else{
                in_filename=QOpenHDVideoHelper::get_default_openhd_test_file(settings.video_codec);
            }

        }
    }
    av_log_set_level(AV_LOG_TRACE);

    // These options are needed for using the foo.sdp (rtp streaming)
    // https://stackoverflow.com/questions/20538698/minimum-sdp-for-making-a-h264-rtp-stream
    // https://stackoverflow.com/questions/16658873/how-to-minimize-the-delay-in-a-live-streaming-with-ffmpeg
    AVDictionary* av_dictionary=nullptr;
    av_dict_set(&av_dictionary, "protocol_whitelist", "file,udp,rtp", 0);
    /*av_dict_set(&av_dictionary, "buffer_size", "212992", 0);
    av_dict_set_int(&av_dictionary,"max_delay",0,0);
    av_dict_set(&av_dictionary,"reuse_sockets","1",0);
    av_dict_set_int(&av_dictionary, "reorder_queue_size", 0, 0);
    av_dict_set_int(&av_dictionary,"network-caching",0,0);
    //
    //av_dict_set(&av_dictionary,"sync","ext",0);
    //
    //av_dict_set_int(&av_dictionary, "probesize", 32, 0);
    //av_dict_set_int(&av_dictionary, "analyzeduration", 1000*100, 0); // Is in microseconds

    // I think those values are in seconds ?
    av_dict_set_int(&av_dictionary, "rw_timeout", 1000*100, 0); //microseconds
    av_dict_set_int(&av_dictionary, "stimeout", 1000*100, 0); //microseconds
    //av_dict_set_int(&av_dictionary, "rw_timeout", 0, 0);
    //av_dict_set_int(&av_dictionary, "stimeout",0, 0);
    av_dict_set_int(&av_dictionary,"rtbufsize",0,0);
    av_dict_set_int(&av_dictionary,"max_interleave_delta",1,0); //in microseconds
    //av_dict_set_int(&av_dictionary,"max_streams",1,0);

    av_dict_set(&av_dictionary, "rtsp_transport", "udp", 0);*/

    AVFormatContext *input_ctx = nullptr;
    input_ctx=avformat_alloc_context();
    assert(input_ctx);
    /*input_ctx->video_codec_id=AV_CODEC_ID_H264;
    input_ctx->flags |= AVFMT_FLAG_FLUSH_PACKETS;
    input_ctx->flags |= AVFMT_FLAG_NOBUFFER;*/
    //input_ctx->avio_flags = AVIO_FLAG_DIRECT;
    //input_ctx->flags |= AVFMT_FLAG_NOBUFFER;// | AVFMT_FLAG_FLUSH_PACKETS;

    // open the input file
    if (avformat_open_input(&input_ctx,in_filename.c_str(), NULL, &av_dictionary) != 0) {
        qDebug()<< "Cannot open input file ["<<in_filename.c_str()<<"]";
        open_input_error_count++;
        avformat_close_input(&input_ctx);
        // sleep a bit before returning in this case, to not occupy a full CPU thread just trying
        // to open a file/stream that doesn't exist / is ill-formated
        std::this_thread::sleep_for(std::chrono::seconds(1));
        return -1;
    }
    qDebug()<<"done avformat_open_input["<<in_filename.c_str()<<"]";

    if (avformat_find_stream_info(input_ctx, NULL) < 0) {
        qDebug()<< "Cannot find input stream information.";
        avformat_close_input(&input_ctx);
        return -1;
    }
    qDebug()<<"done avformat_find_stream_info";
    // find the video stream information
    //ret = av_find_best_stream(input_ctx, AVMEDIA_TYPE_VIDEO, -1, -1,(const AVCodec**) &decoder, 0);
    int ret = av_find_best_stream(input_ctx, AVMEDIA_TYPE_VIDEO, -1, -1,(AVCodec**) &decoder, 0);
    if (ret < 0) {
        qDebug()<< "Cannot find a video stream in the input file";
        avformat_close_input(&input_ctx);
        return -1;
    }
    qDebug()<<"done av_find_best_stream:"<<ret;
    const int video_stream = ret;

    if(!(decoder->id==AV_CODEC_ID_H264 || decoder->id==AV_CODEC_ID_H265 || decoder->id==AV_CODEC_ID_MJPEG)){
      qDebug()<<"We only do h264,h265 and mjpeg in this project";
      avformat_close_input(&input_ctx);
      return 0;
    }

    const AVHWDeviceType kAvhwDeviceType = AV_HWDEVICE_TYPE_DRM;
    //const AVHWDeviceType kAvhwDeviceType = AV_HWDEVICE_TYPE_VAAPI;
    //const AVHWDeviceType kAvhwDeviceType = AV_HWDEVICE_TYPE_CUDA;
    //const AVHWDeviceType kAvhwDeviceType = AV_HWDEVICE_TYPE_VDPAU;


    bool is_mjpeg=false;
    if (decoder->id == AV_CODEC_ID_H264) {
        qDebug()<<"H264 decode";
        qDebug()<<all_hw_configs_for_this_codec(decoder).c_str();
        if(!settings.enable_software_video_decoder){
            // weird workaround needed for pi + DRM_PRIME
            /*if ((decoder = avcodec_find_decoder_by_name("h264_v4l2m2m")) == NULL) {
                fprintf(stderr, "Cannot find the h264 v4l2m2m decoder\n");
                avformat_close_input(&input_ctx);
                return -1;
            }*/
            auto tmp = avcodec_find_decoder_by_name("h264_mmal");
            if(tmp!=nullptr){
                decoder = tmp;
                 wanted_hw_pix_fmt = AV_PIX_FMT_MMAL;
            }else{
                wanted_hw_pix_fmt = AV_PIX_FMT_YUV420P;
            }
        }else{
            wanted_hw_pix_fmt = AV_PIX_FMT_YUV420P;
        }
    }
    else if(decoder->id==AV_CODEC_ID_H265){
        qDebug()<<"H265 decode";
        for (int i = 0;; i++) {
            const AVCodecHWConfig *config = avcodec_get_hw_config(decoder, i);
            if (!config) {
                fprintf(stderr, "Decoder %s does not support device type %s.\n",
                        decoder->name, safe_av_hwdevice_get_type_name(kAvhwDeviceType).c_str());
                //return -1;
                break;
            }
            std::stringstream ss;
            ss<<"HW config "<<i<<" ";
            ss<<"HW Device name: "<<safe_av_hwdevice_get_type_name(config->device_type);
            ss<<" PIX fmt: "<<safe_av_get_pix_fmt_name(config->pix_fmt);
            qDebug()<<ss.str().c_str();

            if (config->methods & AV_CODEC_HW_CONFIG_METHOD_HW_DEVICE_CTX &&
                config->device_type == kAvhwDeviceType) {
                wanted_hw_pix_fmt = config->pix_fmt;
                break;
            }
        }
        wanted_hw_pix_fmt = AV_PIX_FMT_DRM_PRIME;
        //wanted_hw_pix_fmt = AV_PIX_FMT_CUDA;
        //wanted_hw_pix_fmt = AV_PIX_FMT_VAAPI;
        //wanted_hw_pix_fmt = AV_PIX_FMT_YUV420P;
        //wanted_hw_pix_fmt = AV_PIX_FMT_VAAPI;
        //wanted_hw_pix_fmt = AV_PIX_FMT_VDPAU;
    }else if(decoder->id==AV_CODEC_ID_MJPEG){
        qDebug()<<"Codec mjpeg";
        qDebug()<<all_hw_configs_for_this_codec(decoder).c_str();
        wanted_hw_pix_fmt=AV_PIX_FMT_YUVJ422P;
        //wanted_hw_pix_fmt=AV_PIX_FMT_YUVJ420P;
        //wanted_hw_pix_fmt=AV_PIX_FMT_CUDA;
        //wanted_hw_pix_fmt = AV_PIX_FMT_DRM_PRIME;
        is_mjpeg= true;
    }else{
        assert(true);
        avformat_close_input(&input_ctx);
        return 0;
    }

    if (!(decoder_ctx = avcodec_alloc_context3(decoder))){
        qDebug()<<"avcodec_alloc_context3 failed";
        avformat_close_input(&input_ctx);
        return -1;
    }
#ifdef HAVE_MMAL
     RpiMMALDisplay::instance().prepareDecoderContext(decoder_ctx,&av_dictionary);
#endif

    // From moonlight-qt. However, on PI, this doesn't seem to make any difference, at least for H265 decode.
    // (I never measured h264, but don't think there it is different).
    // Always request low delay decoding
    decoder_ctx->flags |= AV_CODEC_FLAG_LOW_DELAY;
    // Allow display of corrupt frames and frames missing references
    decoder_ctx->flags |= AV_CODEC_FLAG_OUTPUT_CORRUPT;
    decoder_ctx->flags2 |= AV_CODEC_FLAG2_SHOW_ALL;

    AVStream *video = input_ctx->streams[video_stream];
    if (avcodec_parameters_to_context(decoder_ctx, video->codecpar) < 0){
        avformat_close_input(&input_ctx);
        return -1;
    }

    if(settings.enable_software_video_decoder ||
            // for mjpeg we always use sw decode r.n, since for some reason the "fallback" to sw decode doesn't work here
            // and also the PI cannot do HW mjpeg decode anyways at least no one bothered to fix ffmpeg for it.
            settings.video_codec==QOpenHDVideoHelper::VideoCodecMJPEG
            ){
        qDebug()<<"User wants SW decode / mjpeg";
        decoder_ctx->get_format  = get_sw_format;
    }else{
        qDebug()<<"Try HW decode";
        decoder_ctx->get_format  = get_hw_format;
        if (hw_decoder_init(decoder_ctx, kAvhwDeviceType) < 0){
          qDebug()<<"HW decoder init failed,fallback to SW decode";
          // Use SW decode as fallback ?!
          //return -1;
          // H264 and H265 sw decode is always YUV420P, MJPEG seems to be always YUVJ422P;
          if(is_mjpeg){
            wanted_hw_pix_fmt=AV_PIX_FMT_YUVJ422P;
          }
          wanted_hw_pix_fmt=AV_PIX_FMT_YUV420P;
        }
    }

    // A thread count of 1 reduces latency for both SW and HW decode
    decoder_ctx->thread_count = 1;

   if ((ret = avcodec_open2(decoder_ctx, decoder, nullptr)) < 0) {
        qDebug()<<"Failed to open codec for stream "<< video_stream;
        avformat_close_input(&input_ctx);
        return -1;
    }
    AVPacket packet;
    // actual decoding and dump the raw data
    const auto decodingStart=std::chrono::steady_clock::now();
    int nFeedFrames=0;
    auto lastFrame=std::chrono::steady_clock::now();
    n_no_output_frame_after_x_seconds=0;
    last_frame_width=-1;
    last_frame_height=-1;
    avg_decode_time.reset();
    test_dequeue_fames=true;
    //m_pull_frames_from_ffmpeg_thread=std::make_unique<std::thread>([this]{this->dequeue_frames_test();});
    keep_fetching_frames_or_input_packets=true;
    std::unique_ptr<std::thread> tmp_thread=nullptr;
    if(enable_wtf){
        tmp_thread=std::make_unique<std::thread>([this]{this->fetch_frame_or_feed_input_packet();});
    }
    DecodingStatistcs::instance().set_doing_wait_for_frame_decode("Yes");
    while (ret >= 0) {
        if(has_been_canceled){
            break;
        }
        if(request_restart){
            request_restart=false;
            // Since we do streaming and SPS/PPS come in regular intervals, we can just cancel and restart at any time.
            break;
        }
        if ((ret = av_read_frame(input_ctx, &packet)) < 0){
            qDebug()<<"av_read_frame returned:"<<ret<<" "<<av_error_as_string(ret).c_str();
            if(ret==-110){ //-110   Connection timed out
                ret=0;
                continue;
            }
            break;
        }
        //qDebug()<<"Got av_packet"<<debug_av_packet(&packet).c_str();
        if(false){
             qDebug()<<"Got "<<debug_av_packet(&packet).c_str();
        }else{
            if (video_stream == packet.stream_index){
                int limitedFrameRate=settings.dev_limit_fps_on_test_file;
                if(settings.dev_test_video_mode==QOpenHDVideoHelper::VideoTestMode::DISABLED){
                    // never limit the fps on decode when doing live streaming !
                    limitedFrameRate=-1;
                }
                if(limitedFrameRate>0){
                    const long frameDeltaNs=1000*1000*1000 / limitedFrameRate;
                    while (std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::steady_clock::now()-lastFrame).count()<frameDeltaNs){
                        // busy wait
                    }
                    lastFrame=std::chrono::steady_clock::now();
                }
                if(enable_wtf){
                    enqueue_av_packet(packet);
                }else{
                    ret = decode_and_wait_for_frame(&packet);
                }
                nFeedFrames++;
                if(limitedFrameRate>0){
                    const uint64_t runTimeMs=std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now()-decodingStart).count();
                    const double runTimeS=runTimeMs/1000.0f;
                    const double fps=runTimeS==0 ? 0 : nFeedFrames/runTimeS;
                    //qDebug()<<"Fake fps:"<<fps;
                }
            }
        }
        if(enable_wtf){
            if(keep_fetching_frames_or_input_packets==false){
                qDebug()<<"Decoder encountered an error";
                break;
            }
        }else{
            av_packet_unref(&packet);
        }
    }
    qDebug()<<"Broke out of the queue_data_dequeue_frame loop";
    keep_fetching_frames_or_input_packets=false;
    if(tmp_thread){
        tmp_thread->join();
        tmp_thread=nullptr;
    }
    test_dequeue_fames=false;
    //m_pull_frames_from_ffmpeg_thread->join();
    //m_pull_frames_from_ffmpeg_thread=nullptr;
    // flush the decoder - not needed
    //packet.data = NULL;
    //packet.size = 0;
    //ret = decode_and_wait_for_frame(&packet);
    DecodingStatistcs::instance().set_decode_time("-1");
    DecodingStatistcs::instance().set_primary_stream_frame_format("-1");
    avcodec_free_context(&decoder_ctx);
    qDebug()<<"avcodec_free_context done";
    avformat_close_input(&input_ctx);
    qDebug()<<"avformat_close_input_done";
    return 0;
}

void AVCodecDecoder::add_fed_timestamp(int64_t ts)
{
    m_fed_timestamps_queue.push_back(ts);
    if(m_fed_timestamps_queue.size()>=MAX_FED_TIMESTAMPS_QUEUE_SIZE){
        m_fed_timestamps_queue.pop_front();
    }
}

bool AVCodecDecoder::check_is_a_valid_timestamp(int64_t ts)
{
    for(const auto& el:m_fed_timestamps_queue){
        if(el==ts)return true;
    }
    return false;
}

void AVCodecDecoder::debug_is_valid_timestamp(int64_t ts)
{
    const bool valid=check_is_a_valid_timestamp(ts);
    if(valid){
        qDebug()<<"Is a valid timestamp";
    }else{
        qDebug()<<"Is not a valid timestamp";
    }
}
