import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12


CheckBox {
    id: el
    enabled: unknownState == false

    contentItem: Text {
        text: el.text
        font: el.font
        color: textColor
        verticalAlignment: Text.AlignVCenter
        leftPadding: el.indicator.width + el.spacing
    }

    indicator: Rectangle {
        implicitWidth: 20
        implicitHeight: 20
        x: el.leftPadding
        y: parent.height / 2 - height / 2
        radius: 3
        color: "#00000000"
        border.color: boxColor
        border.width: 3

        Rectangle {
            width: 16
            height: 16
            x: 2
            y: 2
            radius: 0
            color: boxColor
            visible: el.checked || unknownState
        }

        Text {
            id: checkMark
            width: 14
            height: 14
            color: checkColor
            text: unknownState ? "?" : "\uf00c"
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.family: "Font Awesome 5 Free"
            styleColor: checkColor
            font.pixelSize: 14
            visible: el.checked || unknownState
        }
    }
}

