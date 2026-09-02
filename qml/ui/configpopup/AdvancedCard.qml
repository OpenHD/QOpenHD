import QtQuick 2.12

Rectangle {
    id: root
    default property alias cardContent: content.data
    property int contentMargin: 16

    color: settings_form.panelBackground
    radius: 12
    border.width: 1
    border.color: settings_form.lineColor

    Item {
        id: content
        anchors.fill: parent
        anchors.margins: root.contentMargin
    }
}
