import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12

import OpenHD 1.0

/*
 * This file is WAY longer than I'd like, it's very repetitive and could probably be cleaned
 * up with a common base Component for some of the elements
 *
 */
Rectangle {
    color: "#00000000"

    border.width: dragging ? 1 : 0
    border.color: dragging ? "white" : "#00000000"

    //property alias widgetControls: widgetControls
    property alias widgetDetail: widgetDetail
    property alias widgetAction: widgetAction
    property alias alignmentType: choiceBox.currentIndex

    /* intended to be overriden by widgets, anything in this item will show up inside the
       detail popover
    */
    property Item widgetDetailComponent: Item {}
    property bool hasWidgetDetail: false
    property int widgetDetailWidth: 300
    property int widgetDetailHeight: 250

    property Item widgetActionComponent: Item {}
    property bool hasWidgetAction: false
    property int widgetActionWidth: 256
    property int widgetActionHeight: 164

    property Popup widgetPopup: Popup {}
    property bool hasWidgetPopup: false


    Behavior on width {
        NumberAnimation { duration: 200 }
    }


    Behavior on height {
        NumberAnimation { duration: 200 }
    }

    Popup {
        id: widgetDetail


        width: widgetDetailWidth
        height: widgetDetailHeight

        background: Rectangle {
            color: "#ea000000"
            border.width: 1
            border.color: "white"
            radius: 12
        }

        closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape

        onAboutToHide: {
            dragging = false
            // @disable-check M222
            //widgetControls.close()
            // @disable-check M222
            saveAlignment()
            // @disable-check M222
            loadAlignment()
            globalDragLock = false
        }



        /*
         * This centers the popup on the screen rather than positioning it
         * relative to the parent item
         *
         */
        parent: Overlay.overlay
        x: {
            if (widgetBase.x <= Math.round((parent.width - width) / 2)) {
                return 24;
            } else {
                return parent.width - width - 24;
            }
        }
        y: {
            if (widgetBase.y <= Math.round((parent.height - height) / 2)) {
                return 64;
            } else {
                return parent.height - height - 64;
            }
        }



        contentItem: widgetDetailComponent

        //this is an ugly adaptation.. So that there are no null returns on this model
        Item {
            anchors.fill: parent

            ComboBox {
                id: choiceBox
                model: ["Top Left", "Top Right", "Bottom Right", "Bottom Left"]
            }
        }
    }

    Popup {
        id: widgetAction


        width: widgetActionWidth
        height: widgetActionHeight

        background: Rectangle {
            color: "#ea000000"
            border.width: 1
            border.color: "white"
            radius: 12
        }

        closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape

        /*
         * This centers the popup on the screen rather than positioning it
         * relative to the parent item
         *
         */
        parent: Overlay.overlay
        x: {
            if (widgetBase.x <= Math.round((parent.width - width) / 2)) {
                return 24;
            } else {
                return parent.width - width - 24;
            }
        }
        y: {
            if (widgetBase.y <= Math.round((parent.height - height) / 2)) {
                return 64;
            } else {
                return parent.height - height - 64;
            }
        }

        contentItem: widgetActionComponent


    }
    /*  Below are the old controls popup.. Left as a reference

    Popup {
        id: widgetControls

        width: 196
        // the alignment dropdown isn't necessary on the ground station so we hide it
        height: OpenHDPi.is_raspberry_pi ? 244 : 304

        background: Rectangle {
            color: "#ea000000"
        }


        parent: Overlay.overlay
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)


        Item {
            anchors.fill: parent

            Item {
                id: buttonContainer
                width: parent.width
                height: 150
                anchors.top: parent.top

                Text {
                    id: upButton
                    text: "\uf0aa"
                    color: vCenter.checked ? "#bababa" : upButtonMouseArea.pressed ? "#eaeaea" : "white"
                    anchors.top: parent.top
                    anchors.topMargin: 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: 42
                    font.family: "Font Awesome 5 Free"
                    horizontalAlignment: Text.AlignHCenter
                    MouseArea {
                        id: upButtonMouseArea
                        anchors.fill: parent
                        enabled: !vCenter.checked
                        // @disable-check M222
                        onClicked: moveUp()
                    }
                    // @disable-check M221
                    Timer {
                        id: timer1
                        interval: 50
                        repeat: true
                        triggeredOnStart: false
                        running: upButtonMouseArea.pressed
                        // @disable-check M222
                        onTriggered: moveUp()
                    }
                }

                Text {
                    id: leftButton
                    text: "\uf0a8"
                    color: hCenter.checked ? "#bababa" : leftButtonMouseArea.pressed ? "#eaeaea" : "white"
                    anchors.left: parent.left
                    anchors.leftMargin: 0
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 42
                    font.family: "Font Awesome 5 Free"
                    horizontalAlignment: Text.AlignRight
                    MouseArea {
                        id: leftButtonMouseArea
                        anchors.fill: parent
                        enabled: !hCenter.checked
                        // @disable-check M222
                        onClicked: moveLeft()
                    }
                    // @disable-check M221
                    Timer {
                        id: timer2
                        interval: 50
                        repeat: true
                        triggeredOnStart: false
                        running: leftButtonMouseArea.pressed
                        // @disable-check M222
                        onTriggered: moveLeft()
                    }
                }

                Text {
                    id: rightButton
                    text: "\uf0a9"
                    color: hCenter.checked ? "#bababa" : rightButtonMouseArea.pressed ? "#eaeaea" : "white"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    font.pixelSize: 42
                    font.family: "Font Awesome 5 Free"
                    horizontalAlignment: Text.AlignLeft
                    MouseArea {
                        id: rightButtonMouseArea
                        anchors.fill: parent
                        enabled: !hCenter.checked
                        // @disable-check M222
                        onClicked: moveRight()
                    }
                    // @disable-check M221
                    Timer {
                        id: timer3
                        interval: 50
                        repeat: true
                        triggeredOnStart: false
                        running: rightButtonMouseArea.pressed
                        // @disable-check M222
                        onTriggered: moveRight()
                    }
                }
                Text {
                    id: downButton
                    text: "\uf0ab"
                    color: vCenter.checked ? "#bababa" : downButtonMouseArea.pressed ? "#eaeaea" : "white"
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: 42
                    font.family: "Font Awesome 5 Free"
                    horizontalAlignment: Text.AlignHCenter
                    MouseArea {
                        id: downButtonMouseArea
                        anchors.fill: parent
                        enabled: !vCenter.checked
                        // @disable-check M222
                        onClicked: moveDown()

                    }
                    // @disable-check M221
                    Timer {
                        id: timer4
                        interval: 50
                        repeat: true
                        triggeredOnStart: false
                        running: downButtonMouseArea.pressed
                        // @disable-check M222
                        onTriggered: moveDown()
                    }
                }


                Text {
                    id: doneButton
                    text: "\uf058"
                    color: doneButtonMouseArea.pressed ? "#eaeaea" : "white"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 52
                    font.family: "Font Awesome 5 Free"
                    MouseArea {
                        id: doneButtonMouseArea
                        anchors.fill: parent
                        // @disable-check M223
                        onClicked: {
                            dragging = false
                            // @disable-check M222
                            widgetControls.close()
                            // @disable-check M222
                            saveAlignment()
                            // @disable-check M222
                            loadAlignment()
                            globalDragLock = false
                        }
                    }
                }

            }

            Item {
                height: 60
                width: parent.width
                id: checkboxContainer
                anchors.top: buttonContainer.bottom
                anchors.topMargin: 6

                CheckBox {
                    height: 24
                    id: hCenter
                    font.bold: true
                    leftPadding: 0

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: vCenter.top

                    text: "Horizontal Center"

                    // @disable-check M223
                    Component.onCompleted: {

                         // @disable-check M222
                        var _hCenter = settings.value(hCenterIdentifier, defaultHCenter)
                         // @disable-check M223
                        if (_hCenter === "true" || _hCenter === 1 || _hCenter === true) {
                            checked = true;
                        // @disable-check M223
                        } else {
                            checked = false;
                        }
                    }
                    // @disable-check M222
                    onCheckedChanged: settings.setValue(hCenterIdentifier, checked)


                    contentItem: Text {
                        text: hCenter.text
                        font: hCenter.font
                        color: "white"
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: hCenter.indicator.width + hCenter.spacing
                    }

                    indicator: Rectangle {
                        implicitWidth: 20
                        implicitHeight: 20
                        x: hCenter.leftPadding
                        y: parent.height / 2 - height / 2
                        radius: 3
                        color: "#00000000"
                        border.color: "white"

                        Rectangle {
                            width: 14
                            height: 14
                            x: 3
                            y: 3
                            radius: 2
                            color: "white"
                            visible: hCenter.checked
                        }
                    }
                }

                CheckBox {
                    height: 24
                    id: vCenter
                    font.bold: true
                    leftPadding: 0

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: hCenter.bottom
                    anchors.bottom: parent.bottom

                    text: "Vertical Center"

                    // @disable-check M223
                    Component.onCompleted: {
                         // @disable-check M222
                        var _vCenter = settings.value(vCenterIdentifier, defaultVCenter)
                         // @disable-check M223
                        if (_vCenter === "true" || _vCenter === 1 || _vCenter === true) {
                            checked = true;
                        // @disable-check M223
                        } else {
                            checked = false;
                        }
                    }
                    // @disable-check M222
                    onCheckedChanged: settings.setValue(vCenterIdentifier, checked)

                    contentItem: Text {
                        text: vCenter.text
                        font: vCenter.font
                        color: "white"
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: vCenter.indicator.width + vCenter.spacing
                    }

                    indicator: Rectangle {
                        implicitWidth: 20
                        implicitHeight: 20
                        x: vCenter.leftPadding
                        y: parent.height / 2 - height / 2
                        radius: 3
                        color: "#00000000"
                        border.color: "white"

                        Rectangle {
                            width: 14
                            height: 14
                            x: 3
                            y: 3
                            radius: 2
                            color: "white"
                            visible: vCenter.checked
                        }
                    }
                }
            }
        }
    }
    */
}


/*##^##
Designer {
    D{i:0;autoSize:true;height:150;width:150}
}
##^##*/
