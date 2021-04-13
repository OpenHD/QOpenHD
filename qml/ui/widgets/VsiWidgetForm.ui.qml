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
    id: vsiWidget
    width: 50
    height: 50
    defaultAlignment: 1
    defaultXOffset: -20
    defaultHCenter: false
    defaultVCenter: true

    visible: settings.show_vsi

    widgetIdentifier: "vsi_widget"

    hasWidgetDetail: true

    widgetDetailComponent: ScrollView{

        contentHeight: vsiSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true
        Column {
            id: vsiSettingsColumn
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
                    id: vsi_opacity_Slider
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.vsi_opacity
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96
                    // @disable-check M223
                    onValueChanged: {
                        settings.vsi_opacity = vsi_opacity_Slider.value
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
                    id: vsi_size_Slider
                    orientation: Qt.Horizontal
                    from: .5
                    value: settings.vsi_size
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.vsi_size = vsi_size_Slider.value
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
                    text: qsTr("Range")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: vsi_max_Slider
                    orientation: Qt.Horizontal
                    from: 5
                    value: settings.vsi_max
                    to: 50
                    stepSize: 5
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96
                    // @disable-check M223
                    onValueChanged: {
                        settings.vsi_max = vsi_max_Slider.value
                    }
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: settings.vsi_opacity

        Item {
            anchors.fill: parent
            anchors.centerIn: parent
            transform: Scale { origin.x: 25; origin.y: 25; xScale: settings.vsi_size ; yScale: settings.vsi_size}

            Shape {
                anchors.fill: parent
                id: gaugeArcGlow

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: settings.color_glow
                    strokeWidth: 3
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: 25
                        centerY: 25
                        radiusX: 25
                        radiusY: 25
                        startAngle: 45
                        sweepAngle: 270
                    }
                }
            }
            Shape {
                anchors.fill: parent
                id: gaugeArc

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: settings.color_shape
                    strokeWidth: 1
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: 25
                        centerY: 25
                        radiusX: 25
                        radiusY: 25
                        startAngle: 45
                        sweepAngle: 270
                    }
                }
            }

            CircularGauge {
                id: gauge
                anchors.fill: parent
                antialiasing: true

                rotation: 270

                minimumValue: settings.vsi_max*-1
                maximumValue: settings.vsi_max

                value: OpenHD.vsi

                style: CircularGaugeStyle {
                    labelInset: outerRadius * -.3
                    minorTickmarkCount : 0
                    tickmarkStepSize : {settings.vsi_max/5}
                    // @disable-check M223
                    labelStepSize : {settings.vsi_max/5}
                    maximumValueAngle : 135
                    minimumValueAngle : -135

                    tickmark: Rectangle {
                        visible: styleData.value
                        implicitWidth: outerRadius * 0.05
                        antialiasing: true
                        implicitHeight: outerRadius * 0.2
                        color: settings.color_shape
                        border.color: settings.color_glow
                        border.width: 1
                        width: 3
                    }

                    tickmarkLabel:  Text {
                        rotation: 90
                        //font.pixelSize: Math.max(6, outerRadius * 0.1)
                        font.pixelSize: 9
                        font.family: settings.font_text
                        text: styleData.value
                        color: settings.color_text
                        antialiasing: true
                        style: Text.Outline
                        styleColor: settings.color_glow
                    }

                    needle: Rectangle {
                        y: outerRadius * -.01 //this is the needle base closest to axis
                        implicitWidth: outerRadius * 0.05
                        implicitHeight: outerRadius
                        antialiasing: true
                        color: settings.color_text
                        border.color: settings.color_glow
                        border.width: 1
                        width: 3
                    }
                }
            }
        }
    }
}
