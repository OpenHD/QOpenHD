#ifndef ANDROIDSURFACETEXTURE_H
#define ANDROIDSURFACETEXTURE_H

#include <qobject.h>

#include <QAndroidJniEnvironment>
#include <QAndroidJniObject>

#include <QMatrix4x4>

QT_BEGIN_NAMESPACE

class AndroidSurfaceTexture : public QObject {
    Q_OBJECT
public:
    explicit AndroidSurfaceTexture(quint32 texName);
    ~AndroidSurfaceTexture();
    jobject surfaceTexture();
    jobject surface();
    jobject surfaceHolder();
    inline bool isValid() const { return m_surfaceTexture.isValid(); }
    QMatrix4x4 getTransformMatrix();
    void release(); // API level 14
    void updateTexImage();
    void attachToGLContext(quint32 texName); // API level 16
    void detachFromGLContext(); // API level 16
    static bool initJNI(JNIEnv *env);
Q_SIGNALS:
    void frameAvailable();
private:
    void setOnFrameAvailableListener(const QAndroidJniObject &listener);
    QAndroidJniObject m_surfaceTexture;
    QAndroidJniObject m_surface;
    QAndroidJniObject m_surfaceHolder;
};
QT_END_NAMESPACE
#endif // ANDROIDSURFACETEXTURE_H
