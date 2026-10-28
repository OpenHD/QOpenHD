import QtQuick 2.12

Item {
    id: root
    implicitHeight: 24
    property var segments: []
    property real denominator: 100
    property color emptyColor: "#294154"
    Canvas {
        anchors.fill: parent
        property var values: root.segments
        property real total: root.denominator
        property color empty: root.emptyColor
        onValuesChanged: requestPaint()
        onTotalChanged: requestPaint()
        onEmptyChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            var ctx=getContext("2d"), w=width, h=height, r=Math.min(8,h/2)
            ctx.reset();ctx.clearRect(0,0,w,h);ctx.save();ctx.beginPath()
            ctx.moveTo(r,0);ctx.lineTo(w-r,0);ctx.quadraticCurveTo(w,0,w,r)
            ctx.lineTo(w,h-r);ctx.quadraticCurveTo(w,h,w-r,h);ctx.lineTo(r,h)
            ctx.quadraticCurveTo(0,h,0,h-r);ctx.lineTo(0,r);ctx.quadraticCurveTo(0,0,r,0)
            ctx.closePath();ctx.clip();ctx.fillStyle=empty;ctx.fillRect(0,0,w,h)
            var x=0
            for(var i=0;i<values.length;i++) {
                var span=w*Math.max(0,Number(values[i].value))/Math.max(1,total)
                if(span>0) {
                    ctx.fillStyle=values[i].color;ctx.fillRect(x,0,span,h)
                    if(x>0) {ctx.fillStyle="#142b3d";ctx.fillRect(x,0,2,h)}
                    x+=span
                }
            }
            ctx.restore()
        }
    }
}
