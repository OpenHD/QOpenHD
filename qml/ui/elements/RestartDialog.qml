import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0
import QtGraphicalEffects 1.12

Card {
    id: restartDialog
    cardNameColor: "black"
    hasHeaderImage: true
    visible: false

    property bool stateVisible: visible

    states: [
        State {
            when: restartDialog.stateVisible;
            PropertyChanges {
                target: restartDialog
                opacity: 1.0
            }
        },
        State {
            when: !restartDialog.stateVisible;
            PropertyChanges {
                target: restartDialog
                opacity: 0.0
            }
        }
    ]
    transitions: [ Transition { NumberAnimation { property: "opacity"; duration: 250}} ]

    cardName: qsTr("Restart required")
    cardBody: Column {
        height: restartDialog.height
        width: restartDialog.width

        Text {
            text: qsTr("You must restart the app for your loaded configuration file to take effect")
            width: parent.width
            leftPadding: 12
            rightPadding: 12
            wrapMode: Text.WordWrap
        }
    }

    hasFooter: true
    cardFooter: Item {
        anchors.fill: parent
        Button {
            width: 96
            height: 48
            text: qsTr("Cancel")
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            font.pixelSize: 14
            font.capitalization: Font.MixedCase

            onPressed: {
                restartDialog.visible = false
            }
        }

        Button {
            width: 140
            height: 48
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            font.pixelSize: 14
            font.capitalization: Font.MixedCase
            Material.accent: Material.Red
            highlighted: true

            text:  {
                /*if (IsAndroid) {
                    return qsTr("Restart App")
                }*/
                return qsTr("Close App")
            }


            onPressed: {
                /*if (IsAndroid) {
                    ManageSettings.restartApp();
                    return;
                }*/
                Qt.quit();
            }
        }
    }
}
