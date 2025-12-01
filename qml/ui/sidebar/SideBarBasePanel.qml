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

    // Allow child panels to add their content directly to the scrollable area
    default property alias content: flickableContent.data

    property string override_title: "OVERRIDE ME"

    // The main background
    Rectangle{
        anchors.fill: parent
        color: secondaryUiColor
        opacity: secondaryUiOpacity
    }

    // The header / title
    Rectangle {
        id: header
        width: secondaryUiWidth
        height: secondaryUiHeight/8
        color: highlightColor
        opacity: 1.0
        Text {
            anchors.centerIn: parent
            text: override_title
            font.pixelSize: 21
            font.family: "AvantGarde-Medium"
            color: "#ffffff"
            smooth: true
        }
    }

    // Holds the actual panel content and makes it scrollable when needed
    Flickable {
        id: contentFlickable
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        contentWidth: width
        contentHeight: flickableContent.childrenRect.height
        clip: true
        interactive: contentHeight > height

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        Item {
            id: flickableContent
            width: contentFlickable.width
            height: childrenRect.height
        }
    }

    // Ensures an element taking keyboard control is visible inside the flickable viewport
    function ensure_content_visible(item) {
        if (!contentFlickable || !item) {
            return;
        }
        const itemPos = item.mapToItem(flickableContent, 0, 0);
        const itemTop = itemPos.y;
        const itemBottom = itemTop + item.height;
        const viewTop = contentFlickable.contentY;
        const viewBottom = viewTop + contentFlickable.height;

        if (itemTop < viewTop) {
            contentFlickable.contentY = Math.max(0, itemTop);
        } else if (itemBottom > viewBottom) {
            const newContentY = itemBottom - contentFlickable.height;
            const maxContentY = contentFlickable.contentHeight - contentFlickable.height;
            contentFlickable.contentY = Math.min(maxContentY, newContentY);
        }
    }
}
