// @disable-check M222
// @disable-check M223

import QtQuick 2.13

import QtQuick.Layouts 1.13
import QtQuick.Controls 2.13

Rectangle {
    id: rectangle
    width: 504
    height: 64
    color: index % 2 == 0 ? "#8cbfd7f3" : "white"


    // allow access to the index of the setting item within the ListModel within the onActivated
    // signal, which has its own "index" argument
    property var itemIndex: index

    Text {
        text: title
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 12
        verticalAlignment: Text.AlignVCenter
        width: 192
        height: 32
        font.bold: true
        font.pixelSize: 13
        anchors.left: parent.left
    }

    ComboBox {
        id: choiceBox
        x: 382
        y: 8
        textRole: "title"
        model: itemModel.choiceValues
        width: 212
        height: 40
        font.pixelSize: 14
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 8


        Component.onCompleted: {
            for (var i = 0; i < model.count; i++) {
                var choice = model.get(i);
                if (choice.value == value) {
                    currentIndex = i;
                }
            }
        }

        onActivated: {
            listModel.setProperty(itemIndex, "value", choiceBox.model.get(index).value);
        }

        /*
         * These are mostly copied from the Qt source code in order to change some of the styling
         * and alignment. If there is a better way to do that, these can be deleted.
         *
         */
        delegate: ItemDelegate {
            id: itemDelegate
            width: parent.width
            text: choiceBox.textRole ? (Array.isArray(choiceBox.model) ? modelData[choiceBox.textRole] : model[choiceBox.textRole]) : modelData
            font.weight: choiceBox.currentIndex === index ? Font.DemiBold : Font.Normal
            highlighted: choiceBox.highlightedIndex === index
            hoverEnabled: choiceBox.hoverEnabled

            contentItem: Label {
                text: itemDelegate.text
                font: itemDelegate.font
                elide: Label.ElideRight
                verticalAlignment: Label.AlignVCenter
                horizontalAlignment: Label.AlignRight
            }
        }

        contentItem: TextField {
            leftPadding: !choiceBox.mirrored ? 12 : choiceBox.editable && activeFocus ? 3 : 1
            rightPadding: choiceBox.mirrored ? 12 : choiceBox.editable && activeFocus ? 3 : 1
            topPadding: 6 - choiceBox.padding
            bottomPadding: 6 - choiceBox.padding

            text: choiceBox.editable ? choiceBox.editText : choiceBox.displayText

            enabled: choiceBox.editable
            autoScroll: choiceBox.editable
            readOnly: choiceBox.down
            inputMethodHints: choiceBox.inputMethodHints
            validator: choiceBox.validator

            font: choiceBox.font
            color: choiceBox.editable ? choiceBox.palette.text : choiceBox.palette.buttonText
            selectionColor: choiceBox.palette.highlight
            selectedTextColor: choiceBox.palette.highlightedText
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight

            background: Rectangle {
                visible: choiceBox.enabled && choiceBox.editable && !choiceBox.flat
                border.width: parent && parent.activeFocus ? 2 : 1
                border.color: parent && parent.activeFocus ? choiceBox.palette.highlight : choiceBox.palette.button
                color: choiceBox.palette.base
            }
        }
    }
}
