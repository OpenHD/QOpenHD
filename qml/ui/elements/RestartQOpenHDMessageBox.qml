import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../configpopup"

FocusScope {
    id: root
    width: Math.min(430, parent ? parent.width - 32 : 430)
    height: 196
    anchors.centerIn: parent
    z: 30
    visible: _restartqopenhdmessagebox.visible

    readonly property var _sf: { try { return settings_form } catch(e) { return null } }
    QtObject {
        id: _fallback
        readonly property bool darkMode: true
        readonly property color primaryText: "#f2f6fb"
        readonly property color secondaryText: "#aebdcb"
        readonly property color lineColor: "#26394c"
        readonly property color panelBackground: "#102235"
        readonly property color panelBackgroundRaised: "#15283b"
        readonly property color accentColor: "#278cff"
        readonly property color errorColor: "#ff4e5d"
    }
    readonly property var _theme: _sf ? _sf : _fallback

    Rectangle {
        parent: root.parent
        anchors.fill: parent
        z: 29
        visible: root.visible
        color: _theme.darkMode ? "#99030d17" : "#660b1b2d"
        MouseArea { anchors.fill: parent }
    }

    function closePopup() {
        _restartqopenhdmessagebox.hide_element()
        if (typeof hudOverlayGrid !== "undefined") hudOverlayGrid.regain_focus()
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: _theme.panelBackgroundRaised
        border.width: root.activeFocus ? 2 : 1
        border.color: root.activeFocus ? _theme.accentColor : _theme.lineColor
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Rectangle {
                width: 34; height: 34; radius: 9
                color: _theme.darkMode ? "#3b2d14" : "#fff1d6"
                Text {
                    anchors.centerIn: parent
                    text: "\uf2f1"
                    font.family: "Font Awesome 5 Free"
                    font.pixelSize: 15
                    color: _theme.darkMode ? "#ffbf69" : "#9a5700"
                }
            }
            Text {
                Layout.fillWidth: true
                text: qsTr("Restart QOpenHD")
                color: _theme.primaryText
                font.pixelSize: 16
                font.bold: true
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: _restartqopenhdmessagebox.text
            color: _theme.secondaryText
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            verticalAlignment: Text.AlignTop
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Item { Layout.fillWidth: true }
            AdvancedActionButton {
                id: cancelButton
                Layout.preferredWidth: 112
                text: qsTr("Cancel")
                iconText: "\uf00d"
                onClicked: root.closePopup()
                KeyNavigation.right: restartButton
            }
            AdvancedActionButton {
                id: restartButton
                Layout.preferredWidth: 132
                text: qsTr("Restart")
                iconText: "\uf2f1"
                primary: true
                onClicked: {
                    _restartqopenhdmessagebox.hide_element()
                    _qopenhd.quit_qopenhd()
                }
                KeyNavigation.left: cancelButton
            }
        }
    }

    onVisibleChanged: if (visible) {
        forceActiveFocus()
        Qt.callLater(function() { cancelButton.forceActiveFocus() })
    }
    Keys.onEscapePressed: root.closePopup()
}
