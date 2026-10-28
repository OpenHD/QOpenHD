import QtQuick 2.12
import QtQuick.Controls 2.12

ToolButton {
    id: control
    property string glyph: "plus"
    property string label: ""
    property bool tooltipsEnabled: true
    property bool selected: false
    readonly property color ink: selected ? "#62bbff" : "#eff6ff"
    width: 36
    height: 36
    padding: 0
    hoverEnabled: true
    activeFocusOnTab: true
    Accessible.name: label
    background: Rectangle {
        radius: 11
        color: control.down ? "#405e7e" : control.selected ? "#22486a" : control.hovered ? "#2a415a" : "transparent"
        border.width: control.activeFocus ? 2 : 0
        border.color: "#62bbff"
        Behavior on color { ColorAnimation { duration: 100 } }
    }
    contentItem: Item {
        Canvas {
            id: iconCanvas
            anchors.centerIn: parent
            width: 24; height: 24
            scale: Math.min(1, (control.width - 4) / 24)
            onPaint: {
                var c = getContext("2d")
                c.clearRect(0, 0, width, height)
                c.strokeStyle = control.ink
                c.lineWidth = 1.8
                c.lineCap = "round"
                c.lineJoin = "round"
                c.beginPath()
                if (control.glyph === "plus" || control.glyph === "minus") {
                    c.moveTo(6, 12); c.lineTo(18, 12)
                    if (control.glyph === "plus") { c.moveTo(12, 6); c.lineTo(12, 18) }
                } else if (control.glyph === "locate") {
                    c.arc(12, 12, 6, 0, Math.PI * 2)
                    c.moveTo(12, 2); c.lineTo(12, 6)
                    c.moveTo(12, 18); c.lineTo(12, 22)
                    c.moveTo(2, 12); c.lineTo(6, 12)
                    c.moveTo(18, 12); c.lineTo(22, 12)
                } else if (control.glyph === "expand") {
                    c.moveTo(9, 4); c.lineTo(4, 4); c.lineTo(4, 9)
                    c.moveTo(15, 4); c.lineTo(20, 4); c.lineTo(20, 9)
                    c.moveTo(4, 15); c.lineTo(4, 20); c.lineTo(9, 20)
                    c.moveTo(15, 20); c.lineTo(20, 20); c.lineTo(20, 15)
                } else {
                    c.moveTo(4, 9); c.lineTo(9, 9); c.lineTo(9, 4)
                    c.moveTo(15, 4); c.lineTo(15, 9); c.lineTo(20, 9)
                    c.moveTo(4, 15); c.lineTo(9, 15); c.lineTo(9, 20)
                    c.moveTo(15, 20); c.lineTo(15, 15); c.lineTo(20, 15)
                }
                c.stroke()
                if (control.glyph === "locate") {
                    c.fillStyle = control.ink
                    c.beginPath(); c.arc(12, 12, 2, 0, Math.PI * 2); c.fill()
                }
            }
            Connections {
                target: control
                function onInkChanged() { iconCanvas.requestPaint() }
                function onGlyphChanged() { iconCanvas.requestPaint() }
            }
        }
    }
}
