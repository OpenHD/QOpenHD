import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

Column {
    id: category_column
    spacing: 0
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
        width: parent.width
        height: rowHeight*2 / 3;
        //color: "green"
        //color: "#8cbfd7f3"
        color: "#8cbfd7f3"


        Text {
            id: description
            text: qsTr(m_description)
            font.weight: Font.Bold
            font.pixelSize: 13
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.fill: parent

            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter

        }
        MouseArea{
            anchors.fill: description
            onClicked: {
                m_hide_elements=!m_hide_elements
                change_children_visibility()
            }
        }
        Rectangle{
            width: parent.width
            height: 2
            color: "black"
            anchors.bottom: parent.bottom
            anchors.left: parent.left
        }
    }


}

