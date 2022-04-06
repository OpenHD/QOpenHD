#if defined(ENABLE_VIDEO_RENDER)
#if defined(__android__)

#ifndef OPENHDANDROIDRENDER_H
#define OPENHDANDROIDRENDER_H

#include <QAndroidJniObject>
#include <QQuickItem>


class OpenHDAndroidRender : public QQuickItem {
    Q_OBJECT
public:
    OpenHDAndroidRender(QQuickItem *parent = nullptr);
    ~OpenHDAndroidRender() override;

    const QAndroidJniObject &surfaceTexture() const {
        return m_surfaceTexture;
    }

    Q_PROPERTY(QQuickWindow *window MEMBER m_window WRITE setWindow NOTIFY windowChanged)

    Q_INVOKABLE void setWindow(QQuickWindow *window);

    QQuickWindow *m_window = nullptr;

protected:
    QSGNode *updatePaintNode(QSGNode *n, UpdatePaintNodeData *) override;

private slots:
    void handleWindowChanged(QQuickWindow *win);
    void doUpdate();

signals:
    void surfaceTextureChanged(OpenHDAndroidRender *surfaceTexture);
    void windowChanged(QQuickWindow *window);
    void onUpdate();

private:
    uint32_t m_textureId = 0;

    QAndroidJniObject m_surfaceTexture;
};

#endif // OPENHDANDROIDRENDER_H

#endif
#endif
