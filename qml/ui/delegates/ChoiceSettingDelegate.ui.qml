// @disable-check M222
// @disable-check M223

import QtQuick 2.13

import QtQuick.Layouts 1.13
import QtQuick.Controls 2.13

BaseDelegate {
    // allow access to the index of the setting item within the ListModel within the onActivated
    // signal, which has its own "index" argument
    property var itemIndex: index

    ComboBox {
        id: valueElement
        textRole: "title"
        model: itemModel.choiceValues
        width: 212
        height: 40
        font.pixelSize: 14
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 36
        enabled: !itemModel.disabled


        // @disable-check M223
        Component.onCompleted: {
            // @disable-check M223
            for (var i = 0; i < model.count; i++) {
                // @disable-check M222
                var choice = model.get(i);
                // @disable-check M223
                if (choice.value == value) {
                    currentIndex = i;
                }
            }
        }

        // @disable-check M223
        onActivated: {
            // @disable-check M222
            listModel.setProperty(itemIndex, "value", valueElement.model.get(index).value);
            itemModel.modified = true;
        }

        /*
         * These are mostly copied from the Qt source code in order to change some of the styling
         * and alignment. If there is a better way to do that, these can be deleted.
         *
         */
        delegate: ItemDelegate {
            id: itemDelegate
            width: parent.width
            // @disable-check M222
            text: valueElement.textRole ? (Array.isArray(valueElement.model) ? modelData[valueElement.textRole] : model[valueElement.textRole]) : modelData
            font.weight: valueElement.currentIndex === index ? Font.DemiBold : Font.Normal
            highlighted: valueElement.highlightedIndex === index
            hoverEnabled: valueElement.hoverEnabled

            contentItem: Label {
                text: itemDelegate.text
                font: itemDelegate.font
                elide: Label.ElideRight
                verticalAlignment: Label.AlignVCenter
                horizontalAlignment: Label.AlignRight
            }
        }

        contentItem: TextField {
            leftPadding: !valueElement.mirrored ? 12 : valueElement.editable && activeFocus ? 3 : 1
            rightPadding: valueElement.mirrored ? 12 : valueElement.editable && activeFocus ? 3 : 1
            topPadding: 6 - valueElement.padding
            bottomPadding: 6 - valueElement.padding

            text: valueElement.editable ? valueElement.editText : valueElement.displayText

            enabled: valueElement.editable
            autoScroll: valueElement.editable
            readOnly: valueElement.down
            inputMethodHints: valueElement.inputMethodHints
            validator: valueElement.validator

            font: valueElement.font
            color: valueElement.editable ? valueElement.palette.text : valueElement.palette.buttonText
            selectionColor: valueElement.palette.highlight
            selectedTextColor: valueElement.palette.highlightedText
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight

            background: Rectangle {
                visible: valueElement.enabled && valueElement.editable && !valueElement.flat
                border.width: parent && parent.activeFocus ? 2 : 1
                border.color: parent && parent.activeFocus ? valueElement.palette.highlight : valueElement.palette.button
                color: valueElement.palette.base
            }
        }
    }
}
