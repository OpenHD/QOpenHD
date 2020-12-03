/*
 * Copyright Maxime Engel (https://github.com/MaximeEngel)
 *
 * License: GPL v3
 *
 */
 
import QtQuick 2.2
import QtQuick.Window 2.0
import QtQuick.Layouts 1.1
import "ColorUtils.js" as ColorUtils

Item {
    id: root
    focus: true

    // Color value in RGBA with floating point values between 0.0 and 1.0.

    property vector4d colorHSVA: Qt.vector4d(1, 0, 1, 1)
    QtObject {
        id: m
        // Color value in HSVA with floating point values between 0.0 and 1.0.
        property vector4d colorRGBA: ColorUtils.hsva2rgba(root.colorHSVA)
    }

    property string color

    Wheel {
        id: wheel
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.top: parent.top

        width: 150
        height: 150

        hue: colorHSVA.x
        saturation: colorHSVA.y
        onUpdateHS: {
            colorHSVA = Qt.vector4d(hueSignal, saturationSignal, colorHSVA.z, colorHSVA.w)
            color = ColorUtils.hexaFromRGBA(m.colorRGBA.x, m.colorRGBA.y, m.colorRGBA.z, m.colorRGBA.w)
            root.colorChanged()
        }
    }

    // brightness picker slider
    Item {
        id: brightnessBar
        anchors.left: wheel.right
        anchors.leftMargin: 48
        anchors.top: parent.top
        height: 150
        width: 40

        //Brightness background
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    id: brightnessBeginColor
                    position: 0.0
                    color: {
                        var rgba = ColorUtils.hsva2rgba(
                                    Qt.vector4d(colorHSVA.x,
                                                colorHSVA.y, 1, 1))
                        return Qt.rgba(rgba.x, rgba.y, rgba.z, rgba.w)
                    }
                }
                GradientStop {
                    position: 1.0
                    color: "#000000"
                }
            }
        }

        VerticalSlider {
            id: brigthnessSlider
            anchors.fill: parent
            value: colorHSVA.z
            onValueChanged: {
                colorHSVA = Qt.vector4d(colorHSVA.x, colorHSVA.y, value, colorHSVA.w)
                color = ColorUtils.hexaFromRGBA(m.colorRGBA.x, m.colorRGBA.y, m.colorRGBA.z, m.colorRGBA.w)
                root.colorChanged()
            }
        }
    }

    // Alpha picker slider
    Item {
        id: alphaBar
        anchors.left: brightnessBar.right
        anchors.leftMargin: 48
        anchors.top: parent.top
        height: 150
        width: 40


        CheckerBoard {
            cellSide: 4
        }

        //  alpha intensity gradient background
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(m.colorRGBA.x, m.colorRGBA.y, m.colorRGBA.z, 1)
                }
                GradientStop {
                    position: 1.0
                    color: "#00000000"
                }
            }
        }
        VerticalSlider {
            id: alphaSlider
            value: colorHSVA.w
            anchors.fill: parent
            onValueChanged: {
                colorHSVA.w = value
                color = ColorUtils.hexaFromRGBA(m.colorRGBA.x, m.colorRGBA.y, m.colorRGBA.z, m.colorRGBA.w)
                root.colorChanged()
            }
        }
    }


    Item {
        id: numbers
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        height: 40

        NumberBox {
            id: red
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: 80
            caption: "R"
            value: Math.round(m.colorRGBA.x * 255)
            min: 0
            max: 255
            decimals: 0
            onAccepted: {
                var colorTmp = Qt.vector4d( boxValue / 255,
                                           m.colorRGBA.y,
                                           m.colorRGBA.z,
                                           colorHSVA.w) ;
                colorHSVA = ColorUtils.rgba2hsva(colorTmp)
                color = ColorUtils.hexaFromRGBA(m.colorRGBA.x, m.colorRGBA.y, m.colorRGBA.z, m.colorRGBA.w)
                root.colorChanged()
            }
        }

        NumberBox {
            id: green
            anchors.bottom: parent.bottom
            anchors.left: red.right
            width: 80
            caption: "G"
            value: Math.round(m.colorRGBA.y * 255)
            min: 0
            max: 255
            decimals: 0
            onAccepted: {
                var colorTmp = Qt.vector4d( m.colorRGBA.x,
                                           boxValue / 255,
                                           m.colorRGBA.z,
                                           colorHSVA.w) ;
                colorHSVA = ColorUtils.rgba2hsva(colorTmp)
                color = ColorUtils.hexaFromRGBA(m.colorRGBA.x, m.colorRGBA.y, m.colorRGBA.z, m.colorRGBA.w)
                root.colorChanged()
            }
        }

        NumberBox {
            id: blue
            anchors.bottom: parent.bottom
            anchors.left: green.right
            width: 80
            caption: "B"
            value: Math.round(m.colorRGBA.z * 255)
            min: 0
            max: 255
            decimals: 0
            onAccepted: {
                var colorTmp = Qt.vector4d( m.colorRGBA.x,
                                           m.colorRGBA.y,
                                           boxValue / 255,
                                           colorHSVA.w) ;
                colorHSVA = ColorUtils.rgba2hsva(colorTmp)
                color = ColorUtils.hexaFromRGBA(m.colorRGBA.x, m.colorRGBA.y, m.colorRGBA.z, m.colorRGBA.w)
                root.colorChanged()
            }
        }

        NumberBox {
            id: rgbAlpha
            anchors.bottom: parent.bottom
            anchors.left: blue.right
            width: 80
            caption: "A"
            value: Math.round(m.colorRGBA.w * 255)
            min: 0
            max: 255
            decimals: 0
            onAccepted: {
                root.colorHSVA.w = boxValue / 255
                color = ColorUtils.hexaFromRGBA(m.colorRGBA.x, m.colorRGBA.y, m.colorRGBA.z, m.colorRGBA.w)
                root.colorChanged()
            }
        }
    }

}
