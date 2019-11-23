import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12

BaseDelegate {

    SpinBox {
        id: choiceBox
        width: 210
        height: 48
        font.pixelSize: 14
        from: 0
        to: 100
        stepSize: 1
        value: model.value
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.top: parent.top
        anchors.topMargin: 8
        // @disable-check M223
        onValueChanged: {
            model.value = value
            model.modified = true
        }
        enabled: !model.disabled
    }
}
