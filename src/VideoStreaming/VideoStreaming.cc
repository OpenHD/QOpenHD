/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


/**
 * @file
 *   @brief QGC Video Streaming Initialization
 *   @author Gus Grubba <mavlink@grubba.com>
 */

//#include <QtQml>
#include <QDebug>

#if defined(QGC_GST_STREAMING)
#include <gst/gst.h>
#ifdef __android__
//#define ANDDROID_GST_DEBUG
#endif
#if defined(__ios__)
#include "gst_ios_init.h"
#endif
#endif

#include "VideoStreaming.h"
#include "VideoItem.h"
#include "VideoSurface.h"

#if defined(QGC_GST_STREAMING)
    G_BEGIN_DECLS
    // Our own plugin
    GST_PLUGIN_STATIC_DECLARE(QGC_VIDEOSINK_PLUGIN);
    // The static plugins we use
#if defined(__mobile__)

    //#define GST_MOBILE_PLUGINS_GES
    #define GST_MOBILE_PLUGINS_CORE
    //#define GST_MOBILE_PLUGINS_CAPTURE
    //#define GST_MOBILE_PLUGINS_CODECS_RESTRICTED
    //#define GST_MOBILE_PLUGINS_ENCODING
    //#define GST_MOBILE_PLUGINS_CODECS_GPL
    //#define GST_MOBILE_PLUGINS_NET_RESTRICTED
    #define GST_MOBILE_PLUGINS_SYS
    //#define GST_MOBILE_PLUGINS_VIS
    #define GST_MOBILE_PLUGINS_PLAYBACK
    //#define GST_MOBILE_PLUGINS_EFFECTS
    #define GST_MOBILE_PLUGINS_CODECS
    //#define GST_MOBILE_PLUGINS_NET
    #define GST_MOBILE_PLUGIN_X264
    #define GST_MOBILE_PLUGIN_LIBAV
    //#define GST_MOBILE_PLUGIN_ISOMP4
    //#define GST_MOBILE_PLUGIN_VIDEOPARSERSBAD
    //#define GST_MOBILE_PLUGIN_MATROSKA
    //#define GST_MOBILE_GIO_MODULE_GNUTLS

