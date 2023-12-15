import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Extras 1.4
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

BaseWidget {
    id: aoaWidget
    width: 50
    height: 100
    defaultAlignment: 1
    defaultXOffset: 60
    defaultVCenter: true

    visible: settings.show_aoa

    widgetIdentifier: "aoa_widget"
    bw_verbose_name: "ANGLE OF ATTACK"

    hasWidgetDetail: true

    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements
            Item {
                width: parent.width
                height: 32

                Text {
                    text: qsTr("Range")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: aoa_max_Slider
                    orientation: Qt.Horizontal
                    from: 15
                    value: settings.aoa_max
                    to: 40
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96
                    // @disable-check M223
                    onValueChanged: {
                        settings.aoa_max = aoa_max_Slider.value
                    }
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: bw_current_opacity

        //-----------------------ladder start---------------
        Item {
            id: aoaGauge

            anchors.left: parent.left
            anchors.rightMargin: 0 //tweak ladder left or right

            visible: settings.show_aoa

            transform: Scale {
                origin.x: 25
                origin.y: 60
                xScale: bw_current_scale
                yScale: bw_current_scale
            }

            AoaGauge {
                id: aoaGaugeC
                //anchors.centerIn: parent
                anchors.top: parent.bottom

                width: 50
                height: 100
                clip: false
                color: settings.color_shape
                glow: settings.color_glow

                aoaRange: settings.aoa_max
                Behavior on aoa {NumberAnimation { duration: settings.smoothing }}
                aoa: _fcMavlinkSystem.aoa
                fontFamily: settings.font_text
            }
        }

        //-----------------------ladder end---------------
        Text {
            visible:false // used for testing
            anchors.fill: parent
            id: aoa_text
            color: settings.color_text
            font.pixelSize: 14
            font.family: settings.font_text
            transform: Scale {
                origin.x: 12
                origin.y: 12
                xScale: bw_current_scale
                yScale: bw_current_scale
            }
            text: Number(_fcMavlinkSystem.aoa).toLocaleString(
                      Qt.locale(), 'f', 0)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            style: Text.Outline
            styleColor: settings.color_glow
        }
    }
}
