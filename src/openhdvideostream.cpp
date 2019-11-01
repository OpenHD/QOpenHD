#include "openhdvideostream.h"

#include "constants.h"

#include <QtConcurrent>

#if defined(__android__)
#include <jni.h>
#include <gst/gst.h>
#include <QAndroidJniEnvironment>
#include <QAndroidJniObject>
#include <QApplication>

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

static const char kJniClassName[] {"org/openhd/OpenHDActivity"};

void setNativeMethods(void)
{
    JNINativeMethod javaMethods[] {
        {"nativeInit", "()V", reinterpret_cast<void *>(gst_android_init)}
    };

    QAndroidJniEnvironment jniEnv;
    if (jniEnv->ExceptionCheck()) {
        jniEnv->ExceptionDescribe();
        jniEnv->ExceptionClear();
    }

    jclass objectClass = jniEnv->FindClass(kJniClassName);
    if(!objectClass) {
        qWarning() << "Couldn't find class:" << kJniClassName;
        return;
    }

    jint val = jniEnv->RegisterNatives(objectClass, javaMethods, sizeof(javaMethods) / sizeof(javaMethods[0]));

    if (val < 0) {
        qWarning() << "Error registering methods: " << val;
    } else {
        qDebug() << "Main Native Functions Registered";
    }

    if (jniEnv->ExceptionCheck()) {
        jniEnv->ExceptionDescribe();
        jniEnv->ExceptionClear();
    }
}

jint JNI_OnLoad(JavaVM* vm, void* reserved) {
    Q_UNUSED(reserved);

    JNIEnv* env;
    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
        return -1;
    }

    setNativeMethods();
    QAndroidJniObject::callStaticMethod<void>(kJniClassName, "jniOnLoad");

    gst_amc_jni_set_java_vm(vm);
    return JNI_VERSION_1_6;
}
#endif

OpenHDVideoStream::OpenHDVideoStream(QObject *parent): QObject(parent) {
    qDebug() << "OpenHDVideoStream::OpenHDVideoStream()";
    init();
}

OpenHDVideoStream::~OpenHDVideoStream() {
    qDebug() << "~OpenHDVideoStream()";
}

void OpenHDVideoStream::init() {
    qDebug() << "OpenHDVideoStream::init()";
}

void OpenHDVideoStream::_start() {
    qDebug() << "OpenHDVideoStream::_start()";
    if (!m_receiver.running()) {
        m_receiver.start();
    }
}

void OpenHDVideoStream::startVideo() {
    QFuture<void> future = QtConcurrent::run(this, &OpenHDVideoStream::_start);
}

void OpenHDVideoStream::_stop() {
    qDebug() << "OpenHDVideoStream::_stop()";
    if (m_receiver.running()) {
        m_receiver.stop();
    }
}

void OpenHDVideoStream::stopVideo() {
    QFuture<void> future = QtConcurrent::run(this, &OpenHDVideoStream::_stop);
}

void OpenHDVideoStream::setUri(QString uri) {
    m_uri = uri;
    emit uriChanged(m_uri);
    m_receiver.setUri(m_uri);
}
