import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

//
// Similar behvaiour to android Toast
// See c++ QOpenHD instance for more info
//
Item {
    id: card_toast
    z: 22.0

    property string m_text: "FILL ME TEXT"

    width: parent.width
    height: parent.height

    function get_width(){
        var parent_width= parent.width
        if(parent_width>500){
            return 500;
        }
        return parent.width
    }
    function get_bottom_margin(){
        //return 50;
        var parent_height=parent.height
        return parent_height * 0.15;
    }

    Rectangle {
        id: background
        radius: 8
        //color: "green"
        //color: "white"
        color: "black"
        opacity: 0.7
        border.width: 3
        border.color: "white"

        width: get_width()
        height: 100

        //anchors.centerIn: parent
        anchors.bottom: parent.bottom
        anchors.bottomMargin: get_bottom_margin()
        anchors.horizontalCenter: parent.horizontalCenter

        Text{
            text: m_text
            wrapMode: Text.WordWrap
            width: parent.width-24
            height: parent.height-24
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: "white"
            //
            font.pointSize: 17
            minimumPointSize: 10
            fontSizeMode: Text.Fit
        }
    }




}
