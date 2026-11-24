import QtQuick 2.12
import "PortsBoardArtwork.js" as Artwork
import "../MenuTypography.js" as Typography

Item {
    id: root

    property string artwork: "unknown"
    property var highlights: ({})
    property int inspectedPin: 0
    property int inspectedAuxPin: 0
    property real alignedScale: 0
    property real alignedFirstRow: 0
    signal pinPicked(int pin, bool auxiliary)

    readonly property var geometry: Artwork.boards[artwork] || Artwork.boards.unknown
    readonly property bool imageReady: picture.status === Image.Ready
    readonly property real drawingScale: alignedScale > 0 ? alignedScale
        : Math.max(0, Math.min((width - 8) / geometry.w, height / geometry.h))
    readonly property real artHeight: geometry.h * drawingScale
    readonly property real artWidth: geometry.w * drawingScale
    readonly property real alignedHeight: alignedScale > 0
        ? Math.ceil(geometry.h * alignedScale + topForScale(alignedScale)) + 4 : 0
    readonly property real artLeft: (width - artWidth) / 2
    readonly property real artTop: alignedScale > 0 ? topForScale(alignedScale) : (height - artHeight) / 2
    readonly property var pcbBounds: geometry.pcb
        ? Qt.rect(artLeft + geometry.pcb[0] * drawingScale, artTop + geometry.pcb[1] * drawingScale,
                  geometry.pcb[2] * drawingScale, geometry.pcb[3] * drawingScale)
        : Qt.rect(0, 0, 0, 0)

    function topForScale(scale) {
        return geometry.header ? Math.max(4, alignedFirstRow - geometry.header.y * scale) : 4
    }

    function pointForPin(pin, auxiliary) {
        var header = auxiliary ? geometry.aux : geometry.header
        if (!header || pin < 1 || pin > header.rows * header.columns) return Qt.point(-1, -1)
        var slot = slotForPin(pin, header)
        return Qt.point(artLeft + (header.x + slot.column * header.columnGap) * drawingScale,
                        artTop + (header.y + slot.row * header.pitch) * drawingScale)
    }

    function pinCenterY(pin) {
        return pointForPin(pin, false).y
    }

    function slotForPin(pin, header) {
        if (header.order === "around")
            return pin <= header.rows ? {row: pin - 1, column: 0}
                                       : {row: header.rows * 2 - pin, column: 1}
        return {row: Math.floor((pin - 1) / header.columns), column: (pin - 1) % header.columns}
    }

    function pinForSlot(row, column, header) {
        if (header.order === "around")
            return column === 0 ? row + 1 : header.rows * 2 - row
        return row * header.columns + column + 1
    }

    function hitPin(x, y, header) {
        if (!header || drawingScale <= 0) return 0
        var boardX = (x - artLeft) / drawingScale
        var boardY = (y - artTop) / drawingScale
        var row = Math.round((boardY - header.y) / header.pitch)
        var column = header.columns === 1 ? 0 : Math.round((boardX - header.x) / header.columnGap)
        if (row < 0 || row >= header.rows || column < 0 || column >= header.columns) return 0
        if (Math.abs(boardY - header.y - row * header.pitch) > header.pitch / 2 ||
            Math.abs(boardX - header.x - column * header.columnGap) > Math.min(header.columnGap, header.pitch) / 2) return 0
        return pinForSlot(row, column, header)
    }

    Image {
        id: picture
        objectName: "portsBoardImage"
        x: root.artLeft
        y: root.artTop
        width: root.artWidth
        height: root.artHeight
        source: "artwork/" + root.artwork + ".png"
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }

    // Keep live highlights as scene-graph items on top of the decoded artwork.
    Repeater {
        model: root.imageReady ? [root.geometry.header, root.geometry.aux] : []
        delegate: Item {
            id: connector
            readonly property var header: modelData
            readonly property bool auxiliary: index === 1
            Repeater {
                model: connector.header ? connector.header.rows * connector.header.columns : 0
                delegate: Item {
                    id: marker
                    readonly property int pin: index + 1
                    readonly property var assignment: connector.auxiliary ? null : root.highlights[pin]
                    readonly property bool option: !!assignment && assignment.option === true
                    readonly property bool pending: !!assignment && assignment.pending === true
                    readonly property bool inspected: (connector.auxiliary ? root.inspectedAuxPin : root.inspectedPin) === pin
                    readonly property bool hovered: (connector.auxiliary ? hitArea.hoveredAuxPin : hitArea.hoveredPin) === pin
                    readonly property point pinPoint: root.pointForPin(pin, connector.auxiliary)
                    readonly property color signalColor: assignment ? assignment.color : "#edf8ff"
                    readonly property bool labelOnLeft: pinPoint.x < root.width / 2
                    readonly property var slot: root.slotForPin(pin, connector.header)
                    readonly property int otherPin: connector.header.columns === 2
                        ? root.pinForSlot(slot.row, 1 - slot.column, connector.header) : 0
                    readonly property bool nearEdge: labelOnLeft ? slot.column === 0 : slot.column === connector.header.columns - 1

                    objectName: (connector.auxiliary ? "portsBoardAuxMarker" : "portsBoardMarker") + pin
                    visible: !!assignment || inspected || hovered
                    width: Math.max(4, Math.min(23, connector.header.pitch * root.drawingScale * 1.12))
                    height: width
                    x: pinPoint.x - width / 2
                    y: pinPoint.y - height / 2
                    z: inspected ? 1 : 0

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Qt.rgba(marker.signalColor.r, marker.signalColor.g, marker.signalColor.b,
                                       marker.option || marker.pending ? 0.16 : 0.42)
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width * 0.80
                        height: width
                        radius: width / 2
                        color: "#112533"
                        border.color: marker.inspected ? "white" : marker.signalColor
                        border.width: Math.max(1, Math.min(2.5, marker.width * (marker.option ? 0.10 : 0.17)))
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        visible: !marker.option && !marker.pending
                        width: parent.width * 0.43
                        height: width
                        radius: width / 2
                        color: marker.signalColor
                    }
                    Text {
                        readonly property real gutter: marker.labelOnLeft ? root.artLeft : root.width - root.artLeft - root.artWidth
                        visible: !!marker.assignment && (marker.nearEdge || !root.highlights[marker.otherPin]) &&
                                 connector.header.pitch * root.drawingScale >= 14 && gutter >= implicitWidth + 10
                        x: marker.labelOnLeft ? root.artLeft - marker.x - implicitWidth - 4
                                              : root.artLeft + root.artWidth - marker.x + 4
                        anchors.verticalCenter: parent.verticalCenter
                        text: !marker.assignment ? "" : marker.option
                              ? marker.assignment.shortName + " " + marker.assignment.signal
                              : marker.assignment.signal + " " + marker.pin
                        color: marker.signalColor
                        font.family: Typography.family
                        font.pixelSize: Typography.helper
                    }
                }
            }
        }
    }

    MouseArea {
        id: hitArea
        anchors.fill: picture
        enabled: root.imageReady && !!root.geometry.header
        hoverEnabled: enabled
        property int hoveredPin: containsMouse
            ? root.hitPin(x + mouseX, y + mouseY, root.geometry.header) : 0
        property int hoveredAuxPin: containsMouse
            ? root.hitPin(x + mouseX, y + mouseY, root.geometry.aux) : 0
        cursorShape: hoveredPin || hoveredAuxPin ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: function(mouse) {
            var pin = root.hitPin(x + mouse.x, y + mouse.y, root.geometry.header)
            var auxiliaryPin = root.hitPin(x + mouse.x, y + mouse.y, root.geometry.aux)
            if (pin) root.pinPicked(pin, false)
            else if (auxiliaryPin) root.pinPicked(auxiliaryPin, true)
        }
    }
}
