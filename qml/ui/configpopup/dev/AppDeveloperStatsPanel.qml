import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import OpenHD 1.0
import ".."

AdvancedPage {
    id: root
    pageIcon: "\uf0ad"
    pageTitle: qsTr("DEVELOPER TOOLS")
    pageSubtitle: qsTr("Diagnostics, service control and system information")
    initialFocusItem: restartService
    onBackRequested: settings_form.side_bar_regain_focus()

    function yes_or_no_as_string(yes) { return yes ? "Y" : "N" }
    function get_features_string() {
        return "AVCODEC:" + yes_or_no_as_string(QOPENHD_ENABLE_VIDEO_VIA_AVCODEC)
                + "  MMAL:" + yes_or_no_as_string(QOPENHD_HAVE_MMAL)
                + "  GSTREAMER:" + yes_or_no_as_string(QOPENHD_ENABLE_GSTREAMER_QMLGLSINK)
    }
    function showSystemInfo(systemObject, title) {
        terminalTextArea.text = qsTr("%1 System Information:\n\n").arg(title)
        if (!systemObject) {
            terminalTextArea.text += qsTr("Information unavailable.")
            return
        }
        for (var key in systemObject) {
            if (systemObject.hasOwnProperty(key) && typeof systemObject[key] !== "function")
                terminalTextArea.text += key + ": " + systemObject[key] + "\n"
        }
    }

    ScrollView {
        id: scroll
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: scroll.availableWidth
            spacing: 10

            AdvancedCard {
                Layout.fillWidth: true
                Layout.preferredHeight: width > 700 ? 104 : 174
                GridLayout {
                    anchors.fill: parent
                    columns: width > 700 ? 4 : 2
                    columnSpacing: 8
                    rowSpacing: 8
                    Repeater {
                        model: [
                            { label: qsTr("VERSION"), value: _qopenhd.version_string },
                            { label: qsTr("PLATFORM"), value: Qt.platform.os.toUpperCase() },
                            { label: qsTr("WINDOW"), value: _qrenderstats.window_width + " x " + _qrenderstats.window_height },
                            { label: qsTr("TELEMETRY"), value: _mavlinkTelemetry.telemetry_pps_in + " pps" }
                        ]
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 8
                            color: settings_form.panelBackgroundRaised
                            Column {
                                anchors.centerIn: parent
                                spacing: 4
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: settings_form.secondaryText; font.pixelSize: 9; font.bold: true }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.value; color: settings_form.primaryText; font.pixelSize: 13; font.bold: true }
                            }
                        }
                    }
                }
            }

            AdvancedCard {
                Layout.fillWidth: true
                Layout.preferredHeight: actionGrid.implicitHeight + 32
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Text { text: qsTr("ACTIONS"); color: settings_form.accentColor; font.pixelSize: 12; font.bold: true }
                    GridLayout {
                        id: actionGrid
                        Layout.fillWidth: true
                        columns: width > 760 ? 3 : (width > 430 ? 2 : 1)
                        rowSpacing: 8
                        columnSpacing: 8
                        AdvancedActionButton { id: restartService; Layout.fillWidth: true; text: qsTr("Restart local service"); iconText: "\uf2f1"; onClicked: _qopenhd.restart_local_oenhd_service() }
                        AdvancedActionButton { id: localIp; Layout.fillWidth: true; text: qsTr("Show local IP"); iconText: "\uf0ac"; onClicked: text = _qopenhd.show_local_ip() }
                        AdvancedActionButton { id: groundLog; Layout.fillWidth: true; text: qsTr("Write Ground log"); iconText: "\uf56e"; onClicked: text = _qopenhd.write_local_log() }
                        AdvancedActionButton { Layout.fillWidth: true; text: qsTr("Reapply telemetry rates"); iconText: "\uf021"; onClicked: _mavlinkTelemetry.re_apply_rates() }
                        AdvancedActionButton { visible: _qopenhd.is_linux(); Layout.fillWidth: true; text: qsTr("Start OpenHD"); iconText: "\uf04b"; onClicked: _qopenhd.sysctl_openhd(0) }
                        AdvancedActionButton { visible: _qopenhd.is_linux(); Layout.fillWidth: true; text: qsTr("Stop OpenHD"); iconText: "\uf04d"; onClicked: _qopenhd.sysctl_openhd(1) }
                        AdvancedActionButton { visible: _qopenhd.is_linux(); Layout.fillWidth: true; text: qsTr("Enable OpenHD"); iconText: "\uf00c"; onClicked: _qopenhd.sysctl_openhd(2) }
                        AdvancedActionButton { visible: _qopenhd.is_linux(); Layout.fillWidth: true; text: qsTr("Disable OpenHD"); iconText: "\uf05e"; onClicked: _qopenhd.sysctl_openhd(3) }
                        AdvancedActionButton { Layout.fillWidth: true; text: qsTr("Restart QOpenHD"); iconText: "\uf2f1"; onClicked: qopenhdservicedialoque.open_dialoque(0) }
                        AdvancedActionButton { Layout.fillWidth: true; text: qsTr("Close QOpenHD"); destructive: true; iconText: "\uf011"; onClicked: qopenhdservicedialoque.open_dialoque(1) }
                    }
                }
            }

            AdvancedCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 245
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: qsTr("SYSTEM INSPECTOR"); color: settings_form.accentColor; font.pixelSize: 12; font.bold: true }
                        Item { Layout.fillWidth: true }
                        AdvancedActionButton { text: qsTr("Air"); onClicked: root.showSystemInfo(_ohdSystemAir, qsTr("Air")) }
                        AdvancedActionButton { text: qsTr("Ground"); onClicked: root.showSystemInfo(_ohdSystemGround, qsTr("Ground")) }
                        AdvancedActionButton { text: qsTr("MAVLink"); onClicked: root.showSystemInfo(_fcMavlinkSystem, qsTr("MAVLink")) }
                        AdvancedActionButton { text: qsTr("Clear"); iconText: "\uf2ed"; onClicked: terminalTextArea.clear() }
                    }
                    TextArea {
                        id: terminalTextArea
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        readOnly: true
                        wrapMode: TextArea.WrapAtWordBoundaryOrAnywhere
                        color: settings_form.primaryText
                        selectionColor: settings_form.accentColor
                        selectedTextColor: "white"
                        font.family: "Roboto Mono"
                        font.pixelSize: 11
                        background: Rectangle { color: settings_form.pageBackground; radius: 7; border.color: settings_form.lineColor }
                    }
                }
            }

            Text { Layout.fillWidth: true; text: qsTr("Build features: %1").arg(root.get_features_string()); color: settings_form.secondaryText; font.pixelSize: 10; wrapMode: Text.WordWrap }
        }
    }

    QOpenHDServiceDialoque { id: qopenhdservicedialoque }
}
