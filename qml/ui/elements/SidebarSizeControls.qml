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