#define GST_MOBILE_PLUGIN_RTP
#define GST_MOBILE_PLUGIN_UDP

    #if defined(GST_MOBILE_PLUGIN_COREELEMENTS) || defined(GST_MOBILE_PLUGINS_CORE)
    GST_PLUGIN_STATIC_DECLARE(coreelements);
    #endif
    #if defined(GST_MOBILE_PLUGIN_CORETRACERS) || defined(GST_MOBILE_PLUGINS_CORE)
    GST_PLUGIN_STATIC_DECLARE(coretracers);
    #endif
    #if defined(GST_MOBILE_PLUGIN_ADDER) || defined(GST_MOBILE_PLUGINS_CORE)
    GST_PLUGIN_STATIC_DECLARE(adder);
    #endif
    #if defined(GST_MOBILE_PLUGIN_APP) || defined(GST_MOBILE_PLUGINS_CORE)
    GST_PLUGIN_STATIC_DECLARE(app);
    #endif
    #if defined(GST_MOBILE_PLUGIN_AUDIOCONVERT) || defined(GST_MOBILE_PLUGINS_CORE)
    GST_PLUGIN_STATIC_DECLARE(audioconvert);
    #endif
    #if defined(GST_MOBILE_PLUGIN_AUDIOMIXER) || defined(GST_MOBILE_PLUGINS_CORE)
    GST_PLUGIN_STATIC_DECLARE(audiomixer);
    #endif
    #if defined(GST_MOBILE_PLUGIN_AUDIORATE) || defined(GST_MOBILE_PLUGINS_CORE)
    GST_PLUGIN_STATIC_DECLARE(audiorate);
    #endif
    #if defined(GST_MOBILE_PLUGIN_AUDIORESAMPLE) || defined(GST_MOBILE_PLUGINS_CORE)
    GST_PLUGIN_STATIC_DECLARE(audioresample);
    #endif
    #if defined(GST_MOBILE_PLUGIN_AUDIOTESTSRC) || defined(GST_MOBILE_PLUGINS_CORE)
    GST_PLUGIN_STATIC_DECLARE(audiotestsrc);
    #endif
    #if defined(GST_MOBILE_PLUGIN_GIO) || defined(GST_MOBILE_PLUGINS_CORE)
    GST_PLUGIN_STATIC_DECLARE(gio);
    #endif

    #if defined(GST_MOBILE_PLUGIN_RAWPARSE) || defined(GST_MOBILE_PLUGINS_CORE)
    GST_PLUGIN_STATIC_DECLARE(rawparse);
    #endif
    #if defined(GST_MOBILE_PLUGIN_TYPEFINDFUNCTIONS) || defined(GST_MOBILE_PLUGINS_CORE)
    GST_PLUGIN_STATIC_DECLARE(typefindfunctions);
    #endif
    #if defined(GST_MOBILE_PLUGIN_VIDEOCONVERT) || defined(GST_MOBILE_PLUGINS_CORE)
    GST_PLUGIN_STATIC_DECLARE(videoconvert);
    #endif
    #if defined(GST_MOBILE_PLUGIN_VIDEORATE) || defined(GST_MOBILE_PLUGINS_CORE)
    GST_PLUGIN_STATIC_DECLARE(videorate);
    #endif
    #if defined(GST_MOBILE_PLUGIN_VIDEOSCALE) || defined(GST_MOBILE_PLUGINS_CORE)
    GST_PLUGIN_STATIC_DECLARE(videoscale);
    #endif
    #if defined(GST_MOBILE_PLUGIN_VIDEOTESTSRC) || defined(GST_MOBILE_PLUGINS_CORE)
    GST_PLUGIN_STATIC_DECLARE(videotestsrc);
    #endif
    #if defined(GST_MOBILE_PLUGIN_VOLUME) || defined(GST_MOBILE_PLUGINS_CORE)
    GST_PLUGIN_STATIC_DECLARE(volume);
    #endif
    #if defined(GST_MOBILE_PLUGIN_AUTODETECT) || defined(GST_MOBILE_PLUGINS_CORE)
    GST_PLUGIN_STATIC_DECLARE(autodetect);
    #endif
    #if defined(GST_MOBILE_PLUGIN_VIDEOFILTER) || defined(GST_MOBILE_PLUGINS_CORE)
    GST_PLUGIN_STATIC_DECLARE(videofilter);
    #endif

    #if defined(GST_MOBILE_PLUGIN_MPEGPSDEMUX) || defined(GST_MOBILE_PLUGINS_CODECS_RESTRICTED)
    GST_PLUGIN_STATIC_DECLARE(mpegpsdemux);
    #endif
    #if defined(GST_MOBILE_PLUGIN_MPEGPSMUX) || defined(GST_MOBILE_PLUGINS_CODECS_RESTRICTED)
    GST_PLUGIN_STATIC_DECLARE(mpegpsmux);
    #endif
    #if defined(GST_MOBILE_PLUGIN_MPEGTSDEMUX) || defined(GST_MOBILE_PLUGINS_CODECS_RESTRICTED)
    GST_PLUGIN_STATIC_DECLARE(mpegtsdemux);
    #endif
    #if defined(GST_MOBILE_PLUGIN_MPEGTSMUX) || defined(GST_MOBILE_PLUGINS_CODECS_RESTRICTED)
    GST_PLUGIN_STATIC_DECLARE(mpegtsmux);
    #endif

    #if defined(GST_MOBILE_PLUGIN_X264) || defined(GST_MOBILE_PLUGINS_CODECS_RESTRICTED)
    GST_PLUGIN_STATIC_DECLARE(x264);
    #endif
    #if defined(GST_MOBILE_PLUGIN_LIBAV) || defined(GST_MOBILE_PLUGINS_CODECS_RESTRICTED)
    GST_PLUGIN_STATIC_DECLARE(libav);
    #endif

    #if defined(GST_MOBILE_PLUGIN_OPENGL) || defined(GST_MOBILE_PLUGINS_SYS)
    GST_PLUGIN_STATIC_DECLARE(opengl);
    #endif

    #if defined(__ios__)
    #if defined(GST_MOBILE_PLUGIN_OSXAUDIO) || defined(GST_MOBILE_PLUGINS_SYS)
    GST_PLUGIN_STATIC_DECLARE(osxaudio);
    #endif
    #if defined(GST_MOBILE_PLUGIN_APPLEMEDIA) || defined(GST_MOBILE_PLUGINS_SYS)
    GST_PLUGIN_STATIC_DECLARE(applemedia);
    #endif
    #endif

    #if defined(__android__)
    #if defined(GST_MOBILE_PLUGIN_ANDROIDMEDIA) || defined(GST_MOBILE_PLUGINS_SYS)
    GST_PLUGIN_STATIC_DECLARE(androidmedia);
    #endif
    #endif


    #if defined(GST_MOBILE_PLUGIN_PLAYBACK) || defined(GST_MOBILE_PLUGINS_PLAYBACK)
    GST_PLUGIN_STATIC_DECLARE(playback);
    #endif
    #if defined(GST_MOBILE_PLUGIN_ALPHA) || defined(GST_MOBILE_PLUGINS_EFFECTS)
    GST_PLUGIN_STATIC_DECLARE(alpha);
    #endif
    #if defined(GST_MOBILE_PLUGIN_ALPHACOLOR) || defined(GST_MOBILE_PLUGINS_EFFECTS)
    GST_PLUGIN_STATIC_DECLARE(alphacolor);
    #endif

    #if defined(GST_MOBILE_PLUGIN_DEBUG) || defined(GST_MOBILE_PLUGINS_EFFECTS)
    GST_PLUGIN_STATIC_DECLARE(debug);
    #endif

    #if defined(GST_MOBILE_PLUGIN_SMPTE) || defined(GST_MOBILE_PLUGINS_EFFECTS)
    GST_PLUGIN_STATIC_DECLARE(smpte);
    #endif

    #if defined(GST_MOBILE_PLUGIN_VIDEOBOX) || defined(GST_MOBILE_PLUGINS_EFFECTS)
    GST_PLUGIN_STATIC_DECLARE(videobox);
    #endif
    #if defined(GST_MOBILE_PLUGIN_VIDEOCROP) || defined(GST_MOBILE_PLUGINS_EFFECTS)
    GST_PLUGIN_STATIC_DECLARE(videocrop);
    #endif
    #if defined(GST_MOBILE_PLUGIN_VIDEOMIXER) || defined(GST_MOBILE_PLUGINS_EFFECTS)
    GST_PLUGIN_STATIC_DECLARE(videomixer);
    #endif

    #if defined(GST_MOBILE_PLUGIN_DEBUGUTILSBAD) || defined(GST_MOBILE_PLUGINS_EFFECTS)
    GST_PLUGIN_STATIC_DECLARE(debugutilsbad);
    #endif

    #if defined(GST_MOBILE_PLUGIN_COMPOSITOR) || defined(GST_MOBILE_PLUGINS_EFFECTS)
    GST_PLUGIN_STATIC_DECLARE(compositor);
    #endif


    #if defined(GST_MOBILE_PLUGIN_AUDIOPARSERS) || defined(GST_MOBILE_PLUGINS_CODECS)
    GST_PLUGIN_STATIC_DECLARE(audioparsers);
    #endif
    #if defined(GST_MOBILE_PLUGIN_AUPARSE) || defined(GST_MOBILE_PLUGINS_CODECS)
    GST_PLUGIN_STATIC_DECLARE(auparse);
    #endif


    #if defined(GST_MOBILE_PLUGIN_ISOMP4) || defined(GST_MOBILE_PLUGINS_CODECS)
    GST_PLUGIN_STATIC_DECLARE(isomp4);
    #endif


    #if defined(GST_MOBILE_PLUGIN_VIDEOPARSERSBAD) || defined(GST_MOBILE_PLUGINS_CODECS)
    GST_PLUGIN_STATIC_DECLARE(videoparsersbad);
    #endif

    #if defined(GST_MOBILE_PLUGIN_TCP) || defined(GST_MOBILE_PLUGINS_NET)
    GST_PLUGIN_STATIC_DECLARE(tcp);
    #endif
    #if defined(GST_MOBILE_PLUGIN_RTSP) || defined(GST_MOBILE_PLUGINS_NET)
    GST_PLUGIN_STATIC_DECLARE(rtsp);
    #endif
    #if defined(GST_MOBILE_PLUGIN_RTP) || defined(GST_MOBILE_PLUGINS_NET)
    GST_PLUGIN_STATIC_DECLARE(rtp);
    #endif
    #if defined(GST_MOBILE_PLUGIN_RTPMANAGER) || defined(GST_MOBILE_PLUGINS_NET)
    GST_PLUGIN_STATIC_DECLARE(rtpmanager);
    #endif
    #if defined(GST_MOBILE_PLUGIN_SOUP) || defined(GST_MOBILE_PLUGINS_NET)
    GST_PLUGIN_STATIC_DECLARE(soup);
    #endif
    #if defined(GST_MOBILE_PLUGIN_UDP) || defined(GST_MOBILE_PLUGINS_NET)
    GST_PLUGIN_STATIC_DECLARE(udp);
    #endif
    #if defined(GST_MOBILE_PLUGIN_DTLS) || defined(GST_MOBILE_PLUGINS_NET)
    GST_PLUGIN_STATIC_DECLARE(dtls);
    #endif
    #if defined(GST_MOBILE_PLUGIN_SDPELEM) || defined(GST_MOBILE_PLUGINS_NET)
    GST_PLUGIN_STATIC_DECLARE(sdpelem);
    #endif
    #if defined(GST_MOBILE_PLUGIN_SRTP) || defined(GST_MOBILE_PLUGINS_NET)
    GST_PLUGIN_STATIC_DECLARE(srtp);
    #endif

    #if defined(GST_MOBILE_PLUGIN_WEBRTC) || defined(GST_MOBILE_PLUGINS_NET)
    GST_PLUGIN_STATIC_DECLARE(webrtc);
    #endif

    #if defined(GST_MOBILE_PLUGIN_RTSPCLIENTSINK) || defined(GST_MOBILE_PLUGINS_NET)
    GST_PLUGIN_STATIC_DECLARE(rtspclientsink);
    #endif

