#include "avcodec_decoder.h"
#include "qdebug.h"
#include <QFileInfo>
#include <iostream>
#include <sstream>

#include "avcodec_helper.hpp"
#include "util/time/TimeHelper.hpp"

#include "texturerenderer.h"

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

// FFMPEG needs a ".sdp" file to do rtp udp h264,h265 or mjpeg
// For MJPEG we map mjpeg to 26 (mjpeg), for h264/5 we map h264/5 to 96 (general)
static std::string create_udp_rtp_sdp_file(const QOpenHDVideoHelper::VideoCodec& video_codec){
    std::stringstream ss;
    ss<<"c=IN IP4 127.0.0.1\n";
    if(video_codec==QOpenHDVideoHelper::VideoCodec::VideoCodecMJPEG){
         ss<<"m=video 5600 RTP/AVP 26\n";
        ss<<"a=rtpmap:26 JPEG/90000\n";
    }else{
        ss<<"m=video 5600 RTP/AVP 96\n";
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
    QObject(parent)//, timer(new QTimer)
{

}

void AVCodecDecoder::init(bool primaryStream)
{
    /*QObject::connect(timer, &QTimer::timeout, this, &AVCodecDecoder::lulatsch);
    timer->start(1000);*/
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
        request_restart=true;
        m_last_video_settings=new_settings;
    }
}

void AVCodecDecoder::constant_decode()
{
    while(true){
        qDebug()<<"Start decode";
        lulatsch();
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
    int ret = avcodec_send_packet(decoder_ctx, packet);
    if (ret < 0) {
        fprintf(stderr, "Error during decoding\n");
        return ret;
    }
    // alloc output frame(s)
    if (!(frame = av_frame_alloc())) {
        fprintf(stderr, "Can not alloc frame\n");
        ret = AVERROR(ENOMEM);
        av_frame_free(&frame);
        return ret;
    }
    // Poll until we get the frame out
    const auto loopUntilFrameBegin=std::chrono::steady_clock::now();
    bool gotFrame=false;
    while (!gotFrame){
        ret = avcodec_receive_frame(decoder_ctx, frame);
        if(ret == AVERROR_EOF){
            std::cout<<"Got EOF\n";
            break;
        }else if(ret==0){
            // we got a new frame
            const auto x_delay=std::chrono::steady_clock::now()-beforeFeedFrame;
            qDebug()<<"(True) decode delay:"<<((float)std::chrono::duration_cast<std::chrono::microseconds>(x_delay).count()/1000.0f)<<" ms";
            gotFrame=true;
            const auto now=getTimeUs();
            //MLOGD<<"Frame pts:"<<frame->pts<<" Set to:"<<now<<"\n";
            //frame->pts=now;
            frame->pts=beforeFeedFrameUs;
            // display frame
            on_new_frame(frame);
        }else{
            if(n_no_output_frame_after_x_seconds>=2){
                // note decode latency is now wrong
                qDebug()<<"Skipping encode decode lockstep due to no frame for more than X seconds\n";
                break;
            }
            //std::cout<<"avcodec_receive_frame returned:"<<ret<<"\n";
            // for some video files, the decoder does not output a frame every time a h264 frame has been fed
            // In this case, I unblock after X seconds, but we cannot measure the decode delay by using the before-after
            // approach. We can still measure it using the pts timestamp from av, but this one cannot necessarily be trusted 100%
            if(std::chrono::steady_clock::now()-loopUntilFrameBegin > std::chrono::seconds(2)){
              qDebug()<<"Got no frame after X seconds. Break, but decode delay will be reported wrong";
              n_no_output_frame_after_x_seconds++;
              break;
            }
        }
    }
    av_frame_free(&frame);
    return 0;
}

void AVCodecDecoder::on_new_frame(AVFrame *frame)
{
    qDebug()<<"Got frame format:"<<QString(safe_av_get_pix_fmt_name((AVPixelFormat)frame->format).c_str());
    TextureRenderer::instance().queue_new_frame_for_display(frame);
}


int AVCodecDecoder::lulatsch()
{
    const auto settings = QOpenHDVideoHelper::read_from_settings();
    std::string in_filename="";
    if(settings.dev_test_video_mode==QOpenHDVideoHelper::VideoTestMode::DISABLED){
        in_filename=get_udp_rtp_sdp_filename(settings.video_codec);
    }else{
        if(settings.dev_enable_custom_pipeline){
            in_filename=settings.dev_custom_pipeline;
        }else{
            if(settings.video_codec==QOpenHDVideoHelper::VideoCodecH264){
               in_filename="/home/consti10/Desktop/hello_drmprime/in/jetson_test.h264";
            }else if(settings.video_codec==QOpenHDVideoHelper::VideoCodecH265){
               in_filename="/home/consti10/Desktop/hello_drmprime/in/jetson_test.h265";
            }else{
               in_filename="/home/consti10/Desktop/hello_drmprime/in/uv_640x480.mjpeg";
            }
        }
    }
    //const char* in_filename="/home/consti10/Desktop/hello_drmprime/in/rv1126.h265";
    //const char* in_filename="/home/consti10/Desktop/hello_drmprime/in/rtp_h264.sdp";
    //const char* in_filename="/home/consti10/Desktop/hello_drmprime/in/rtp_mjpeg.sdp";
    //const char* in_filename="/home/consti10/Desktop/hello_drmprime/in/jetson_test.h265";
    //const char* in_filename="/home/consti10/Desktop/hello_drmprime/in/uv_640x480.mjpeg";
    //const char* in_filename="empty";

    //char* in_filename="/home/openhd/hello_drmprime/in/rtp_h264.sdp";
    //char* in_filename="/home/openhd/hello_drmprime/in/rv_1280x720_green_white.h265";
    //in_filename="/home/consti10/Desktop/hello_drmprime/in/Big_Buck_Bunny_1080_10s_1MB_h264.mp4";

    // These options are needed for using the foo.sdp (rtp streaming)
    // https://stackoverflow.com/questions/20538698/minimum-sdp-for-making-a-h264-rtp-stream
    // https://stackoverflow.com/questions/16658873/how-to-minimize-the-delay-in-a-live-streaming-with-ffmpeg
    AVDictionary* av_dictionary=nullptr;
    av_dict_set(&av_dictionary, "protocol_whitelist", "file,udp,rtp", 0);
    av_dict_set(&av_dictionary, "buffer_size", "212992", 0);
    av_dict_set(&av_dictionary,"max_delay","0",0);
    av_dict_set(&av_dictionary,"reuse_sockets","1",0);
    /*av_dict_set_int(&av_dictionary, "stimeout", 1000000, 0);
    av_dict_set_int(&av_dictionary, "rw_timeout", 1000000, 0);*/
    av_dict_set_int(&av_dictionary, "reorder_queue_size", 1, 0);
    AVFormatContext *input_ctx = nullptr;
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

    if (avformat_find_stream_info(input_ctx, NULL) < 0) {
        qDebug()<< "Cannot find input stream information.";
        avformat_close_input(&input_ctx);
        return -1;
    }

    // find the video stream information
    //ret = av_find_best_stream(input_ctx, AVMEDIA_TYPE_VIDEO, -1, -1,(const AVCodec**) &decoder, 0);
    int ret = av_find_best_stream(input_ctx, AVMEDIA_TYPE_VIDEO, -1, -1,(AVCodec**) &decoder, 0);
    if (ret < 0) {
        qDebug()<< "Cannot find a video stream in the input file";
        avformat_close_input(&input_ctx);
        return -1;
    }
    const int video_stream = ret;

    if(!(decoder->id==AV_CODEC_ID_H264 || decoder->id==AV_CODEC_ID_H265 || decoder->id==AV_CODEC_ID_MJPEG)){
      std::cerr<<"We only do h264,h265 and mjpeg in this project\n";
      avformat_close_input(&input_ctx);
      return 0;
    }

    const AVHWDeviceType kAvhwDeviceType = AV_HWDEVICE_TYPE_DRM;
    //const AVHWDeviceType kAvhwDeviceType = AV_HWDEVICE_TYPE_VAAPI;
    //const AVHWDeviceType kAvhwDeviceType = AV_HWDEVICE_TYPE_CUDA;
    //const AVHWDeviceType kAvhwDeviceType = AV_HWDEVICE_TYPE_VDPAU;

    bool is_mjpeg=false;
    if (decoder->id == AV_CODEC_ID_H264) {
        std::cout<<"H264 decode\n";
        if ((decoder = avcodec_find_decoder_by_name("h264_v4l2m2m")) == NULL) {
            fprintf(stderr, "Cannot find the h264 v4l2m2m decoder\n");
            avformat_close_input(&input_ctx);
            return -1;
        }
        wanted_hw_pix_fmt = AV_PIX_FMT_DRM_PRIME;
        //wanted_hw_pix_fmt = AV_PIX_FMT_YUV420P;
    }
    else if(decoder->id==AV_CODEC_ID_H265){
        assert(decoder->id==AV_CODEC_ID_H265);
        std::cout<<"H265 decode\n";
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
            ss<<" PIX fmt: "<<safe_av_get_pix_fmt_name(config->pix_fmt)<<"\n";
            std::cout<<ss.str();

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
      std::cout<<"Codec mjpeg\n";
      wanted_hw_pix_fmt=AV_PIX_FMT_YUVJ422P;
      //wanted_hw_pix_fmt=AV_PIX_FMT_CUDA;
      //wanted_hw_pix_fmt = AV_PIX_FMT_DRM_PRIME;
      is_mjpeg= true;
    }else{
      std::cerr<<"We only do h264,h265 and mjpeg in this project\n";
      avformat_close_input(&input_ctx);
      return 0;
    }

    if (!(decoder_ctx = avcodec_alloc_context3(decoder))){
        qDebug()<<"avcodec_alloc_context3 failed";
        avformat_close_input(&input_ctx);
        return -1;
    }
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

    decoder_ctx->get_format  = get_hw_format;

    if(settings.enable_software_video_decoder ||
            // for mjpeg we always use sw decode r.n, since for some reason the "fallback" to sw decode doesn't work here
            // and also the PI cannot do HW mjpeg decode anyways at least no one bothered to fix ffmpeg for it.
            settings.video_codec==QOpenHDVideoHelper::VideoCodecMJPEG
            ){
        qDebug()<<"User wants SW decode / mjpeg";
        // SW decode is always YUV420 for H264/H265 and YUVJ22P for mjpeg
        if(is_mjpeg){
          wanted_hw_pix_fmt=AV_PIX_FMT_YUVJ422P;
        }else{
          wanted_hw_pix_fmt=AV_PIX_FMT_YUV420P;
        }
    }else{
        qDebug()<<"Try HW decode";
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
            qDebug()<<"av_read_frame returned:"<<ret<<"\n";
            break;
        }
        const int limitedFrameRate=120;
        if (video_stream == packet.stream_index){
            if(limitedFrameRate>0){
                const long frameDeltaNs=1000*1000*1000 / limitedFrameRate;
                while (std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::steady_clock::now()-lastFrame).count()<frameDeltaNs){
                    // busy wait
                }
                lastFrame=std::chrono::steady_clock::now();
            }
            ret = decode_and_wait_for_frame(&packet);
            nFeedFrames++;
            const uint64_t runTimeMs=std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now()-decodingStart).count();
            const double runTimeS=runTimeMs/1000.0f;
            const double fps=runTimeS==0 ? 0 : nFeedFrames/runTimeS;
            qDebug()<<"Fake fps:"<<fps;
        }
        av_packet_unref(&packet);
    }
    // flush the decoder - not needed
    packet.data = NULL;
    packet.size = 0;
    ret = decode_and_wait_for_frame(&packet);

    avcodec_free_context(&decoder_ctx);
    avformat_close_input(&input_ctx);

    return 0;

}
