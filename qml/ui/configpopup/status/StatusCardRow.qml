import QtQuick 2.12
import QtQuick.Controls 2.12

Item {
    id: row
    width: parent ? parent.width : 0
    height: visible ? 34 : 0

    property string m_left_text: qsTr("LEFT")
    property string m_right_text: qsTr("RIGHT")
    property bool m_has_error: false
    property color m_right_text_color: settings_form.goodColor
    property color m_right_text_color_error: settings_form.errorColor
    property string m_error_text: qsTr("NONE")
    property bool m_error_view: false

    function iconForLabel(label) {
        var value = label.toLowerCase()
        if (value.indexOf("platform") >= 0 || value.indexOf("firmware") >= 0) return "\uf1b3"
        if (value.indexOf("version") >= 0) return "\uf013"
        if (value.indexOf("link") >= 0) return "\uf0c1"
        if (value.indexOf("hidden") >= 0) return "\uf070"
        if (value.indexOf("wifi") >= 0) return "\uf1eb"
        if (value.indexOf("sys") >= 0) return "\uf2db"
        if (value.indexOf("ping") >= 0) return "\uf1eb"
        if (value.indexOf("type") >= 0) return "\uf2d2"
        if (value.indexOf("alive") >= 0) return "\uf2f2"
        if (value.indexOf("shared") >= 0) return "\uf0fe"
        return "\uf111"
    }

    Rectangle {
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 1; color: settings_form.lineColor; opacity: 0.72
    }
    Text {
        id: icon
        anchors.left: parent.left; anchors.leftMargin: row.width < 260 ? 10 : 19; anchors.verticalCenter: parent.verticalCenter
        width: row.width < 260 ? 15 : 18
        text: iconForLabel(m_left_text)
        color: m_has_error ? settings_form.errorColor : settings_form.secondaryText
        font.family: "Font Awesome 5 Free"; font.pixelSize: row.width < 260 ? 10 : 12
        horizontalAlignment: Text.AlignHCenter
    }
    Text {
        id: label
        anchors.left: icon.right; anchors.leftMargin: row.width < 260 ? 6 : 10; anchors.verticalCenter: parent.verticalCenter
        width: Math.max(56, row.width * 0.34)
        text: m_left_text.replace(":", "")
        color: settings_form.primaryText
        font.pixelSize: row.width < 260 ? 10 : 12
        elide: Text.ElideRight
    }
    Text {
        anchors.left: label.right; anchors.right: parent.right; anchors.rightMargin: row.width < 260 ? 10 : 19
        anchors.verticalCenter: parent.verticalCenter
        text: m_right_text
        color: m_has_error ? m_right_text_color_error : m_right_text_color
        font.pixelSize: row.width < 260 ? 10 : 12
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
    }
    MouseArea {
        anchors.fill: parent
        enabled: m_has_error
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: _messageBoxInstance.set_text_and_show(m_error_text)
    }
}
