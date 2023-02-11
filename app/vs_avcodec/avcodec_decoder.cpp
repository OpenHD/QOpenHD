#include "avcodec_decoder.h"
#include "qdebug.h"
#include <QFileInfo>
#include <iostream>
#include <sstream>

#include "avcodec_helper.hpp"
#include "../common/TimeHelper.hpp"

#include "texturerenderer.h"
#include "../vs_util/decodingstatistcs.h"
#include "common/SchedulingHelper.hpp"
#include "../util/WorkaroundMessageBox.h"
#include "../logging/hudlogmessagesmodel.h"

#ifdef HAVE_MMAL
#include "mmal/rpimmaldecodedisplay.h"
//#include "mmal/rpi_check_fkms.h"
#endif

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

static enum AVPixelFormat wanted_hw_pix_fmt;
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
        if(tmp==AV_PIX_FMT_YUV420P || tmp==AV_PIX_FMT_YUV422P || tmp==AV_PIX_FMT_YUVJ422P || tmp==AV_PIX_FMT_YUVJ420P){
            return tmp;
        }
    }
    qDebug()<<"Weird, we should be able to do SW decoding on all platforms";
    return AV_PIX_FMT_NONE;
}


AVCodecDecoder::AVCodecDecoder(QObject *parent):
    QObject(parent)
{
    //drm_prime_out=std::make_unique<DRMPrimeOut>(1,false,false);
}

AVCodecDecoder::~AVCodecDecoder()
{
    terminate();
}

void AVCodecDecoder::init(bool primaryStream)
{
    qDebug() << "AVCodecDecoder::init()";
    m_last_video_settings=QOpenHDVideoHelper::read_from_settings();
    decode_thread = std::make_unique<std::thread>([this]{this->constant_decode();} );
    timer_check_settings_changed=std::make_unique<QTimer>();
    QObject::connect(timer_check_settings_changed.get(), &QTimer::timeout, this, &AVCodecDecoder::timer_check_settings_changed_callback);
    timer_check_settings_changed->start(1000);
}

