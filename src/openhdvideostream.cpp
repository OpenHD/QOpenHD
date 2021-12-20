#if defined(ENABLE_GSTREAMER)

#include "openhdvideostream.h"

#include "constants.h"

#include <QtConcurrent>
#include <QtQuick>

#include <gst/gst.h>

#include "localmessage.h"

#include "openhd.h"

#if defined(__android__)
#include <jni.h>
#include <QAndroidJniEnvironment>
#include <QAndroidJniObject>
#include <QApplication>
#include <QtAndroidExtras/QtAndroid>

static jobject _class_loader = nullptr;
static jobject _context = nullptr;

extern "C" {
    void gst_amc_jni_set_java_vm(JavaVM *java_vm);

    jobject gst_android_get_application_class_loader(void) {
        return _class_loader;
    }
}

static void gst_android_init(JNIEnv* env, jobject context) {
    jobject class_loader = nullptr;

    jclass context_cls = env->GetObjectClass(context);
    if (!context_cls) {
        return;
    }

    jmethodID get_class_loader_id = env->GetMethodID(context_cls, "getClassLoader", "()Ljava/lang/ClassLoader;");
    if (env->ExceptionCheck()) {
        env->ExceptionDescribe();
        env->ExceptionClear();
        return;
    }

    class_loader = env->CallObjectMethod(context, get_class_loader_id);
    if (env->ExceptionCheck()) {
        env->ExceptionDescribe();
        env->ExceptionClear();
        return;
    }

    _context = env->NewGlobalRef(context);
    _class_loader = env->NewGlobalRef(class_loader);
}

jint JNI_OnLoad(JavaVM* vm, void* reserved) {
    Q_UNUSED(reserved);

    JNIEnv* env;
    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
        return -1;
    }

    gst_amc_jni_set_java_vm(vm);
    return JNI_VERSION_1_6;
}
#endif


#if defined(__ios__)
#include "gst_ios_init.h"
#endif

static void putenv(const QString& key, const QString& root, const QString& path) {
    QString value = root + path;
    qputenv(key.toStdString().c_str(), QByteArray(value.toStdString().c_str()));
}


G_BEGIN_DECLS

#define GST_G_IO_MODULE_DECLARE(name) \
extern void G_PASTE(g_io_module_, G_PASTE(name, _load_static)) (void)

#define GST_G_IO_MODULE_LOAD(name) \
G_PASTE(g_io_module_, G_PASTE(name, _load_static)) ()

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
#define GST_MOBILE_PLUGIN_UDP
#define GST_MOBILE_PLUGIN_RTP
#define GST_MOBILE_PLUGIN_RTPMANAGER
#endif

#if defined(ENABLE_MAIN_VIDEO) || defined(ENABLE_PIP)
#ifndef __desktoplinux__
#ifndef __rasp_pi__
GST_PLUGIN_STATIC_DECLARE(qmlgl);
#endif
#endif
#endif

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

#if defined(GST_MOBILE_GIO_MODULE_GNUTLS)
  #include <gio/gio.h>
  GST_G_IO_MODULE_DECLARE(gnutls);
#endif
G_END_DECLS


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

      if (dbg_msg == nullptr) {
          return;
      }

      qDebug() << dbg_msg;

      /* quick hack to still get stuff to show if GST_DEBUG is set */
      if (g_getenv ("GST_DEBUG")) {
        gst_debug_log_default (category, level, file, function, line, object,
            message, unused);
      }
 }


class SetPlaying : public QRunnable {
public:
    SetPlaying(GstElement *);
    virtual ~SetPlaying();
    void run();
private:
    GstElement * m_pipeline;
};

SetPlaying::SetPlaying(GstElement * pipeline) {
    qDebug() << "SetPlaying::SetPlaying()";
    this->m_pipeline = pipeline ? static_cast<GstElement *> (gst_object_ref (pipeline)) : nullptr;
}

