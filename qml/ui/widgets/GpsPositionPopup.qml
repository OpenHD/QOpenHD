import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Shapes 1.12

Item {
    id: root
    property bool expanded: false
    property string latitudeText: qsTr("Unavailable")
    property string longitudeText: qsTr("Unavailable")
    property string textFont: "Sans Serif"
    property color panelColor: "#102235"
    property color textColor: "white"
    property color accentColor: textColor
    property real backgroundOpacity: 0.5
    property real textPixelSize: 16
    property real pointerX: width - 48
    readonly property real bodyHeight: height - 10
    readonly property real tipX: Math.max(20, Math.min(width - 20, pointerX))
    signal expansionRequested(bool expanded)
    function open() { expansionRequested(true) }
    function close() { expansionRequested(false) }
    visible: expanded
    width: Math.min(Math.ceil(latitudeLabel.implicitWidth) + Math.ceil(longitudeLabel.implicitWidth) + 48, parent.width - 16)
    height: 42

    Shape {
        anchors.fill: parent
        opacity: root.backgroundOpacity
        ShapePath {
            strokeWidth: 1
            strokeColor: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.3)
            fillColor: root.panelColor
            startX: 10; startY: 0
            PathLine { x: root.width; y: 0 }
            PathLine { x: root.width; y: root.bodyHeight }
            PathLine { x: root.tipX + 10; y: root.bodyHeight }
            PathLine { x: root.tipX; y: root.height }
            PathLine { x: root.tipX - 10; y: root.bodyHeight }
            PathLine { x: 0; y: root.bodyHeight }
            PathLine { x: 10; y: 0 }
        }
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: root.accentColor
            startX: 10; startY: 0
            PathLine { x: 16; y: 0 }
            PathLine { x: 6; y: root.bodyHeight }
            PathLine { x: 0; y: root.bodyHeight }
            PathLine { x: 10; y: 0 }
        }
    }
    RowLayout {
        x: 18; y: 0
        width: parent.width - 30
        height: root.bodyHeight
        spacing: 14
        Text {
            id: latitudeLabel
            objectName: "gpsPopupLatitude"
            text: root.latitudeText
            color: root.textColor
            font.family: root.textFont
            font.pixelSize: root.textPixelSize
            Layout.preferredWidth: Math.ceil(implicitWidth) + 2
            elide: Text.ElideRight
        }
        Text {
            id: longitudeLabel
            objectName: "gpsPopupLongitude"
            text: root.longitudeText
            color: root.textColor
            font.family: root.textFont
            font.pixelSize: root.textPixelSize
            Layout.preferredWidth: Math.ceil(implicitWidth) + 2
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }
    }
}
