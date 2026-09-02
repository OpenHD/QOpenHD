import QtQuick 2.12

Column {
    id: category
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: 8

    property string m_description: ""
    property bool m_hide_elements: false

    function updateChildren() {
        for (var i = 1; i < children.length; ++i)
            children[i].visible = !m_hide_elements
    }

    onM_hide_elementsChanged: updateChildren()
    Component.onCompleted: updateChildren()

    Rectangle {
        width: parent.width
        height: 40
        radius: 9
        color: settings_form.panelBackgroundRaised
        border.color: settings_form.lineColor

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 9
            Text {
                text: category.m_hide_elements ? "\uf0da" : "\uf0d7"
                color: settings_form.accentColor
                font.family: "Font Awesome 5 Free"
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: category.m_description
                color: settings_form.primaryText
                font.pixelSize: 12
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: category.m_hide_elements = !category.m_hide_elements
        }
    }
}