SetPlaying::~SetPlaying() {
    qDebug() << "SetPlaying::~SetPlaying()";
    if (this->m_pipeline) {
        gst_object_unref (this->m_pipeline);
    }
}

void
SetPlaying::run() {
    qDebug() << "SetPlaying::run()";
    if (this->m_pipeline) {
        gst_element_set_state (this->m_pipeline, GST_STATE_PLAYING);
    }
}


OpenHDVideoStream::OpenHDVideoStream(int &argc, char *argv[], QObject * parent): QObject(parent), timer(new QTimer) {
    qDebug() << "OpenHDVideoStream::OpenHDVideoStream()";

#ifdef __macos__
    #if defined(ENABLE_MAIN_VIDEO) || defined(ENABLE_PIP)
        #ifdef RELEASE_BUILD
            QString currentDir = QCoreApplication::applicationDirPath();
            putenv("GST_PLUGIN_SCANNER",           currentDir, "/../Frameworks/GStreamer.framework/Versions/1.0/libexec/gstreamer-1.0/gst-plugin-scanner");
            putenv("GTK_PATH",                     currentDir, "/../Frameworks/GStreamer.framework/Versions/Current");
            putenv("GIO_EXTRA_MODULES",            currentDir, "/../Frameworks/GStreamer.framework/Versions/Current/lib/gio/modules");
            putenv("GST_PLUGIN_SYSTEM_PATH_1_0",   currentDir, "/../Frameworks/GStreamer.framework/Versions/Current/lib/gstreamer-1.0");
            putenv("GST_PLUGIN_SYSTEM_PATH",       currentDir, "/../Frameworks/GStreamer.framework/Versions/Current/lib/gstreamer-1.0");
            putenv("GST_PLUGIN_PATH_1_0",          currentDir, "/../Frameworks/GStreamer.framework/Versions/Current/lib/gstreamer-1.0");
            putenv("GST_PLUGIN_PATH",              currentDir, "/../Frameworks/GStreamer.framework/Versions/Current/lib/gstreamer-1.0");
        #endif
    #endif
#endif

#if defined(__windows__)
    QString currentDir = QCoreApplication::applicationDirPath();
    putenv("GST_PLUGIN_PATH", currentDir, "/gstreamer-plugins");
#endif


    char debuglevel[] = "*:3";
    #if defined(__android__)
    char logpath[] = "/sdcard";
    #else
    char logpath[] = "/tmp";
    #endif

    qputenv("GST_DEBUG", debuglevel);

    QString file = QString("%1/%2").arg(logpath).arg("gstreamer-log.txt");

    qputenv("GST_DEBUG_NO_COLOR", "1");
    qputenv("GST_DEBUG_FILE", file.toStdString().c_str());
    qputenv("GST_DEBUG_DUMP_DOT_DIR", logpath);

    #if defined(__ios__)
        gst_ios_init(NULL, NULL);
    #elif defined (__android__)
        QAndroidJniEnvironment jniEnv;
        JNIEnv *env = jniEnv;
        QAndroidJniObject QJObj = QtAndroid::androidActivity();
        jobject context = QJObj.object<jobject> ();
        gst_android_init(jniEnv, context);

        if (env->ExceptionCheck()) {
            jclass throwable_class = env->FindClass("java/lang/Throwable");
            jmethodID throwable_to_string_id = env->GetMethodID(throwable_class, "toString", "()Ljava/lang/String;");
            jstring msg_obj = (jstring) env->CallObjectMethod (context, throwable_to_string_id);
            const char* msg_str = env->GetStringUTFChars (msg_obj, 0);

            //g_set_error (error, GST_LIBRARY_ERROR, GST_LIBRARY_ERROR_INIT, "%s", msg_str);

            env->ReleaseStringUTFChars (msg_obj, msg_str);
            env->DeleteLocalRef (throwable_class);
            env->DeleteLocalRef (msg_obj);
        }
        GError* error = nullptr;
        if (!gst_init_check(&argc, &argv, &error)) {
            qCritical() << "gst_init_check() failed: " << error->message;
            g_error_free(error);
        }
    #else
        GError* error = nullptr;
        if (!gst_init_check(&argc, &argv, &error)) {
            qCritical() << "gst_init_check() failed: " << error->message;
            g_error_free(error);
        }
    #endif


    //gst_debug_remove_log_function(gst_debug_log_default);
    //gst_debug_add_log_function(printf_extension_log_func, nullptr, nullptr);
#if defined(ENABLE_MAIN_VIDEO) || defined(ENABLE_PIP)
#ifndef __desktoplinux__
#ifndef __rasp_pi__
    GST_PLUGIN_STATIC_REGISTER(qmlgl);
#endif
#endif
#endif

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

    /* If qmlgl plugin was dynamically linked, this will force GStreamer to go find it and
     * load it before the QML gets loaded in main.cpp (without this, Qt will complain that
     * it can't find org.freedesktop.gstreamer.GLVideoItem)
     */
    GstElement *sink = gst_element_factory_make("qmlglsink", NULL);
}

