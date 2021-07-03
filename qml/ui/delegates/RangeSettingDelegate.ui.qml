import QtQuick 2.12

import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12

BaseDelegate {

    Slider {
        id: valueElement
        width: 210
        height: 48
        from: model.from
        to: model.to
        stepSize: 1
        value: model.value
        anchors.right: parent.right
        anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
        anchors.top: parent.top
        anchors.topMargin: 8

        ToolTip {
            parent: valueElement.handle
            visible: valueElement.pressed
            // @disable-check M222
            text: "%1%2".arg(valueElement.value).arg(model.unit)
        }
        onValueChanged: {
            model.value = value
        }
        enabled: !model.disabled
    }
}
