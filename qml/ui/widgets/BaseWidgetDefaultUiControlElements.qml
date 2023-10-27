import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

// Can be used to quickly add the right UI elements for (persistently) setting scale and opacity for a HUD element (e.g. an element extending BaseWidget)
// By default, placed in one of the popups, and more values can be added manually if needed
// NOTE: Element needs to already extend base widget (we call methods and use variables from BaseWidget, the lazy evaluation of QML is fine with such an approach)
// If you are wondering how to use this file, just look into one of the widgets already using it as an example, it should be self-explanatory when creating new widgets
ColumnLayout{
    width: 270
    spacing: 0
    clip: false

    // Set these to true if the settings "horizontal / vertical lock" should be shown
    // (aka it makes sense that the user wishes to place this widget vertically / horizontally in the center)
    property bool show_vertical_lock: false
    property bool show_horizontal_lock: false
    property bool show_transparency: true

    Item {
        width: parent.width
        height: 42
        Text {
            id: settings_title
            text: qsTr(bw_verbose_name)
            color: "white"
            height: parent.height - 10
            width: parent.width
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: detailPanelFontPixels
            verticalAlignment: Text.AlignVCenter
        }
        Rectangle {
            id: settings_title_underline
            y: 34
            width: parent.width
            height: 3
            color: "white"
            radius: 5
        }
    }
    Item {
        width: parent.width
        height: 32
        visible: show_transparency
        Text {
            id: opacityTitle
            text: qsTr("Transparency")
            color: "white"
            height: parent.height
            font.bold: true
            font.pixelSize: detailPanelFontPixels
            anchors.left: parent.left
            verticalAlignment: Text.AlignVCenter
        }
        Slider {
            id: transparency_slider
            orientation: Qt.Horizontal
            from: .1
            value: bw_current_opacity
            to: 1
            stepSize: .1
            height: parent.height
            anchors.rightMargin: 0
            anchors.right: parent.right
            width: parent.width - 96

            onValueChanged: {
                bw_set_current_opacity(transparency_slider.value);
            }
        }
    }

    Item {
        width: parent.width
        height: 32
        Text {
            text: qsTr("Size: x"+bw_current_scale.toFixed(1))
            color: "white"
            height: parent.height
            font.bold: true
            font.pixelSize: detailPanelFontPixels
            anchors.left: parent.left
            verticalAlignment: Text.AlignVCenter
        }
        Slider {
            id: item_scale_Slider
            orientation: Qt.Horizontal
            from: .5
            value: bw_current_scale
            to: 3
            stepSize: .1
            height: parent.height
            anchors.rightMargin: 0
            anchors.right: parent.right
            width: parent.width - 96

            onValueChanged: {
                bw_set_current_scale(item_scale_Slider.value)
            }
        }
    }

    Item {
        width: 230
        height: 32
        visible: show_horizontal_lock
        Text {
            text: qsTr("Lock to Horizontal Center")
            color: "white"
            height: parent.height
            font.bold: true
            font.pixelSize: detailPanelFontPixels
            anchors.left: parent.left
            verticalAlignment: Text.AlignVCenter
        }
        Switch {
            width: 32
            height: parent.height
            anchors.rightMargin: 6
            anchors.right: parent.right
            checked: {
                // @disable-check M222
                var _hCenter = settings.value(hCenterIdentifier,
                                              defaultHCenter)
                // @disable-check M223
                if (_hCenter === "true" || _hCenter === 1
                        || _hCenter === true) {
                    checked = true
                    // @disable-check M223
                } else {
                    checked = false
                }
            }

            onCheckedChanged: settings.setValue(hCenterIdentifier,
                                                checked)
        }
    }
    Item {
        width: 230
        height: 32
        visible: show_vertical_lock
        Text {
            text: qsTr("Lock to Vertical Center")
            color: "white"
            height: parent.height
            font.bold: true
            font.pixelSize: detailPanelFontPixels
            anchors.left: parent.left
            verticalAlignment: Text.AlignVCenter
        }
        Switch {
            width: 32
            height: parent.height
            anchors.rightMargin: 6
            anchors.right: parent.right
            checked: {
                // @disable-check M222
                var _vCenter = settings.value(vCenterIdentifier,
                                              defaultVCenter)
                // @disable-check M223
                if (_vCenter === "true" || _vCenter === 1
                        || _vCenter === true) {
                    checked = true
                    // @disable-check M223
                } else {
                    checked = false
                }
            }

            onCheckedChanged: settings.setValue(vCenterIdentifier,
                                                checked)
        }
    }

}
