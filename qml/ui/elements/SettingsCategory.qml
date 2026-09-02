import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12

import QtQuick.Controls.Material 2.12

Column {
    id: category_column
    spacing: 5
    anchors.left: parent.left
    anchors.right: parent.right

    property string m_description: "FILL ME"

    property bool m_hide_elements: false


    function change_children_visibility(){
        // 1st item is the headline itself
        for (var i = 1; i < category_column.children.length; i++){
            //console.log("item "+i);
            //console.log(category_column.children[i].propname);
            if(m_hide_elements){
                category_column.children[i].visible=false;
            }else{
                category_column.children[i].visible=true;
            }
        }
    }

    Component.onCompleted: {
        change_children_visibility()
    }

    Rectangle {
        id: categoryHeader
        width: parent.width
        height: rowHeight*2 / 3;
        radius: 8
        color: activeFocus
               ? (settings_form.darkMode ? "#174d82" : "#dcecff")
               : settings_form.panelBackgroundRaised
        border.color: activeFocus ? settings_form.accentColor : settings_form.lineColor
        border.width: activeFocus ? 2 : 1
        activeFocusOnTab: true

        Text {
            id: description
            text: qsTr(m_description)
            font.weight: Font.Bold
            font.pixelSize: 13
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 40
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            color: settings_form.primaryText
            elide: Text.ElideRight

        }

        Text{
            text: m_hide_elements ?  qsTr("\uf0d7") : qsTr("\uf0d8");
            font.family: "Font Awesome 5 Free";
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.rightMargin: 14
            font.pixelSize: 13
            color: settings_form.accentColor
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
        MouseArea{
            anchors.fill: parent
            onClicked: {
                categoryHeader.forceActiveFocus()
                m_hide_elements=!m_hide_elements
                change_children_visibility()
            }
        }

        Keys.onReturnPressed: {
            m_hide_elements = !m_hide_elements
            change_children_visibility()
        }
        Keys.onEnterPressed: {
            m_hide_elements = !m_hide_elements
            change_children_visibility()
        }

        /*Rectangle{
            implicitWidth: parent.width
            implicitHeight: parent.height
            color: "transparent"
            border.color: "black"
            border.width: 2
        }*/
    }


}

