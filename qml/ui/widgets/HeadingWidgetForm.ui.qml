import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import QtQuick.Shapes 1.0

import OpenHD 1.0

BaseWidget {
    id: headingWidget
    width: 48
    height: 48

    visible: settings.show_heading

    defaultYOffset: 50

    widgetIdentifier: "heading_widget"

    defaultHCenter: true
    defaultVCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: ScrollView{

        contentHeight: headingSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        ColumnLayout{
            id: headingSettingsColumn
            spacing:0
            clip: true

            Item {
                width: 230
                height: 32
                Text {
                    id: opacityText
                    text: "Transparency"
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: heading_opacity_Slider
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.heading_opacity
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 5
                    anchors.right: parent.right
                    width: parent.width-96

                    onValueChanged: {
                        settings.heading_opacity = heading_opacity_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    id: sizeText
                    text: "Size"
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: heading_size_Slider
                    orientation: Qt.Horizontal
                    from: .7
                    value: settings.heading_size
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 5
                    anchors.right: parent.right
                    width: parent.width-96

                    onValueChanged: {
                        settings.heading_size = heading_size_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: "Ardupilot / iNav"
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
                    checked: settings.heading_inav
                    onCheckedChanged: settings.heading_inav = checked
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: "Show ticks"
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
                    checked: settings.show_heading_ladder
                    onCheckedChanged: settings.show_heading_ladder = checked
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: "Show N/S/E/W"
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
                    checked: settings.heading_ladder_text
                    onCheckedChanged: settings.heading_ladder_text = checked
                }
            }
        }
    }

    Glow {
        anchors.fill: widgetInner
        radius: 3
        samples: 17
        color: settings.color_glow
        opacity: settings.heading_opacity
        source: widgetInner
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: settings.heading_opacity

        //-----------------------ladder start---------------
        Item {
            id: headingLadder

            anchors.centerIn: parent

            visible: settings.show_heading_ladder

            transform: Scale { origin.x: 24; origin.y: 0; xScale: settings.heading_size ; yScale: settings.heading_size}

            Connections{
                target:OpenHD
                function onHdgChanged() {
                    canvasHeadingLadder.requestPaint()
                }
            }
            Connections{
                target:settings
                function onHeading_ladder_textChanged() {
                    canvasHeadingLadder.requestPaint()
                }
            }

            Canvas {
                id: canvasHeadingLadder
                anchors.centerIn: parent
                width: 250
                height: 50
                clip: false

                onPaint: { // @disable-check M223
                    var ctx = getContext("2d"); // @disable-check M222
                    ctx.reset(); // @disable-check M222

                    if (settings.show_heading_ladder === false){
                        return; // to stop it from painting per user selection
                    }

                    ctx.fillStyle = settings.color_shape;
                    //cant get a good approximation of glow via canvas
                    //ctx.strokeStyle = settings.color_glow;
                    //ctx.lineWidth = 1;
                    ctx.font = "bold 11px sans-serif";
                    ctx.textAlign = "center";



                    var y = 25; // ticks up/down position
                    var y_label = 22; // labels up/down position

                    var y_position= height/2; // ladder center up/down..tweak
                    var x_position= width/2; // ladder center left/right..tweak

                    var home_heading = 0;
                    var compass_direction;
                    var draw_text = false;

                    var range= 180;
                    var ratio_heading = width/range;
                    var heading=OpenHD.hdg;

                    var heading_ladder_text = settings.heading_ladder_text;

                    var x;
                    var i;
                    var j;

                    for (i = (heading - range / 2); i <= heading + range / 2; i++) {    // @disable-check M223
                        x =  x_position + ((i - heading) * ratio_heading);
                        // console.log("heading:  ",i);
                        if (i % 30 == 0) {
                            //big ticks
                            ctx.rect(x, y, 3, 8);
                            ctx.fill();
                        }
                        else if (i % 15 == 0) {
                            //little ticks
                            ctx.rect(x, y+3, 2,5);
                            ctx.fill();
                        }
                        else {
                            continue;
                        }

                        if (x < width/2-26 || x > width/2+31){  // dont draw thru compass
                            j = i;
                            if (j < 0) j += 360;
                            if (j >= 360) j -= 360;
                            switch (j) {
                                case 0:
                                    draw_text = true;
                                    compass_direction = heading_ladder_text ?
                                                qsTr("N") : (j);
                                break;
                                case 45:
                                    draw_text = true;
                                    compass_direction = heading_ladder_text ?
                                                qsTr("NE") : (j);
                                break;
                                case 90:
                                    draw_text = true;
                                    compass_direction = heading_ladder_text ?
                                            qsTr("E") : (j);
                                break;
                                case 135:
                                    draw_text = true;
                                    compass_direction = heading_ladder_text ?
                                                qsTr("SE") : (j);
                                break;
                                case 180:
                                    draw_text = true;
                                    compass_direction = heading_ladder_text ?
                                                qsTr("S") : (j);
                                break;
                                case 225:
                                    draw_text = true;
                                    compass_direction = heading_ladder_text ?
                                                qsTr("SW") : (j);
                                break;
                                case 270:
                                    draw_text = true;
                                    compass_direction = heading_ladder_text ?
                                                qsTr("W") : (j);
                                break;
                                case 315:
                                    draw_text = true;
                                    compass_direction = heading_ladder_text ?
                                                qsTr("NW") : (j);
                                break;
                            }
                            if (draw_text === true) {
                                ctx.fillText(compass_direction, x, y_label);
                                draw_text = false;
                            }
                            /*  if (j == home_heading) {
                                             ctx.text(x, parent.height - height_element*2, "");
                                             ctx.stroke();
                                } */
                        }
                    }
                }
            }
        }
        //-----------------------ladder end---------------


        Text {
            id: hdg_text
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: parent.height - 24
            color: settings.color_text            
            font.pixelSize: 14
            transform: Scale { origin.x: 24; origin.y: 24; xScale: settings.heading_size ; yScale: settings.heading_size}
            text: Number(OpenHD.hdg).toLocaleString( Qt.locale(), 'f', 0)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Shape {
            id: outline
            anchors.fill: parent
            transform: Scale { origin.x: 24; origin.y: 24; xScale: settings.heading_size ; yScale: settings.heading_size}
            ShapePath {
                capStyle: ShapePath.RoundCap
                strokeColor: settings.color_shape
                strokeWidth: 1
                strokeStyle: ShapePath.SolidLine
                fillColor: "transparent"
                startX: 4
                startY: 0
                PathLine {
                    x: 4
                    y: 0
                }
                PathLine {
                    x: 44
                    y: 0
                }
                PathLine {
                    x: 44
                    y: 24
                }
                PathLine {
                    x: 32
                    y: 24
                }
                PathLine {
                    x: 24
                    y: 32
                }
                PathLine {
                    x: 16
                    y: 24
                }
                PathLine {
                    x: 4
                    y: 24
                }
                PathLine {
                    x: 4
                    y: 0
                }
            }
        }
    }
}
