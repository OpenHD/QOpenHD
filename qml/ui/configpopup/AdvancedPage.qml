import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Window 2.12

FocusScope {
    id: root

    property string pageIcon: ""
    property string pageTitle: ""
    property string pageSubtitle: ""
    property Item initialFocusItem: null
    default property alias pageContent: content.data
    readonly property alias contentItem: content
    signal backRequested()
    Material.theme: settings_form.darkMode ? Material.Dark : Material.Light
    Material.accent: settings_form.accentColor

    function gainFocus() {
        if (initialFocusItem && initialFocusItem.visible && initialFocusItem.enabled)
            initialFocusItem.forceActiveFocus()
        else
            content.forceActiveFocus()
    }

    Rectangle {
        anchors.fill: parent
        color: settings_form.pageBackground
    }

    Row {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 18
        anchors.leftMargin: settings_form.compactSidebar ? 16 : 24
        spacing: 13

        Rectangle {
            width: 44
            height: 44
            radius: 11
            color: settings_form.darkMode ? "#153b65" : "#dcecff"

            Text {
                anchors.centerIn: parent
                text: root.pageIcon
                color: settings_form.accentColor
                font.family: "Font Awesome 5 Free"
                font.pixelSize: 21
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            Text {
                text: root.pageTitle
                color: settings_form.primaryText
                font.pixelSize: Math.max(18, Math.min(23, root.width / 48))
                font.bold: true
            }
            Text {
                text: root.pageSubtitle
                color: settings_form.secondaryText
                font.pixelSize: 12
            }
        }
    }

    Item {
        id: content
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 14
        anchors.leftMargin: settings_form.compactSidebar ? 14 : 24
        anchors.rightMargin: settings_form.compactSidebar ? 14 : 24
        anchors.bottomMargin: 18
        focus: true
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            root.backRequested()
            event.accepted = true
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Right
                   || event.key === Qt.Key_Up || event.key === Qt.Key_Left) {
            var current = root.Window.window ? root.Window.window.activeFocusItem : null
            if (current) {
                var forward = event.key === Qt.Key_Down || event.key === Qt.Key_Right
                var next = current.nextItemInFocusChain(forward)
                if (next && next !== current && next !== root) {
                    next.forceActiveFocus()
                    event.accepted = true
                }
            }
        }
    }
}