OpenHDVideoStream::~OpenHDVideoStream() {
    qDebug() << "~OpenHDVideoStream()";
}

void OpenHDVideoStream::init(QQmlApplicationEngine* engine = nullptr, enum StreamType stream_type = StreamTypeMain) {
    m_stream_type = stream_type;
    switch (m_stream_type) {
        case StreamTypeMain:
            m_elementName = "mainVideoGStreamer";
            break;
        case StreamTypePiP:
            m_elementName = "pipVideoGStreamer";
            break;
    }

    m_engine = engine;
    QSettings settings;
    m_enable_videotest = settings.value("enable_videotest", false).toBool();
    if (m_stream_type == StreamTypeMain) {
        m_video_port = settings.value("main_video_port", 5600).toInt();
    } else {
        m_video_port = settings.value("pip_video_port", 5601).toInt();
    }
    m_enable_rtp = settings.value("enable_rtp", true).toBool();

    m_enable_lte_video = settings.value("enable_lte_video", false).toBool();

    lastDataTimeout = QDateTime::currentMSecsSinceEpoch();

    QObject::connect(timer, &QTimer::timeout, this, &OpenHDVideoStream::_timer);
    timer->start(1000);

    qDebug() << "OpenHDVideoStream::init()";
}


static gboolean PipelineCb(GstBus *bus, GstMessage *msg, gpointer data) {
    auto instance = static_cast<OpenHDVideoStream*>(data);

    switch (GST_MESSAGE_TYPE(msg)){
    case GST_MESSAGE_EOS:{
            break;
        }
        case GST_MESSAGE_ERROR:{
            break;
        }
        case GST_MESSAGE_WARNING:{
            break;
        }
        case GST_MESSAGE_INFO:{
            break;
        }
        case GST_MESSAGE_TAG:{
            break;
        }
        case GST_MESSAGE_BUFFERING:{
            break;
        }
        case GST_MESSAGE_ELEMENT:{
            auto m = QString(gst_structure_get_name(gst_message_get_structure(msg)));
            if (m == "GstUDPSrcTimeout") {
                instance->lastDataTimeout = QDateTime::currentMSecsSinceEpoch();
            }
            break;
        }
        case GST_MESSAGE_LATENCY: {
            break;
        }
        case GST_MESSAGE_QOS: {
            break;
        }
        case GST_MESSAGE_UNKNOWN: {
            break;
        }
        default: {
            break;
        }
    }

    return TRUE;
}

