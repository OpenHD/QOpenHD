import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Layouts 1.12
Rectangle {
    id: section
    property string title
    property string icon
    default property alias contents: body.data
    color: "#051f2f"; radius: 12; border.color: "#0d4059"
    implicitHeight: body.implicitHeight + 66
    Text { x: 18; y: 14; text: section.icon; font.family: "Font Awesome 5 Free"; font.pixelSize: MenuTypography.sectionIcon; color: "#12a8f3" }
    Text { x: 54; y: 16; text: section.title; color: "#edf4fa"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.sectionTitle; font.bold: true }
    ColumnLayout { id: body; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 18; anchors.topMargin: 52; spacing: 0 }
}
