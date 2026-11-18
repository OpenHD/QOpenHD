import QtQuick 2.15

// Vector artwork stays crisp at every launcher size, without font dependencies.
Canvas {
    id: tab
    property color tabColor: "white"
    property bool emphasized: false
    onTabColorChanged: requestPaint()
    onEmphasizedChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        ctx.scale(width / 40, height / 150)
        ctx.strokeStyle = tabColor
        ctx.fillStyle = tabColor
        ctx.shadowColor = tabColor
        ctx.shadowBlur = emphasized ? 12 : 8
        ctx.lineWidth = 1.2
        ctx.beginPath()
        ctx.moveTo(1, 1)
        ctx.bezierCurveTo(1, 21, 32, 20, 32, 40)
        ctx.lineTo(32, 110)
        ctx.bezierCurveTo(32, 130, 1, 129, 1, 149)
        ctx.stroke()
        ctx.lineWidth = 4
        ctx.lineCap = "round"
        ctx.lineJoin = "round"
        ctx.beginPath()
        ctx.moveTo(12, 47)
        ctx.lineTo(21, 56)
        ctx.lineTo(12, 65)
        ctx.stroke()
        for (var i = 0; i < 3; ++i) {
            ctx.beginPath()
            ctx.arc(16, 84 + i * 10, 2.5, 0, Math.PI * 2)
            ctx.fill()
        }
    }
}
