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
#include <QSGSimpleRectNode>

#include "../vscommon/QOpenHDVideoHelper.hpp"
#include "../vscommon/video_ratio_helper.hpp"

// -----------------------------------------------------------------------------
// Debug Pink build switch: define to render a solid magenta rectangle and bypass
// the Android SurfaceTexture + EXTERNAL_OES path entirely. Comment out to return
// to normal rendering.
// -----------------------------------------------------------------------------
#define QST_DEBUG_PINK 1

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
        m_qsgTexture = QNativeInterface::QSGOpenGLTexture::fromNative(
                m_textureId, m_window, initialSize, {});
#endif
        auto *mat = new QSGTextureMaterial();
        mat->setTexture(m_qsgTexture);
        setMaterial(mat);
        setFlag(OwnsMaterial, true);

        // Prepare a global jfloat[16] for the transform matrix (optional use later)
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

        delete m_qsgTexture;
        m_qsgTexture = nullptr;
    }

    void setRect(const QRectF &rect, const QRectF &texRect)
    {
        QSGGeometry::updateTexturedRectGeometry(&m_geometry, rect, texRect);
        markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);
    }

    void preprocess() override
    {
        m_surfaceTexture.callMethod<void>("updateTexImage");
        // If needed later:
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
#ifndef QST_DEBUG_PINK
    if (m_textureId) {
        glBindTexture(GL_TEXTURE_EXTERNAL_OES, 0);
        glDeleteTextures(1, &m_textureId);
        m_textureId = 0;
    }
#else
    Q_UNUSED(m_textureId);
#endif
}

void QSurfaceTexture::set_video_texture_size(int width_px, int height_px)
{
    m_texture_width_px = width_px;
    m_texture_height_px = height_px;
}

// Flip vertically (swap top/bottom).
static void qrectf_flip_horizontally(QRectF& rect){
    float tmp = rect.top();
    rect.setTop(rect.bottom());
    rect.setBottom(tmp);
}

QSGNode *QSurfaceTexture::updatePaintNode(QSGNode *n, QQuickItem::UpdatePaintNodeData *)
{
#ifdef QST_DEBUG_PINK
    // Debug path: always draw a solid pink rect. This bypasses all OES/SurfaceTexture work
    // to quickly verify the item is alive, visible, and repainting.
    if (n) {
        delete n;  // ensure we don't keep the old texture node around
        n = nullptr;
    }

    auto *rectNode = new QSGSimpleRectNode();
    rectNode->setRect(boundingRect());
    rectNode->setColor(QColor(255, 0, 255)); // bright magenta

    // Keep requesting frames so you also confirm the render loop is ticking.
    QMetaObject::invokeMethod(this, "update", Qt::QueuedConnection);
    return rectNode;
#else
    auto *node = static_cast<SurfaceTextureNode *>(n);
    if (!node) {
        glGenTextures(1, &m_textureId);
        glBindTexture(GL_TEXTURE_EXTERNAL_OES, m_textureId);

        glTexParameterf(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameterf(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        m_surfaceTexture = QAndroidJniObject("android/graphics/SurfaceTexture", "(I)V", m_textureId);

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

    qrectf_flip_horizontally(rect);

    const QRectF texture_coords = QRectF(0, 0, 1, 1);
    node->setRect(rect, texture_coords);

    QMetaObject::invokeMethod(reinterpret_cast<QSurfaceTexture*>(this), "update", Qt::QueuedConnection);
    return node;
#endif
}
