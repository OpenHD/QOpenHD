#ifndef EXTERNALDECODESERVICE_H
#define EXTERNALDECODESERVICE_H

#include "QOpenHDVideoHelper.hpp"
#include "common/openhd-util.hpp"
#include "decodingstatistcs.h"

#include <logging/logmessagesmodel.h>
#include <logging/hudlogmessagesmodel.h>
#include <thread>
#include <cstring>
#include <sstream>

#ifdef __linux__
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#endif

//
// On some platforms, it is easiest to just start and stop a service that does the video decode (QOpenHD is then transparently layered on top)
// On rpi, this also gives by far the best performance / latency (but requires openhd mmal hacks)
// On ubuntu / x86, it is also quite usefully
//
namespace qopenhd::decode::service {

static bool qopenhd_is_background_transparent(){
    QSettings settings;
    return settings.value("app_background_transparent",true).toBool();
}

static bool send_sysutil_video_request(const std::string& action,
                                       const QOpenHDVideoHelper::VideoStreamConfigXX& config,
                                       int rotation,
                                       bool scale_to_fit,
                                       bool is_secondary){
#ifdef __linux__
    constexpr const char* kSocketPath="/run/openhd/openhd_sys.sock";
    int fd = ::socket(AF_UNIX, SOCK_STREAM, 0);
    if(fd < 0){
        qDebug()<<"sysutils video request: socket failed";
        return false;
    }
    sockaddr_un addr{};
    addr.sun_family = AF_UNIX;
    if(std::strlen(kSocketPath) >= sizeof(addr.sun_path)){
        qDebug()<<"sysutils video request: socket path too long";
        ::close(fd);
        return false;
    }
    std::strncpy(addr.sun_path, kSocketPath, sizeof(addr.sun_path) - 1);
    if(::connect(fd, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) < 0){
        qDebug()<<"sysutils video request: connect failed";
        ::close(fd);
        return false;
    }
    std::stringstream ss;
    ss<<"{\"type\":\"sysutil.video.request\",\"action\":\""<<action
      <<"\",\"codec\":\""<<QOpenHDVideoHelper::video_codec_to_string(config.video_codec)
      <<"\",\"udp_ip\":\""<<config.udp_rtp_input_ip_address
      <<"\",\"udp_port\":"<<config.udp_rtp_input_port
      <<",\"rotation\":"<<rotation
      <<",\"scale_to_fit\":"<<(scale_to_fit ? 1 : 0)
      <<",\"stream\":\""<<(is_secondary ? "secondary" : "primary")<<"\"}\n";
    const auto payload = ss.str();
    const auto sent = ::send(fd, payload.c_str(), payload.size(), MSG_NOSIGNAL);
    ::close(fd);
    return sent == static_cast<ssize_t>(payload.size());
#else
    (void)action;
    (void)config;
    (void)rotation;
    (void)scale_to_fit;
    (void)is_secondary;
    return false;
#endif
}

void decode_via_external_decode_service(const QOpenHDVideoHelper::VideoStreamConfig& settings,std::atomic<bool>& request_restart){
    qDebug()<<"dirty_generic_decode_via_external_decode_service begin";
    // this is always for primary video, unless switching is enabled
    auto stream_config=settings.primary_stream_config;
    const bool is_secondary=settings.generic.qopenhd_switch_primary_secondary;
    if(settings.generic.qopenhd_switch_primary_secondary){
        stream_config=settings.secondary_stream_config;
    }

    // QRS are not available with this implementation
    DecodingStatistcs::instance().reset_all_to_default();
    {
        std::stringstream type;
        type<<"External "<<QOpenHDVideoHelper::video_codec_to_string(settings.primary_stream_config.video_codec);
        DecodingStatistcs::instance().set_decoding_type(type.str().c_str());
    }
    // Background should be transparent
    if(!qopenhd_is_background_transparent()){
        HUDLogMessagesModel::instance().add_message_warning("Background not transparent !");
        HUDLogMessagesModel::instance().add_message_warning("Make transparent (Screen Settings) and restart !");
    }

    const auto rotation=QOpenHDVideoHelper::get_display_rotation();
    if(!send_sysutil_video_request("start", stream_config, rotation, false, is_secondary)){
        LogMessagesModel::instanceGround().add_message_warn("QOpenHD","Failed to request video service from sysutils");
        HUDLogMessagesModel::instance().add_message_warning("Sysutils video request failed");
    }
    // We follow the same pattern here as the decode flows that don't use an "external service"
    while(true){
        if(request_restart){
            request_restart=false;
            break;
        }
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
    send_sysutil_video_request("stop", stream_config, rotation, false, is_secondary);
    qDebug()<<"dirty_generic_decode_via_external_decode_service end";
}

}

#endif // EXTERNALDECODESERVICE_H