#endif
    G_END_DECLS
#endif

#if defined(QGC_GST_STREAMING)
#if (defined(Q_OS_MAC) && defined(QGC_INSTALL_RELEASE)) || defined(Q_OS_WIN)
static void qgcputenv(const QString& key, const QString& root, const QString& path)
{
    QString value = root + path;
    qputenv(key.toStdString().c_str(), QByteArray(value.toStdString().c_str()));
}
#endif
#endif

#ifdef ANDDROID_GST_DEBUG
// Redirects stdio and stderr to logcat
#include <unistd.h>
#include <pthread.h>
#include <android/log.h>

static int pfd[2];
static pthread_t thr;
static const char *tag = "myapp";

static void *thread_func(void*)
{
    ssize_t rdsz;
    char buf[128];
    while((rdsz = read(pfd[0], buf, sizeof buf - 1)) > 0) {
        if(buf[rdsz - 1] == '\n') --rdsz;
        buf[rdsz] = 0;  /* add null-terminator */
        __android_log_write(ANDROID_LOG_DEBUG, tag, buf);
    }
    return 0;
}

int start_logger(const char *app_name)
{
    tag = app_name;

    /* make stdout line-buffered and stderr unbuffered */
    setvbuf(stdout, 0, _IOLBF, 0);
    setvbuf(stderr, 0, _IONBF, 0);

    /* create the pipe and redirect stdout and stderr */
    pipe(pfd);
    dup2(pfd[1], 1);
    dup2(pfd[1], 2);

    /* spawn the logging thread */
    if(pthread_create(&thr, 0, thread_func, 0) == -1)
        return -1;
    pthread_detach(thr);
    return 0;
}
#endif



