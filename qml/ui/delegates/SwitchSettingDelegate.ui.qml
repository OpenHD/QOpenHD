import QtQuick 2.12

import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12

BaseDelegate {

    Switch {
        id: valueElement
        checked: model.checked
        anchors.right: parent.right
        anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
        anchors.top: parent.top
        anchors.topMargin: 8
        width: 210
        height: 48
        // @disable-check M223
        onCheckedChanged: {
            model.value = (checked == true) ? model.checkedValue : model.uncheckedValue;
        }
        enabled: !model.disabled
    }
}
