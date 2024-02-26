import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

BaseWidget {
    property alias gaugeAngle: throttleArc.sweepAngle

    property alias gaugeAngleGlow: throttleArcGlow.sweepAngle

    id: throttleWidget
    width: 96
    height: 68

    visible: settings.show_throttle

    widgetIdentifier: "throttle_widget"
    bw_verbose_name: "THROTTLE"

    defaultAlignment: 2
    defaultXOffset: 96
    defaultYOffset: 72
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    hasWidgetAction: true

    function map(input, input_start, input_end, output_start, output_end) {
        var input_range = input_end - input_start;
        var output_range = output_end - output_start;

        return (input - input_start)*output_range / input_range + output_start;
    }

    Connections {
        target: _fcMavlinkSystem

        function onThrottleChanged(throttle) {
            gaugeAngle = map(throttle, 0, 100, 0, 180);
            gaugeAngleGlow = map(throttle, 0, 100, 0, 180);
        }
    }

    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements
        }
    }

    //---------------------------ACTION WIDGET COMPONENT BELOW-----------------------------
    widgetActionComponent: ScrollView {

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        ColumnLayout {
            width: 200
            spacing: 10

            Item {
                height: 32
                Text {
                    text: "Only For Ardupilot/PX4/inav"
                    color: "white"
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                }
            }
            ArmDisarmSlider{
                id: arm_disarm_slider
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: bw_current_opacity

        Item {
            anchors.fill: parent
            anchors.centerIn: parent
            transform: Scale {
                origin.x: 48
                origin.y: 34
                xScale: bw_current_scale
                yScale: bw_current_scale
            }

            Text {
                id: throttle_percent
                y: 0
                width: 24
                height: 18
                color: settings.color_text
                text: _fcMavlinkSystem.throttle
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 18
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 18
                font.family: settings.font_text
                style: Text.Outline
                styleColor: settings.color_glow
            }

            Shape {
                id: throttleGauge
                anchors.fill: parent
                scale: 1.0

                ShapePath {
                    id: throttleShapeGlow

                    fillColor: "transparent"
                    strokeColor: settings.color_glow
                    strokeWidth: 11
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        id: throttleArcGlow
                        centerX: 48
                        centerY: 48
                        radiusX: 32
                        radiusY: 32
                        startAngle: -180
                    }
                }

                ShapePath {
                    id: throttleShape

                    fillColor: "transparent"
                    strokeColor: settings.color_shape
                    strokeWidth: 9
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        id: throttleArc
                        centerX: 48
                        centerY: 48
                        radiusX: 32
                        radiusY: 32
                        startAngle: -180
                    }
                }
            }

            Text {
                id: throttle_description
                y: 0
                width: parent.width
                height: 14
                color: settings.color_text
                text: qsTr("throttle")
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 0
                verticalAlignment: Text.AlignBottom
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 14
                font.family: settings.font_text
                style: Text.Outline
                styleColor: settings.color_glow
            }
        }
    }
}
