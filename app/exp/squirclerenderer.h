#ifndef SQUIRCLERENDERER_H
#define SQUIRCLERENDERER_H

#include <QObject>
#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickWindow>
#include <QOpenGLShaderProgram>
#include <QOpenGLFunctions>
#include <chrono>

//! [1]
class SquircleRenderer : public QObject, protected QOpenGLFunctions
{
    Q_OBJECT
public:
    ~SquircleRenderer();

    void setT(qreal t) { m_t = t; }
    void setViewportSize(const QSize &size) { m_viewportSize = size; }
    void setWindow(QQuickWindow *window) { m_window = window; }

public slots:
    void init();
    void paint();

private:
    QSize m_viewportSize;
    qreal m_t = 0.0;
    QOpenGLShaderProgram *m_program = nullptr;
    QQuickWindow *m_window = nullptr;
    std::chrono::steady_clock::time_point last_frame=std::chrono::steady_clock::now();
};
//! [1]

#endif // SQUIRCLERENDERER_H
