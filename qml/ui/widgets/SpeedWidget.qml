import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: speedWidget
    width: 64
    height: 24

    visible: settings.speed_ladder_show

    defaultXOffset: 20
    defaultVCenter: true

    widgetIdentifier: "speed_widget"
    bw_verbose_name: "SPEED"

    defaultHCenter: false

    hasWidgetDetail: true

    widgetDetailHeight: 250+150
    m_show_grid_when_dragging: true

    function get_speed_number(){
        var speed_m_per_second=settings.speed_ladder_use_groundspeed ? _fcMavlinkSystem.ground_speed_meter_per_second : _fcMavlinkSystem.air_speed_meter_per_second;
        if(settings.enable_imperial){
            return speed_m_per_second*2.23694;
        }
        if(settings.speed_ladder_use_kmh){
            return speed_m_per_second*3.6;
        }
        return speed_m_per_second;
    }

    function get_speed_unit(){
        if(settings.enable_imperial){
            return " mph";
        }
        if(settings.speed_ladder_use_kmh){
            return " kph";
        }
        return " m/s";
    }

    function get_text_speed(){
        var speed = get_speed_number()
        var ret=Number(speed).toLocaleString( Qt.locale(), 'f', 0)
        if(settings.speed_ladder_show_unit && speed <99){
            ret+=get_speed_unit();
        }
        return ret;
    }

    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements

            show_horizontal_lock: true
            show_vertical_lock: true

            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Use groundspeed")
                    horizontalAlignment: Text.AlignRight
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
                    checked: settings.speed_ladder_use_groundspeed
                    onCheckedChanged: settings.speed_ladder_use_groundspeed = checked
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Show ladder")
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
                    checked: settings.speed_ladder_show_ladder
                    onCheckedChanged: settings.speed_ladder_show_ladder = checked
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Show unit")
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
                    checked: settings.speed_ladder_show_unit
                    onCheckedChanged: settings.speed_ladder_show_unit = checked
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Use km/h")
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
                    checked: settings.speed_ladder_use_kmh
                    onCheckedChanged: settings.speed_ladder_use_kmh = checked
                }
            }
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
                    id: speed_range_Slider
                    orientation: Qt.Horizontal
                    from: 40
                    value: settings.speed_ladder_range
                    to: 150
                    stepSize: 10
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        // @disable-check M223
                        settings.speed_ladder_range = speed_range_Slider.value
                    }
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Minimum:"+settings.speed_ladder_minimum)
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: speed_minimum_Slider
                    orientation: Qt.Horizontal
                    from: 0
                    value: settings.speed_ladder_minimum
                    to: 50
                    stepSize: 10
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        // @disable-check M223
                        settings.speed_ladder_minimum = speed_minimum_Slider.value
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
            id: speedLadder

            anchors.right: parent.right
            anchors.rightMargin: 20 //tweak ladder left or right

            visible: settings.speed_ladder_show_ladder

            transform: Scale {
                origin.x: -33
                origin.y: 12
                xScale: bw_current_scale
                yScale: bw_current_scale
            }

            SpeedLadder {
                id: speedLadderC
                anchors.centerIn: parent
                width: 50
                height: 300
                clip: false
                color: settings.color_shape
                glow: settings.color_glow
                speedMinimum: settings.speed_ladder_minimum
                speedRange: settings.speed_ladder_range
                Behavior on speed {NumberAnimation { duration: settings.smoothing }}
                speed: get_speed_number()
                fontFamily: settings.font_text
            }
        }

        //-----------------------ladder end---------------
        Text {
            anchors.fill: parent
            id: speed_text
            color: settings.color_text
            font.pixelSize: 14
            font.family: settings.font_text
            transform: Scale {
                origin.x: 12
                origin.y: 12
                xScale: bw_current_scale
                yScale: bw_current_scale
            }
            text: get_text_speed()
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            style: Text.Outline
            styleColor: settings.color_glow
        }
        Shape {
            id: outlineGlow
            anchors.fill: parent
            rotation: 180
            transform: Scale {
                origin.x: 12
                origin.y: 12
                xScale: bw_current_scale
                yScale: bw_current_scale
            }
            ShapePath {
                strokeColor: settings.color_glow
                strokeWidth: 3
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: 0
                startY: 12
                PathLine {
                    x: 0
                    y: 12
                }
                PathLine {
                    x: 12
                    y: 0
                }
                PathLine {
                    x: 58
                    y: 0
                }
                PathLine {
                    x: 58
                    y: 24
                }
                PathLine {
                    x: 12
                    y: 24
                }
                PathLine {
                    x: 0
                    y: 12
                }
            }
        }
        Shape {
            id: outline
            anchors.fill: parent
            rotation: 180
            transform: Scale {
                origin.x: 12
                origin.y: 12
                xScale: bw_current_scale
                yScale: bw_current_scale
            }
            ShapePath {
                strokeColor: settings.color_shape
                strokeWidth: 1
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: 0
                startY: 12
                PathLine {
                    x: 0
                    y: 12
                }
                PathLine {
                    x: 12
                    y: 0
                }
                PathLine {
                    x: 58
                    y: 0
                }
                PathLine {
                    x: 58
                    y: 24
                }
                PathLine {
                    x: 12
                    y: 24
                }
                PathLine {
                    x: 0
                    y: 12
                }
            }
        }
    }
}

