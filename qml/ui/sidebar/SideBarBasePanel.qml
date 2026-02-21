import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"


Item {
    width: secondaryUiWidth
    height: secondaryUiHeight

    property string override_title: "OVERRIDE ME"
    property real headerHeight: secondaryUiHeight / 8

    // The main background
    Rectangle{
        anchors.fill: parent
        color: secondaryUiColor
        opacity: secondaryUiOpacity
    }

    ScrollView {
        id: bodyScroll
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: header.bottom
        clip: true
        focus: false
        activeFocusOnTab: false
        Keys.onPressed: (event)=> {
            if(event.key === Qt.Key_Left){
                sidebar.regain_control_on_sidebar_stack();
                event.accepted = true;
            }
        }
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        Item {
            id: contentContainer
            width: bodyScroll.width
            implicitWidth: Math.max(childrenRect.width, width)
            implicitHeight: childrenRect.height
        }
    }

    // The header / title
    Rectangle {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: headerHeight
        color: highlightColor
        opacity: 0.95
        z: 1
        Text {
            anchors.centerIn: parent
            text: override_title
            font.pixelSize: 18
            font.family: "AvantGarde-Medium"
            color: "#ffffff"
            smooth: true
        }
    }

    // Actual UI elements are added here by implementation
    default property alias contentData: contentContainer.data

    function ensure_body_item_visible(item){
        if(!item){
            return;
        }
        const flickable = bodyScroll.contentItem;
        if(!flickable){
            return;
        }
        const item_pos = item.mapToItem(contentContainer, 0, 0);
        const item_top = item_pos.y;
        const item_bottom = item_top + item.height;
        const view_top = flickable.contentY;
        const view_bottom = view_top + bodyScroll.height;
        if(item_top < view_top){
            flickable.contentY = item_top;
        }else if(item_bottom > view_bottom){
            flickable.contentY = item_bottom - bodyScroll.height;
        }
    }
}
