import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12
import Qt.labs.settings 1.0

import OpenHD 1.0

// Special "Button" for the left selection bar
Item {

    // Filled with icon
    property string m_icon_text: "IC"
    // Filled with description
    property string m_description_text: "DESCR"

    // Stack layout element that should be shown when this element is selected
    property int m_selection_index: -1

    id: credits
    visible: true
    height:  46
    width: parent.width

    Button{
        id: genericButton

        height: parent.height
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter

        Text {
            id: genericIcon
            text: m_icon_text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: "Font Awesome 5 Free"
            font.pixelSize: 18
            height: parent.height
            width: 24
            anchors.left: parent.left
            anchors.leftMargin: 12
            color: "#dde4ed"
        }

        Text {
            id: genericDescription
            height: parent.height
            anchors.left: genericIcon.right
            anchors.leftMargin: 6

            text: qsTr(m_description_text)
            font.pixelSize: 15
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            color: mainStackLayout.currentIndex == m_selection_index ? "#33aaff" : "#dde4ed"
        }
        background: Rectangle {
            opacity: .5
            radius: 5
            //later this can be changed to focus
            color: genericButton.hovered ? "grey" : "transparent" // I update background color by this
        }
        onClicked: {
            mainStackLayout.currentIndex = m_selection_index
        }
    }
}
