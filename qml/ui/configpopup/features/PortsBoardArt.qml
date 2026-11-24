import QtQuick 2.12
import "../MenuTypography.js" as Typography

Item {
    id: root
    property bool radxa: true
    property var highlights: ({})
    property int inspectedPin: 0

    Canvas {
        id: canvas
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: root
            function onHighlightsChanged() { canvas.requestPaint() }
            function onInspectedPinChanged() { canvas.requestPaint() }
            function onRadxaChanged() { canvas.requestPaint() }
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var zoom = Math.min(width / 264, height / 382)
            ctx.translate((width - zoom * 264) / 2, (height - zoom * 382) / 2)
            ctx.scale(zoom, zoom)

            function box(x, y, w, h, r, fill, edge, weight) {
                ctx.beginPath()
                ctx.moveTo(x + r, y)
                ctx.arcTo(x + w, y, x + w, y + h, r)
                ctx.arcTo(x + w, y + h, x, y + h, r)
                ctx.arcTo(x, y + h, x, y, r)
                ctx.arcTo(x, y, x + w, y, r)
                ctx.closePath()
                ctx.fillStyle = fill
                ctx.fill()
                ctx.strokeStyle = edge
                ctx.lineWidth = weight
                ctx.stroke()
            }
            function dot(x, y, radius, fill, edge, weight) {
                ctx.beginPath()
                ctx.arc(x, y, radius, 0, Math.PI * 2)
                ctx.fillStyle = fill
                ctx.fill()
                ctx.strokeStyle = edge
                ctx.lineWidth = weight
                ctx.stroke()
            }
            function metal(x, y, w, h) {
                var gradient = ctx.createLinearGradient(x, y, x + w, y + h)
                gradient.addColorStop(0, "#d4e7f5")
                gradient.addColorStop(0.45, "#9aadc3")
                gradient.addColorStop(1, "#596b88")
                box(x, y, w, h, 5, gradient, "#091322", 5)
                box(x + 4, y + 5, 5, h - 10, 2, "#35485d", "#e2ebf3", 1)
            }

            var pcb = ctx.createLinearGradient(24, 20, 246, 359)
            pcb.addColorStop(0, "#157861")
            pcb.addColorStop(0.58, "#096052")
            pcb.addColorStop(1, "#063b36")
            box(22, 18, 228, 349, 21, "#031520", "#031520", 9)
            box(21, 13, 228, 349, 21, pcb, "#36d6c3", 3)
            box(29, 21, 212, 333, 16, "rgba(7,25,33,0.08)", "#2cb29b", 1)

            ctx.strokeStyle = "#3a9d82"
            ctx.lineWidth = 1.5
            for (var trace = 0; trace < 8; ++trace) {
                ctx.beginPath()
                ctx.moveTo(47, 83 + trace * 23)
                ctx.lineTo(84 + trace * 6, 83 + trace * 23)
                ctx.lineTo(106 + trace * 6, 105 + trace * 23)
                ctx.lineTo(205, 105 + trace * 23)
                ctx.stroke()
            }

            var holes = [[43, 36], [225, 36], [43, 337], [225, 337]]
            for (var h = 0; h < holes.length; ++h) {
                dot(holes[h][0], holes[h][1], 12, "#eabd54", "#0b3140", 3)
                dot(holes[h][0], holes[h][1], 6, "#081c25", "#88602c", 2)
            }

            var components = [[72,56],[98,52],[151,58],[180,63],[76,108],
                              [172,109],[79,230],[163,220],[75,281],[176,283],
                              [74,314],[101,319],[161,323],[181,310]]
            for (var j = 0; j < components.length; ++j) {
                var part = components[j]
                box(part[0], part[1], 15, 10, 2, "#f7cd77", "#102237", 3)
                ctx.fillStyle = "#e9f2dc"
                ctx.fillRect(part[0] + 1, part[1] + 2, 4, 6)
                ctx.fillRect(part[0] + 10, part[1] + 2, 4, 6)
            }

            if (root.radxa) {
                metal(8, 69, 49, 41)
                metal(4, 129, 49, 46)
                metal(4, 201, 49, 46)
                metal(90, 15, 60, 27)
                box(90, 239, 76, 65, 5, "#adb9ca", "#091322", 5)
                box(95, 244, 66, 55, 3, "#859ab1", "#d9e4ea", 1)
            } else {
                metal(7, 75, 52, 52)
                metal(7, 137, 52, 52)
                metal(7, 201, 58, 63)
                metal(80, 329, 37, 36)
                metal(132, 329, 37, 36)
                box(94, 243, 66, 55, 4, "#17283b", "#051420", 4)
            }

            box(92, 67, 60, 45, 5, "#142e3e", "#081621", 5)
            box(81, 123, 94, 88, 7, "#0b2033", "#06101e", 6)
            box(85, 127, 86, 80, 5, "#1c3348", "#66899e", 2)
            for (var lead = 0; lead < 9; ++lead) {
                ctx.fillStyle = "#adbfac"
                ctx.fillRect(91 + lead * 9, 116, 3, 6)
                ctx.fillRect(91 + lead * 9, 212, 3, 5)
            }

            box(196, 63, 37, 251, 7, "#0c2938", "#081624", 4)
            for (var pin = 1; pin <= 40; ++pin) {
                var info = root.highlights[pin]
                var x = pin % 2 === 1 ? 207 : 222
                var y = 72 + Math.floor((pin - 1) / 2) * 12.25
                var selected = pin === root.inspectedPin
                if (selected || info)
                    dot(x, y, 6, "rgba(22,91,117,0.6)", selected ? "#ffffff" : info.color, 2)
                dot(x, y, 3.5, info ? info.color : "#f9cc66", "#6a4323", 1)
            }
        }
    }

    Column {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -width * 0.04
        anchors.verticalCenterOffset: -Math.min(root.width / 264, root.height / 382) * 23
        spacing: 2
        Repeater {
            model: root.radxa ? ["Radxa", "ZERO 3W"] : ["Raspberry", "Pi 4 Model B"]
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData
                color: "#e2edf9"
                font.family: Typography.family
                font.bold: true
                font.pixelSize: Math.max(Typography.helper, Math.min(Typography.sectionTitle, root.width / 14))
                style: Text.Outline
                styleColor: "#102133"
            }
        }
    }
}