static void printf_extension_log_func(GstDebugCategory * category,
                                       GstDebugLevel level,
                                       const gchar * file,
                                       const gchar * function,
                                       gint line,
                                       GObject * object,
                                       GstDebugMessage * message,
                                       gpointer unused) {
      const gchar *dbg_msg;

      dbg_msg = gst_debug_message_get (message);

      if (dbg_msg == NULL) {
          return;
      }

      g_print ("%s\n", dbg_msg);

      /* quick hack to still get stuff to show if GST_DEBUG is set */
      if (g_getenv ("GST_DEBUG")) {
        gst_debug_log_default (category, level, file, function, line, object,
            message, unused);
      }
 }

void initializeVideoStreaming(int &argc, char* argv[], char* logpath, char* debuglevel)
{
#if defined(QGC_GST_STREAMING)
    #ifdef __macos__
        #ifdef QGC_INSTALL_RELEASE
            QString currentDir = QCoreApplication::applicationDirPath();
            qgcputenv("GST_PLUGIN_SCANNER",           currentDir, "/../Frameworks/GStreamer.framework/Versions/1.0/libexec/gstreamer-1.0/gst-plugin-scanner");
            qgcputenv("GTK_PATH",                     currentDir, "/../Frameworks/GStreamer.framework/Versions/Current");
            qgcputenv("GIO_EXTRA_MODULES",            currentDir, "/../Frameworks/GStreamer.framework/Versions/Current/lib/gio/modules");
            qgcputenv("GST_PLUGIN_SYSTEM_PATH_1_0",   currentDir, "/../Frameworks/GStreamer.framework/Versions/Current/lib/gstreamer-1.0");
            qgcputenv("GST_PLUGIN_SYSTEM_PATH",       currentDir, "/../Frameworks/GStreamer.framework/Versions/Current/lib/gstreamer-1.0");
            qgcputenv("GST_PLUGIN_PATH_1_0",          currentDir, "/../Frameworks/GStreamer.framework/Versions/Current/lib/gstreamer-1.0");
            qgcputenv("GST_PLUGIN_PATH",              currentDir, "/../Frameworks/GStreamer.framework/Versions/Current/lib/gstreamer-1.0");
        #endif
    #elif defined(Q_OS_WIN)
        QString currentDir = QCoreApplication::applicationDirPath();
        qgcputenv("GST_PLUGIN_PATH", currentDir, "/gstreamer-plugins");
    #endif

    // Initialize GStreamer
    #if defined(__ios__)
        //-- iOS specific initialization
        gst_ios_init();
    #else
        //-- Generic initialization
        if (logpath) {
            QString gstDebugFile = QString("%1/%2").arg(logpath).arg("gstreamer-log.txt");
            qDebug() << "GStreamer debug output:" << gstDebugFile;
            if (debuglevel) {
                qputenv("GST_DEBUG", debuglevel);
            }
            qputenv("GST_DEBUG_NO_COLOR", "1");
            qputenv("GST_DEBUG_FILE", gstDebugFile.toStdString().c_str());
            qputenv("GST_DEBUG_DUMP_DOT_DIR", logpath);
        }
        GError* error = nullptr;
        if (!gst_init_check(&argc, &argv, &error)) {
            qCritical() << "gst_init_check() failed: " << error->message;
            g_error_free(error);
        }
    #endif
        // Our own plugin
        GST_PLUGIN_STATIC_REGISTER(QGC_VIDEOSINK_PLUGIN);
        // The static plugins we use
    #if defined(__mobile__)

        #if defined(GST_MOBILE_PLUGIN_COREELEMENTS) || defined(GST_MOBILE_PLUGINS_CORE)
                GST_PLUGIN_STATIC_REGISTER(coreelements);
        #endif
        #if defined(GST_MOBILE_PLUGIN_CORETRACERS) || defined(GST_MOBILE_PLUGINS_CORE)
                GST_PLUGIN_STATIC_REGISTER(coretracers);
        #endif
        #if defined(GST_MOBILE_PLUGIN_ADDER) || defined(GST_MOBILE_PLUGINS_CORE)
                GST_PLUGIN_STATIC_REGISTER(adder);
        #endif
        #if defined(GST_MOBILE_PLUGIN_APP) || defined(GST_MOBILE_PLUGINS_CORE)
                GST_PLUGIN_STATIC_REGISTER(app);
        #endif
        #if defined(GST_MOBILE_PLUGIN_AUDIOCONVERT) || defined(GST_MOBILE_PLUGINS_CORE)
                GST_PLUGIN_STATIC_REGISTER(audioconvert);
        #endif
        #if defined(GST_MOBILE_PLUGIN_AUDIOMIXER) || defined(GST_MOBILE_PLUGINS_CORE)
                GST_PLUGIN_STATIC_REGISTER(audiomixer);
        #endif
        #if defined(GST_MOBILE_PLUGIN_AUDIORATE) || defined(GST_MOBILE_PLUGINS_CORE)
                GST_PLUGIN_STATIC_REGISTER(audiorate);
        #endif
        #if defined(GST_MOBILE_PLUGIN_AUDIORESAMPLE) || defined(GST_MOBILE_PLUGINS_CORE)
                GST_PLUGIN_STATIC_REGISTER(audioresample);
        #endif
        #if defined(GST_MOBILE_PLUGIN_AUDIOTESTSRC) || defined(GST_MOBILE_PLUGINS_CORE)
                GST_PLUGIN_STATIC_REGISTER(audiotestsrc);
        #endif
        #if defined(GST_MOBILE_PLUGIN_GIO) || defined(GST_MOBILE_PLUGINS_CORE)
                GST_PLUGIN_STATIC_REGISTER(gio);
        #endif

        #if defined(GST_MOBILE_PLUGIN_RAWPARSE) || defined(GST_MOBILE_PLUGINS_CORE)
                GST_PLUGIN_STATIC_REGISTER(rawparse);
        #endif
        #if defined(GST_MOBILE_PLUGIN_TYPEFINDFUNCTIONS) || defined(GST_MOBILE_PLUGINS_CORE)
                GST_PLUGIN_STATIC_REGISTER(typefindfunctions);
        #endif
        #if defined(GST_MOBILE_PLUGIN_VIDEOCONVERT) || defined(GST_MOBILE_PLUGINS_CORE)
                GST_PLUGIN_STATIC_REGISTER(videoconvert);
        #endif
        #if defined(GST_MOBILE_PLUGIN_VIDEORATE) || defined(GST_MOBILE_PLUGINS_CORE)
                GST_PLUGIN_STATIC_REGISTER(videorate);
        #endif
        #if defined(GST_MOBILE_PLUGIN_VIDEOSCALE) || defined(GST_MOBILE_PLUGINS_CORE)
                GST_PLUGIN_STATIC_REGISTER(videoscale);
        #endif
        #if defined(GST_MOBILE_PLUGIN_VIDEOTESTSRC) || defined(GST_MOBILE_PLUGINS_CORE)
                GST_PLUGIN_STATIC_REGISTER(videotestsrc);
        #endif
        #if defined(GST_MOBILE_PLUGIN_VOLUME) || defined(GST_MOBILE_PLUGINS_CORE)
                GST_PLUGIN_STATIC_REGISTER(volume);
        #endif
        #if defined(GST_MOBILE_PLUGIN_AUTODETECT) || defined(GST_MOBILE_PLUGINS_CORE)
                GST_PLUGIN_STATIC_REGISTER(autodetect);
        #endif
        #if defined(GST_MOBILE_PLUGIN_VIDEOFILTER) || defined(GST_MOBILE_PLUGINS_CORE)
                GST_PLUGIN_STATIC_REGISTER(videofilter);
        #endif

        #if defined(GST_MOBILE_PLUGIN_MPEGPSDEMUX) || defined(GST_MOBILE_PLUGINS_CODECS_RESTRICTED)
                GST_PLUGIN_STATIC_REGISTER(mpegpsdemux);
        #endif
        #if defined(GST_MOBILE_PLUGIN_MPEGPSMUX) || defined(GST_MOBILE_PLUGINS_CODECS_RESTRICTED)
                GST_PLUGIN_STATIC_REGISTER(mpegpsmux);
        #endif
        #if defined(GST_MOBILE_PLUGIN_MPEGTSDEMUX) || defined(GST_MOBILE_PLUGINS_CODECS_RESTRICTED)
                GST_PLUGIN_STATIC_REGISTER(mpegtsdemux);
        #endif
        #if defined(GST_MOBILE_PLUGIN_MPEGTSMUX) || defined(GST_MOBILE_PLUGINS_CODECS_RESTRICTED)
                GST_PLUGIN_STATIC_REGISTER(mpegtsmux);
        #endif

        #if defined(GST_MOBILE_PLUGIN_X264) || defined(GST_MOBILE_PLUGINS_CODECS_RESTRICTED)
                GST_PLUGIN_STATIC_REGISTER(x264);
        #endif
        #if defined(GST_MOBILE_PLUGIN_LIBAV) || defined(GST_MOBILE_PLUGINS_CODECS_RESTRICTED)
                GST_PLUGIN_STATIC_REGISTER(libav);
        #endif
        #if defined(GST_MOBILE_PLUGIN_ENCODING) || defined(GST_MOBILE_PLUGINS_ENCODING)
                GST_PLUGIN_STATIC_REGISTER(encoding);
        #endif

        #if defined(GST_MOBILE_PLUGIN_OPENGL) || defined(GST_MOBILE_PLUGINS_SYS)
                GST_PLUGIN_STATIC_REGISTER(opengl);
        #endif

        #if defined(__ios__)
        #if defined(GST_MOBILE_PLUGIN_OSXAUDIO) || defined(GST_MOBILE_PLUGINS_SYS)
                GST_PLUGIN_STATIC_REGISTER(osxaudio);
        #endif
        #if defined(GST_MOBILE_PLUGIN_APPLEMEDIA) || defined(GST_MOBILE_PLUGINS_SYS)
                GST_PLUGIN_STATIC_REGISTER(applemedia);
        #endif
        #endif

        #if defined(__android__)
        #if defined(GST_MOBILE_PLUGIN_ANDROIDMEDIA) || defined(GST_MOBILE_PLUGINS_SYS)
                GST_PLUGIN_STATIC_REGISTER(androidmedia);
        #endif
        #endif


        #if defined(GST_MOBILE_PLUGIN_PLAYBACK) || defined(GST_MOBILE_PLUGINS_PLAYBACK)
                GST_PLUGIN_STATIC_REGISTER(playback);
        #endif

        #if defined(GST_MOBILE_PLUGIN_DEBUG) || defined(GST_MOBILE_PLUGINS_EFFECTS)
                GST_PLUGIN_STATIC_REGISTER(debug);
        #endif

        #if defined(GST_MOBILE_PLUGIN_SMPTE) || defined(GST_MOBILE_PLUGINS_EFFECTS)
                GST_PLUGIN_STATIC_REGISTER(smpte);
        #endif

        #if defined(GST_MOBILE_PLUGIN_VIDEOBOX) || defined(GST_MOBILE_PLUGINS_EFFECTS)
                GST_PLUGIN_STATIC_REGISTER(videobox);
        #endif
        #if defined(GST_MOBILE_PLUGIN_VIDEOCROP) || defined(GST_MOBILE_PLUGINS_EFFECTS)
                GST_PLUGIN_STATIC_REGISTER(videocrop);
        #endif
        #if defined(GST_MOBILE_PLUGIN_VIDEOMIXER) || defined(GST_MOBILE_PLUGINS_EFFECTS)
                GST_PLUGIN_STATIC_REGISTER(videomixer);
        #endif

        #if defined(GST_MOBILE_PLUGIN_AUTOCONVERT) || defined(GST_MOBILE_PLUGINS_EFFECTS)
                GST_PLUGIN_STATIC_REGISTER(autoconvert);
        #endif

        #if defined(GST_MOBILE_PLUGIN_COLOREFFECTS) || defined(GST_MOBILE_PLUGINS_EFFECTS)
                GST_PLUGIN_STATIC_REGISTER(coloreffects);
        #endif
        #if defined(GST_MOBILE_PLUGIN_DEBUGUTILSBAD) || defined(GST_MOBILE_PLUGINS_EFFECTS)
                GST_PLUGIN_STATIC_REGISTER(debugutilsbad);
        #endif

        #if defined(GST_MOBILE_PLUGIN_COMPOSITOR) || defined(GST_MOBILE_PLUGINS_EFFECTS)
                GST_PLUGIN_STATIC_REGISTER(compositor);
        #endif


        #if defined(GST_MOBILE_PLUGIN_AUDIOPARSERS) || defined(GST_MOBILE_PLUGINS_CODECS)
                GST_PLUGIN_STATIC_REGISTER(audioparsers);
        #endif

        #if defined(GST_MOBILE_PLUGIN_ISOMP4) || defined(GST_MOBILE_PLUGINS_CODECS)
                GST_PLUGIN_STATIC_REGISTER(isomp4);
        #endif

        #if defined(GST_MOBILE_PLUGIN_VIDEOPARSERSBAD) || defined(GST_MOBILE_PLUGINS_CODECS)
                GST_PLUGIN_STATIC_REGISTER(videoparsersbad);
        #endif


        #if defined(GST_MOBILE_PLUGIN_TCP) || defined(GST_MOBILE_PLUGINS_NET)
                GST_PLUGIN_STATIC_REGISTER(tcp);
        #endif
        #if defined(GST_MOBILE_PLUGIN_RTSP) || defined(GST_MOBILE_PLUGINS_NET)
                GST_PLUGIN_STATIC_REGISTER(rtsp);
        #endif
        #if defined(GST_MOBILE_PLUGIN_RTP) || defined(GST_MOBILE_PLUGINS_NET)
                GST_PLUGIN_STATIC_REGISTER(rtp);
        #endif
        #if defined(GST_MOBILE_PLUGIN_RTPMANAGER) || defined(GST_MOBILE_PLUGINS_NET)
                GST_PLUGIN_STATIC_REGISTER(rtpmanager);
        #endif
        #if defined(GST_MOBILE_PLUGIN_SOUP) || defined(GST_MOBILE_PLUGINS_NET)
                GST_PLUGIN_STATIC_REGISTER(soup);
        #endif
        #if defined(GST_MOBILE_PLUGIN_UDP) || defined(GST_MOBILE_PLUGINS_NET)
                GST_PLUGIN_STATIC_REGISTER(udp);
        #endif
        #if defined(GST_MOBILE_PLUGIN_DTLS) || defined(GST_MOBILE_PLUGINS_NET)
                GST_PLUGIN_STATIC_REGISTER(dtls);
        #endif
        #if defined(GST_MOBILE_PLUGIN_SDPELEM) || defined(GST_MOBILE_PLUGINS_NET)
                GST_PLUGIN_STATIC_REGISTER(sdpelem);
        #endif
        #if defined(GST_MOBILE_PLUGIN_SRTP) || defined(GST_MOBILE_PLUGINS_NET)
                GST_PLUGIN_STATIC_REGISTER(srtp);
        #endif
        #if defined(GST_MOBILE_PLUGIN_WEBRTC) || defined(GST_MOBILE_PLUGINS_NET)
                GST_PLUGIN_STATIC_REGISTER(webrtc);
        #endif
        #if defined(GST_MOBILE_PLUGIN_RTSPCLIENTSINK) || defined(GST_MOBILE_PLUGINS_NET)
                GST_PLUGIN_STATIC_REGISTER(rtspclientsink);
        #endif

        #if defined(GST_MOBILE_GIO_MODULE_GNUTLS)
                GST_G_IO_MODULE_LOAD(gnutls);
        #endif

    #endif
#else
    Q_UNUSED(argc);
    Q_UNUSED(argv);
    Q_UNUSED(logpath);
    Q_UNUSED(debuglevel);
#endif
    qmlRegisterType<VideoItem>              ("QGroundControl.QgcQtGStreamer", 1, 0, "VideoItem");
    qmlRegisterUncreatableType<VideoSurface>("QGroundControl.QgcQtGStreamer", 1, 0, "VideoSurface", QStringLiteral("VideoSurface from QML is not supported"));

    //gst_debug_remove_log_function(gst_debug_log_default);
    //gst_debug_add_log_function (printf_extension_log_func, NULL, NULL);

}

void shutdownVideoStreaming()
{
    /* From: http://gstreamer.freedesktop.org/data/doc/gstreamer/head/gstreamer/html/gstreamer-Gst.html#gst-deinit
     *
     * "It is normally not needed to call this function in a normal application as the resources will automatically
     * be freed when the program terminates. This function is therefore mostly used by testsuites and other memory
     * profiling tools."
     *
     * It's causing a hang on exit. It hangs while deleting some thread.
     *
#if defined(QGC_GST_STREAMING)
     gst_deinit();
#endif
    */
}
