// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#ifdef ENABLE_V4L2_GL_PLAYER

#include "placebo_video_item.h"
#include "v4l2_pipeline.h"
#include "../vscommon/QOpenHDVideoHelper.hpp"

#include <QDebug>
#include <QtQuick/qquickwindow.h>
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

    // Initialize and start the pipeline
    auto& pipeline = V4L2Pipeline::instance();
    if (!pipeline.is_running()) {
        qInfo() << "PlaceboVideoItem: initializing V4L2Pipeline";
        if (!pipeline.init_from_settings()) {
            qWarning() << "PlaceboVideoItem: failed to init V4L2Pipeline";
        } else if (!pipeline.start()) {
            qWarning() << "PlaceboVideoItem: failed to start V4L2Pipeline";
        }
    }

    // Get frame queue from pipeline
    m_frame_queue = &pipeline.get_frame_queue();

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

    // Stop waiter thread
    if (m_waiter_thread) {
        m_waiter_thread->stop();
        m_waiter_thread.reset();
    }

    // Return current frame to decoder if we have one
    if (m_has_current_frame && m_frame_queue) {
        m_frame_queue->return_buffer(m_current_frame);
        m_has_current_frame = false;
    }

    // Stop the pipeline (will be restarted if a new PlaceboVideoItem is created)
    V4L2Pipeline::instance().stop();
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
        if (m_renderer->init_gl()) {
            m_initialized = true;
            qInfo() << "PlaceboVideoItem: renderer initialized";
        } else {
            qWarning() << "PlaceboVideoItem: failed to initialize renderer";
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
