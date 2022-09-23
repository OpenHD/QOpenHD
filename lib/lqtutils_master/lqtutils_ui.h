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

#ifndef LQTUTILS_UI_H
#define LQTUTILS_UI_H

#include <QObject>
#include <QDateTime>
#include <QList>
#include <QJSValue>

#include "lqtutils_prop.h"
#include "lqtutils_freq.h"

class QQuickWindow;

class LQTFrameRateMonitor : public LQTFreqMeter
{
    Q_OBJECT
public:
    LQTFrameRateMonitor(QQuickWindow* w = nullptr, QObject* parent = nullptr);
    Q_INVOKABLE void setWindow(QQuickWindow* w);
};

class LQTQmlUtils : public QObject
{
    Q_OBJECT
public:
    LQTQmlUtils(QObject* parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE void singleShot(int msec, QJSValue callback);
};

#endif // LQTUTILS_UI_H
