import QtQuick 2.13

import QtQuick.Layouts 1.13
import QtQuick.Controls 2.13

BaseDelegate {

    Switch {
        id: valueElement
        anchors.right: parent.right
        checked: model.value
        font.pixelSize: 16
        topPadding: 0
        anchors.verticalCenter: parent.verticalCenter
        bottomPadding: 0
        anchors.rightMargin: 22
        width: 32
        height: 32
        // @disable-check M223
        onCheckedChanged: {
            model.value = checked
            model.modified = true
        }
        enabled: !model.disabled
    }
}
