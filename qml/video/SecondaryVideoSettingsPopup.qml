import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../ui/configpopup"
import "../ui/configpopup/MenuTypography.js" as MenuTypography

AdvancedDialog {
    id: popup
    objectName: "secondaryVideoSettingsPopup"
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(480, parent.width - 24)
    height: Math.min(implicitHeight, parent.height - 24)
    title: qsTr("Secondary Video")
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    standardButtons: Dialog.NoButton

    contentItem: Flickable {
        implicitHeight: controls.implicitHeight
        contentWidth: width; contentHeight: controls.implicitHeight
        clip: true; boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        Column {
            id: controls
            width: parent.width; spacing: 0
            Repeater {
                model: [
                    {key: "secondary_video_minimized_width", label: qsTr("Minimized width"), unit: "px", minimum: 25, maximum: 500},
                    {key: "secondary_video_minimized_height", label: qsTr("Minimized height"), unit: "px", minimum: 25, maximum: 500},
                    {key: "secondary_video_maximize_factor_perc", label: qsTr("Maximize factor"), unit: "%", minimum: 120, maximum: 800}
                ]
                delegate: Item {
                    id: settingRow
                    property var entry: modelData
                    width: controls.width; height: 64
                    Rectangle { visible: index > 0; width: parent.width; height: 1; color: "#123b50" }
                    RowLayout {
                        anchors.fill: parent; spacing: 12
                        Text {
                            Layout.fillWidth: true; wrapMode: Text.WordWrap
                            text: settingRow.entry.label
                            color: "#edf4fa"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.body
                        }
                        SpinBox {
                            id: editor
                            objectName: "secondaryVideoSetting" + index
                            Layout.preferredWidth: 140; Layout.preferredHeight: 40
                            from: settingRow.entry.minimum; to: settingRow.entry.maximum
                            stepSize: 1; editable: true
                            font.family: MenuTypography.family; font.pixelSize: MenuTypography.body
                            value: settings[settingRow.entry.key]
                            onValueModified: settings[settingRow.entry.key] = value
                            Accessible.name: settingRow.entry.label
                            leftPadding: 34; rightPadding: 34
                            contentItem: TextInput {
                                text: editor.textFromValue(editor.value, editor.locale)
                                font: editor.font; color: "#edf4fa"; selectionColor: "#147fc1"; selectedTextColor: "white"
                                horizontalAlignment: TextInput.AlignHCenter; verticalAlignment: TextInput.AlignVCenter
                                readOnly: !editor.editable; validator: editor.validator
                                inputMethodHints: Qt.ImhDigitsOnly
                            }
                            background: Rectangle { radius: 9; color: "#06283a"; border.color: editor.activeFocus ? "#38b9ff" : "#006997"; border.width: editor.activeFocus ? 2 : 1 }
                            up.indicator: Rectangle {
                                x: editor.width - width; width: 32; height: editor.height; radius: 8
                                color: editor.up.pressed ? "#145777" : "#0a354c"
                                Text { anchors.centerIn: parent; text: "+"; color: editor.up.enabled ? "#edf4fa" : "#6e8da1"; font.pixelSize: 20 }
                            }
                            down.indicator: Rectangle {
                                width: 32; height: editor.height; radius: 8
                                color: editor.down.pressed ? "#145777" : "#0a354c"
                                Text { anchors.centerIn: parent; text: "-"; color: editor.down.enabled ? "#edf4fa" : "#6e8da1"; font.pixelSize: 20 }
                            }
                        }
                        Text { Layout.preferredWidth: 20; text: settingRow.entry.unit; color: "#a9c2d3"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.helper }
                    }
                }
            }
        }
    }
}
