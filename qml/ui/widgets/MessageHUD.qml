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
        anchors.bottom: parent.bottom

        ListView {
            id: messageListView
            anchors.fill: parent
            model: _hudLogMessagesModel
            interactive: false
            // https://wiki.qt.io/How_to_make_QML_ListView_align_bottom-to-top
            rotation: 180

            clip: true
            delegate: MessageHUDRow {
                width: messageListView.width
                // bottom fix
                rotation: 180
            }

            add: Transition {
                NumberAnimation {
                    property: "opacity";
                    from: 0;
                    to: 0.9;
                    duration: 250
                }
            }

            remove: Transition {
                NumberAnimation {
                    property: "opacity";
                    from: 0.9;
                    to: 0.0;
                    duration: 250
                }
            }

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
