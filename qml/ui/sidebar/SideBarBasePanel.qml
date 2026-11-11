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
    property string headerIcon: "\uf013"
    property real headerHeight: 78
    property alias headerAction: headerActionLoader.sourceComponent

    ScrollView {
        id: bodyScroll
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: header.bottom
        padding: 0
        contentWidth: width
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
            policy: ScrollBar.AlwaysOff
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
        color: "transparent"
        opacity: 1.0
        z: 1
        Text {
            anchors.left: parent.left
            anchors.right: headerActionLoader.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 84
            horizontalAlignment: Text.AlignLeft
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            text: qsTr(override_title)
            font.pixelSize: 30
            color: "#edf6ff"
            smooth: true
        }
        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            height: 44
            radius: 12
            color: "#253e54"
            Text {
                anchors.centerIn: parent
                text: headerIcon
                font.family: "Font Awesome 5 Free"
                font.pixelSize: 23
                color: "#89dbff"
            }
        }
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.leftMargin: 24; anchors.rightMargin: 24
            height: 1; color: "#3b5063"
        }
        Rectangle {
            visible: override_title === "Link"
            anchors.right: parent.right; anchors.rightMargin: 28; anchors.verticalCenter: parent.verticalCenter
            width: 56; height: 27; radius: 14; color: "transparent"; border.color: "#3cd77d"; border.width: 1
            Text { anchors.centerIn: parent; text: "AIR"; color: "#3cd77d"; font.pixelSize: 18; font.bold: true }
        }
        Loader {
            id: headerActionLoader
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: item ? headerHeight : 0
            height: headerHeight
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
