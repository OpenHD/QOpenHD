import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Rectangle {
    id: root
    property var host
    property int cardIndex: -1
    property bool keyboardSelected: false
    property bool remoteConfigured: _ohdSystemAir.fleetcontrol_lte_active ||
                                    _ohdSystemAir.fleetcontrol_lte_max_kbit > 0
    property bool linkActive: remoteConfigured ? _ohdSystemAir.fleetcontrol_lte_active
                                               : _fleetControlLte.active
    property int uploadKbit: remoteConfigured ? _ohdSystemAir.fleetcontrol_lte_upload_kbit
                                              : _fleetControlLte.uploadKbit
    property int downloadKbit: remoteConfigured ? _ohdSystemAir.fleetcontrol_lte_download_kbit
                                                : _fleetControlLte.downloadKbit
    property int maxKbit: remoteConfigured ? _ohdSystemAir.fleetcontrol_lte_max_kbit
                                           : _fleetControlLte.configuredMaxKbit

    radius: 10
    color: settings_form.panelBackgroundRaised
    border.color: keyboardSelected ? settings_form.accentColor : settings_form.lineColor
    border.width: keyboardSelected ? 2 : 1

    focus: true
    function controls() { return [root] }
    function gainFocus() { root.forceActiveFocus() }
    function keyNav(event) {
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Up) {
            if (host) host.collapseCard(cardIndex)
            event.accepted = true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            spacing: 8
            Rectangle {
                width: 28; height: 28; radius: 8
                color: root.linkActive ? Qt.rgba(0.1, 0.8, 0.35, 0.14) : Qt.rgba(1.0, 0.65, 0.1, 0.14)
                Text {
                    anchors.centerIn: parent
                    text: "\uf1eb"
                    color: root.linkActive ? settings_form.goodColor : "#f0a43c"
                    font.family: "Font Awesome 5 Free"
                    font.pixelSize: 15
                }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 0
                Text { text: qsTr("FleetControl LTE"); color: settings_form.primaryText; font.pixelSize: 12; font.bold: true }
                Text {
                    Layout.fillWidth: true
                    text: qsTr("Air-only encrypted uplink")
                    color: settings_form.secondaryText; font.pixelSize: 8; elide: Text.ElideRight
                }
            }
            Rectangle {
                width: stateText.implicitWidth + 14; height: 21; radius: 7
                color: root.linkActive ? Qt.rgba(0.1, 0.8, 0.35, 0.12) : Qt.rgba(1.0, 0.65, 0.1, 0.12)
                Text {
                    id: stateText; anchors.centerIn: parent
                    text: root.linkActive ? qsTr("ACTIVE") : qsTr("STANDBY")
                    color: root.linkActive ? settings_form.goodColor : "#f0a43c"
                    font.pixelSize: 8; font.bold: true
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.width < 310 ? 112 : 58
            columns: root.width < 310 ? 1 : 3
            columnSpacing: 0; rowSpacing: 0
            Repeater {
                model: [
                    {label: qsTr("UPLOAD"), value: root.uploadKbit + " kbit/s"},
                    {label: qsTr("DOWNLOAD"), value: root.downloadKbit + " kbit/s"},
                    {label: qsTr("CEILING"), value: root.maxKbit > 0 ? root.maxKbit + " kbit/s" : qsTr("AUTO")}
                ]
                delegate: Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    color: settings_form.panelBackground; border.color: settings_form.lineColor
                    Column {
                        anchors.centerIn: parent; spacing: 2
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: settings_form.secondaryText; font.pixelSize: 7; font.bold: true }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.value; color: settings_form.primaryText; font.pixelSize: 10; font.bold: true }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: statusColumn.implicitHeight + 22
            radius: 7; color: settings_form.panelBackground; border.color: settings_form.lineColor
            ColumnLayout {
                id: statusColumn
                anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 10; spacing: 4
                Text { text: qsTr("CONNECTION"); color: settings_form.secondaryText; font.pixelSize: 8; font.bold: true }
                Text {
                    Layout.fillWidth: true
                    text: root.remoteConfigured
                          ? (root.linkActive ? qsTr("Connected on OpenHD Air") : qsTr("Profile installed; waiting for tunnel"))
                          : _fleetControlLte.statusText
                    color: root.linkActive ? settings_form.goodColor : settings_form.secondaryText
                    font.pixelSize: 10; wrapMode: Text.WordWrap
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: accountColumn.implicitHeight + 22
            radius: 7; color: settings_form.panelBackground; border.color: settings_form.lineColor
            ColumnLayout {
                id: accountColumn
                anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 10; spacing: 4
                Text { text: qsTr("MANAGED BY FLEETCONTROL"); color: settings_form.secondaryText; font.pixelSize: 8; font.bold: true }
                Text {
                    Layout.fillWidth: true
                    text: qsTr("Sign in under OpenHD → FleetControl to bind this craft, verify its license and select MAVLink, Video 1 and Video 2 independently.")
                    color: settings_form.secondaryText; font.pixelSize: 9; wrapMode: Text.WordWrap
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: qsTr("Encoder ceiling: Air Camera → BITRATE_MBITS. Keep VARIABLE_BITRATE enabled.")
            color: settings_form.secondaryText; font.pixelSize: 8; wrapMode: Text.WordWrap
        }
        Item { Layout.fillHeight: true }
        RowLayout {
            Layout.fillWidth: true; Layout.preferredHeight: 25
            Text { Layout.fillWidth: true; text: qsTr("FleetControl encrypted network"); color: settings_form.secondaryText; font.pixelSize: 7 }
            Rectangle { width: 7; height: 7; radius: 4; color: root.linkActive ? settings_form.goodColor : "#f0a43c" }
        }
    }

}
