import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Popup {
    id: popup
    objectName: "linkAllocationPopup"
    property var usage: null
    property var linkUsages: []
    readonly property var displayedUsages: linkUsages && linkUsages.length ? linkUsages.slice().sort(function(a,b) { return Number(a.id)-Number(b.id) }) : [usage]
    readonly property var primarySection: sections.count ? sections.itemAt(0) : null
    readonly property var allocation: primarySection ? primarySection.allocation : null
    readonly property var streams: primarySection ? primarySection.streams : []
    readonly property var trafficRows: primarySection ? primarySection.trafficRows : []
    readonly property int draftPercent: primarySection ? primarySection.draftPercent : 0
    readonly property bool connected: primarySection ? primarySection.connected : false
    function dynamicCount() { return primarySection ? primarySection.dynamicCount() : 0 }
    function datalinkBps() { return primarySection ? primarySection.datalinkBps() : -1 }
    function categoryBps(id) { return primarySection ? primarySection.categoryBps(id) : -1 }
    function rateBps(value) { return primarySection ? primarySection.rateBps(value) : qsTr("Not reported") }
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(parent.width - 24, 800)
    height: Math.min(parent.height - 24, 38 + 12 + linkContents.implicitHeight + padding * 2)
    padding: 16
    modal: true; dim: true; focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    background: Rectangle { radius: 16; color: "#041d2c"; border.color: "#0089c4" }
    Overlay.modal: Rectangle { color: "#af000b12" }
    onOpened: {
        linksScroll.contentY = 0
        for (var i=0; i<sections.count; i++) {
            var section = sections.itemAt(i)
            if (section) section.draftPercent = section.primaryPercent
        }
    }
    contentItem: Item {
        RowLayout {
            id: titleRow
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            height: 38; spacing: 18
            Text { text: "\uf0c1"; font.family: "Font Awesome 5 Free"; font.pixelSize: MenuTypography.sectionIcon; color: "#00a8ed" }
            Text { Layout.fillWidth: true; text: qsTr("Link Allocation"); color: "#edf4fa"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.dialogTitle; font.bold: true }
            ToolButton {
                objectName: "closeLinkAllocation"; implicitWidth: 40; implicitHeight: MenuTypography.controlHeight
                Accessible.name: qsTr("Close link allocation")
                onClicked: popup.close()
                background: Rectangle { radius: 9; color: parent.hovered ? "#15435b" : "#092a3c"; border.color: "#10374b" }
                contentItem: Text { text: "\uf00d"; font.family: "Font Awesome 5 Free"; font.pixelSize: MenuTypography.sectionIcon; color: "#edf4fa"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
        }
        Flickable {
            id: linksScroll
            objectName: "linkAllocationScroll"
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: titleRow.bottom; anchors.bottom: parent.bottom; anchors.topMargin: 12
            contentWidth: width; contentHeight: linkContents.implicitHeight
            clip: true; boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; active: linksScroll.contentHeight > linksScroll.height }
            Column {
                id: linkContents; width: parent.width; spacing: 20
                Repeater {
                    id: sections
                    // Keep editors alive when live telemetry replaces the snapshots.
                    model: popup.displayedUsages.length
                    delegate: LinkAllocationSection { width: linkContents.width; usage: popup.displayedUsages[index] }
                }
            }
        }
    }
}
