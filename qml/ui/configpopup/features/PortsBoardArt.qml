import QtQuick 2.12

Item {
    id: root
    property int platform: 20
    property var highlights: ({})
    property int inspectedPin: 0
    property real alignedScale: 0
    readonly property real drawingScale: alignedScale > 0 ? alignedScale : Math.min(width / 298, height / 426)
    readonly property real canvasTop: alignedScale > 0 ? 8 : (height - drawingScale * 426) / 2
    readonly property real headerStart: 66
    readonly property real headerPitch: 15

    function pinCenterY(pin) {
        return canvasTop + (headerStart + Math.floor((pin - 1) / 2) * headerPitch) * drawingScale
    }
    readonly property bool radxa: platform === 20
    readonly property bool pi5: platform === 13

    Canvas {
        id: canvas
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: root
            function onHighlightsChanged() { canvas.requestPaint() }
            function onInspectedPinChanged() { canvas.requestPaint() }
            function onPlatformChanged() { canvas.requestPaint() }
            function onDrawingScaleChanged() { canvas.requestPaint() }
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var zoom = root.drawingScale
            if (zoom <= 0) return
            ctx.translate((width - zoom * 298) / 2, root.canvasTop)
            ctx.scale(zoom, zoom)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            var ink = "#071422"
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
            function line(points, color, weight) {
                ctx.beginPath()
                ctx.moveTo(points[0], points[1])
                for (var i = 2; i < points.length; i += 2)
                    ctx.lineTo(points[i], points[i + 1])
                ctx.strokeStyle = color
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
            function text(value, x, y, size, color) {
                ctx.font = "bold " + size + "px sans-serif"
                ctx.textAlign = "center"
                ctx.fillStyle = color
                ctx.fillText(value, x, y)
            }
            function finish(x, y, w, h, colors) {
                var gradient = ctx.createLinearGradient(x, y, x + w, y + h)
                for (var i = 0; i < colors.length; ++i)
                    gradient.addColorStop(i / (colors.length - 1), colors[i])
                return gradient
            }
            function metal(x, y, w, h, socket) {
                box(x + 3, y + 5, w, h, 6, "#19283c", ink, 5)
                box(x, y, w, h, 6, finish(x, y, w, h, ["#ecf9ff", "#aebfd5", "#566881"]), ink, 5)
                line([x + 5, y + h - 7, x + 5, y + 6, x + w - 9, y + 6], "#f6fdff", 2.5)
                if (socket)
                    box(x + Math.round(w * 0.56), y + 9, Math.round(w * 0.28), h - 18, 3, socket, ink, 3)
            }
            function chip(x, y, w, h, name, brand, steel) {
                for (var i = 0; i < 8; ++i) {
                    var px = x + 9 + i * (w - 18) / 7
                    line([px, y - 6, px, y + 1], "#c4c8b6", 3)
                    line([px, y + h - 1, px, y + h + 6], "#c4c8b6", 3)
                }
                box(x + 3, y + 5, w, h, 7, "#09172a", ink, 6)
                var shade = steel ? ["#e7f4fc", "#8ea4bc", "#5a6d84"] : ["#385269", "#20354b", "#17283a"]
                box(x, y, w, h, 7, finish(x, y, w, h, shade), ink, 6)
                line([x + 6, y + h - 8, x + 6, y + 7, x + w - 9, y + 7], steel ? "#f4fbff" : "#7894a9", 2)
                dot(x + 13, y + 14, 3, steel ? "#475f7a" : "#9db2bc", ink, 1)
                text(brand, x + w / 2, y + h * 0.43, 10, steel ? "#1c2c3d" : "#b9d5e5")
                text(name, x + w / 2, y + h * 0.66, w < 55 ? 11 : 15, steel ? "#12273c" : "#f0f7ff")
            }

            // Top-side views. The Pi is rotated clockwise so its header reads down the page.
            var narrow = root.radxa
            var x0 = narrow ? 58 : 24
            var x1 = narrow ? 234 : 262
            var y0 = narrow ? 21 : 31
            var y1 = narrow ? 402 : 378
            var pcb = finish(x0, y0, x1 - x0, y1 - y0,
                             narrow ? ["#21967a", "#106356", "#073b36"]
                                    : ["#75a644", "#397c40", "#21563c"])
            box(x0 + 5, y0 + 9, x1 - x0, y1 - y0, 19, "#050f1c", ink, 10)
            box(x0, y0, x1 - x0, y1 - y0, 18, pcb, ink, 7)
            box(x0 + 4, y0 + 4, x1 - x0 - 8, y1 - y0 - 8, 15,
                "rgba(0,0,0,0)", narrow ? "#4bd8b3" : "#b4d666", 2.5)

            for (var trace = 0; trace < 10; ++trace) {
                var sx = x0 + 26 + (trace % 4) * 12
                var sy = y0 + 62 + trace * 24
                line([sx, sy, sx + 34, sy, sx + 48, sy + 14, x1 - 33, sy + 14],
                     narrow ? "#338d71" : "#91ab55", 1.6)
                dot(sx, sy, 2, "#c3ac6c", ink, 0.8)
            }

            var holes = [[x0 + 19,y0 + 20], [x1 - 19,y0 + 20],
                         [x0 + 19,y1 - 20], [x1 - 19,y1 - 20]]
            for (var h = 0; h < holes.length; ++h) {
                var hole = holes[h]
                dot(hole[0], hole[1], 10.5, "#ffd578", ink, 3)
                dot(hole[0], hole[1], 5.5, "#071722", "#aa7a3c", 2)
            }

            for (var j = 0; j < 24; ++j) {
                var dx = x0 + 48 + (j * 31) % (x1 - x0 - 80)
                var dy = y0 + 47 + (j * 41) % (y1 - y0 - 90)
                box(dx, dy, 12, 7, 1, j % 3 ? "#e7bb62" : "#253a49", ink, 2)
                line([dx + 2, dy + 2, dx + 9, dy + 2], "#e4e1ba", 1)
            }

            if (narrow) {
                metal(216, 64, 41, 44, "#33435c")
                metal(216, 135, 41, 45, "#355a7a")
                metal(210, 316, 40, 37, "#6b481d")
                chip(120, 54, 45, 35, "PMIC", "", false)
                chip(115, 124, 82, 47, "LPDDR4", "", false)
                chip(113, 197, 93, 89, "RK3566", "ROCKCHIP", false)
                for (var component = 0; component < 28; ++component) {
                    var cx = 104 + (component % 7) * 16
                    var cy = [108, 180, 295, 373][Math.floor(component / 7)]
                    box(cx, cy, 8, 5, 1, component % 3 ? "#e6bd65" : "#798693", ink, 1.2)
                    line([cx + 1, cy + 1, cx + 6, cy + 1], "#effad4", 0.9)
                }
                metal(116, 309, 69, 55, "")
                text("Wi-Fi", 149, 342, 11, "#24364b")
                line([114, 390, 124, 390, 124, 378, 133, 378, 133, 390, 141, 390], "#f7c867", 2.5)
            } else {
                metal(11, 73, 37, 36, "#354457")
                metal(13, 123, 35, 30, "#304050")
                metal(13, 163, 35, 30, "#304050")
                if (!root.pi5) metal(15, 223, 40, 35, "#151b22")
                metal(50, 337, 56, 56, root.pi5 ? "#2c3146" : "#b98d49")
                metal(117, 337, 53, 54, "#1c7bba")
                metal(183, 334, 53, 59, root.pi5 ? "#bd944e" : "#292c3a")
                chip(93, 107, 93, 76, root.pi5 ? "BCM2712" : "BCM2711", "BROADCOM", true)
                chip(93, 207, 63, 43, root.pi5 ? "RP1" : "LPDDR4", "", false)
                if (root.pi5) {
                    box(59, 204, 15, 29, 3, "#e9e9d7", ink, 3)
                    box(59, 243, 15, 29, 3, "#e9e9d7", ink, 3)
                    box(181, 69, 22, 10, 2, "#f1eddf", ink, 3)
                } else {
                    box(56, 259, 18, 57, 3, "#e1ddd1", ink, 4)
                    metal(177, 265, 40, 34, "")
                }
            }

            var headerX = narrow ? 69 : 218
            var headerY = root.headerStart
            var pitch = root.headerPitch
            box(headerX - 9, headerY - 10, 34, pitch * 19 + 20, 5, "#102436", ink, 4)
            for (var pin = 1; pin <= 40; ++pin) {
                var assignment = root.highlights[pin]
                var leftColumn = pin % 2 === 1
                var px = headerX + (leftColumn ? 0 : 15)
                var py = headerY + Math.floor((pin - 1) / 2) * pitch
                var active = pin === root.inspectedPin || assignment
                var pinColor = assignment ? assignment.color : "#f9cb64"
                if (active)
                    dot(px, py, 6.8, "#0c3146", pin === root.inspectedPin ? "#ffffff" : pinColor, 2)
                if (pin === 1)
                    box(px - 4, py - 4, 8, 8, 1, pinColor, "#583c23", 1.3)
                else
                    dot(px, py, 3.6, pinColor, "#583c23", 1.3)
                dot(px - 0.8, py - 0.8, 1, "#fff1b6", "transparent", 1)
            }
        }
    }
}
