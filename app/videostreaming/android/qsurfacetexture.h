#ifndef QSURFACETEXTURE_H
#define QSURFACETEXTURE_H

#include <QAndroidJniObject>
#include <QQuickItem>

#include "lowlagdecoder.h"

class QSurfaceTexture : public QQuickItem
{
    Q_OBJECT
public:
    QSurfaceTexture(QQuickItem *parent = nullptr);
    ~QSurfaceTexture();

    // returns surfaceTexture Java object.
    const QAndroidJniObject &surfaceTexture() const { return m_surfaceTexture; }

    // Needs to be explicitly called from c++ to do proper aspect ratio
    // not thread safe, but this doesn't matter
    void set_video_texture_size(int width_px,int height_px);
    void setDecoder(LowLagDecoder* decoder);
    // QQuickItem interface
protected:
    QSGNode *updatePaintNode(QSGNode *n, UpdatePaintNodeData *) override;

signals:
    void surfaceTextureChanged(QSurfaceTexture *surfaceTexture);

private:

    // our texture
    uint32_t m_textureId = 0;

    // Java SurfaceTexture object
    QAndroidJniObject m_surfaceTexture;

    int m_texture_width_px=0;
    int m_texture_height_px=0;
    LowLagDecoder* m_decoder;
    QTimer *m_updateTimer;
};

#endif // QSURFACETEXTURE_H