void AVCodecDecoder::terminate()
{
    // Stop the timer, which can be done (almost) immediately (it's runnable doesn't block)
    timer_check_settings_changed->stop();
    timer_check_settings_changed=nullptr;
    // This will stop the constant_decode as soon as the current running decode_until_error loop returns
    m_should_terminate=true;
    // This will break out of a running "decode until error" loop if there is one currently running
    request_restart=true;
    if(decode_thread){
        // Wait for everything to cleanup and stop
        decode_thread->join();
    }
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

void AVCodecDecoder::constant_decode()
{
    while(!m_should_terminate){
        qDebug()<<"Start decode";
         const auto settings = QOpenHDVideoHelper::read_from_settings();
         bool do_custom_rtp=settings.dev_use_low_latency_parser_when_possible;
         if(settings.video_codec==QOpenHDVideoHelper::VideoCodecMJPEG){
             // we got no support for mjpeg in our custom rtp parser
             do_custom_rtp=false;
         }
         if(settings.dev_test_video_mode!=QOpenHDVideoHelper::VideoTestMode::DISABLED){
             // file playback always goes via non-custom rtp parser (since it is not rtp)
             do_custom_rtp=false;
         }
         if(do_custom_rtp){
#ifdef HAVE_MMAL
             // When we have mmal at compile time, we can do the "even more optimized" path for h264 decode on pi
             // (but only for h264 HW decode and rtp)
             if(settings.dev_test_video_mode==QOpenHDVideoHelper::VideoTestMode::DISABLED
                     && settings.enable_software_video_decoder==false
                     && settings.video_codec==QOpenHDVideoHelper::VideoCodecH264){
                 if(settings.dev_rpi_use_external_mmal_decode_service){
                     dirty_rpi_decode_via_external_decode_service();
                 }else{
                     open_and_decode_until_error_custom_rtp_and_mmal_direct(settings);
                 }
             }else{
                 open_and_decode_until_error_custom_rtp(settings);
             }
#else
             // Does h264 and h265 custom rtp parse, but uses avcodec for decode
             open_and_decode_until_error_custom_rtp(settings);
#endif
         }else{
             open_and_decode_until_error(settings);
         }
        qDebug()<<"Decode stopped,restarting";
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
}


int AVCodecDecoder::decode_and_wait_for_frame(AVPacket *packet,std::optional<std::chrono::steady_clock::time_point> parse_time)
{
    AVFrame *frame = nullptr;
    //qDebug()<<"Decode packet:"<<packet->pos<<" size:"<<packet->size<<" B";
    const auto beforeFeedFrame=std::chrono::steady_clock::now();
    if(parse_time!=std::nullopt){
        const auto delay=beforeFeedFrame-parse_time.value();
        avg_parse_time.add(delay);
        avg_parse_time.custom_print_in_intervals(std::chrono::seconds(3),[](const std::string name,const std::string message){
            //qDebug()<<name.c_str()<<":"<<message.c_str();
            DecodingStatistcs::instance().set_parse_and_enqueue_time(message.c_str());
        });
    }
    const auto beforeFeedFrameUs=getTimeUs();
    packet->pts=beforeFeedFrameUs;
    timestamp_add_fed(packet->pts);

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
            avg_decode_time.custom_print_in_intervals(std::chrono::seconds(3),[](const std::string name,const std::string message){
                //qDebug()<<name.c_str()<<":"<<message.c_str();
                DecodingStatistcs::instance().set_decode_time(message.c_str());
            });
        }else if(ret==AVERROR(EAGAIN)){
            // TODO FIXME REMOVE
            if(true){
                break;
            }
            if(n_no_output_frame_after_x_seconds>=2){
                // note decode latency is now wrong
                //qDebug()<<"Skipping decode lockstep due to no frame for more than X seconds\n";
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
            break;
        }
        n_times_we_tried_getting_a_frame_this_time++;
    }
    av_frame_free(&frame);
    return 0;
}

int AVCodecDecoder::decode_config_data(AVPacket *packet)
{
     const int ret_avcodec_send_packet = avcodec_send_packet(decoder_ctx, packet);
     return ret_avcodec_send_packet;
}


bool AVCodecDecoder::feed_rtp_frame_if_available()
{
    auto frame=m_rtp_receiver->get_next_frame();
    if(frame){
        {
            // parsing delay
            const auto delay=std::chrono::steady_clock::now()-frame->creationTime;
            avg_parse_time.add(delay);
            avg_parse_time.custom_print_in_intervals(std::chrono::seconds(3),[](const std::string name,const std::string message){
                //qDebug()<<name.c_str()<<":"<<message.c_str();
                DecodingStatistcs::instance().set_parse_and_enqueue_time(message.c_str());
            });
        }
        AVPacket *pkt=av_packet_alloc();
        pkt->data=(uint8_t*)frame->getData();
        pkt->size=frame->getSize();
        const auto beforeFeedFrameUs=getTimeUs();
        pkt->pts=beforeFeedFrameUs;
        timestamp_add_fed(pkt->pts);
        avcodec_send_packet(decoder_ctx, pkt);
        av_packet_free(&pkt);
        return true;
    }
    return false;
}

bool AVCodecDecoder::create_decoder_context(const QOpenHDVideoHelper::VideoStreamConfig settings)
{

}

void AVCodecDecoder::fetch_frame_or_feed_input_packet(){
    AVPacket *pkt=av_packet_alloc();
    bool keep_fetching_frames_or_input_packets=true;
    while(keep_fetching_frames_or_input_packets){
        if(request_restart){
            keep_fetching_frames_or_input_packets=false;
            request_restart=false;
            continue;
        }
        AVFrame* frame= av_frame_alloc();
        assert(frame);
        const int ret = avcodec_receive_frame(decoder_ctx, frame);
        //m_ffmpeg_dequeue_or_queue_mutex.unlock();
        if(ret == AVERROR_EOF){
            qDebug()<<"Got EOF";
            keep_fetching_frames_or_input_packets=false;
        }else if(ret==0){
            timestamp_debug_valid(frame->pts);
            // we got a new frame
            const auto now_us=getTimeUs();
            const auto delay_us=now_us-frame->pts;
            //qDebug()<<"(True) decode delay(nowait):"<<((float)delay_us/1000.0f)<<" ms";
            //frame->pts=now;
            avg_decode_time.add(std::chrono::microseconds(delay_us));
            // display frame
            on_new_frame(frame);
            avg_decode_time.custom_print_in_intervals(std::chrono::seconds(3),[](const std::string name,const std::string message){
                 //qDebug()<<name.c_str()<<":"<<message.c_str();
                 DecodingStatistcs::instance().set_decode_time(message.c_str());
            });
            av_frame_free(&frame);
            frame= av_frame_alloc();
        }else if(ret==AVERROR(EAGAIN)){
            //qDebug()<<"Needs more data";
            // Get more encoded data
            const bool success=feed_rtp_frame_if_available();
            if(!success){
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
            }
        }else{
            qDebug()<<"Weird decoder error:"<<ret;
            keep_fetching_frames_or_input_packets=false;
        }
    }
    av_packet_free(&pkt);
}

void AVCodecDecoder::on_new_frame(AVFrame *frame)
{
    {
        std::stringstream ss;
        ss<<safe_av_get_pix_fmt_name((AVPixelFormat)frame->format)<<" "<<frame->width<<"x"<<frame->height;
        DecodingStatistcs::instance().set_primary_stream_frame_format(QString(ss.str().c_str()));
        //qDebug()<<"Got frame:"<<ss.str().c_str();
    }
    // Once we got the first frame, reduce the log level
    av_log_set_level(AV_LOG_WARNING);
    if(frame->format==AV_PIX_FMT_MMAL){
#ifdef HAVE_MMAL
        TextureRenderer::instance().clear_all_video_textures_next_frame();
        const auto before=std::chrono::steady_clock::now();
        RpiMMALDisplay::instance().display_frame(frame);
        avg_send_mmal_frame_to_display.add(std::chrono::steady_clock::now()-before);
        avg_send_mmal_frame_to_display.custom_print_in_intervals(std::chrono::seconds(3),[](const std::string name,const std::string message){
            qDebug()<<name.c_str()<<":"<<message.c_str();
        });
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

void AVCodecDecoder::reset_before_decode_start()
{
    n_no_output_frame_after_x_seconds=0;
    last_frame_width=-1;
    last_frame_height=-1;
    avg_decode_time.reset();
    avg_parse_time.reset();
    DecodingStatistcs::instance().set_doing_wait_for_frame_decode("Yes");
    last_frame_width=-1;
    last_frame_height=-1;
    m_fed_timestamps_queue.clear();
    DecodingStatistcs::instance().set_decoding_type("?");
}

int AVCodecDecoder::open_and_decode_until_error(const QOpenHDVideoHelper::VideoStreamConfig settings)
{
    std::string in_filename="";
    if(settings.dev_test_video_mode==QOpenHDVideoHelper::VideoTestMode::DISABLED){
        in_filename=QOpenHDVideoHelper::get_udp_rtp_sdp_filename(settings);
        //in_filename="rtp://192.168.0.1:5600";
    }else{
        if(settings.dev_enable_custom_pipeline){
            in_filename=settings.dev_custom_pipeline;
        }else{
            // For testing, I regulary change the filename(s) and recompile
            const bool consti_testing=false;
            if(consti_testing){
                if(settings.video_codec==QOpenHDVideoHelper::VideoCodecH264){
                     //in_filename="/tmp/x_raw_h264.h264";
                    in_filename="/home/consti10/Desktop/hello_drmprime/in/rpi_1080.h264";
                    //in_filename="/home/consti10/Desktop/hello_drmprime/in/rv_1280x720_green_white.h264";
                    //in_filename="/home/consti10/Desktop/hello_drmprime/in/Big_Buck_Bunny_1080_10s_1MB_h264.mp4";
                }else if(settings.video_codec==QOpenHDVideoHelper::VideoCodecH265){
                      //in_filename="/tmp/x_raw_h265.h265";
                    in_filename="/home/consti10/Desktop/hello_drmprime/in/jetson_test.h265";
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

    av_dict_set(&av_dictionary,"timeout",0,0);

    // For decode ?!
    av_dict_set_int(&av_dictionary, "extra_buffers", 10, 0);

    AVFormatContext *input_ctx = nullptr;
    input_ctx=avformat_alloc_context();
    assert(input_ctx);
    /*input_ctx->video_codec_id=AV_CODEC_ID_H264;
    input_ctx->flags |= AVFMT_FLAG_FLUSH_PACKETS;
    input_ctx->flags |= AVFMT_FLAG_NOBUFFER;*/
    //input_ctx->avio_flags = AVIO_FLAG_DIRECT;
    //input_ctx->flags |= AVFMT_FLAG_NOBUFFER;// | AVFMT_FLAG_FLUSH_PACKETS;

    //input_ctx->flags |= AVFMT_FLAG_NOFILLIN;
    //input_ctx->flags |= AVFMT_FLAG_NOPARSE;
    //input_ctx->flags |= AVFMT_FLAG_NONBLOCK;

    // open the input file
    if (avformat_open_input(&input_ctx,in_filename.c_str(), NULL, &av_dictionary) != 0) {
        qDebug()<< "Cannot open input file ["<<in_filename.c_str()<<"]";
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
    int ret=0;
    // find the video stream information
#if LIBAVFORMAT_VERSION_MAJOR < 59 || (LIBAVFORMAT_VERSION_MAJOR == 59 && LIBAVFORMAT_VERSION_MINOR == 0 && LIBAVFORMAT_VERSION_MICRO < 100)
     ret = av_find_best_stream(input_ctx, AVMEDIA_TYPE_VIDEO, -1, -1,(AVCodec**) &decoder, 0);
#else
    ret = av_find_best_stream(input_ctx, AVMEDIA_TYPE_VIDEO, -1, -1,(const AVCodec**) &decoder, 0);
#endif
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
        qDebug()<<all_hw_configs_for_this_codec(decoder).c_str();
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

    std::string selected_decoding_type="?";
    if(settings.enable_software_video_decoder ||
            // for mjpeg we always use sw decode r.n, since for some reason the "fallback" to sw decode doesn't work here
            // and also the PI cannot do HW mjpeg decode anyways at least no one bothered to fix ffmpeg for it.
            settings.video_codec==QOpenHDVideoHelper::VideoCodecMJPEG
            ){
        qDebug()<<"User wants SW decode / mjpeg";
        decoder_ctx->get_format  = get_sw_format;
        selected_decoding_type="SW";
    }else{
        qDebug()<<"Try HW decode";
        decoder_ctx->get_format  = get_hw_format;
        if (hw_decoder_init(decoder_ctx, kAvhwDeviceType) < 0){
          qDebug()<<"HW decoder init failed,fallback to SW decode";
          selected_decoding_type="SW(HW failed)";
          // Use SW decode as fallback ?!
          //return -1;
          // H264 and H265 sw decode is always YUV420P, MJPEG seems to be always YUVJ422P;
          if(is_mjpeg){
            wanted_hw_pix_fmt=AV_PIX_FMT_YUVJ422P;
          }
          wanted_hw_pix_fmt=AV_PIX_FMT_YUV420P;
        }else{
            selected_decoding_type="HW";
        }
    }

    // A thread count of 1 reduces latency for both SW and HW decode
    decoder_ctx->thread_count = 1;

   if ((ret = avcodec_open2(decoder_ctx, decoder, nullptr)) < 0) {
        qDebug()<<"Failed to open codec for stream ";//<< video_stream;
        avformat_close_input(&input_ctx);
        return -1;
    }
    AVPacket packet;
    // actual decoding and dump the raw data
    const auto decodingStart=std::chrono::steady_clock::now();
    int nFeedFrames=0;
    auto lastFrame=std::chrono::steady_clock::now();
    reset_before_decode_start();
    DecodingStatistcs::instance().set_decoding_type(selected_decoding_type.c_str());
    while (ret >= 0) {
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
            //std::vector<uint8_t> as_buff(packet.data,packet.data+packet.size);
            //qDebug()<<"Packet:"<<StringHelper::vectorAsString(as_buff).c_str()<<"\n";

            if (video_stream == packet.stream_index){
            //if(true){
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
                ret = decode_and_wait_for_frame(&packet);
                nFeedFrames++;
                if(limitedFrameRate>0){
                    const uint64_t runTimeMs=std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now()-decodingStart).count();
                    const double runTimeS=runTimeMs/1000.0f;
                    const double fps=runTimeS==0 ? 0 : nFeedFrames/runTimeS;
                    //qDebug()<<"Fake fps:"<<fps;
                }
            }
        }
         av_packet_unref(&packet);
    }
    qDebug()<<"Broke out of the queue_data_dequeue_frame loop";
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


// https://ffmpeg.org/doxygen/3.3/decode_video_8c-example.html
void AVCodecDecoder::open_and_decode_until_error_custom_rtp(const QOpenHDVideoHelper::VideoStreamConfig settings)
{
    // This thread pulls frame(s) from the rtp decoder and therefore should have high priority
    SchedulingHelper::setThreadParamsMaxRealtime();
    av_log_set_level(AV_LOG_TRACE);
     assert(settings.video_codec==QOpenHDVideoHelper::VideoCodecH264 || settings.video_codec==QOpenHDVideoHelper::VideoCodecH265);
     if(settings.video_codec==QOpenHDVideoHelper::VideoCodecH264){
         decoder = avcodec_find_decoder(AV_CODEC_ID_H264);
     }else if(settings.video_codec==QOpenHDVideoHelper::VideoCodecH265){
         decoder = avcodec_find_decoder(AV_CODEC_ID_H265);
     }
     if (!decoder) {
         qDebug()<< "AVCodecDecoder::open_and_decode_until_error_custom_rtp: Codec not found";
         return;
     }
     // ----------------------
     bool use_pi_hw_decode=false;
     if (decoder->id == AV_CODEC_ID_H264) {
         qDebug()<<"H264 decode";
         qDebug()<<all_hw_configs_for_this_codec(decoder).c_str();
         if(!settings.enable_software_video_decoder){
             auto tmp = avcodec_find_decoder_by_name("h264_mmal");
             if(tmp!=nullptr){
                 decoder = tmp;
                 wanted_hw_pix_fmt = AV_PIX_FMT_MMAL;
                 use_pi_hw_decode=true;
             }else{
                 wanted_hw_pix_fmt = AV_PIX_FMT_YUV420P;
             }
         }else{
             wanted_hw_pix_fmt = AV_PIX_FMT_YUV420P;
         }
     }else if(decoder->id==AV_CODEC_ID_H265){
         qDebug()<<"H265 decode";
         if(!settings.enable_software_video_decoder){
             qDebug()<<all_hw_configs_for_this_codec(decoder).c_str();
             // HW format used by rpi h265 HW decoder
             wanted_hw_pix_fmt = AV_PIX_FMT_DRM_PRIME;
             use_pi_hw_decode=true;
         }else{

         }
     }
     // ------------------------------------
     decoder_ctx = avcodec_alloc_context3(decoder);
     if (!decoder_ctx) {
         qDebug()<< "AVCodecDecoder::open_and_decode_until_error_custom_rtp: Could not allocate video codec context";
         return;
     }
     // ----------------------------------
#ifdef HAVE_MMAL
     AVDictionary* av_dictionary=nullptr;
     RpiMMALDisplay::instance().prepareDecoderContext(decoder_ctx,&av_dictionary);
#endif
    // From moonlight-qt. However, on PI, this doesn't seem to make any difference, at least for H265 decode.
    // (I never measured h264, but don't think there it is different).
    // Always request low delay decoding
    decoder_ctx->flags |= AV_CODEC_FLAG_LOW_DELAY;
    // Allow display of corrupt frames and frames missing references
    decoder_ctx->flags |= AV_CODEC_FLAG_OUTPUT_CORRUPT;
    decoder_ctx->flags2 |= AV_CODEC_FLAG2_SHOW_ALL;
    // --------------------------------------
    // --------------------------------------
    std::string selected_decoding_type="?";
    if(use_pi_hw_decode){
        decoder_ctx->get_format  = get_hw_format;
        if (hw_decoder_init(decoder_ctx, AV_HWDEVICE_TYPE_DRM) < 0){
          qDebug()<<"HW decoder init failed,fallback to SW decode";
          selected_decoding_type="SW(HW failed)";
          assert(true);
        }else{
            selected_decoding_type="HW";
        }
    }else{
        selected_decoding_type="SW";
    }
    // A thread count of 1 reduces latency for both SW and HW decode
    decoder_ctx->thread_count = 1;

    // ---------------------------------------

     if (avcodec_open2(decoder_ctx, decoder, NULL) < 0) {
         fprintf(stderr, "Could not open codec\n");
         avcodec_free_context(&decoder_ctx);
         return;
     }
     qDebug()<<"AVCodecDecoder::open_and_decode_until_error_custom_rtp()-begin loop";
     m_rtp_receiver=std::make_unique<RTPReceiver>(settings.udp_rtp_input_port,settings.udp_rtp_input_ip_address,settings.video_codec==1,settings.dev_feed_incomplete_frames_to_decoder);

     reset_before_decode_start();
     DecodingStatistcs::instance().set_decoding_type(selected_decoding_type.c_str());
     AVPacket *pkt=av_packet_alloc();
     assert(pkt!=nullptr);
     bool has_keyframe_data=false;
     while(true){
         // We break out of this loop if someone requested a restart
         if(request_restart){
             request_restart=false;
             goto finish;
         }
         // or the decode config changed and we need a restart
         if(m_rtp_receiver->config_has_changed_during_decode){
             qDebug()<<"Break/Restart,config has changed during decode";
             goto finish;
         }
         //std::this_thread::sleep_for(std::chrono::milliseconds(3000));
         if(!has_keyframe_data){
              std::shared_ptr<std::vector<uint8_t>> keyframe_buf=m_rtp_receiver->get_config_data();
              if(keyframe_buf==nullptr){
                  std::this_thread::sleep_for(std::chrono::milliseconds(100));
                  continue;
              }
              qDebug()<<"Got decode data (before keyframe)";
              pkt->data=keyframe_buf->data();
              pkt->size=keyframe_buf->size();
              decode_config_data(pkt);
              has_keyframe_data=true;
              continue;
         }else{
             std::shared_ptr<NALU> buf =m_rtp_receiver->get_next_frame(std::chrono::milliseconds(kDefaultFrameTimeout));
             if(buf==nullptr){
                 // No buff after X seconds
                 continue;
             }
             //qDebug()<<"Got decode data (after keyframe)";
             pkt->data=(uint8_t*)buf->getData();
             pkt->size=buf->getSize();
             decode_and_wait_for_frame(pkt,buf->creationTime);
             //fetch_frame_or_feed_input_packet();
         }
     }
finish:
     qDebug()<<"AVCodecDecoder::open_and_decode_until_error_custom_rtp()-end loop";
     m_rtp_receiver=nullptr;
     avcodec_free_context(&decoder_ctx);
}

#ifdef HAVE_MMAL
void AVCodecDecoder::open_and_decode_until_error_custom_rtp_and_mmal_direct(const QOpenHDVideoHelper::VideoStreamConfig settings)
{
    qDebug()<<"AVCodecDecoder::open_and_decode_until_error_custom_rtp_and_mmal_direct";
    //if(!rpi::check_mmal::is_fkms_enabled()){
    //    workaround::makePopupMessage("FKMS disabled - video won't work");
    //}
    assert(settings.video_codec==QOpenHDVideoHelper::VideoCodecH264);
    assert(settings.enable_software_video_decoder==false);
    assert(settings.dev_test_video_mode==QOpenHDVideoHelper::VideoTestMode::DISABLED);

    m_rtp_receiver=std::make_unique<RTPReceiver>(settings.udp_rtp_input_port,settings.udp_rtp_input_ip_address,false,settings.dev_feed_incomplete_frames_to_decoder);
    std::unique_ptr<RPIMMalDecodeDisplay> mmal_decode_display=std::make_unique<RPIMMalDecodeDisplay>();
    // We use the HW composer, not opengl
    TextureRenderer::instance().clear_all_video_textures_next_frame();

    reset_before_decode_start();
    DecodingStatistcs::instance().set_primary_stream_frame_format("MMAL waiting");
    DecodingStatistcs::instance().set_decoding_type("HW");
    bool cb_set=false;

    bool has_keyframe_data=false;
    int feed_frame_error_count=0;

    std::chrono::steady_clock::time_point m_last_log_decoder_unhealty=std::chrono::steady_clock::now();

    while(true){
        if(request_restart){
            request_restart=false;
            goto finish;
        }
        if(m_rtp_receiver->config_has_changed_during_decode){
            qDebug()<<"Break/Restart,config has changed during decode";
            goto finish;
        }
        /*if(feed_frame_error_count>10){
            // Decoder clearly unhealthy, use a full restart to fix it
            qDebug()<<"MMAL Direct decoder unhealthy-restart";
            goto finish;
        }*/
        //std::this_thread::sleep_for(std::chrono::milliseconds(3000));
        if(!has_keyframe_data){
            std::shared_ptr<std::vector<uint8_t>> keyframe_buf=m_rtp_receiver->get_config_data();
            if(keyframe_buf==nullptr){
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
                continue;
            }
             qDebug()<<"Got decode data (before keyframe)";
             //RPIMMALDecoder::instance().initialize(keyframe_buf->data(),keyframe_buf->size(),640,480,30);
             const auto w_h=m_rtp_receiver->sps_get_width_height();
             {
                 std::stringstream ss;
                 ss<<"MMAL "<<w_h[0]<<"x"<<w_h[1];
                 DecodingStatistcs::instance().set_primary_stream_frame_format(ss.str().c_str());
             }
             mmal_decode_display->initialize(keyframe_buf->data(),keyframe_buf->size(),w_h[0], w_h[1],60);
             has_keyframe_data=true;
             continue;
        }else{
		  // Switch over to a callback-based approach for lower latency. mmal already has a frame queue, so we don't need an extra one
            if(!cb_set){
                auto cb=[this,&mmal_decode_display,&feed_frame_error_count,&m_last_log_decoder_unhealty](std::shared_ptr<NALU> buf){
                    const bool feed_frame_success=mmal_decode_display->feed_frame(buf->getData(),buf->getSize(),std::chrono::milliseconds(8));
                    //const auto duration_feed_frame=std::chrono::steady_clock::now()-before_feed_frame;
                    //qDebug()<<"feed frame time:"<<MyTimeHelper::R(duration_feed_frame).c_str();
                    if(!feed_frame_success){
                        qDebug()<<"MMAL - cannot feed frame";
                        feed_frame_error_count++;
                        DecodingStatistcs::instance().set_n_decoder_dropped_frames(feed_frame_error_count);
                        // Tell user what's going on
                        const auto elapsed_since_last_log=std::chrono::steady_clock::now()-m_last_log_decoder_unhealty;
                        if(elapsed_since_last_log>std::chrono::seconds(3)){
                            m_last_log_decoder_unhealty=std::chrono::steady_clock::now();
                            HUDLogMessagesModel::instance().add_message_warning("Decoder unhealthy-reduce load");
                        }
                    }
                    const auto delay=std::chrono::steady_clock::now()-buf->creationTime;
                    avg_parse_time.add(delay);
                    avg_parse_time.custom_print_in_intervals(std::chrono::seconds(3),[](const std::string name,const std::string message){
                        //qDebug()<<name.c_str()<<":"<<message.c_str();
                        DecodingStatistcs::instance().set_parse_and_enqueue_time(message.c_str());
                    });
                };
                m_rtp_receiver->register_new_nalu_callback(cb);
                cb_set=true;
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(500));
            /*std::shared_ptr<NALU> buf=nullptr;
             while(buf==nullptr){
                 // for some weird reason, using the queue with a waking up approach doesn't work on rpi.
                 // doesn't work == by using a timeout, we get incredibly high parse & enqueue time (in the 250ms range)
                 // It doesn't make sense from a sw standpoint, but we unfortunately need to use a
                 // "wake upd in regular intervalls and fetch latest" approach here.
                 // This doesn't work
                 //buf=m_rtp_receiver->get_next_frame(std::chrono::milliseconds(5));
                 // This works
                 std::this_thread::sleep_for(std::chrono::milliseconds(5));
                 buf=m_rtp_receiver->get_next_frame(std::nullopt);
                 if(request_restart){
                     request_restart=false;
                     goto finish;
                 }
             }
              //const auto before_feed_frame=std::chrono::steady_clock::now();
              const bool feed_frame_success=mmal_decode_display->feed_frame(buf->getData(),buf->getSize());
              //const auto duration_feed_frame=std::chrono::steady_clock::now()-before_feed_frame;
              //qDebug()<<"feed frame time:"<<MyTimeHelper::R(duration_feed_frame).c_str();
              if(!feed_frame_success){
                  feed_frame_error_count++;
              }
              const auto delay=std::chrono::steady_clock::now()-buf->creationTime;
              avg_parse_time.add(delay);
              avg_parse_time.custom_print_in_intervals(std::chrono::seconds(3),[](const std::string name,const std::string message){
                  //qDebug()<<name.c_str()<<":"<<message.c_str();
                  DecodingStatistcs::instance().set_parse_and_enqueue_time(message.c_str());
              });*/
        }
    }
finish:
    qDebug()<<"AVCodecDecoder::open_and_decode_until_error_custom_rtp_and_mmal_direct-end loop";
    m_rtp_receiver=nullptr;
    mmal_decode_display->cleanup();
    mmal_decode_display=nullptr;
}
#endif


void AVCodecDecoder::timestamp_add_fed(int64_t ts)
{
    m_fed_timestamps_queue.push_back(ts);
    if(m_fed_timestamps_queue.size()>=MAX_FED_TIMESTAMPS_QUEUE_SIZE){
        m_fed_timestamps_queue.pop_front();
    }
}

bool AVCodecDecoder::timestamp_check_valid(int64_t ts)
{
    for(const auto& el:m_fed_timestamps_queue){
        if(el==ts)return true;
    }
    return false;
}

void AVCodecDecoder::timestamp_debug_valid(int64_t ts)
{
    const bool valid=timestamp_check_valid(ts);
    if(valid){
        qDebug()<<"Is a valid timestamp";
    }else{
        qDebug()<<"Is not a valid timestamp";
    }
}