void OpenHDVideoStream::_start() {
    qDebug() << "OpenHDVideoStream::_start()";

    GError *error = nullptr;

    QSettings settings;
    auto pipeline = new QString();
    m_video_h264 = settings.value("video_h264", false).toBool();
    QTextStream s(pipeline);

    if (m_enable_videotest) {
        qDebug() << "Using video test";
        s << "videotestsrc pattern=smpte !";
        s << "video/x-raw,width=640,height=480 !";
        s << "queue !";
    } else {
        qDebug() << "Listening on port" << m_video_port;

        if (m_enable_rtp || m_stream_type == StreamTypePiP) {
            if (m_video_h264 == true ){
                qDebug() << "h264 video stream started";
                s << QString("udpsrc port=%1 caps=\"application/x-rtp, media=(string)video, clock-rate=(int)90000, encoding-name=(string)H264\" timeout=1000000000 !").arg(m_video_port);
                s << "rtpjitterbuffer !";
                s << "rtph264depay ! ";
            }
            else { //we are h265.. it has its own verbose setting but not using it here
                qDebug() << "h265 TEST video stream started";
                s << QString("udpsrc port=%1 caps=\"application/x-rtp, encoding-name=(string)H265,payload=96\" timeout=1000000000 !").arg(m_video_port);
                s << "h265parse !";
                s << "rtph265depay ! ";
            }
        } else {
            s << QString("udpsrc port=%1 timeout=1000000000 !").arg(m_video_port);
        }
        s << "queue !";

        if (m_enable_software_video_decoder) {
            qDebug() << "Forcing software decoder";
            s << "h264parse !";
            s << "avdec_h264 !";
        } else {
            qDebug() << "Using hardware decoder, fallback to software if unavailable";
            s << "h264parse !";
            #if defined(__rasp_pi__)
            s << "omxh264dec !";
            #else
            s << "decodebin3 !";
            #endif
        }
    }
    s << "queue !";

    s << "glupload ! glcolorconvert !";
    s << "qmlglsink name=qmlglsink sync=false";

    m_pipeline = gst_parse_launch(pipeline->toUtf8(), &error);
    qDebug() << "GSTREAMER PIPE=" << pipeline->toUtf8();
    if (error) {
        qDebug() << "gst_parse_launch error: " << error->message;
    }
    GstElement *qmlglsink = gst_bin_get_by_name(GST_BIN(m_pipeline), "qmlglsink");


    GstBus *bus = gst_pipeline_get_bus (GST_PIPELINE(m_pipeline));

    gst_bus_add_signal_watch(bus);
    g_signal_connect(bus, "message", (GCallback)PipelineCb, this);


    QQuickItem *videoItem;
    QQuickWindow *rootObject;
    auto rootObjects = m_engine->rootObjects();
    if (rootObjects.length() < 1) {
        qDebug() << "Failed to obtain root object list!";
        LocalMessage::instance()->showMessage("Could not start video stream (E1)", 2);
        return;
    }
    rootObject = static_cast<QQuickWindow *>(rootObjects.first());
    videoItem = rootObject->findChild<QQuickItem *>(m_elementName.toUtf8());
    qDebug() << "Setting element on " << m_elementName;
    if (videoItem == nullptr) {
        qDebug() << "Failed to obtain video item pointer for " << m_elementName;
        LocalMessage::instance()->showMessage("Could not start video stream (E2)", 2);
        return;
    }
    g_object_set(qmlglsink, "widget", videoItem, NULL);


    /*
     * When the app first launches we have to wait for the QML element to be ready before the pipeline
     * starts pushing frames to it.
     *
     * After that point we can just set the pipeline to GST_STATE_PLAYING directly.
     */
    if (firstRun) {
        firstRun = false;
        rootObject->scheduleRenderJob(new SetPlaying (m_pipeline), QQuickWindow::BeforeSynchronizingStage);
    } else {
        gst_element_set_state (m_pipeline, GST_STATE_PLAYING);
    }

    lastDataTimeout = QDateTime::currentMSecsSinceEpoch();
    OpenHD::instance()->set_main_video_running(false);
    OpenHD::instance()->set_pip_video_running(false);

    mainLoop = g_main_loop_new(nullptr, FALSE);
    g_main_loop_run(mainLoop);
}

