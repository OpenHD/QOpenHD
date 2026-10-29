import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12

Item {
    id: row
    width: parent ? parent.width : 0
    height: visible ? 56 : 0
    property string m_left_text: ""
    property string m_right_text: ""
    property string m_icon: "\uf2db"
    property string m_value_icon: ""
    property bool m_status_dot: false
    property bool m_separator: true
    property bool m_has_error: false
    property color m_right_text_color: "#dce6ef"
    property color m_right_text_color_error: settings_form.errorColor
    property string m_error_text: ""
    property bool m_error_view: false
    Rectangle {
        visible: row.m_separator
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.leftMargin: 22; anchors.rightMargin: 22
        height: 1; color: "#15384c"
    }
    Text {
        id: icon
        anchors.left: parent.left; anchors.leftMargin: 28; anchors.verticalCenter: parent.verticalCenter
        width: 24
        text: row.m_icon; color: "#d9e9f6"
        font.family: "Font Awesome 5 Free"; font.pixelSize: 23
        horizontalAlignment: Text.AlignHCenter
    }
    Text {
        id: label
        anchors.left: icon.right; anchors.leftMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        text: row.m_left_text.replace(":", ""); color: "#dce6ef"
        font.family: "Archivo"; font.pixelSize: MenuTypography.body
        width: row.width * 0.35
        elide: Text.ElideRight
    }
    Item {
        id: valueColumn
        anchors.left: label.right; anchors.leftMargin: 10
        anchors.right: parent.right; anchors.rightMargin: 30
        height: parent.height
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            Rectangle {
                visible: row.m_status_dot
                anchors.verticalCenter: parent.verticalCenter
                width: visible ? 20 : 0; height: width; radius: width / 2
                color: value.color
            }
            Text {
                visible: row.m_value_icon !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: row.m_value_icon; color: "#38a5ff"
                font.family: "Font Awesome 5 Free"; font.pixelSize: 26
            }
            Text {
                id: value
                objectName: "statusRowValue"
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, Math.max(0, valueColumn.width - (row.m_status_dot ? 32 : 0) - (row.m_value_icon !== "" ? 42 : 0)))
                text: row.m_right_text
                color: row.m_has_error ? row.m_right_text_color_error : row.m_right_text_color
                font.family: "Archivo"; font.pixelSize: MenuTypography.body
                horizontalAlignment: Text.AlignRight; elide: Text.ElideRight
            }
        }
    }
}
