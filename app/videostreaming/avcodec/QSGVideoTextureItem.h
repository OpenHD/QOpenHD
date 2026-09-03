// Copyright (C) 2016 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#ifndef QSGVideoTextureItem_H
#define QSGVideoTextureItem_H

#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickWindow>

#include "texturerenderer.h"

#include "avcodec_decoder.h"

// QSG stands for QT Screne Graph (an abbreviation they recommend)
// Hoock into the QT Scene graph and draw video directly with (custom) OpenGL.
// This is the only way to skip the the "intermediate" rgba texture as
// required (for examle) qmlglsink. See the qt "Squircle" documentation
class QSGVideoTextureItem : public QQuickItem
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool primaryStream READ primaryStream WRITE setPrimaryStream NOTIFY primaryStreamChanged)
public:
    QSGVideoTextureItem();
    ~QSGVideoTextureItem() override;

    bool primaryStream() const { return m_primary_stream; }
    void setPrimaryStream(bool primaryStream);

signals:
    void primaryStreamChanged();

public slots:
    void sync();

private slots:
    void handleWindowChanged(QQuickWindow *win);

private:
    void componentComplete() override;
    void releaseResources() override;

    TextureRenderer* m_renderer=nullptr;
public slots:
    void m_QQuickWindow_beforeRendering();
    void m_QQuickWindow_beforeRenderPassRecording();
private:
    std::unique_ptr<AVCodecDecoder> m_av_codec_decoder=nullptr;
    bool m_primary_stream=true;
    bool m_decoder_started=false;
};

#endif // QSGVideoTextureItem_H
