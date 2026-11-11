/*
 * Copyright Maxime Engel (https://github.com/MaximeEngel)
 *
 * License: GPL v3
 *
 */
 
import QtQuick 2.0
import "ColorUtils.js" as ColorUtils

Item {
    id: root

    property real hue : 1
    property real saturation : 1

    signal accepted()
    signal updateHS(var hueSignal, var saturationSignal)

    states :
        // When user is moving the slider
        State {
            name: "editing"
            PropertyChanges {
                target: root
                // Better solution ? because the value is change in the fonction of mouse area
                hue: hue
                saturation: saturation
            }
        }

    Rectangle {
        id: wheel
        //Keep the wheel round
        width: parent.width < parent.height ? parent.width : parent.height ;
        height: width ;
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"
        Canvas {
            objectName: "colorWheelSurface"
            anchors.fill: parent
            onAvailableChanged: if (available) requestPaint()
            onVisibleChanged: if (visible) requestPaint()
            onWidthChanged: requestPaint()
            onPaint: {
                const context = getContext("2d")
                const size = Math.round(width)
                if (size < 1)
                    return
                const radius = size / 2
                const pixels = context.createImageData(size, size)
                const data = pixels.data
                for (let y = 0; y < size; ++y) {
                    for (let x = 0; x < size; ++x) {
                        const dx = x + 0.5 - radius
                        const dy = radius - y - 0.5
                        const distance = Math.sqrt(dx * dx + dy * dy)
                        if (distance >= radius + 0.5)
                            continue
                        const hue = Math.atan2(dy, dx) / (2 * Math.PI) + 0.5
                        const saturation = Math.min(1, distance / radius)
                        const rgb = ColorUtils.hsva2rgba(Qt.vector4d(hue, saturation, 1, 1))
                        const offset = 4 * (y * size + x)
                        data[offset] = 255 * rgb.x
                        data[offset + 1] = 255 * rgb.y
                        data[offset + 2] = 255 * rgb.z
                        data[offset + 3] = 255 * Math.min(1, radius + 0.5 - distance)
                    }
                }
                context.clearRect(0, 0, size, size)
                context.putImageData(pixels, 0, 0, 0, 0, size, size)
            }
        }

        Item {
            id: pickerCursor
            x: parent.width/2 * (1 + root.saturation * Math.cos(2 * Math.PI * root.hue - Math.PI)) - r
            y: parent.width/2 * (1 + root.saturation * Math.sin(-2 * Math.PI * root.hue - Math.PI)) - r
            property int r : 8
            Rectangle {
                width: parent.r*2; height: parent.r*2
                radius: parent.r
                border.color: "black"; border.width: 2
                color: "transparent"
                Rectangle {
                    anchors.fill: parent; anchors.margins: 2;
                    border.color: "white"; border.width: 2
                    radius: width/2
                    color: "transparent"
                }
            }
        }

        MouseArea {
            id : wheelArea
            // Keep cursor in wheel
            function keepCursorInWheel(mouse, wheelArea, wheel) {
                root.state = 'editing'
                if (mouse.buttons & Qt.LeftButton) {
                    // cartesian to polar coords
                    var ro = Math.sqrt(Math.pow(mouse.x-wheel.width/2,2)+Math.pow(mouse.y-wheel.height/2,2));
                    var theta = Math.atan2(((mouse.y-wheel.height/2)*(-1)),((mouse.x-wheel.width/2)));

                    // Wheel limit
                    if (ro > wheel.width/2)
                        ro = wheel.width/2;

                    // polar to cartesian coords
                    var cursor = Qt.vector2d(0, 0);
                    cursor.x = Math.max(-pickerCursor.r, Math.min(wheelArea.width, ro*Math.cos(theta)+wheel.width/2)-pickerCursor.r);
                    cursor.y = Math.max(-pickerCursor.r, Math.min(wheelArea.height, wheel.height/2-ro*Math.sin(theta)-pickerCursor.r));

                    hue = Math.ceil((Math.atan2(((cursor.y+pickerCursor.r-wheel.height/2)*(-1)),((cursor.x+pickerCursor.r-wheel.width/2)))/(Math.PI*2)+0.5)*100)/100
                    if (hue < 0) hue = 0;
                    if (hue > 1) hue = 1;
                    saturation = Math.ceil(Math.sqrt(Math.pow(cursor.x+pickerCursor.r-width/2,2)+Math.pow(cursor.y+pickerCursor.r-height/2,2))/wheel.height*2*100)/100;
                    if (saturation < 0) saturation = 0;
                    if (saturation > 1) saturation = 1;
                    root.updateHS(hue, saturation);
                }
            }
            anchors.fill: parent
            onPositionChanged: keepCursorInWheel(mouse, wheelArea,  wheel)
            onPressed: keepCursorInWheel(mouse, wheelArea, wheel)
            onReleased: {
                root.state = ''
                root.accepted();
            }
        }
    }

}
