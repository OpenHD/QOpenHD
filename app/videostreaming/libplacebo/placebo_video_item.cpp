// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#ifdef ENABLE_V4L2_GL_PLAYER

#include "placebo_video_item.h"
#include "v4l2_pipeline.h"
#include "../v4l2/v4l2_decoder_detector.h"
#include "../vscommon/QOpenHDVideoHelper.hpp"

#include <QDebug>
#include <QtQuick/qquickwindow.h>
#include <QSGRendererInterface>
#include <QOpenGLContext>
#include <QSettings>


// ==================== FrameWaiterThread ====================

FrameWaiterThread::FrameWaiterThread(PlaceboFrameQueue* queue, QObject* parent)
    : QThread(parent)
    , m_queue(queue)
{
}

FrameWaiterThread::~FrameWaiterThread()
{
    stop();
}

void FrameWaiterThread::stop()
{
    m_running.store(false);
    if (m_queue) {
        m_queue->stop();
    }
    if (isRunning()) {
        wait(1000);  // Wait up to 1 second
        if (isRunning()) {
            qWarning() << "FrameWaiterThread: forcing termination";
            terminate();
            wait();
        }
    }
}

void FrameWaiterThread::run()
{
    qDebug() << "FrameWaiterThread: started";

    while (m_running.load()) {
        // Block until frame available or stopped
        if (m_queue->wait_frame()) {
            emit frameAvailable();
        }
    }

    qDebug() << "FrameWaiterThread: stopped";
}


// ==================== PlaceboVideoItem ====================

PlaceboVideoItem::PlaceboVideoItem(QQuickItem *parent)
    : QQuickItem(parent)
{
    qDebug() << "PlaceboVideoItem: constructor";

    // Connect to window changes
    connect(this, &QQuickItem::windowChanged, this, &PlaceboVideoItem::handleWindowChanged);

    // Read video configuration from settings
    const auto settings = QOpenHDVideoHelper::read_config_from_settings();
    const auto& stream_config = settings.primary_stream_config;

    // Detect available V4L2 decoders
    auto decoders = V4L2DecoderDetector::detect_decoders();
    qInfo() << "PlaceboVideoItem: found" << decoders.size() << "V4L2 decoders";

    // Find first decoder matching required codec
    DecoderInfo* selected_decoder = nullptr;
    for (auto& dec : decoders) {
        qInfo() << "  Decoder:" << dec.device_path.c_str()
                << "codec:" << (dec.codec == VideoCodec::H264 ? "H264" : "H265")
                << "type:" << (dec.type == V4L2DecoderType::Stateless ? "Stateless" : "Stateful")
                << "driver:" << dec.driver_name.c_str();

        if (dec.codec == stream_config.video_codec && !selected_decoder) {
            selected_decoder = &dec;
        }
    }

    if (!selected_decoder) {
        qFatal("PlaceboVideoItem: No V4L2 decoder found for codec");
    }

    qInfo() << "PlaceboVideoItem: selected decoder" << selected_decoder->device_path.c_str();

    // Create pipeline configuration
    V4L2Pipeline::Config pipeline_config;
    pipeline_config.rtp_listen_addr = stream_config.udp_rtp_input_ip_address;
    pipeline_config.rtp_listen_port = static_cast<uint16_t>(stream_config.udp_rtp_input_port);

    // Create and start the pipeline
    m_pipeline = std::make_unique<V4L2Pipeline>(pipeline_config, *selected_decoder);

    if (!m_pipeline->start()) {
        qFatal("PlaceboVideoItem: failed to start V4L2Pipeline");
    }

    // Get frame queue from pipeline
    m_frame_queue = &m_pipeline->get_frame_queue();

    // Create and start waiter thread
    m_waiter_thread = std::make_unique<FrameWaiterThread>(m_frame_queue, this);

    // Connect waiter signal to our slot (cross-thread via QueuedConnection)
    connect(m_waiter_thread.get(), &FrameWaiterThread::frameAvailable,
            this, &PlaceboVideoItem::onFrameAvailable,
            Qt::QueuedConnection);

    m_waiter_thread->start();
}

PlaceboVideoItem::~PlaceboVideoItem()
{
    qDebug() << "PlaceboVideoItem: destructor";

    // Stop waiter thread first
    if (m_waiter_thread) {
        m_waiter_thread->stop();
        m_waiter_thread.reset();
    }

    // Return current frame to decoder if we have one
    if (m_has_current_frame && m_frame_queue) {
        m_frame_queue->return_buffer(m_current_frame);
        m_has_current_frame = false;
    }

    // Stop and destroy the pipeline
    if (m_pipeline) {
        m_pipeline->stop();
        m_pipeline.reset();
    }
}

void PlaceboVideoItem::handleWindowChanged(QQuickWindow *win)
{
    qDebug() << "PlaceboVideoItem::handleWindowChanged" << win;

    if (win) {
        connect(win, &QQuickWindow::beforeSynchronizing,
                this, &PlaceboVideoItem::sync,
                Qt::DirectConnection);
    }
}

