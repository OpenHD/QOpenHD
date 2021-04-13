import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import QtQuick.Shapes 1.0

import OpenHD 1.0

/* Plane or Copter decides if the widget will use mavlink wind msg (only available for planes)
  or openhd calculated wind messages which are based on expected tilt vs actual tilt.

  Within our own openhd calculated wind there are two modes calculated. Both modes rely on
  no climbing and unaccelerated flight. One mode is in position hold type of flight mode and the
  other mode is in unaccelerated level motion */


BaseWidget {
    id: windWidget
    width: 50
    height: 50

    visible: settings.show_wind

    widgetIdentifier: "wind_widget"

    defaultAlignment: 3
    defaultXOffset: 6
    defaultYOffset: 128

    hasWidgetDetail: true

    widgetDetailComponent: ScrollView{

        contentHeight: windSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true
        Column {
            id: windSettingsColumn
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Transparency")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: wind_opacity_Slider
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.wind_opacity
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {// @disable-check M223
                        settings.wind_opacity = wind_opacity_Slider.value
                    }
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Size")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: wind_size_Slider
                    orientation: Qt.Horizontal
                    from: .5
                    value: settings.wind_size
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.wind_size = wind_size_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
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
                        var _hCenter = settings.value(hCenterIdentifier, defaultHCenter)
                        // @disable-check M223
                        if (_hCenter === "true" || _hCenter === 1 || _hCenter === true) {
                            checked = true;
                            // @disable-check M223
                        } else {
                            checked = false;
                        }
                    }

                    onCheckedChanged: settings.setValue(hCenterIdentifier, checked)
                }
            }
            Item {
                width: 230
                height: 32
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
                        var _vCenter = settings.value(vCenterIdentifier, defaultVCenter)
                        // @disable-check M223
                        if (_vCenter === "true" || _vCenter === 1 || _vCenter === true) {
                            checked = true;
                            // @disable-check M223
                        } else {
                            checked = false;
                        }
                    }

                    onCheckedChanged: settings.setValue(vCenterIdentifier, checked)
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Style: Arrow / Circle")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels;
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.wind_arrow_circle
                    onCheckedChanged: settings.wind_arrow_circle = checked
                }
            }
            Item {
                width: parent.width
                height: 32
                Text {
                    text: qsTr("Plane / Copter")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels;
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.wind_plane_copter
                    onCheckedChanged: settings.wind_plane_copter = checked
                }
            }
            Item {
                width: parent.width
                height: 32
                visible: settings.wind_plane_copter ? true : false

                Text {
                    text: qsTr("45 Degree Speed M/S")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    id: decimalRect
                    height: 40
                    width: 30
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    antialiasing: true;

                    Tumbler {
                        id: decimalTumbler
                        model: 10

                        visibleItemCount : 1
                        anchors.fill: parent

                        currentIndex: settings.wind_tumbler_decimal

                        Component.onCompleted: {
                            currentIndex= settings.wind_tumbler_decimal ;
                        }

                        delegate: Text {
                            text: modelData
                            color: "white"
                            font.family: "Arial"
                            font.weight: Font.Thin
                            font.pixelSize: 14

                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            //opacity: 1.0 - Math.abs(Tumbler.displacement) / root.visibleItemCount
                            scale: opacity
                        }

                        onCurrentIndexChanged: {
                            settings.wind_tumbler_decimal = currentIndex;
                            //  console.log("decimal Changed-",settings.wind_tumbler_decimal)
                        }
                    }
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Material.color(Material.Grey ,Material.Shade500) }
                        GradientStop { position: 0.5; color: "transparent" }
                        GradientStop { position: 1.0; color: Material.color(Material.Grey ,Material.Shade500) }
                    }
                }
                Text {
                    id:decimalText
                    text: "."
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.right: decimalRect.left
                    rightPadding: 5
                    leftPadding: 5
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    id: tensRect
                    height: 40
                    width: 30
                    anchors.right: decimalText.left
                    antialiasing: true;

                    Tumbler {
                        id: tensTumbler
                        model: 60
                        visibleItemCount : 1
                        anchors.fill: parent

                        currentIndex: settings.wind_tumbler_tens

                        Component.onCompleted: {
                            // rounds it due to int
                            currentIndex= settings.wind_tumbler_tens;
                        }
                        delegate: Text {
                            text: modelData
                            color: "white"

                            font.family: "Arial"
                            font.weight: Font.Thin
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            //opacity: 1.0 - Math.abs(Tumbler.displacement) / root.visibleItemCount
                            scale: opacity
                        }
                        onCurrentIndexChanged: {
                            settings.wind_tumbler_tens = currentIndex;
                            //   console.log("tens Changed-",settings.wind_tumbler_tens);
                        }
                    }
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Material.color(Material.Grey ,Material.Shade500) }
                        GradientStop { position: 0.5; color: "transparent" }
                        GradientStop { position: 1.0; color: Material.color(Material.Grey ,Material.Shade500) }
                    }
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        antialiasing: true

        opacity: settings.wind_opacity

        Item {
            anchors.fill: parent
            anchors.centerIn: parent
            transform: Scale { origin.x: 25; origin.y: 25; xScale: settings.wind_size ; yScale: settings.wind_size}

            Shape {
                id: arrow
                anchors.fill: parent
                antialiasing: true

                visible: settings.wind_arrow_circle ? false : true

                ShapePath {
                    capStyle: ShapePath.RoundCap
                    strokeColor: settings.color_glow
                    fillColor: settings.color_shape
                    strokeWidth: 1
                    strokeStyle: ShapePath.SolidLine

                    startX: 4
                    startY: 0
                    PathLine { x: 8;                 y: 12  }//right edge of arrow
                    PathLine { x: 5;                 y: 12  }//inner right edge
                    PathLine { x: 5;                 y: 40 }//bottom right edge
                    PathLine { x: 3;                  y: 40 }//bottom left edge
                    PathLine { x: 3;                  y: 12  }//inner left edge
                    PathLine { x: 0;                  y: 12  }//outer left
                    PathLine { x: 3;                  y: 0  }//back to start
                }

                transform: Rotation {
                    origin.x: 3;
                    origin.y: 20;
                    angle: (settings.wind_plane_copter ? OpenHD.wind_direction : OpenHD.mav_wind_direction) - OpenHD.hdg - 180
                }
            }
            Rectangle {
                id: outerCircleGlow

                anchors.centerIn: parent
                visible: settings.wind_arrow_circle ? true : false
                width: ((parent.width<parent.height?parent.width:parent.height))+2
                height: width
                color: "transparent"
                radius: width*0.5
                border.color: settings.color_glow
                border.width: 3
            }
            Rectangle {
                id: innerCircleGlow

                anchors.centerIn: parent
                visible: settings.wind_arrow_circle ? true : false
                width: ((parent.width<parent.height?parent.width:parent.height)/2)+2
                height: width
                color: "transparent"
                radius: width*0.5

                border.color: settings.color_glow
                border.width: 3
            }
            Shape {
                id: lowerPointer
                anchors.fill: parent
                antialiasing: true

                visible: settings.wind_arrow_circle ? true : false

                ShapePath {
                    capStyle: ShapePath.FlatCap
                    strokeColor: settings.color_glow
                    strokeWidth: 3
                    strokeStyle: ShapePath.SolidLine

                    startX: 25
                    startY: 37
                    PathLine { x: 25; y: 49  }
                }
                ShapePath {
                    capStyle: ShapePath.FlatCap
                    strokeColor: settings.color_shape
                    strokeWidth: 1
                    strokeStyle: ShapePath.SolidLine

                    startX: 25
                    startY: 37
                    PathLine { x: 25; y: 49  }
                }

                transform: Rotation {
                    origin.x: 25;
                    origin.y: 25;
                    angle: (settings.wind_plane_copter ? OpenHD.wind_direction : OpenHD.mav_wind_direction - 10) - OpenHD.hdg - 190
                }
            }
            Shape {
                id: upperPointer

                anchors.fill: parent
                antialiasing: true

                visible: settings.wind_arrow_circle ? true : false

                ShapePath {
                    capStyle: ShapePath.FlatCap
                    strokeColor: settings.color_glow
                    strokeWidth: 3
                    strokeStyle: ShapePath.SolidLine
                    startX: 25
                    startY: 38
                    PathLine { x: 25; y: 49  }
                }
                ShapePath {
                    capStyle: ShapePath.FlatCap
                    strokeColor: settings.color_shape
                    strokeWidth: 1
                    strokeStyle: ShapePath.SolidLine
                    startX: 25
                    startY: 38
                    PathLine { x: 25; y: 49  }
                }

                transform: Rotation {
                    origin.x: 25;
                    origin.y: 25;
                    angle: {// @disable-check M223

                        //   var wind=getWindDirection();
                        //  var wind_direction=wind.direction - OpenHD.hdg + 185;
                        //   return wind_direction;
                        (settings.wind_plane_copter ? OpenHD.wind_direction : OpenHD.mav_wind_direction)-OpenHD.hdg-170;
                    }
                }
            }

            Rectangle {
                id: outerCircle

                anchors.centerIn: parent
                visible: settings.wind_arrow_circle ? true : false
                width: (parent.width<parent.height?parent.width:parent.height)
                height: width
                color: "transparent"
                radius: width*0.5
                border.color: settings.color_shape
                border.width: .5
            }
            Rectangle {
                id: innerCircle

                anchors.centerIn: parent
                visible: settings.wind_arrow_circle ? true : false
                width: (parent.width<parent.height?parent.width:parent.height)/2
                height: width
                color: "transparent"
                radius: width*0.5

                border.color: settings.color_shape
                border.width: .5
            }

            Text {
                id: wind_text
                color: settings.color_text
                anchors.centerIn: parent
                font.pixelSize: 12
                text: {// @disable-check M223
                    Number(settings.enable_imperial ?
                               (settings.wind_plane_copter ? OpenHD.wind_speed*2.237 : OpenHD.mav_wind_speed*2.237) :
                               (settings.wind_plane_copter ? OpenHD.wind_speed*3.6 : OpenHD.mav_wind_speed*3.6))
                    .toLocaleString(Qt.locale(), 'f', 0)} // @disable-check M222
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                style: Text.Outline
                styleColor: settings.color_glow
            }
        }
    }
}



