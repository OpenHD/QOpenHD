import QtQuick 2.12
import QtQuick.Controls 2.12

ComboBox {
    id: control
    property color panelColor: settings_form.panelBackground
    property color popupColor: settings_form.panelBackgroundRaised
    property color textColor: settings_form.primaryText
    property color mutedColor: settings_form.secondaryText
    property color outlineColor: settings_form.lineColor
    property color focusColor: settings_form.accentColor
    property int popupWidth: width

    function openForKeyboard() {
        if (!enabled || popup.visible) return
        popup.open()
    }

    Keys.onReturnPressed: {
        control.openForKeyboard()
        event.accepted = true
    }
    Keys.onEnterPressed: {
        control.openForKeyboard()
        event.accepted = true
    }

    hoverEnabled: true
    leftPadding: 12
    rightPadding: 36
    font.pixelSize: 10

    contentItem: Text {
        leftPadding: 0
        rightPadding: 0
        text: control.displayText
        color: control.enabled ? control.textColor : control.mutedColor
        font: control.font
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Text {
        x: control.width - width - 13
        anchors.verticalCenter: parent.verticalCenter
        text: control.popup.visible ? "\uf077" : "\uf078"
        color: control.enabled && (control.hovered || control.activeFocus)
               ? control.focusColor : control.mutedColor
        font.family: "Font Awesome 5 Free"
        font.pixelSize: 8
    }

    background: Rectangle {
        radius: 8
        color: control.down || control.popup.visible
               ? Qt.rgba(0.12, 0.55, 1.0, settings_form.darkMode ? 0.16 : 0.10)
               : (control.hovered ? control.popupColor : control.panelColor)
        border.color: control.activeFocus || control.popup.visible
                      ? control.focusColor : control.outlineColor
        border.width: control.activeFocus ? 2 : 1
    }

    delegate: ItemDelegate {
        width: ListView.view ? ListView.view.width : Math.max(0, control.popupWidth - 12)
        height: 38
        hoverEnabled: true
        highlighted: hovered || (control.popup.visible && popupList.currentIndex === index)
        leftPadding: 12
        rightPadding: 38
        contentItem: Text {
            text: control.textRole.length > 0 ? model[control.textRole] : modelData
            color: highlighted ? control.focusColor : control.textColor
            font.pixelSize: 10
            font.bold: control.currentIndex === index
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        indicator: Rectangle {
            width: 14; height: 14; radius: 7
            x: parent.width - width - 12
            anchors.verticalCenter: parent.verticalCenter
            color: "transparent"
            border.width: 2
            border.color: control.currentIndex === index ? control.focusColor : control.mutedColor
            Rectangle {
                anchors.centerIn: parent
                width: 6; height: 6; radius: 3
                visible: control.currentIndex === index
                color: control.focusColor
            }
        }
        background: Rectangle {
            radius: 7
            color: highlighted
                   ? Qt.rgba(0.12, 0.55, 1.0, settings_form.darkMode ? 0.14 : 0.09)
                   : "transparent"
        }
    }

    popup: Popup {
        id: dropdownPopup
        y: control.height + 4
        width: control.popupWidth
        implicitHeight: Math.min(contentItem.implicitHeight + 12, 280)
        padding: 6
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: {
            popupList.currentIndex = control.currentIndex >= 0 ? control.currentIndex : 0
            popupList.positionViewAtIndex(popupList.currentIndex, ListView.Contain)
            popupList.forceActiveFocus()
        }
        onClosed: control.forceActiveFocus()
        background: Rectangle {
            radius: 8
            color: control.popupColor
            border.color: control.outlineColor
            border.width: 1
        }
        contentItem: ListView {
            id: popupList
            clip: true
            spacing: 2
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: -1
            keyNavigationEnabled: true
            keyNavigationWraps: true
            highlightMoveDuration: 0
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }
            Keys.onReturnPressed: {
                if (currentIndex >= 0) {
                    control.currentIndex = currentIndex
                    control.activated(currentIndex)
                    dropdownPopup.close()
                }
                event.accepted = true
            }
            Keys.onEnterPressed: {
                if (currentIndex >= 0) {
                    control.currentIndex = currentIndex
                    control.activated(currentIndex)
                    dropdownPopup.close()
                }
                event.accepted = true
            }
            Keys.onEscapePressed: {
                dropdownPopup.close()
                event.accepted = true
            }
            Keys.onLeftPressed: event.accepted = true
            Keys.onRightPressed: event.accepted = true
        }
    }
}