/*
 * Fired by m_timer.
 *
 * Checks every second if the enable_videotest setting has changed, if so we restart the
 * stream and let the the pipeline be reconstructed using whichever video source is now enabled.
 */
void OpenHDVideoStream::_timer() {    
    // skip everything until the video is known to have started at least once.
    if (firstRun) {
        return;
    }

    QSettings settings;

    auto _enable_videotest = settings.value("enable_videotest", false).toBool();
    auto _enable_software_video_decoder = settings.value("enable_software_video_decoder", false).toBool();
    auto _enable_rtp = settings.value("enable_rtp", true).toBool();

    auto _enable_lte_video = settings.value("enable_lte_video", false).toBool();   

    auto _show_pip_video = settings.value("show_pip_video", false).toBool();

    auto _main_video_port = settings.value("main_video_port", main_default_port).toInt();
    if (m_enable_lte_video) {
        _main_video_port = 8000;
    }

    auto _pip_video_port = settings.value("pip_video_port", pip_default_port).toInt();


    if (m_stream_type == StreamTypeMain) {
        if (_enable_videotest != m_enable_videotest || _enable_software_video_decoder != m_enable_software_video_decoder || _main_video_port != m_video_port || _enable_rtp != m_enable_rtp || _enable_lte_video != m_enable_lte_video) {
            qDebug() << "Restarting main stream";
            stopVideo();
            m_enable_videotest = _enable_videotest;
            m_enable_software_video_decoder = _enable_software_video_decoder;            
            m_enable_rtp = _enable_rtp;
            m_enable_lte_video= _enable_lte_video;
            m_video_port = _main_video_port;
            startVideo();
        }
    } else if (m_stream_type == StreamTypePiP) {
        if (m_enable_pip_video != _show_pip_video || _enable_videotest != m_enable_videotest || _enable_software_video_decoder != m_enable_software_video_decoder || _pip_video_port != m_video_port || _enable_rtp != m_enable_rtp) {
            qDebug() << "Restarting PiP stream";
            stopVideo();
            m_enable_videotest = _enable_videotest;
            m_enable_software_video_decoder = _enable_software_video_decoder;
            m_enable_rtp = _enable_rtp;

            m_video_port = _pip_video_port;
            m_enable_pip_video = _show_pip_video;
            if (_show_pip_video) {
                startVideo();
            }
        }
    }

    auto currentTime = QDateTime::currentMSecsSinceEpoch();

    if (currentTime - lastDataTimeout < 2500) {
        if (m_stream_type == StreamTypeMain) {
            OpenHD::instance()->set_main_video_running(false);
        } else {
            OpenHD::instance()->set_pip_video_running(false);
        }
    } else {
        if (m_stream_type == StreamTypeMain) {
            OpenHD::instance()->set_main_video_running(true);
        } else {
            OpenHD::instance()->set_pip_video_running(true);
        }
    }
}

void OpenHDVideoStream::startVideo() {
#if defined(ENABLE_MAIN_VIDEO) || defined(ENABLE_PIP)
    QFuture<void> future = QtConcurrent::run(this, &OpenHDVideoStream::_start);
#endif
}

void OpenHDVideoStream::_stop() {
#if defined(ENABLE_MAIN_VIDEO) || defined(ENABLE_PIP)
    qDebug() << "OpenHDVideoStream::_stop()";

    if (m_pipeline != nullptr) {
        gst_element_set_state (m_pipeline, GST_STATE_NULL);
        //gst_object_unref (m_pipeline);
        g_main_loop_quit(mainLoop);
    }
#endif
}

void OpenHDVideoStream::stopVideo() {
#if defined(ENABLE_MAIN_VIDEO) || defined(ENABLE_PIP)
    QFuture<void> future = QtConcurrent::run(this, &OpenHDVideoStream::_stop);
#endif
}


#endif
