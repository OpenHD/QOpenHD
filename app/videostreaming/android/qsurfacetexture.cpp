#include "qsurfacetexture.h"

// --- Qt5/Qt6 JNI compatibility shim ---
#include <QtGlobal>
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
  #include <QJniObject>
  #include <QJniEnvironment>
  #include <QtCore/qnativeinterface.h>
  using QAndroidJniObject = QJniObject;
  using QAndroidJniEnvironment = QJniEnvironment;
#else
  #include <QAndroidJniObject>
  #include <QAndroidJniEnvironment>
  #include <QtAndroid>
#endif
// --------------------------------------

// Android OpenGL ES
#ifdef Q_OS_ANDROID
  #include <GLES2/gl2.h>
  #include <GLES2/gl2ext.h>
#endif

#include <QMatrix4x4>
#include <QRectF>
#include <QList>
#include <QByteArray>

#include <QSGGeometryNode>
#include <QSGGeometry>
#include <QSGTexture>
#include <QSGTextureMaterial>

#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
// Needed for QNativeInterface::QSGOpenGLTexture::fromNativeExternalOES
#include <qsgtextureplatform.h>
#endif

#include "../vscommon/QOpenHDVideoHelper.hpp"
#include "../vscommon/video_ratio_helper.hpp"

// A node that renders an EXTERNAL_OES texture using Qt's built-in texture material.
class SurfaceTextureNode : public QSGGeometryNode
{
public:
    SurfaceTextureNode(const QAndroidJniObject &surfaceTexture,
                       QQuickWindow *win,
                       GLuint textureId,
                       const QSize &initialSize)
        : m_surfaceTexture(surfaceTexture)
        , m_geometry(QSGGeometry::defaultAttributes_TexturedPoint2D(), 4)
        , m_textureId(textureId)
        , m_window(win)
    {
        setFlag(UsePreprocess);
        setGeometry(&m_geometry);
        setFlag(OwnsGeometry, false);

        // Wrap the external OES texture as a QSGTexture
#if QT_VERSION >= QT_VERSION_CHECK(6, 1, 0)
        m_qsgTexture = QNativeInterface::QSGOpenGLTexture::fromNativeExternalOES(
                m_textureId, m_window, initialSize, {});
#else
        // Fallback (should not happen on your Qt 6.9, but keeps the code compilable)
        m_qsgTexture = QNativeInterface::QSGOpenGLTexture::fromNative(
                m_textureId, m_window, initialSize, {});
#endif
        // Material that samples the QSGTexture
        auto *mat = new QSGTextureMaterial();
        mat->setTexture(m_qsgTexture);
        setMaterial(mat);
        setFlag(OwnsMaterial, true);

        // Prepare a global jfloat[16] for the transform matrix (kept if you later want to apply it)
        QAndroidJniEnvironment env;
        jfloatArray array = env->NewFloatArray(16);
        m_uSTMatrixArray = jfloatArray(env->NewGlobalRef(array));
        env->DeleteLocalRef(array);
    }

    ~SurfaceTextureNode() override
    {
        QAndroidJniEnvironment env;
        if (m_uSTMatrixArray)
            env->DeleteGlobalRef(m_uSTMatrixArray);
        m_uSTMatrixArray = nullptr;

        // QSGTexture is *not* owned by the material, so clean it up.
        delete m_qsgTexture;
        m_qsgTexture = nullptr;
    }

    void setRect(const QRectF &rect, const QRectF &texRect)
    {
        // Basic rect + (0..1) tex coords. If you later want to apply uSTMatrix,
        // you can compute transformed UVs here and fill vertex data manually.
        QSGGeometry::updateTexturedRectGeometry(&m_geometry, rect, texRect);
        markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);
    }

    // QSGNode interface
    void preprocess() override
    {
        // Update the texture content
        m_surfaceTexture.callMethod<void>("updateTexImage");

        // If you need the transform, keep retrieving it here (render thread):
        // m_surfaceTexture.callMethod<void>("getTransformMatrix", "([F)V", m_uSTMatrixArray);
        // QAndroidJniEnvironment env;
        // env->GetFloatArrayRegion(m_uSTMatrixArray, 0, 16, m_uSTMatrix.data());
    }

private:
    QAndroidJniObject m_surfaceTexture;
    QSGGeometry m_geometry;
    jfloatArray m_uSTMatrixArray = nullptr;
    GLuint m_textureId = 0;
    QQuickWindow *m_window = nullptr;
    QSGTexture *m_qsgTexture = nullptr;
};

// ---- QSurfaceTexture item ----

QSurfaceTexture::QSurfaceTexture(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlags(ItemHasContents);
}

QSurfaceTexture::~QSurfaceTexture()
{
    // Delete our texture
    if (m_textureId) {
        glBindTexture(GL_TEXTURE_EXTERNAL_OES, 0);
        glDeleteTextures(1, &m_textureId);
        m_textureId = 0;
    }
}

void QSurfaceTexture::set_video_texture_size(int width_px, int height_px)
{
    m_texture_width_px = width_px;
    m_texture_height_px = height_px;
}

// Flip vertically. Despite the name, this swaps top/bottom to correct orientation on Android.
static void qrectf_flip_horizontally(QRectF& rect){
    float tmp = rect.top();
    rect.setTop(rect.bottom());
    rect.setBottom(tmp);
}

QSGNode *QSurfaceTexture::updatePaintNode(QSGNode *n, QQuickItem::UpdatePaintNodeData *)
{
    auto *node = static_cast<SurfaceTextureNode *>(n);
    if (!node) {
        // Create the external OES texture
        glGenTextures(1, &m_textureId);
        glBindTexture(GL_TEXTURE_EXTERNAL_OES, m_textureId);

        // Can't do mipmapping with camera/video source
        glTexParameterf(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameterf(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

        // Clamp to edge is the only option
        glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        // Create the Java SurfaceTexture bound to our GL texture
        m_surfaceTexture = QAndroidJniObject("android/graphics/SurfaceTexture", "(I)V", m_textureId);

        // Build the scene graph node around it
        const QSize texSize = (m_texture_width_px > 0 && m_texture_height_px > 0)
                                ? QSize(m_texture_width_px, m_texture_height_px)
                                : QSize(1, 1);
        node = new SurfaceTextureNode(m_surfaceTexture, window(), m_textureId, texSize);
        emit surfaceTextureChanged(this);
    }

    QRectF rect(boundingRect());
    if (m_texture_width_px > 0 && m_texture_height_px > 0) {
        auto coords = helper::ratio::calculate_viewport(
            boundingRect().width(),
            boundingRect().height(),
            m_texture_width_px,
            m_texture_height_px,
            QOpenHDVideoHelper::get_primary_video_scale_to_fit());
        rect = QRectF(coords.x, coords.y, coords.width, coords.height);
    }

    // Flip vertical - otherwise video can appear upside down on Android
    qrectf_flip_horizontally(rect);

    // For now we use the basic 0..1 texture rect. If you need the Android uSTMatrix
    // applied (crop/rotate), we can extend setRect() to write transformed UVs.
    const QRectF texture_coords = QRectF(0, 0, 1, 1);

    node->setRect(rect, texture_coords);

    // Schedule a repaint on the GUI thread
    QMetaObject::invokeMethod(reinterpret_cast<QSurfaceTexture*>(this), "update", Qt::QueuedConnection);
    return node;
}
