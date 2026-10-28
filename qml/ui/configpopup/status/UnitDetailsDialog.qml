import QtQuick 2.12
import QtQuick.Controls 2.12

Popup {
    id: unitDetails
    function open_dialoque(system) { systemType = system; open() }
    property int systemType: 0
    readonly property var model: systemType === 0 ? _ohdSystemGround : _ohdSystemAir
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(parent.width - 24, 520)
    height: Math.min(parent.height - 24, detailContent.implicitHeight + 40)
    modal: true; focus: true; padding: 20
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    background: Rectangle { color: "#091f2e"; radius: 18; border.color: "#153c53" }
    contentItem: Flickable {
        contentHeight: detailContent.implicitHeight; clip: true
        Column {
            id: detailContent
            width: parent.width; spacing: 14
            Text { text: unitDetails.systemType === 0 ? qsTr("Ground station details") : qsTr("Air unit details"); color: settings_form.primaryText; font.pixelSize: 20; font.bold: true }
            StatusCardBodyOpenHD { m_is_ground: unitDetails.systemType === 0 }
            StatusCardRow { m_left_text: qsTr("CPU load"); m_icon: "\uf2db"; m_right_text: unitDetails.model.is_alive && unitDetails.model.curr_cpuload_perc >= 0 ? unitDetails.model.curr_cpuload_perc + " %" : qsTr("Not reported") }
            Row {
                spacing: 12
                Button { text: qsTr("Reboot"); enabled: !_qopenhd.debugMenuPreview && unitDetails.model.is_alive; onClicked: { unitDetails.close(); statusPanel.open_power_action_dialoque(unitDetails.systemType, true) } }
                Button { text: qsTr("Shutdown"); enabled: !_qopenhd.debugMenuPreview && unitDetails.model.is_alive; onClicked: { unitDetails.close(); statusPanel.open_power_action_dialoque(unitDetails.systemType, false) } }
                Button { text: qsTr("Close"); onClicked: unitDetails.close() }
            }
        }
    }
    onClosed: if (statusPanel.visible) statusPanel.gainFocus()
}
