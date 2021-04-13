import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import QtQuick.Shapes 1.0

import OpenHD 1.0

BaseWidget {
    id: arrowWidget
    width: 64
    height: 48
    defaultYOffset: 135

    visible: settings.show_arrow

    widgetIdentifier: "arrow_widget"

    defaultHCenter: true
    defaultVCenter: false

    hasWidgetDetail: true

    widgetDetailComponent: ScrollView{

        contentHeight: arrowSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true
        Column {
            id: arrowSettingsColumn
            Item {
                width: parent.width
                height: 32
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
                    id: arrow_opacity_Slider
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.arrow_opacity
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.arrow_opacity = arrow_opacity_Slider.value
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
                    id: arrow_size_Slider
                    orientation: Qt.Horizontal
                    from: .5
                    value: settings.arrow_size
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.arrow_size = arrow_size_Slider.value
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
                    text: qsTr("Invert Arrow")
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
                    checked: settings.arrow_invert
                    onCheckedChanged: settings.arrow_invert = checked
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent

        Item {
            anchors.fill: parent
            anchors.centerIn: parent
            transform: Scale { origin.x: 32; origin.y: 12; xScale: settings.arrow_size ; yScale: settings.arrow_size}


            Shape {
                id: arrow
                anchors.fill: parent
                antialiasing: true
                opacity: settings.arrow_opacity

                ShapePath {
                    capStyle: ShapePath.RoundCap
                    strokeColor: settings.color_glow
                    fillColor: settings.color_shape
                    strokeWidth: 1
                    strokeStyle: ShapePath.SolidLine

                    startX: 32
                    startY: 24
                    PathLine { x: 26;                  y: 24 }//bottom left edge
                    PathLine { x: 26;                  y: 12  }//inner left edge
                    PathLine { x: 20;                  y: 12  }//outer left
                    PathLine { x: 32;                  y: 0  }//point
                    PathLine { x: 44;                 y: 12  }//right edge of arrow
                    PathLine { x: 38;                 y: 12  }//inner right edge
                    PathLine { x: 38;                 y: 24 }//bottom right edge
                    PathLine { x: 32;                 y: 24 }//back to start

                }

                transform: Rotation {
                    origin.x: 32;
                    origin.y: 12;
                    angle: settings.arrow_invert ? OpenHD.home_course : OpenHD.home_course-180
                }
            }
        }
    }
}

