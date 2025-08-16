#ifndef QSURFACETEXTURE_H
#define QSURFACETEXTURE_H

#include <QtGlobal>

// --- Qt5/Qt6 JNI compatibility ---
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
  #include <QJniObject>
  // Alias so existing code using QAndroidJniObject still compiles on Qt 6
  using QAndroidJniObject = QJniObject;
#else
  #include <QAndroidJniObject>   // Qt 5 (AndroidExtras)
#endif
// ---------------------------------

#include <QQuickItem>
#include <cstdint>

class QSGNode;

class QSurfaceTexture : public QQuickItem
{
    Q_OBJECT
public:
    explicit QSurfaceTexture(QQuickItem *parent = nullptr);
    ~QSurfaceTexture() override;

    // Returns the Java SurfaceTexture wrapper.
    const QAndroidJniObject &surfaceTexture() const { return m_surfaceTexture; }

    // Needs to be explicitly called from C++ to apply proper aspect ratio.
    // Not thread-safe (by design for this path).
    void set_video_texture_size(int width_px, int height_px);

protected:
    // QQuickItem interface
    QSGNode *updatePaintNode(QSGNode *n, UpdatePaintNodeData *) override;

signals:
    void surfaceTextureChanged(QSurfaceTexture *surfaceTexture);

private:
    // Our GL external texture
    uint32_t m_textureId = 0;

    // Java android.graphics.SurfaceTexture
    QAndroidJniObject m_surfaceTexture;

    int m_texture_width_px  = 0;
    int m_texture_height_px = 0;
};

#endif // QSURFACETEXTURE_H
