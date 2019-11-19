import QtQuick 2.13

import QtQuick.Layouts 1.13
import QtQuick.Controls 2.13

BaseDelegate {

    TextField {
        id: valueElement
        anchors.right: parent.right
        font.pixelSize: 14
        topPadding: 0
        anchors.verticalCenter: parent.verticalCenter
        bottomPadding: 8
        horizontalAlignment: Text.AlignRight
        anchors.rightMargin: 36
        width: 192
        height: 32
        // @disable-check M223
        Component.onCompleted: {
            text = model.value
            cursorPosition = 0
        }
        // @disable-check M223
        onTextChanged: {
            model.value = text;
            model.modified = true;
        }
        enabled: !model.disabled
    }
}
