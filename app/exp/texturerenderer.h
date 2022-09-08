#ifndef TEXTURERENDERER_H
#define TEXTURERENDERER_H


#include <QObject>
#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickWindow>
#include <QOpenGLShaderProgram>
#include <QOpenGLFunctions>
#include <chrono>
#include <QOpenGLTexture>
#include <QOpenGLBuffer>
#include <memory>

#include "gl_shaders.h"

//! [1]
class TextureRenderer : public QObject, protected QOpenGLFunctions
{
    Q_OBJECT
public:
    ~TextureRenderer();

    void setViewportSize(const QSize &size) { m_viewportSize = size; }
    void setWindow(QQuickWindow *window) { m_window = window; }
    // create and link the shaders
    void init();
    // draw function
    void paint();

private:
    QSize m_viewportSize;
    int m_index=0;
    QOpenGLShaderProgram *m_program = nullptr;
    QQuickWindow *m_window = nullptr;
    std::chrono::steady_clock::time_point last_frame=std::chrono::steady_clock::now();
    //
    std::unique_ptr<QOpenGLTexture> texture1=nullptr;
    std::unique_ptr<QOpenGLTexture> texture2=nullptr;
    //
    std::unique_ptr<GL_shaders> gl_shaders=nullptr;
    //
    int renderCount=0;
    GLuint vbo;
    GLint pos;
    GLint uvs;
    //
};
//! [1]

#endif // TEXTURERENDERER_H
