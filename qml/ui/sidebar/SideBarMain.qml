import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"


Item {
    id: sidebar
    width: 64
    height: 24
    visible: settings.show_sidebar || m_extra_is_visible

    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter


    property int secondaryUiWidth: 335
    property int secondaryUiHeight: 420
    property string secondaryUiColor: "#000"
    property real secondaryUiOpacity: 0.75
    property string mainDarkColor: "#302f30"
    property string highlightColor: "#555"

    property int selectedItemIndex: -1

    // Set to true if the sidebar is active (and some HUD elements shall be disabled)
    property bool m_is_active : false


    property bool m_extra_is_visible: false
    property int m_stack_index: -1;


    // Gives (keyboard / joystick) control to this element
    function open_and_take_control(){
        m_extra_is_visible=true;
        m_stack_index=0;
        m_is_active = true
        focus=true;
    }

    // This is called whenever the user clicks on the 'WBLIink' widget
    function open_link_category(){
        m_extra_is_visible=true;
        m_stack_index=0;
        m_is_active = true
    }

    // This is called when the user clicks on the configure button of the CAM1 / CAM2 widget
    function open_video_stream_category(is_primary){
        if(is_primary){
            m_extra_is_visible=true;
            m_stack_index=3;
            m_is_active = true
        }
    }

    // CLoses the sidebar and gives focus back to HUD overlay grid
    function close(){
        m_stack_index=-1;
        m_is_active=false;
        hudOverlayGrid.focus=true;
    }



    // Item that opens up the sidebar
    Item {
        id: uiButton
        width: 32
        height: 32
        anchors.verticalCenter: parent.verticalCenter
        MouseArea {
            id: mouseArea1
            anchors.fill: parent
            onClicked: {
                open_and_take_control()
            }
            Rectangle {
                width: parent.width
                height: parent.height
                color: "transparent"
                RowLayout {
                    width: parent.width
                    height: parent.height

                    Text {
                        text: "\uf054"
                        font.pixelSize: 16
                        opacity: 1.0
                        font.family: "Font Awesome 5 Free"
                        color: "grey"
                    }
                }
            }
        }
    }


    // Item that manages the stack on the right
    Rectangle{
        id: stack_manager
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: secondaryUiHeight / 8 //number of items
        height: secondaryUiHeight
        color: highlightColor
        opacity: 0.7
        visible: m_stack_index!=-1;

        ListView {
            width: parent.width
            height: parent.height
            focus: true
            keyNavigationEnabled: true
            interactive: false

            model: ListModel {
                ListElement { text: " \uf053"; subText: "back" }
                ListElement { text: " \uf1eb"; subText: "link" }
                ListElement { text: " \uf11b"; subText: "rc" }
                ListElement { text: " \uf03d"; subText: "video" }
                ListElement { text: " \uf030"; subText: "camera" }
                ListElement { text: " \uf0c7"; subText: "recording" }
                ListElement { text: " \uf26c"; subText: "display" }
                ListElement { text: " \uf55b"; subText: "drone" }
            }

            delegate: Item {
                width: parent.width
                height: secondaryUiHeight / 8 //number of items

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent

                    onClicked: {
                        // Update the selected item index
                        console.log("Item clicked: " + model.subText)
                        var uiElementName = model.subText + "UI";
                        if (model.subText === "back") {
                            close();
                        } else if (model.subText === "link") {
                             m_stack_index=0;
                        } else if (model.subText === "rc") {
                            m_stack_index=1;
                        } else if (model.subText === "video") {
                           m_stack_index=2;
                        } else if (model.subText === "camera") {
                            m_stack_index=3;
                        } else if (model.subText === "recording") {
                           m_stack_index=4;
                        } else if (model.subText === "display") {
                           m_stack_index=5;
                        } else if (model.subText === "drone") {
                           m_stack_index=6;
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: parent.height
                        color: index === m_stack_index ? highlightColor : mainDarkColor
                    }

                    RowLayout {
                        width: parent.width
                        height: parent.height

                        Text {
                            text: model.text
                            font.pixelSize: secondaryUiHeight / 16
                            opacity: 1.0
                            font.family: "Font Awesome 5 Free"
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        Text {
                            text: model.subText
                            visible: false
                            font.pixelSize: secondaryUiHeight / 16
                            opacity: 1.0
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    Item{
        width: secondaryUiWidth
        height: secondaryUiHeight
        anchors.left: stack_manager.right
        anchors.top: stack_manager.top

        Panel1Link{
            id: linkUI
            visible: m_stack_index==0;
        }
        Panel2RC{
            id: rcUI
            visible: m_stack_index==1;
        }

        Panel3Video{
            id: videoUI
            visible: m_stack_index==2;
        }

        Panel4Camera{
            id: cameraUI
            visible: m_stack_index==3;
        }

        Panel5Recording{
            id: recordingUI
            visible: m_stack_index==4;
        }

        Panel6Display{
            id: displayUI
            visible: m_stack_index==5;
        }

        Panel7Misc{
            id: miscUI
            visible: m_stack_index==6;
        }
    }

}
