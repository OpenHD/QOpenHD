import QtQuick 2.12

import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12

BaseDelegate {

    Switch {
        id: valueElement
        anchors.right: parent.right
        checked: model.value
        font.pixelSize: 16
        topPadding: 0
        bottomPadding: 0
        anchors.rightMargin: 36
        anchors.top: parent.top
        anchors.topMargin: 12
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
