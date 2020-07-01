import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0

import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    width: 256
    height: 48

    visible: settings.show_example_widget

    widgetIdentifier: "example_widget"

    defaultAlignment: 0
    defaultXOffset: 92
    defaultYOffset: 192
    defaultHCenter: false
    defaultVCenter: true


    hasWidgetDetail: false

    Item {
        id: widgetInner

        anchors.fill: parent

        Text {
            text: "Example widget";
            color: "white"
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideNone
            wrapMode: Text.NoWrap
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
            visible: OpenHD.rcChannel7 <= 1500 ? true : false
        }
    }
}
