#ifndef TEXTURERENDERER_H
#define TEXTURERENDERER_H


#include <QObject>
#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickWindow>
#include <QOpenGLShaderProgram>
#include <QOpenGLFunctions>
#include <chrono>
#include <QOpenGLTexture>

//! [1]
class TextureRenderer : public QObject, protected QOpenGLFunctions
{
    Q_OBJECT
public:
    ~TextureRenderer();

    void setT(qreal t) { m_t = t; }
    void setViewportSize(const QSize &size) { m_viewportSize = size; }
    void setWindow(QQuickWindow *window) { m_window = window; }
    // create and link the shaders
    void init();
    // draw function
    void paint();

private:
    QSize m_viewportSize;
    qreal m_t = 0.0;
    int m_index=0;
    QOpenGLShaderProgram *m_program = nullptr;
    QQuickWindow *m_window = nullptr;
    std::chrono::steady_clock::time_point last_frame=std::chrono::steady_clock::now();
    //
    //QOpenGLTexture *texture = nullptr;
};
//! [1]

#endif // TEXTURERENDERER_H
