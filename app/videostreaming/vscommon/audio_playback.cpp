#include "audio_playback.h"
#include "qdebug.h"



#ifdef QOPENHD_ENABLE_GSTREAMER_QMLGLSINK
#include "../gstreamer/gstrtpaudioplayer.h"
#endif
#ifdef QOPENHD_ENABLE_QT_AUDIO
#include "qt_audio_player.h"
#endif

#include <util/qopenhd.h>
#include <logging/logmessagesmodel.h>

void platform_start_audio_streaming_if_enabled()
{
    // Always listen for incoming audio; the Air unit controls whether audio is streamed.
#ifdef QOPENHD_ENABLE_GSTREAMER_QMLGLSINK
#ifdef QOPENHD_ENABLE_QT_AUDIO
    if (QOpenHD::instance().is_android()) {
        QtAudioPlayer::instance().start_playing();
        return;
    }
#endif
    GstRtpAudioPlayer::instance().start_playing();
    return;
#elif defined(QOPENHD_ENABLE_QT_AUDIO)
    QtAudioPlayer::instance().start_playing();
    return;
#endif
    LogMessagesModel::instanceGround().add_message_debug("QOpenHD","No audio playback");
}

void platform_audio_terminate()
{
#ifdef QOPENHD_ENABLE_GSTREAMER_QMLGLSINK
#ifdef QOPENHD_ENABLE_QT_AUDIO
    if (QOpenHD::instance().is_android()) {
        QtAudioPlayer::instance().stop_playing();
        return;
    }
#endif
    GstRtpAudioPlayer::instance().stop_playing();
#elif defined(QOPENHD_ENABLE_QT_AUDIO)
    QtAudioPlayer::instance().stop_playing();
#endif
}
