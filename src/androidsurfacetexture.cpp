
#include "androidsurfacetexture.h"

#include <QAndroidJniEnvironment>
#include <QAndroidJniObject>

#include <QtCore/qmutex.h>


static const char QtSurfaceTextureListenerClassName[] = "com/openhd/android/SurfaceTextureListener";

typedef QVector<jlong> SurfaceTextures;

Q_GLOBAL_STATIC(SurfaceTextures, g_surfaceTextures);
Q_GLOBAL_STATIC(QMutex, g_textureMutex);

// native method for QtSurfaceTexture.java

static void notifyFrameAvailable(JNIEnv* , jobject, jlong id) {
    const QMutexLocker lock(g_textureMutex);
    const int idx = g_surfaceTextures->indexOf(id);

    if (idx == -1) {
        return;
    }

    AndroidSurfaceTexture *obj = reinterpret_cast<AndroidSurfaceTexture *>(g_surfaceTextures->at(idx));

    if (obj) {
        Q_EMIT obj->frameAvailable();
    }
}


AndroidSurfaceTexture::AndroidSurfaceTexture(quint32 texName): QObject() {
    Q_STATIC_ASSERT(sizeof (jlong) >= sizeof (void *));

    QAndroidJniEnvironment env;

    m_surfaceTexture = QAndroidJniObject("android/graphics/SurfaceTexture", "(I)V", jint(texName));

    if (env->ExceptionCheck()) {
        env->ExceptionClear();
    }

    if (!m_surfaceTexture.isValid()) {
        return;
    }

    const QMutexLocker lock(g_textureMutex);

    g_surfaceTextures->append(jlong(this));

    QAndroidJniObject listener(QtSurfaceTextureListenerClassName, "(J)V", jlong(this));

    setOnFrameAvailableListener(listener);
}


AndroidSurfaceTexture::~AndroidSurfaceTexture() {
    if (m_surface.isValid()) {
        m_surface.callMethod<void>("release");
    }

    if (m_surfaceTexture.isValid()) {
        release();

        const QMutexLocker lock(g_textureMutex);

        const int idx = g_surfaceTextures->indexOf(jlong(this));

        if (idx != -1) {
            g_surfaceTextures->remove(idx);
        }
    }
}


QMatrix4x4 AndroidSurfaceTexture::getTransformMatrix() {
    QMatrix4x4 matrix;
    if (!m_surfaceTexture.isValid()) {
        return matrix;
    }

    QAndroidJniEnvironment env;

    jfloatArray array = env->NewFloatArray(16);

    m_surfaceTexture.callMethod<void>("getTransformMatrix", "([F)V", array);

    env->GetFloatArrayRegion(array, 0, 16, matrix.data());
    env->DeleteLocalRef(array);

    return matrix;
}


void AndroidSurfaceTexture::release() {
    m_surfaceTexture.callMethod<void>("release");
}


void AndroidSurfaceTexture::updateTexImage() {
    if (!m_surfaceTexture.isValid()) {
        return;
    }

    m_surfaceTexture.callMethod<void>("updateTexImage");
}


jobject AndroidSurfaceTexture::surfaceTexture() {
    return m_surfaceTexture.object();
}


jobject AndroidSurfaceTexture::surface() {
    if (!m_surface.isValid()) {
        m_surface = QAndroidJniObject("android/view/Surface",
                                      "(Landroid/graphics/SurfaceTexture;)V",
                                      m_surfaceTexture.object());
    }
    return m_surface.object();
}


jobject AndroidSurfaceTexture::surfaceHolder() {
    if (!m_surfaceHolder.isValid()) {
        m_surfaceHolder = QAndroidJniObject("org/qtproject/qt5/android/multimedia/QtSurfaceTextureHolder",
                                            "(Landroid/view/Surface;)V",
                                            surface());
    }

    return m_surfaceHolder.object();
}


void AndroidSurfaceTexture::attachToGLContext(quint32 texName) {
    if (!m_surfaceTexture.isValid()) {
        return;
    }

    m_surfaceTexture.callMethod<void>("attachToGLContext", "(I)V", texName);
}


void AndroidSurfaceTexture::detachFromGLContext() {
    if (!m_surfaceTexture.isValid()) {
        return;
    }

    m_surfaceTexture.callMethod<void>("detachFromGLContext");
}


bool AndroidSurfaceTexture::initJNI(JNIEnv *env) {
    QAndroidJniEnvironment jenv;

    jclass clazz = jenv.findClass(QtSurfaceTextureListenerClassName);

    QAndroidJniObject qjniObject(QtSurfaceTextureListenerClassName);

    static const JNINativeMethod methods[] = {
        {"notifyFrameAvailable", "(J)V", (void *)notifyFrameAvailable}
    };

    if (clazz && env->RegisterNatives(clazz,
                                      methods,
                                      sizeof(methods) / sizeof(methods[0])) != JNI_OK) {
        return false;
    }
    return true;
}

jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    Q_UNUSED(reserved)
    static bool initialized = false;
    if (initialized) {
        return JNI_VERSION_1_6;
    }

    initialized = true;

    JNIEnv* env;
    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
        return -1;
    }

    AndroidSurfaceTexture::initJNI(env);

    return JNI_VERSION_1_6;
}

void AndroidSurfaceTexture::setOnFrameAvailableListener(const QAndroidJniObject &listener) {
    m_surfaceTexture.callMethod<void>("setOnFrameAvailableListener",
                                      "(Landroid/graphics/SurfaceTexture$OnFrameAvailableListener;)V",
                                      listener.object());
}
