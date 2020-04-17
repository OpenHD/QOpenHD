import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Extras 1.4
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0



BaseWidget {
    id: altitudeWidget
    width: 64
    height: 24
    // resize with right side (technically top right, but it doesn't matter because VCenter is set)
    defaultAlignment: 1
    defaultXOffset: 20
    defaultVCenter: true

    visible: settings.show_altitude

    widgetIdentifier: "altitude_widget"

    defaultHCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 32
            Text {
                id: opacityTitle
                text: "Opacity"
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Slider {
                id: altitude_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.altitude_opacity
                to: 1
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: { // @disable-check M223
                    settings.altitude_opacity = altitude_opacity_Slider.value
                }
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                id: sizeTitle
                text: "Size"
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Slider {
                id: altitude_size_Slider
                orientation: Qt.Horizontal
                from: .7
                value: settings.altitude_size
                to: 3
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: { // @disable-check M223
                    settings.altitude_size = altitude_size_Slider.value
                }
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                text: "Relative (off) / MSL (on)"
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
                anchors.rightMargin: 12
                anchors.right: parent.right
                checked: settings.altitude_rel_msl
                onCheckedChanged: settings.altitude_rel_msl = checked
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                text: "Ladder (off) / (on)"
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
                anchors.rightMargin: 12
                anchors.right: parent.right
                checked: settings.show_altitude_ladder
                onCheckedChanged: settings.show_altitude_ladder = checked
            }
        }
    }

    Glow {
        anchors.fill: widgetInner
        radius: 3
        samples: 17
        color: settings.color_glow
        opacity: settings.altitude_opacity
        source: widgetInner
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: settings.altitude_opacity

        //-----------------------ladder start---------------
        Item {
            id: altLadder

            anchors.verticalCenter: parent
            anchors.left: parent.left
            anchors.leftMargin: 20 //tweak ladder left or right

            transform: Scale { origin.x: -5; origin.y: 12; xScale: settings.altitude_size ; yScale: settings.altitude_size}

            Connections{
                target:OpenHD
                onAlt_rel_changed: { // if user selects msl it is part of same mavlink msg
                    canvasAltLadder.requestPaint()
                }
            }

            Canvas {
                id: canvasAltLadder
                anchors.centerIn: parent
                width: 50
                height: 300
                clip: false

                onPaint: { // @disable-check M223
                    var ctx = getContext("2d"); // @disable-check M222
                    ctx.reset(); // @disable-check M222

                    if (settings.show_altitude_ladder === false){
                        return; // to stop it from painting per user selection
                    }

                    ctx.fillStyle = settings.color_shape;
                    //cant get a good approximation of glow via canvas
                    //ctx.strokeStyle = settings.color_glow;
                    //ctx.lineWidth = .5;
                    ctx.font = "bold 11px sans-serif";

                    function getWidth(pos_x_percent) {                      // @disable-check M222
                                        return (width * 0.01 * pos_x_percent);
                                    }
                    function getHeight(pos_y_percent) {                     // @disable-check M222
                                        return (height * 0.01 * pos_y_percent);
                                    }

                    var alt=settings.altitude_rel_msl ? OpenHD.alt_msl : OpenHD.alt_rel;

                    var x = 6; // ticks right/left position
                    var y_position= height/2+11; // ladder center up/down..tweak
                    var x_label = 25; // ladder labels right/left position

                    var range = 100; // alt range range of display, i.e. lowest and highest number on the ladder
                    var ratio_alt = height / range;

                    var k;
                    var y;

                    for (k = (alt - range / 2); k <= alt + range / 2; k++) {    // @disable-check M223
                        y =  y_position + ((k - alt) * ratio_alt)*-1;
                        if (k % 10 == 0) {                                      // @disable-check M223
                            if (k >= 0) {                                       // @disable-check M223
                                /// big ticks
                                ctx.rect(x, y, 12, 3);
                                ctx.fill();                                     // @disable-check M222
                                //ctx.stroke();
                                if (k>alt+5 || k<alt-5){                        // @disable-check M223
                                    // text
                                    ctx.fillText(k, x_label, y+6);              // @disable-check M222
                                }
                            }
                            if (k < 0) {                                        // @disable-check M223
                                //start position alt (squares) below "0"
                                ctx.rect(x, y-15, 15, 15);
                                ctx.fill();                                     // @disable-check M222
                                //ctx.stroke();
                            }
                        }
                        else if ((k % 5 == 0) && (k > 0)){                      // @disable-check M223
                            //little ticks
                            ctx.rect(x, y, 7, 2);
                            ctx.fill(); // @disable-check M222
                            //ctx.stroke();
                        }
                    }
                }
            }
        }
        //-----------------------ladder end---------------
        Item {
            id: altPointer
            anchors.fill: parent

            Text {
                id: alt_text
                color: settings.color_text

                font.pixelSize: 14
                transform: Scale { origin.x: 12; origin.y: 12; xScale: settings.altitude_size ; yScale: settings.altitude_size}
                text: Number( // @disable-check M222
                          settings.altitude_rel_msl ? OpenHD.alt_msl : OpenHD.alt_rel).toLocaleString(
                          Qt.locale(), 'f', 0) // @disable-check M222
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Shape {
                id: outline
                anchors.fill: parent

                transform: Scale {
                    origin.x: 12
                    origin.y: 12
                    xScale: settings.altitude_size
                    yScale: settings.altitude_size
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
}
