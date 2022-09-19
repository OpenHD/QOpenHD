// Copyright (C) 2016 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#ifndef SQUIRCLE_H
#define SQUIRCLE_H

#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickWindow>
#include <QOpenGLShaderProgram>
#include <QOpenGLFunctions>
#include <QTimer>

//#include "squirclerenderer.h"
#include "texturerenderer.h"

#include "avcodec_decoder.h"

// Hoock into the QT Scene graph and draw video directly without the "intermediate" rgba texture as
// required with qmlglsink. See the qt "Squircle" documentation
class Squircle : public QQuickItem
{
    Q_OBJECT
    QML_ELEMENT
public:
    Squircle();

public slots:
    void sync();
    void cleanup();

private slots:
    void handleWindowChanged(QQuickWindow *win);

private:
    void releaseResources() override;

    //SquircleRenderer *m_renderer;
    TextureRenderer* m_renderer;
public slots:
    void m_QQuickWindow_beforeRendering();
    void m_QQuickWindow_beforeRenderPassRecording();
private:
    std::unique_ptr<AVCodecDecoder> m_av_codec_decoder=nullptr;
};

#endif // SQUIRCLE_H
