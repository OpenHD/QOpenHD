import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import QtGraphicalEffects 1.13
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: altitudeWidget
    width: 40
    height: 25
    defaultXOffset: 740
    defaultVCenter: true

    widgetIdentifier: "altitude_widget"

    defaultHCenter: false

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 24
            Text {
                text: "Relative Or MSL"
                color: "white"
                font.bold: true
                anchors.left: parent.left
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 12
                anchors.right: parent.right
                // @disable-check M222
                Component.onCompleted: checked = settings.value("alt_msl_rel",
                                                                true)
                // @disable-check M222
                onCheckedChanged: settings.setValue("alt_msl_rel", checked)
            }
        }
    }

    Item {
        id: altitude_Text
        anchors.fill: parent

        Text {
            id: alt_text
            color: "white"
            text: qsTr(OpenHD.alt_rel)
            topPadding: 2
            bottomPadding: 2
            anchors.fill: parent
        }

        Text {
            id: alt_glyph
            y: 0
            width: 40
            height: 18
            color: "#ffffff"
            text: "\ufdd6"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Font Awesome 5 Free-Solid-900.otf"
            font.pixelSize: 14
        }

        antialiasing: true
    }
}

/*##^##
Designer {
    D{i:0;invisible:true}
}
##^##*/

