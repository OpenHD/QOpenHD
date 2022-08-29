// Copyright (C) 2016 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include "squircle.h"

#include <QtQuick/qquickwindow.h>
#include <QOpenGLShaderProgram>
#include <QOpenGLContext>
#include <QtCore/QRunnable>


class CleanupJob : public QRunnable
{
public:
    CleanupJob(TextureRenderer *renderer) : m_renderer(renderer) { }
    void run() override { delete m_renderer; }
private:
   TextureRenderer *m_renderer;
};

Squircle::Squircle()
    : m_t(0)
    , m_renderer(nullptr)
    ,timerAlwaysRedraw(new QTimer)
{
    connect(this, &QQuickItem::windowChanged, this, &Squircle::handleWindowChanged);
    QObject::connect(timerAlwaysRedraw, &QTimer::timeout, this, &Squircle::timerCallback);
    timerAlwaysRedraw->start(5);
}

void Squircle::setT(qreal t)
{
    //qDebug()<<"Set t:"<<t;
    if (t == m_t)
        return;
    m_t = t;
    emit tChanged();
    if (window())
        window()->update();
}

void Squircle::handleWindowChanged(QQuickWindow *win)
{
    if (win) {
        connect(win, &QQuickWindow::beforeSynchronizing, this, &Squircle::sync, Qt::DirectConnection);
        connect(win, &QQuickWindow::sceneGraphInvalidated, this, &Squircle::cleanup, Qt::DirectConnection);
        // Ensure we start with cleared to black. The squircle's blend mode relies on this.
        win->setColor(Qt::black);
    }
}

void Squircle::cleanup()
{
    delete m_renderer;
    m_renderer = nullptr;
}

void Squircle::releaseResources()
{
    window()->scheduleRenderJob(new CleanupJob(m_renderer), QQuickWindow::BeforeSynchronizingStage);
    m_renderer = nullptr;
}


void Squircle::sync()
{
    if (!m_renderer) {
        //m_renderer = new SquircleRenderer();
        m_renderer = new TextureRenderer();
        connect(window(), &QQuickWindow::beforeRendering, this, &Squircle::m_QQuickWindow_beforeRendering, Qt::DirectConnection);
        connect(window(), &QQuickWindow::beforeRenderPassRecording, this, &Squircle::m_QQuickWindow_beforeRenderPassRecording, Qt::DirectConnection);
    }
    m_renderer->setViewportSize(window()->size() * window()->devicePixelRatio());
    m_renderer->setT(m_t);
    m_renderer->setWindow(window());
}

void Squircle::m_QQuickWindow_beforeRendering()
{
    if(m_renderer){
        m_renderer->init();
    }
}

void Squircle::m_QQuickWindow_beforeRenderPassRecording()
{
    if(m_renderer){
        m_renderer->paint();
    }
}

void Squircle::timerCallback()
{
    //qDebug()<<"Squircle::timerCallback()";
    //if (window())
    //    window()->update();
}


