import QtQuick 2.13

import QtQuick.Layouts 1.13
import QtQuick.Controls 2.13

BaseDelegate {

    Slider {
        id: choiceBox
        width: 210
        height: 48
        from: 0
        to: 100
        stepSize: 1
        value: model.value
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 18
        onValueChanged: model.modified = true

        ToolTip {
            parent: valueElement.handle
            visible: valueElement.pressed
            // @disable-check M222
            text: "%1%2".arg(valueElement.value).arg(model.unit)
        }
        enabled: !model.disabled
    }
}
