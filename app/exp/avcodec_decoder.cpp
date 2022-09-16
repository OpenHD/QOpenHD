#include "avcodec_decoder.h"
#include "qdebug.h"
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
    std::cout<<"Supported (HW) pixel formats: "<<supported_formats.str()<<"\n";
    if(ret==AV_PIX_FMT_NONE){
      fprintf(stderr, "Failed to get HW surface format. Wanted: %s\n", av_get_pix_fmt_name(wanted_hw_pix_fmt));
    }
    return ret;
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
    decode_thread = std::make_unique<std::thread>([this]{this->constant_decode();} );
}

void AVCodecDecoder::cancel()
{
    has_been_canceled=true;
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
    qDebug()<<"Decode packet:"<<packet->pos<<" size:"<<packet->size<<" B\n";
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
            qDebug()<<"(True) decode delay:"<<((float)std::chrono::duration_cast<std::chrono::microseconds>(x_delay).count()/1000.0f)<<" ms\n";
            gotFrame=true;
            const auto now=getTimeUs();
            //MLOGD<<"Frame pts:"<<frame->pts<<" Set to:"<<now<<"\n";
            //frame->pts=now;
            frame->pts=beforeFeedFrameUs;
            // display frame
            on_new_frame(frame);
        }else{
            std::cout<<"avcodec_receive_frame returned:"<<ret<<"\n";
            // for some video files, the decoder does not output a frame every time a h264 frame has been fed
            // In this case, I unblock after X seconds, but we cannot measure the decode delay by using the before-after
            // approach. We can still measure it using the pts timestamp from av, but this one cannot necessarily be trusted 100%
            if(std::chrono::steady_clock::now()-loopUntilFrameBegin > std::chrono::seconds(2)){
              std::cout<<"Go no frame after X seconds. Break, but decode delay will be reported wrong\n";
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
    const char* in_filename="/home/consti10/Desktop/hello_drmprime/in/rv1126.h265";
    //const char* in_filename="/home/consti10/Desktop/hello_drmprime/in/rtp_h264.sdp";
    //const char* in_filename="/home/consti10/Desktop/hello_drmprime/in/jetson_test.h265";
    //const char* in_filename="/home/consti10/Desktop/hello_drmprime/in/uv_640x480.mjpeg";
    //const char* in_filename="empty";

    //char* in_filename="/home/openhd/hello_drmprime/in/rtp_h264.sdp";
    //char* in_filename="/home/openhd/hello_drmprime/in/rv_1280x720_green_white.h265";

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
    if (avformat_open_input(&input_ctx,in_filename, NULL, &av_dictionary) != 0) {
        fprintf(stderr, "Cannot open input file '%s'\n", in_filename);
        open_input_error_count++;
        avformat_close_input(&input_ctx);
        return -1;
    }

    if (avformat_find_stream_info(input_ctx, NULL) < 0) {
        fprintf(stderr, "Cannot find input stream information.\n");
        avformat_close_input(&input_ctx);
        return -1;
    }

    // find the video stream information
    //ret = av_find_best_stream(input_ctx, AVMEDIA_TYPE_VIDEO, -1, -1,(const AVCodec**) &decoder, 0);
    int ret = av_find_best_stream(input_ctx, AVMEDIA_TYPE_VIDEO, -1, -1,(AVCodec**) &decoder, 0);
    if (ret < 0) {
        fprintf(stderr, "Cannot find a video stream in the input file\n");
        avformat_close_input(&input_ctx);
        return -1;
    }
    const int video_stream = ret;

    if(!(decoder->id==AV_CODEC_ID_H264 || decoder->id==AV_CODEC_ID_H265 || decoder->id==AV_CODEC_ID_MJPEG)){
      std::cerr<<"We only do h264,h265 and mjpeg in this project\n";
      avformat_close_input(&input_ctx);
      return 0;
    }

    //const AVHWDeviceType kAvhwDeviceType = av_hwdevice_find_type_by_name(hwdev);
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
        std::cout<<"avcodec_alloc_context3 failed\n";
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

    // needed for FFMPEG ?
    //decoder_ctx->extra_hw_frames = 10;

    if (hw_decoder_init(decoder_ctx, kAvhwDeviceType) < 0){
      std::cerr<<"HW decoder init failed,fallback to SW decode\n";
      // Use SW decode as fallback ?!
      //return -1;
      // H264 and H265 sw decode is always YUV420P, MJPEG seems to be always YUVJ422P;
      if(is_mjpeg){
        wanted_hw_pix_fmt=AV_PIX_FMT_YUVJ422P;
      }
      wanted_hw_pix_fmt=AV_PIX_FMT_YUV420P;
    }

    // Consti10
    decoder_ctx->thread_count = 1;

    if ((ret = avcodec_open2(decoder_ctx, decoder, nullptr)) < 0) {
        fprintf(stderr, "Failed to open codec for stream #%u\n", video_stream);
        avformat_close_input(&input_ctx);
        return -1;
    }
    AVPacket packet;
    // actual decoding and dump the raw data
    const auto decodingStart=std::chrono::steady_clock::now();
    int nFeedFrames=0;
    auto lastFrame=std::chrono::steady_clock::now();
    while (ret >= 0) {
        if ((ret = av_read_frame(input_ctx, &packet)) < 0){
            qDebug()<<"av_read_frame returned 0\n";
            break;
        }
        const int limitedFrameRate=120;
        if (video_stream == packet.stream_index){
            if(limitedFrameRate!=-1){
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
            qDebug()<<"Fake fps:"<<fps<<"\n";
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
