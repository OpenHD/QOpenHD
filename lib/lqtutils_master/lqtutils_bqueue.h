/**
 * MIT License
 *
 * Copyright (c) 2021 Luca Carlon
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 **/

#ifndef LQTUTILS_BQUEUE
#define LQTUTILS_BQUEUE

#include <QString>
#include <QMutex>
#include <QWaitCondition>
#include <QList>

#include <optional>

template<typename T>
class LQTBlockingQueue
{
public:
    LQTBlockingQueue(int capacity, const QString& name = QString()) :
        m_capacity(capacity), m_disposed(false), m_name(name) {}
    bool enqueue(const T& e, qint64 timeout = -1);
    bool enqueueDropFirst(const T& e, qint64 timeout = -1);
    std::optional<T> waitFirst(bool remove, qint64 timeout = -1);
    std::optional<T> dequeue(qint64 timeout = -1);
    std::optional<T> peek(qint64 timeout = -1);
    int size() const;
    int capacity() const { return m_capacity; }
    bool isEmpty() const;
    bool isDisposed() const;
    void requestDispose();
    void lockQueue(std::function<void(QList<T>* queue)> callback);
    QString name() { return m_name; }

private:
    int m_capacity;
    bool m_disposed;
    QString m_name;
    mutable QMutex m_mutex;
    QWaitCondition m_condFull;
    QWaitCondition m_condEmpty;
    QList<T> m_queue;
};

template<typename T>
bool LQTBlockingQueue<T>::enqueue(const T& e, qint64 timeout)
{
    QMutexLocker locker(&m_mutex);
    if (m_disposed)
        return false;
    if (m_queue.size() >= m_capacity) {
        if (!m_condFull.wait(&m_mutex, timeout))
            return false;
        if (m_disposed)
            return false;
    }

    m_queue.append(e);
    m_condEmpty.wakeOne();

    return true;
}

template<typename T>
bool LQTBlockingQueue<T>::enqueueDropFirst(const T& e, qint64 timeout)
{
    QMutexLocker locker(&m_mutex);
    if (m_disposed)
        return false;
    if (m_queue.size() >= m_capacity) {
        if (!m_condFull.wait(&m_mutex, timeout))
            if (!m_queue.isEmpty())
                m_queue.takeFirst();
        if (m_disposed)
            return false;
    }

    m_queue.append(e);
    m_condEmpty.wakeOne();

    return true;
}

template<typename T>
std::optional<T> LQTBlockingQueue<T>::waitFirst(bool remove, qint64 timeout)
{
    QMutexLocker locker(&m_mutex);
    if (m_disposed)
        return std::nullopt;
    if (m_queue.isEmpty()) {
        if (!timeout)
            return std::nullopt;
        if (!m_condEmpty.wait(&m_mutex, timeout))
            return std::nullopt;
        if (m_disposed)
            return std::nullopt;
    }

    std::optional<T> ret = remove ? m_queue.takeFirst() : m_queue.first();
    if (remove)
        m_condFull.wakeOne();
    return ret;
}

template<typename T>
std::optional<T> LQTBlockingQueue<T>::dequeue(qint64 timeout)
{
    return waitFirst(true, timeout);
}

template<typename T>
std::optional<T> LQTBlockingQueue<T>::peek(qint64 timeout)
{
    return waitFirst(false, timeout);
}

template<typename T>
int LQTBlockingQueue<T>::size() const
{
    QMutexLocker locker(&m_mutex);
    return m_queue.size();
}

template<typename T>
bool LQTBlockingQueue<T>::isEmpty() const
{
    QMutexLocker locker(&m_mutex);
    return m_queue.isEmpty();
}

template<typename T>
bool LQTBlockingQueue<T>::isDisposed() const
{
    QMutexLocker locker(&m_mutex);
    return m_disposed;
}

template<typename T>
void LQTBlockingQueue<T>::requestDispose()
{
    QMutexLocker locker(&m_mutex);
    m_disposed = true;
    m_condFull.wakeAll();
    m_condEmpty.wakeAll();
}

template<typename T>
void LQTBlockingQueue<T>::lockQueue(std::function<void(QList<T>*)> callback)
{
    QMutexLocker locker(&m_mutex);
    callback(&m_queue);
}

#endif // LQTUTILS_BQUEUE
