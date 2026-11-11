/******************************************************************************
 * OpenHD
 *
 * Licensed under the GNU General Public License (GPL) Version 3.
 *
 * This software is provided "as-is," without warranty of any kind, express or
 * implied, including but not limited to the warranties of merchantability,
 * fitness for a particular purpose, and non-infringement. For details, see the
 * full license in the LICENSE file provided with this source code.
 *
 * Non-Military Use Only:
 * This software and its associated components are explicitly intended for
 * civilian and non-military purposes. Use in any military or defense
 * applications is strictly prohibited unless explicitly and individually
 * licensed otherwise by the OpenHD Team.
 *
 * Contributors:
 * A full list of contributors can be found at the OpenHD GitHub repository:
 * https://github.com/OpenHD
 *
 * © OpenHD, All Rights Reserved.
 ******************************************************************************/

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../configpopup/MenuTypography.js" as Typography

ColumnLayout {
    id: root
    spacing: 2

    property color labelColor: "#f2f6fb"
    property color valueColor: "#aebdcb"

    Repeater {
        model: [
            { key: "sidebar_popup_scale", label: qsTr("Sidebar popup size"), min: 0.5, max: 3 },
            { key: "sidebar_show_icon_scale", label: qsTr("Sidebar button size"), min: 0.7, max: 2.5 }
        ]

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Label {
                    Layout.fillWidth: true
                    text: modelData.label
                    color: root.labelColor
                    font.family: Typography.family
                    font.pixelSize: Typography.body
                    wrapMode: Text.WordWrap
                }
                Label {
                    text: qsTr("%1%").arg(Math.round(sizeSlider.value * 100))
                    color: root.valueColor
                    font.family: Typography.family
                    font.pixelSize: Typography.body
                }
            }
            Slider {
                id: sizeSlider
                objectName: modelData.key
                Layout.fillWidth: true
                Accessible.name: modelData.label
                from: modelData.min
                to: modelData.max
                stepSize: 0.1
                value: settings[modelData.key]
                onMoved: settings[modelData.key] = value
            }
        }
    }
}
