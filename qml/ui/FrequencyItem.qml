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

import QtQuick 2.0
import FrequencyMonitor 1.0

Item {
    id: root
    property bool logging: true
    property bool displayed: true
    property bool enabled: logging || displayed
    property alias active: monitor.active
    property int samplingInterval: 500
    property color textColor: "white"
    property int textSize: 14
    property alias label: monitor.label

    visible: displayed && active

    // This should ensure that the monitor is on top of all other content
    z: 999

    function notify() {
        monitor.notify()
    }

    FrequencyMonitor {
        id: monitor
        samplingInterval: root.enabled ? root.samplingInterval : 0
        onAverageFrequencyChanged: {
            if (root.logging) trace()
            averageFrequencyText.text = monitor.averageFrequency.toFixed(2) + "fps"
        }
    }

    Text {
            id: fps_icon
            y: 0
            width: 24
            height: 24
            color: "#ffffff"
            text: "\uf3fd"
            anchors.top: parent.top
            anchors.topMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0
            font.family: "Font Awesome 5 Free"
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            styleColor: "#f7f7f7"
            font.pixelSize: 14
        }

    Text {
        height: 24
        id: averageFrequencyText
        anchors.top: parent.top
        anchors.left: fps_icon.right
        anchors.leftMargin: 6
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        color: root.textColor
        font.pixelSize: root.textSize
    }
}
