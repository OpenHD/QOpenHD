// Copyright (C) 2016 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include "QSGVideoTextureItem.h"

#include <QtQuick/qquickwindow.h>
#include <QtCore/QRunnable>
#include <QtCore/qmath.h>

#include "util/qrenderstats.h"


QSGVideoTextureItem::QSGVideoTextureItem():
    m_renderer(nullptr)
{
    connect(this, &QQuickItem::windowChanged, this, &QSGVideoTextureItem::handleWindowChanged);
}

QSGVideoTextureItem::~QSGVideoTextureItem()
{
    if (!m_primary_stream) {
        TextureRenderer::instance().setSecondaryViewport(QRect());
    }
}

void QSGVideoTextureItem::setPrimaryStream(bool primaryStream)
{
    if (m_decoder_started || m_primary_stream == primaryStream) {
        return;
    }
    m_primary_stream = primaryStream;
    emit primaryStreamChanged();
}

void QSGVideoTextureItem::componentComplete()
{
    QQuickItem::componentComplete();
    m_av_codec_decoder=std::make_unique<AVCodecDecoder>(nullptr);
    m_av_codec_decoder->init(m_primary_stream);
    m_decoder_started=true;
}

void QSGVideoTextureItem::handleWindowChanged(QQuickWindow *win)
{
    qDebug()<<"QSGVideoTextureItem::handleWindowChanged";
    if (win) {
        connect(win, &QQuickWindow::beforeSynchronizing, this, &QSGVideoTextureItem::sync, Qt::DirectConnection);
        //connect(win, &QQuickWindow::sceneGraphInvalidated, this, &QSGVideoTextureItem::cleanup, Qt::DirectConnection);
        // Ensure we start with cleared to black. The squircle's blend mode relies on this.
        // We do not need that when rendering a texture, which is what we actually want (squircle is just the example where I started with,
        // since I had to start somehow ;)
        // if you put this to any color it will mess up the videorenderer
        //win->setColor(Qt::black);
    }
}


void QSGVideoTextureItem::releaseResources()
{
     qDebug()<<"QSGVideoTextureItem::releaseResources";
     /*if(m_renderer){
         delete(m_renderer);
         m_renderer=nullptr;
     }*/
}


void QSGVideoTextureItem::sync()
{
    if (!m_renderer) {
        m_renderer = &TextureRenderer::instance();
        // Both items render on Qt's scene-graph thread. Keeping a hook per item
        // preserves QML stacking and prevents the secondary pass from replacing
        // the full-screen primary pass.
        if (m_primary_stream) {
            connect(window(), &QQuickWindow::beforeRendering, this, &QSGVideoTextureItem::m_QQuickWindow_beforeRendering, Qt::DirectConnection);
        }
        connect(window(), &QQuickWindow::beforeRenderPassRecording, this, &QSGVideoTextureItem::m_QQuickWindow_beforeRenderPassRecording, Qt::DirectConnection);
        //X
        //QRenderStats::instance().registerOnWindow(window());
    }
    const qreal dpr=window()->devicePixelRatio();
    if (m_primary_stream) {
        m_renderer->setViewportSize(window()->size() * dpr);
    } else {
        const QPointF top_left=mapToScene(QPointF(0, 0));
        const int viewport_x=qRound(top_left.x() * dpr);
        const int viewport_y=qRound((window()->height() - top_left.y() - height()) * dpr);
        const int viewport_width=qRound(width() * dpr);
        const int viewport_height=qRound(height() * dpr);
        m_renderer->setSecondaryViewport(QRect(viewport_x, viewport_y, viewport_width, viewport_height));
    }
}

void QSGVideoTextureItem::m_QQuickWindow_beforeRendering()
{
    if(m_renderer){
        m_renderer->initGL(window());
    }
}

void QSGVideoTextureItem::m_QQuickWindow_beforeRenderPassRecording()
{
    if(m_renderer){
        //qDebug()<<"Rotation:"<<QQuickItem::rotation();
        const auto screen_rotation=QOpenHDVideoHelper::get_display_rotation();
        m_renderer->paint(window(),screen_rotation,m_primary_stream);
    }
    // always trigger a repaint, otherwise QT "thinks" nothing has changed since it doesn't
    // know about the OpenGL commands we do here
    //window()->update();
    window()->update();
    //window()->requestUpdate();
}