void PlaceboVideoItem::sync()
{
    if (!m_renderer) {
        qDebug() << "PlaceboVideoItem::sync - creating renderer";

        // Verify Qt is using OpenGL backend (not Vulkan/Metal/D3D)
        QSGRendererInterface *rif = window()->rendererInterface();
        Q_ASSERT(rif && "Renderer interface must be available");
        QSGRendererInterface::GraphicsApi api = rif->graphicsApi();
        Q_ASSERT((api == QSGRendererInterface::OpenGL ||
                  api == QSGRendererInterface::OpenGLRhi) &&
                 "PlaceboVideoItem requires OpenGL backend");
        if (api != QSGRendererInterface::OpenGL &&
            api != QSGRendererInterface::OpenGLRhi) {
            qCritical() << "PlaceboVideoItem: Qt is not using OpenGL backend, api =" << api;
            return;
        }
        qDebug() << "PlaceboVideoItem: Qt Graphics API:" << api;

        m_renderer = std::make_unique<PlaceboRenderer>();

        // Connect render signals
        connect(window(), &QQuickWindow::beforeRendering,
                this, &PlaceboVideoItem::onBeforeRendering,
                Qt::DirectConnection);
        connect(window(), &QQuickWindow::beforeRenderPassRecording,
                this, &PlaceboVideoItem::onBeforeRenderPassRecording,
                Qt::DirectConnection);
    }

    m_viewportSize = window()->size() * window()->devicePixelRatio();
}

void PlaceboVideoItem::onBeforeRendering()
{
    if (!m_renderer) return;

    // Initialize renderer if not done yet
    if (!m_initialized) {
        QQuickWindow *win = window();
        if (!win) return;

        // CRITICAL: beginExternalCommands() makes the OpenGL context current
        // This is required for Qt6 RHI - without it, eglGetCurrentContext() returns EGL_NO_CONTEXT
        win->beginExternalCommands();

        // Get the OpenGL context and surface for libplacebo callbacks
        QOpenGLContext* ctx = QOpenGLContext::currentContext();
        QSurface* surface = ctx ? ctx->surface() : nullptr;

        bool success = false;
        if (ctx && surface) {
            success = m_renderer->init_gl(ctx, surface);
        } else {
            qCritical() << "PlaceboVideoItem: no OpenGL context or surface available";
        }

        win->endExternalCommands();

        if (success) {
            m_initialized = true;
            qInfo() << "PlaceboVideoItem: renderer initialized";
        } else {
            qCritical() << "PlaceboVideoItem: failed to initialize renderer";
            return;
        }
    }
}

void PlaceboVideoItem::onBeforeRenderPassRecording()
{
    if (!m_renderer || !m_initialized) return;

    QQuickWindow *win = window();
    if (!win) return;

    win->beginExternalCommands();

    int rotation = getScreenRotation();
    int width = m_viewportSize.width();
    int height = m_viewportSize.height();

    // Pop all available frames from queue
    auto frames = m_frame_queue->pop_all();

    if (!frames.empty()) {
        // "Last frame wins" - return all but the last to decoder
        for (size_t i = 0; i < frames.size() - 1; i++) {
            m_frame_queue->return_buffer(frames[i]);
        }

        // Get the newest frame
        PlaceboFrame new_frame = frames.back();

        // Return old current frame if we had one
        if (m_has_current_frame) {
            m_frame_queue->return_buffer(m_current_frame);
        }

        // New frame becomes current
        m_current_frame = new_frame;
        m_has_current_frame = true;
    }

    // Render current frame (or clear to black if none)
    if (m_has_current_frame && m_current_frame.is_valid()) {
        m_renderer->render_frame(m_current_frame, width, height, rotation);
    } else {
        m_renderer->clear_to_black();
    }

    win->endExternalCommands();
}

void PlaceboVideoItem::onFrameAvailable()
{
    // New frame arrived - trigger immediate repaint
    // This runs in the GUI thread due to Qt::QueuedConnection
    if (window()) {
        window()->update();
    }
}

void PlaceboVideoItem::releaseResources()
{
    qDebug() << "PlaceboVideoItem::releaseResources";

    // Return current frame to decoder
    if (m_has_current_frame && m_frame_queue) {
        m_frame_queue->return_buffer(m_current_frame);
        m_has_current_frame = false;
    }

    if (m_renderer && m_initialized) {
        m_renderer->cleanup();
        m_initialized = false;
    }
}

void PlaceboVideoItem::returnFrameToDecoder(PlaceboFrame& frame)
{
    if (frame.is_valid() && m_frame_queue) {
        m_frame_queue->return_buffer(frame);
    }
}

int PlaceboVideoItem::getScreenRotation() const
{
    return QOpenHDVideoHelper::get_display_rotation();
}

#endif // ENABLE_V4L2_GL_PLAYER
