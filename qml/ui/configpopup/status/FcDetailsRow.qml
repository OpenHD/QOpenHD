import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Layouts 1.12
Item {
    id: row
    property string label
    property string icon
    property string value: qsTr("Not reported")
    property string detail
    property real percent: -1
    readonly property real labelX: icon.length ? 40 : 0
    property color valueColor: "#edf4fa"
    Layout.fillWidth: true
    implicitHeight: detail.length || percent >= 0 ? 48 : 36
    Text { x: 2; y: 9; text: row.icon; color: "#b8d9ec"; font.family: "Font Awesome 5 Free"; font.pixelSize: 21 }
    Text { x: row.labelX; y: 10; width: Math.max(0,parent.width * .43 - row.labelX); text: row.label; color: "#a9c2d3"; font.family: "Archivo"; font.pixelSize: MenuTypography.body; elide: Text.ElideRight }
    Text { x: parent.width * .43; y: 8; width: parent.width * .57; text: row.value; color: row.valueColor; font.family: "Archivo"; font.pixelSize: MenuTypography.body; elide: Text.ElideRight }
    Text { visible: row.detail.length > 0; x: parent.width * .43; y: 31; width: parent.width * .57; text: row.detail; color: "#a9c2d3"; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family; elide: Text.ElideRight }
    Rectangle {
        visible: row.percent >= 0; x: parent.width * .43; y: 34; width: parent.width * .57; height: 7; radius: 4; color: "#073c50"
        Rectangle { width: parent.width * Math.max(0,Math.min(100,row.percent))/100; height: parent.height; radius: parent.radius; color: "#08d080" }
    }
    Rectangle { x: row.labelX; anchors.bottom: parent.bottom; width: parent.width - row.labelX; height: 1; color: "#10384b" }
}
