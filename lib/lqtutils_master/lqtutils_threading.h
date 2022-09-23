/**
 * MIT License
 *
 * Copyright (c) 2020 Luca Carlon
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

#ifndef LQTUTILS_THREADING_H
#define LQTUTILS_THREADING_H

#include <QMutex>
#include <QMetaObject>
#include <QThread>
#include <QTimer>
#include <QEventLoop>
#include <QSemaphore>
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
#include <QRecursiveMutex>
#endif
#include <functional>

#define INVOKE_AWAIT_ASYNC(obj, ...) {                                                                               \
        auto type = QThread::currentThread() == obj->thread() ? Qt::DirectConnection : Qt::BlockingQueuedConnection; \
        QMetaObject::invokeMethod(obj, __VA_ARGS__, type);                                                           \
    }

template<typename T> T lqt_run_in_thread_sync(QObject* o, std::function<T()> f)
{
    QSemaphore sem;
    T ret;
    QTimer::singleShot(0, o, [&f, &ret, &sem] {
        ret = f();
        sem.release();
    });
    sem.acquire();
    return ret;
}

template<typename T> T lqt_run_in_thread_sync(QThread* t, std::function<T()> f)
{
    QSemaphore sem;
    T ret;
    QObject* o = new QObject;
    o->moveToThread(t);
    QTimer::singleShot(0, o, [&f, o, &ret, &sem] {
        ret = f();
        o->deleteLater();
        sem.release();
    });
    sem.acquire();
    return ret;
}

inline void lqt_run_in_thread_sync(QThread* t, std::function<void()> f)
{
    QSemaphore sem;
    QObject* o = new QObject;
    o->moveToThread(t);
    QTimer::singleShot(0, o, [&f, o, &sem] {
        f();
        o->deleteLater();
        sem.release();
    });
    sem.acquire();
}

inline void lqt_run_in_thread_sync(QObject* o, std::function<void()> f)
{
    QSemaphore sem;
    QTimer::singleShot(0, o, [&f, &sem] {
        f();
        sem.release();
    });
    sem.acquire();
}

inline void lqt_run_in_thread(QThread* t, std::function<void()> f)
{
    QObject* o = new QObject;
    o->moveToThread(t);
    QTimer::singleShot(0, o, [f, o] {
        f();
        o->deleteLater();
    });
}

#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
class LQTRecursiveMutex : public QMutex
{
public:
    LQTRecursiveMutex() :
        QMutex(QMutex::Recursive) {}
};
#else
typedef QRecursiveMutex LQTRecursiveMutex;
#endif

#endif // LQTUTILS_THREADING_H
