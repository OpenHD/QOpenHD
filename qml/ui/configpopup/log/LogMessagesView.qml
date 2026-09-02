import QtQuick 2.12
import QtQuick.Controls 2.12

FocusScope {
    id: root
    property var m_log_model: _logQOpenHD
    signal backRequested()
    function gainFocus() { logList.forceActiveFocus() }

    ListView {
        id: logList
        anchors.fill: parent
        anchors.margins: 8
        model: root.m_log_model
        clip: true
        spacing: 2
        focus: true
        keyNavigationWraps: false
        highlightMoveDuration: 100
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

        delegate: Rectangle {
            width: logList.width
            height: Math.max(34, messageText.implicitHeight + 14)
            radius: 6
            color: ListView.isCurrentItem ? (settings_form.darkMode ? "#193d60" : "#e1effd")
                                               : (index % 2 ? settings_form.panelBackgroundRaised : "transparent")
            border.width: ListView.isCurrentItem && logList.activeFocus ? 1 : 0
            border.color: settings_form.accentColor
            Row {
                anchors.fill: parent
                anchors.leftMargin: 11
                anchors.rightMargin: 11
                spacing: 10
                Text {
                    width: 72
                    anchors.verticalCenter: parent.verticalCenter
                    text: model.tag
                    color: model.severity_color
                    font.pixelSize: 11
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    id: messageText
                    width: parent.width - 82
                    anchors.verticalCenter: parent.verticalCenter
                    text: model.message
                    color: settings_form.primaryText
                    font.pixelSize: 12
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: { logList.currentIndex = index; logList.forceActiveFocus() }
            }
        }

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Left || event.key === Qt.Key_Escape) {
                root.backRequested()
                event.accepted = true
            }
        }
    }
}
