// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#ifndef PLACEBO_VIDEO_ITEM_H
#define PLACEBO_VIDEO_ITEM_H

#ifdef ENABLE_V4L2_GL_PLAYER

#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickWindow>
#include <QSize>
#include <QThread>
#include <memory>
#include <atomic>

#include "placebo_renderer.h"
#include "placebo_frame_queue.h"

class V4L2Pipeline;

/**
 * @brief Waiter thread that blocks on frame queue and signals Qt.
 *
 * This thread waits for frames from the decoder using a blocking call,
 * then emits a signal to trigger rendering in the Qt GUI thread.
 * This provides low-latency notification without busy-polling.
 */
class FrameWaiterThread : public QThread
{
    Q_OBJECT

public:
    explicit FrameWaiterThread(PlaceboFrameQueue* queue, QObject* parent = nullptr);
    ~FrameWaiterThread() override;

    void stop();

signals:
    void frameAvailable();

protected:
    void run() override;

private:
    PlaceboFrameQueue* m_queue;
    std::atomic<bool> m_running{true};
};


/**
 * @brief QML Item that renders video frames using libplacebo.
 *
 * This QQuickItem hooks into the Qt render thread via beforeRendering signal
 * and uses libplacebo to render video frames from DMA-BUF file descriptors
 * as an underlay (beneath all QML elements).
 *
 * Architecture:
 * - Decoder thread: pushes frames to queue.from_decoder
 * - Waiter thread: blocks on queue, emits signal to trigger render
 * - Qt render thread: pops all frames, renders last, returns others to queue.to_decoder
 *
 * Features:
 * - "Last frame wins" rendering: keeps only most recent frame
 * - Immediate render trigger when new frame arrives
 * - Re-renders current frame if no new frames available
 * - Support for screen rotation
 *
 * Note: This item renders directly to the window backbuffer, so its
 * QML size/position properties do not affect the video rendering area.
 * Video is always rendered fullscreen as an underlay.
 *
 * Usage in QML:
 *   import OpenHD 1.0
 *   PlaceboVideoItem {
 *       anchors.fill: parent
 *   }
 */
class PlaceboVideoItem : public QQuickItem
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit PlaceboVideoItem(QQuickItem *parent = nullptr);
    ~PlaceboVideoItem() override;

signals:
    /**
     * @brief Internal signal for cross-thread frame notification
     */
    void frameReadyForRender();

public slots:
    /**
     * @brief Called when QQuickWindow changes
     */
    void handleWindowChanged(QQuickWindow *win);

    /**
     * @brief Synchronize with scene graph (called before rendering)
     */
    void sync();

private slots:
    /**
     * @brief Called before Qt scene graph renders
     */
    void onBeforeRendering();

    /**
     * @brief Called before render pass recording
     */
    void onBeforeRenderPassRecording();

    /**
     * @brief Called when waiter thread signals a new frame
     */
    void onFrameAvailable();

private:
    void releaseResources() override;

    // Get current screen rotation from settings
    int getScreenRotation() const;

    // Return frame to decoder (if valid)
    void returnFrameToDecoder(PlaceboFrame& frame);

private:
    std::unique_ptr<PlaceboRenderer> m_renderer;
    PlaceboFrameQueue* m_frame_queue = nullptr;  // Owned by V4L2Pipeline

    std::unique_ptr<FrameWaiterThread> m_waiter_thread;

    QSize m_viewportSize;
    bool m_initialized = false;

    // Currently displayed frame (held until replaced by new frame)
    PlaceboFrame m_current_frame;
    bool m_has_current_frame = false;
};

#endif // ENABLE_V4L2_GL_PLAYER

#endif // PLACEBO_VIDEO_ITEM_H
