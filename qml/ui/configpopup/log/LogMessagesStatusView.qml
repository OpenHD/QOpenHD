import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

Item {
    Layout.fillHeight: true
    Layout.fillWidth: true


    property int rowHeight: 64
    property int elementHeight: 48
    property int elementComboBoxWidth: 300
    // Tab bar for selecting items in stack layout
    TabBar {
        id: selectItemInStackLayoutBar
        width: parent.width
        TabButton {
            text: qsTr("LOG OpenHD Air/Gnd")
        }
        TabButton {
            text: qsTr("LOG FC")
        }
        //TabButton {
        //    text: qsTr("LOG OpenHD Ground")
        //}
    }

    // placed right below the top bar
    StackLayout {
        width: parent.width
        height: parent.height-selectItemInStackLayoutBar.height
        anchors.top: selectItemInStackLayoutBar.bottom
        anchors.left: selectItemInStackLayoutBar.left
        anchors.bottom: parent.bottom
        currentIndex: selectItemInStackLayoutBar.currentIndex
        Rectangle {
            color: Qt.rgba(0.2, 0.2, 0.2, 1.0)
            Rectangle {
                width: parent.width - 24
                height: parent.height - 24
                anchors.centerIn: parent
                color: Qt.rgba(0.2, 0.2, 0.2, 1.0)

                // Uses the c++ logmessagemodel under app/logging/logmessagesmodel
                ListView {
                    id: logMessagesModelParentListView
                    width: parent.width
                    height: parent.height-12
                    model: _ohdlogMessagesModel
                    delegate:
                        Rectangle {
                        color: Qt.rgba(0.2, 0.2, 0.2, 1.0)
                        height: childrenRect.height
                        width: logMessagesModelParentListView.width //parent.width for some reason we cannot just use parent.width here

                        Text {
                            id: tagView
                            text: model.tag
                            color: model.severity_color
                            anchors { left:parent.left }
                        }
                        Text {
                            text: model.message
                            color: "#fff"
                            anchors { left:tagView.right; verticalCenter: tagView.verticalCenter; leftMargin: 5 }
                        }
                    }
                }

                // Uses the c++ logmessagemodel under app/logging/logmessagesmodel
                ListView {
                    id: logMessagesModelFCParentListView
                    width: parent.width
                    height: parent.height
                    model: _fclogMessagesModel
                    delegate:
                        Rectangle {
                        color: Qt.rgba(0.2, 0.2, 0.2, 1.0)
                        height: childrenRect.height
                        width: logMessagesModelFCParentListView.width //parent.width for some reason we cannot just use parent.width here

                        Text {
                            id: tagViewFC
                            text: model.tag
                            color: model.severity_color
                            anchors { left:parent.left }
                        }
                        Text {
                            text: model.message
                            anchors { left:tagViewFC.right; verticalCenter: tagViewFC.verticalCenter; leftMargin: 5 }
                        }
                    }
                }
                // TODO Fetch OpenHD log via journalctl + why the fuck is the second tab invisible
            }
        }
    }
}
