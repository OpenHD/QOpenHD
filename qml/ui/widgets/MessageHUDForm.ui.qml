import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: messageWidget
    property alias messageListView: messageListView
    property alias messageWidget: messageWidget

    width: 480
    height: 72

    visible: settings.show_message_hud

    widgetIdentifier: "message_hud_widget"

    defaultAlignment: 3
    defaultXOffset: 0
    defaultYOffset: 48
    defaultHCenter: false
    defaultVCenter: false

    Item {
        id: widgetInner

        anchors.fill: parent

        ListView {
            id: messageListView
            anchors.fill: parent
            model: messageModel
            interactive: false


            clip: true
            delegate: MessageHUDRow {
                width: messageListView.width
            }

            // @disable-check M221
            add: Transition {
                NumberAnimation {
                    property: "opacity";
                    from: 0;
                    to: 0.9;
                    duration: 250
                }
            }

            // @disable-check M221
            remove: Transition {
                NumberAnimation {
                    property: "opacity";
                    from: 0.9;
                    to: 0.0;
                    duration: 250
                }
            }

            // @disable-check M221
            displaced: Transition {
                NumberAnimation {
                    properties: "y";
                    duration: 200;
                    easing.type: Easing.OutBack
                }
            }
        }
    }
}

/*##^##
Designer {
    D{i:1;anchors_height:72;anchors_width:300}
}
##^##*/
