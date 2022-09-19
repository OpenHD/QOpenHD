// Copyright (C) 2016 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include "squircle.h"

#include <QtQuick/qquickwindow.h>
#include <QOpenGLShaderProgram>
#include <QOpenGLContext>
#include <QtCore/QRunnable>

#include "../util/qrenderstats.h"

class CleanupJob : public QRunnable
{
public:
    CleanupJob(TextureRenderer *renderer) : m_renderer(renderer) { }
    void run() override { delete m_renderer; }
private:
   TextureRenderer *m_renderer;
};

Squircle::Squircle():
    m_renderer(nullptr)
{
    connect(this, &QQuickItem::windowChanged, this, &Squircle::handleWindowChanged);
    //
    m_av_codec_decoder=std::make_unique<AVCodecDecoder>(nullptr);
    m_av_codec_decoder->init(true);
}


void Squircle::handleWindowChanged(QQuickWindow *win)
{
    qDebug()<<"Squircle::handleWindowChanged";
    if (win) {
        connect(win, &QQuickWindow::beforeSynchronizing, this, &Squircle::sync, Qt::DirectConnection);
        connect(win, &QQuickWindow::sceneGraphInvalidated, this, &Squircle::cleanup, Qt::DirectConnection);
        // Ensure we start with cleared to black. The squircle's blend mode relies on this.
        // We do not need that when rendering a texture, which is what we actually want (squircle is just the example where I started with,
        // since I had to start somehow ;)
        //win->setColor(Qt::black);
    }
}

void Squircle::cleanup()
{
     qDebug()<<"Squircle::cleanup";
    delete m_renderer;
    m_renderer = nullptr;
}

void Squircle::releaseResources()
{
     qDebug()<<"Squircle::Squircle::releaseResources";
    window()->scheduleRenderJob(new CleanupJob(m_renderer), QQuickWindow::BeforeSynchronizingStage);
    m_renderer = nullptr;
}


void Squircle::sync()
{
    if (!m_renderer) {
        m_renderer = &TextureRenderer::instance();
        connect(window(), &QQuickWindow::beforeRendering, this, &Squircle::m_QQuickWindow_beforeRendering, Qt::DirectConnection);
        connect(window(), &QQuickWindow::beforeRenderPassRecording, this, &Squircle::m_QQuickWindow_beforeRenderPassRecording, Qt::DirectConnection);
        //X
        QRenderStats::instance().registerOnWindow(window());
    }
    m_renderer->setViewportSize(window()->size() * window()->devicePixelRatio());
    m_renderer->setWindow(window());
}

void Squircle::m_QQuickWindow_beforeRendering()
{
    if(m_renderer){
        m_renderer->initGL();
    }
}

void Squircle::m_QQuickWindow_beforeRenderPassRecording()
{
    if(m_renderer){
        m_renderer->paint();
    }
    // always trigger a repaint, otherwise QT "thinks" nothing has changed since it doesn't
    // know about the OpenGL commands we do here
    //window()->update();
    window()->update();
    //window()->requestUpdate();
}



