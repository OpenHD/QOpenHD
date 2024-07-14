import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

ScrollView {
    id: appGeneralSettingsView
    width: parent.width
    height: parent.height
    contentHeight: generalColumn.height

    clip: true

    Item {
        anchors.fill: parent

        Column {
            id: generalColumn
            spacing: 0
            anchors.left: parent.left
            anchors.right: parent.right

            SettingBaseElement{
                m_short_description: "Enable text to speech"

                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.enable_speech
                    onCheckedChanged: settings.enable_speech = checked
                }
            }

            SettingBaseElement{
                m_short_description: "Use Imperial units"

                Switch {
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.enable_imperial
                    onCheckedChanged: settings.enable_imperial = checked
                }
            }

            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("Animation Smoothing")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }

                Text {
                    text: Number(settings.smoothing).toLocaleString(Qt.locale(), 'f', 0) + "ms";
                    font.pixelSize: 16
                    anchors.right: smoothing_Slider.left
                    anchors.rightMargin: 12
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: elementHeight

                }

                Slider {
                    id: smoothing_Slider
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    to : 1000
                    from : 0
                    stepSize: 25
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                    value: settings.smoothing

                    // @disable-check M223
                    onValueChanged: {
                        // @disable-check M222
                        settings.smoothing = smoothing_Slider.value
                    }
                }
            }

            SettingBaseElement{
                m_short_description: "Ground Battery Cells"

                SpinBox {
                    id: gndBatteryCellspinBox
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    from: 1
                    to: 6
                    stepSize: 1
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                    value: settings.ground_battery_cells
                    onValueChanged: settings.ground_battery_cells = value
                }
            }

            SettingBaseElement{
                m_short_description: "Language"

                LanguageSelect {
                    id: languageSelectBox
                    height: elementHeight
                    width: 210
                    anchors.right: parent.right
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizonatalCenter
                }
            }

            // exp
            SettingBaseElement{
                m_short_description: "Mavlink sys id"
                m_long_description: "Mavlink sys id of QOpenHD (this Ground control station application). Leave default (255) ! . Change requires restart."

                SpinBox {
                    id: mavlinkSysIDSpinBox
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    from: 1
                    to: 255
                    stepSize: 1
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                    value: settings.qopenhd_mavlink_sysid
                    onValueChanged: {
                        if(value==100 || value==101){
                            // openhd air and ground unit sys id are hard coded, one should never use them
                            _messageBoxInstance.set_text_and_show("Do not use 100 or 101 for QOpenHD sys id")
                        }
                        settings.qopenhd_mavlink_sysid = value
                    }
                }
            }
            SettingBaseElement{
                m_short_description: "Latitude GPS offset"
                m_long_description: "Set this to a random value only you know to hide lat identity"

                /*SpinBox {
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                    from: -10
                    to: 10
                    stepSize: 1
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                    value: settings.hide_identity_latitude_offset
                    onValueChanged: {
                        settings.hide_identity_latitude_offset = value
                    }
                }*/
                XDecimalSpinBox{
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                    m_default_value: settings.hide_identity_latitude_offset

                    onRealValueChanged: {
                        if(settings.hide_identity_latitude_offset!=realValue){
                            settings.hide_identity_latitude_offset=realValue
                            console.log("Value is: "+settings.hide_identity_latitude_offset)
                        }
                    }
                }

            }
            SettingBaseElement{
                m_short_description: "Longitude GPS offset"
                m_long_description: "Set this to a random value only you know to hide lon identity"

                XDecimalSpinBox{
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                    m_default_value: settings.hide_identity_longitude_offset

                    onRealValueChanged: {
                        if(settings.hide_identity_longitude_offset!=realValue){
                            settings.hide_identity_longitude_offset=realValue
                            console.log("Value is: "+settings.hide_identity_longitude_offset)
                        }
                    }
                }
            }

        }
    }
}
