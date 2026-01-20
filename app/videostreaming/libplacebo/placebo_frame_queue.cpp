// SPDX-License-Identifier: MIT
// Copyright (C) 2024 OpenHD

#ifdef ENABLE_V4L2_GL_PLAYER

#include "placebo_frame_queue.h"

#include <QDebug>


PlaceboFrameQueue::PlaceboFrameQueue()
{
    qDebug() << "PlaceboFrameQueue: created";
}

PlaceboFrameQueue::~PlaceboFrameQueue()
{
    stop();
    qDebug() << "PlaceboFrameQueue: destroyed";
}

// ==================== from_decoder queue ====================

void PlaceboFrameQueue::push(PlaceboFrame frame)
{
    {
        std::lock_guard<std::mutex> lock(m_from_mutex);
        m_from_decoder.push_back(frame);
        m_frames_decoded++;
    }
    m_from_cv.notify_one();
}

bool PlaceboFrameQueue::try_pop(PlaceboFrame& frame)
{
    std::lock_guard<std::mutex> lock(m_from_mutex);

    if (m_from_decoder.empty()) {
        return false;
    }

    frame = m_from_decoder.front();
    m_from_decoder.pop_front();
    m_frames_rendered++;
    return true;
}

std::vector<PlaceboFrame> PlaceboFrameQueue::pop_all()
{
    std::lock_guard<std::mutex> lock(m_from_mutex);

    std::vector<PlaceboFrame> result(m_from_decoder.begin(), m_from_decoder.end());
    m_frames_rendered += m_from_decoder.size();
    m_from_decoder.clear();
    return result;
}

bool PlaceboFrameQueue::wait_frame()
{
    std::unique_lock<std::mutex> lock(m_from_mutex);

    m_from_cv.wait(lock, [this]() {
        return !m_from_decoder.empty() || m_stopped.load();
    });

    return !m_stopped.load() && !m_from_decoder.empty();
}

size_t PlaceboFrameQueue::from_decoder_size() const
{
    std::lock_guard<std::mutex> lock(m_from_mutex);
    return m_from_decoder.size();
}

// ==================== to_decoder queue ====================

void PlaceboFrameQueue::return_buffer(PlaceboFrame frame)
{
    std::lock_guard<std::mutex> lock(m_to_mutex);
    m_to_decoder.push_back(frame);
    m_frames_returned++;
}

bool PlaceboFrameQueue::try_pop_returned(PlaceboFrame& frame)
{
    std::lock_guard<std::mutex> lock(m_to_mutex);

    if (m_to_decoder.empty()) {
        return false;
    }

    frame = m_to_decoder.front();
    m_to_decoder.pop_front();
    m_frames_recycled++;
    return true;
}

size_t PlaceboFrameQueue::to_decoder_size() const
{
    std::lock_guard<std::mutex> lock(m_to_mutex);
    return m_to_decoder.size();
}

// ==================== Control ====================

void PlaceboFrameQueue::stop()
{
    m_stopped.store(true);
    m_from_cv.notify_all();
}

bool PlaceboFrameQueue::is_stopped() const
{
    return m_stopped.load();
}

void PlaceboFrameQueue::reset()
{
    m_stopped.store(false);

    // Clear queues
    {
        std::lock_guard<std::mutex> lock(m_from_mutex);
        m_from_decoder.clear();
    }
    {
        std::lock_guard<std::mutex> lock(m_to_mutex);
        m_to_decoder.clear();
    }
}

// ==================== Statistics ====================

PlaceboFrameQueue::Stats PlaceboFrameQueue::get_stats() const
{
    return Stats{
        m_frames_decoded.load(),
        m_frames_rendered.load(),
        m_frames_returned.load(),
        m_frames_recycled.load()
    };
}

void PlaceboFrameQueue::reset_stats()
{
    m_frames_decoded = 0;
    m_frames_rendered = 0;
    m_frames_returned = 0;
    m_frames_recycled = 0;
}

#endif // ENABLE_V4L2_GL_PLAYER
