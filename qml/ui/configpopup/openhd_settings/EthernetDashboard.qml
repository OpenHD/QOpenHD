import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../MenuTypography.js" as MenuTypography

ColumnLayout {
    id: root
    objectName: "ethernetDashboard"
    property var usage: null
    readonly property bool compact: width < 600
    readonly property color txColor: "#00baf2"
    readonly property color rxColor: "#d270ed"
    property var history: []
    spacing: 12
    function value(name, divisor, suffix, decimals) {
        var number = usage ? usage[name] : undefined
        return number !== undefined && number !== null && isFinite(Number(number))
                ? (Number(number) / divisor).toFixed(decimals) + suffix : qsTr("N/A")
    }
    function sample() {
        var points = history.slice(-59)
        points.push({tx: usage && usage.tx_bps !== null && usage.tx_bps !== undefined ? Number(usage.tx_bps) / 1000000 : -1,
                     rx: usage && usage.rx_bps !== null && usage.rx_bps !== undefined ? Number(usage.rx_bps) / 1000000 : -1})
        history = points
        chart.requestPaint()
    }
    Timer { interval: 500; running: root.visible; repeat: true; triggeredOnStart: true; onTriggered: root.sample() }
    GridLayout {
        Layout.fillWidth: true
        columns: root.compact ? 1 : 2
        columnSpacing: 12; rowSpacing: 12
        Rectangle {
            objectName: "ethernetPortTile"
            Layout.preferredWidth: root.compact ? -1 : Math.max(150, root.width * 0.23)
            Layout.fillWidth: root.compact
            Layout.preferredHeight: root.compact ? 110 : 198
            radius: 12; color: "#102739"; border.color: "#25475d"
            gradient: Gradient { GradientStop { position: 0; color: "#152f44" } GradientStop { position: 1; color: "#0c2031" } }
            Column {
                anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 18
                spacing: root.compact ? 4 : 10
                Text { visible: !root.compact; text: "\uf796"; font.family: "Font Awesome 5 Free"; font.pixelSize: 32; color: "#79d5ff" }
                Text { text: qsTr("Port Speed"); color: "#c3d7e6"; font.family: MenuTypography.family; font.pixelSize: 15 }
                Text { objectName: "ethernetPortSpeed"; text: root.usage && root.usage.capacity_bps > 0 ? root.value("capacity_bps",1000000," Mbit/s",0) : qsTr("N/A"); color: "#f2f7fc"; font.family: MenuTypography.family; font.pixelSize: 23; font.bold: true }
                Text { objectName: "ethernetDuplex"; text: root.usage && root.usage.port_duplex === 1 ? qsTr("Full-Duplex") : root.usage && root.usage.port_duplex === 0 ? qsTr("Half-Duplex") : qsTr("Duplex not reported"); color: "#a8c4d9"; font.family: MenuTypography.family; font.pixelSize: 13 }
            }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 198
            radius: 12; color: "#0d2133"; border.color: "#25475d"
            RowLayout {
                id: legend
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 14
                spacing: 6
                Text { Layout.fillWidth: true; Layout.minimumWidth: 0; elide: Text.ElideRight; text: qsTr("Throughput (Mbit/s)"); color: "#e3eff9"; font.family: MenuTypography.family; font.pixelSize: root.compact ? 12 : 14; font.bold: true }
                Rectangle { width: 10; height: 10; radius: 5; color: root.txColor }
                Text { text: "TX " + root.value("tx_bps",1000000,"",2); color: "#e3eff9"; font.family: MenuTypography.family; font.pixelSize: 12 }
                Rectangle { width: 10; height: 10; radius: 5; color: root.rxColor }
                Text { text: "RX " + root.value("rx_bps",1000000,"",2); color: "#e3eff9"; font.family: MenuTypography.family; font.pixelSize: 12 }
            }
            Canvas {
                id: chart
                objectName: "ethernetThroughputChart"
                anchors.top: legend.bottom; anchors.topMargin: 12; anchors.bottom: parent.bottom
                anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 14
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var left = 30, top = 5, bottom = height - 10, right = width - 3
                    var max = 20
                    for (var p=0;p<root.history.length;p++) max = Math.max(max, root.history[p].tx * 1.15, root.history[p].rx * 1.15)
                    max = Math.ceil(max / 5) * 5
                    ctx.font = "12px Archivo"; ctx.textAlign = "right"; ctx.textBaseline = "middle"
                    for (var i=0;i<=4;i++) {
                        var y = bottom - (bottom-top) * i/4
                        ctx.strokeStyle = "#203b50"; ctx.lineWidth = 1
                        ctx.beginPath(); ctx.moveTo(left,y); ctx.lineTo(right,y); ctx.stroke()
                        ctx.fillStyle = "#a8c1d5"; ctx.fillText((max*i/4).toFixed(max%4 ? 1 : 0), left-7,y)
                    }
                    for (var j=0;j<=6;j++) {
                        var x = left+(right-left)*j/6
                        ctx.beginPath();ctx.moveTo(x,top);ctx.lineTo(x,bottom);ctx.stroke()
                    }
                    function draw(key,color,fill) {
                        var start=-1
                        for (var n=0;n<=root.history.length;n++) {
                            var valid=n<root.history.length && root.history[n][key]>=0
                            if (valid && start<0) start=n
                            if ((valid && n<root.history.length-1) || start<0) continue
                            var end=valid?n:n-1
                            function px(index) {return right-(root.history.length-1-index)*(right-left)/59}
                            function py(index) {return bottom-root.history[index][key]/max*(bottom-top)}
                            function line() {
                                ctx.moveTo(px(start),py(start))
                                for (var k=start+1;k<=end;k++) {
                                    var mid=(px(k-1)+px(k))/2
                                    ctx.bezierCurveTo(mid,py(k-1),mid,py(k),px(k),py(k))
                                }
                            }
                            ctx.beginPath();line()
                            if (fill) {
                                ctx.lineTo(px(end),bottom);ctx.lineTo(px(start),bottom);ctx.closePath()
                                var gradient=ctx.createLinearGradient(0,top,0,bottom)
                                gradient.addColorStop(0,"#087aa7");gradient.addColorStop(1,"#071d2d")
                                ctx.fillStyle=gradient;ctx.fill();ctx.beginPath();line()
                            }
                            ctx.strokeStyle=color;ctx.lineWidth=2.3;ctx.stroke();start=-1
                        }
                    }
                    draw("tx",root.txColor,true);draw("rx",root.rxColor,false)
                }
            }
        }
    }
    GridLayout {
        Layout.fillWidth: true; columns: root.compact ? 2 : 4; columnSpacing: 12; rowSpacing: 12
        Repeater {
            model: [
                {title:qsTr("RTT"), icon:"\uf017", color:"#46bce9", value:root.value("rtt_us",1000," ms",1)},
                {title:qsTr("Jitter"), icon:"\uf83e", color:"#a59bff", value:root.value("jitter_us",1000," ms",1)},
                {title:qsTr("Loss"), icon:"\uf5fd", color:"#46bce9", value:root.value("probe_loss_permille",10,"%",1)},
                {title:qsTr("Errors"), icon:"\uf071", color:"#b8a9ff", value:root.value("send_errors",1,"",0)}]
            delegate: Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 76; radius: 12; color: "#102739"; border.color: "#25475d"
                Row {
                    anchors.centerIn: parent; spacing: root.compact ? 10 : 16
                    Text { anchors.verticalCenter: parent.verticalCenter; text:modelData.icon; color:modelData.color; font.family:"Font Awesome 5 Free"; font.pixelSize:26 }
                    Column { spacing: 4
                        Text { text:modelData.title; color:"#c3d7e6"; font.family:MenuTypography.family; font.pixelSize:14 }
                        Text { text:modelData.value; color:"#f1f7fc"; font.family:MenuTypography.family; font.pixelSize:18; font.bold:true }
                    }
                }
            }
        }
    }
}
