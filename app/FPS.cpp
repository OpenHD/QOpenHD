/****************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the Qt Mobility Components.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

#include "FPS.h"
#include <QDebug>
#include <QElapsedTimer>
#include <QString>
#include <QTime>
#include <QTimer>

//#define VERBOSE_TRACE

inline QDebug qtTrace() { return qDebug() << "[frequencymonitor]"; }
#ifdef VERBOSE_TRACE
inline QDebug qtVerboseTrace() { return qtTrace(); }
#else
inline QNoDebug qtVerboseTrace() { return QNoDebug(); }
#endif

static const int DefaultSamplingInterval = 100;
static const int DefaultTraceInterval = 0;



void FrequencyMonitor::calculateInstantaneousFrequency()
{
    const qint64 ms = m_instantaneousElapsed.restart();
    m_instantaneousFrequency = ms ? qreal(1000) / ms : 0;
    m_stalledTimer->start(3 * ms);
    if (m_instantaneousFrequency) {
        setActive(true);
    }
    emit instantaneousFrequencyChanged(m_instantaneousFrequency);
    emit frequencyChanged();
}

void FrequencyMonitor::calculateAverageFrequency()
{
    const qint64 ms = m_averageElapsed.restart();
    m_averageFrequency = qreal(m_count * 1000) / ms;
    emit averageFrequencyChanged(m_averageFrequency);
    emit frequencyChanged();
    m_count = 0;
}

void FrequencyMonitor::stalled()
{
    if (m_instantaneousFrequency) {
        m_instantaneousFrequency = 0;
        emit instantaneousFrequencyChanged(m_instantaneousFrequency);
        emit frequencyChanged();
    }
}

FrequencyMonitor::FrequencyMonitor(QObject *parent)
:   QObject(parent)
,   m_active(false)
,   m_instantaneousFrequency(0)
,   m_averageTimer(new QTimer(this))
,   m_count(0)
,   m_averageFrequency(0)
,   m_traceTimer(new QTimer(this))
,   m_stalledTimer(new QTimer(this))
{
    m_instantaneousElapsed.start();
    connect(m_averageTimer, &QTimer::timeout,
            this, &FrequencyMonitor::calculateAverageFrequency);
    if (DefaultSamplingInterval)
        m_averageTimer->start(DefaultSamplingInterval);
    m_averageElapsed.start();
    connect(m_traceTimer, &QTimer::timeout, this, &FrequencyMonitor::trace);
    if (DefaultTraceInterval)
        m_traceTimer->start(DefaultTraceInterval);
    m_stalledTimer->setSingleShot(true);
    connect(m_stalledTimer, &QTimer::timeout,
            this, &FrequencyMonitor::stalled);
}

FrequencyMonitor::~FrequencyMonitor()
{

}

QString FrequencyMonitor::label() const
{
    return m_label;
}

bool FrequencyMonitor::active() const
{
    return m_active;
}

int FrequencyMonitor::samplingInterval() const
{
    return m_averageTimer->isActive() ? m_averageTimer->interval() : 0;
}

int FrequencyMonitor::traceInterval() const
{
    return m_traceTimer->isActive() ? m_traceTimer->interval() : 0;
}

qreal FrequencyMonitor::instantaneousFrequency() const
{
    return m_instantaneousFrequency;
}

qreal FrequencyMonitor::averageFrequency() const
{
    return m_averageFrequency;
}

void FrequencyMonitor::notify()
{
    Q_D(FrequencyMonitor);
    ++(m_count);
    calculateInstantaneousFrequency();
}

void FrequencyMonitor::trace()
{
    Q_D(FrequencyMonitor);
    const QString value = QString::fromLatin1("instant %1 average %2")
                            .arg(m_instantaneousFrequency, 0, 'f', 2)
                            .arg(m_averageFrequency, 0, 'f', 2);
    if (m_label.isEmpty())
        qtTrace() << "FrequencyMonitor::trace" << value;
    else
        qtTrace() << "FrequencyMonitor::trace" << "label" << m_label << value;
}

void FrequencyMonitor::setLabel(const QString &value)
{
    Q_D(FrequencyMonitor);
    if (m_label != value) {
        m_label = value;
        emit labelChanged(m_label);
    }
}

void FrequencyMonitor::setActive(bool value)
{
    Q_D(FrequencyMonitor);
    if (m_active != value) {
        m_active = value;
        emit activeChanged(m_active);
    }
}

void FrequencyMonitor::setSamplingInterval(int value)
{
    Q_D(FrequencyMonitor);
    if (samplingInterval() != value) {
        if (value) {
            m_averageTimer->setInterval(value);
            m_averageTimer->start();
        } else {
            m_averageTimer->stop();
        }
        emit samplingIntervalChanged(value);
    }
}

void FrequencyMonitor::setTraceInterval(int value)
{
    Q_D(FrequencyMonitor);
    if (traceInterval() != value) {
        if (value) {
            m_traceTimer->setInterval(value);
            m_traceTimer->start();
        } else {
            m_traceTimer->stop();
        }
        emit traceIntervalChanged(value);
    }
}
