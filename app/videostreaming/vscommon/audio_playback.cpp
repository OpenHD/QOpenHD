#include "audio_playback.h"
#include "qdebug.h"

#include <qsettings.h>


#ifdef QOPENHD_ENABLE_GSTREAMER_QMLGLSINK
#include "../gstreamer/gstrtpaudioplayer.h"
#endif

#include <util/qopenhd.h>
#include <logging/logmessagesmodel.h>

void platform_start_audio_streaming_if_enabled()
{
    QSettings settings;
    const bool dev_enable_live_audio_playback=settings.value("dev_enable_live_audio_playback", false).toBool();
    if(!dev_enable_live_audio_playback){
        qDebug()<<"Live audio playback is disabled";
        return;
    }
#ifdef QOPENHD_ENABLE_GSTREAMER_QMLGLSINK
    GstRtpAudioPlayer::instance().start_playing();
    return;
#endif
    LogMessagesModel::instanceGround().add_message_debug("QOpenHD","No audio playback");
}

void platform_audio_terminate()
{
#ifdef QOPENHD_ENABLE_GSTREAMER_QMLGLSINK
    GstRtpAudioPlayer::instance().stop_playing();
#endif
}
