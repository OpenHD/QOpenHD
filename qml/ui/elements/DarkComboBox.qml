import QtQuick 2.12
import QtQuick.Controls 2.12

ComboBox {
    id: control

    property color panelColor: "#102235"
    property color popupColor: "#15283b"
    property color textColor: "#f2f6fb"
    property color mutedColor: "#aebdcb"
    property color outlineColor: "#33485d"
    property color focusColor: "#278cff"
    property int popupWidth: Math.max(width, 240)
    property real popupScale: 1
    // Callers can supply explanatory metadata without changing value models.
    property var optionDetails: []
    property string optionIcon: "\uf1de"
    function detail(index) {
        if (index >= 0 && index < optionDetails.length) return optionDetails[index]
        var entry = index < 0 ? null : (Array.isArray(model) ? model[index] : (model && model.get ? model.get(index) : null))
        var title = entry && typeof entry === "object" ? entry[textRole || "text"] : entry
        var label = title === undefined || title === null ? "" : String(title)
        var descriptions = {"Auto": qsTr("Choose automatically"), "Automatic": qsTr("Choose automatically"),
            "On": qsTr("Enable this feature"), "Enabled": qsTr("Enable this feature"),
            "Off": qsTr("Disable this feature"), "Disabled": qsTr("Disable this feature")}
        return {icon: entry && entry.icon ? entry.icon : optionIcon,
            description: entry && entry.description ? entry.description : (descriptions[label] || optionDescription)}
    }
    property string optionDescription: ""
    function optionLabel(value) { return value === undefined || value === null ? "" : String(value) }

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

    contentItem: Item {
        implicitWidth: selectedLabel.implicitWidth + 34
        Text {
            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
            text: control.detail(control.currentIndex).icon || control.optionIcon
            color: control.detail(control.currentIndex).color || control.focusColor
            font.family: "Font Awesome 5 Free"; font.pixelSize: 19
        }
        Text {
            id: selectedLabel
            anchors.left: parent.left; anchors.leftMargin: 32
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            text: control.displayText
            color: control.enabled ? control.textColor : control.mutedColor
            font: control.font
            elide: Text.ElideRight
        }
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
               ? "#243f5a" : (control.hovered ? control.popupColor : control.panelColor)
        border.color: control.activeFocus || control.popup.visible
                      ? control.focusColor : control.outlineColor
        border.width: control.activeFocus ? 2 : 1
    }

    delegate: ItemDelegate {
        id: option
        readonly property var details: control.detail(index)
        readonly property string label: control.optionLabel(control.textRole.length > 0
            ? (Array.isArray(control.model) ? modelData[control.textRole] : model[control.textRole]) : modelData)
        width: ListView.view ? ListView.view.width : control.popupWidth - 16
        height: details.description ? 48 : 36
        hoverEnabled: true
        highlighted: hovered || (control.popup.visible && popupList.currentIndex === index)
        contentItem: Item {
            Text {
                x: 10; anchors.verticalCenter: parent.verticalCenter
                text: option.details.icon || control.optionIcon
                color: option.details.color || control.focusColor
                font.family: "Font Awesome 5 Free"; font.pixelSize: 20
            }
            Column {
                x: 38; width: Math.max(0, parent.width - 66)
                anchors.verticalCenter: parent.verticalCenter; spacing: 2
                Text { width: parent.width; text: option.label; color: control.textColor; font.pixelSize: 14; elide: Text.ElideRight }
                Text { width: parent.width; visible: text.length > 0; text: option.details.description || ""; color: control.mutedColor; font.pixelSize: 10; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight }
            }
            Text {
                anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                visible: control.currentIndex === index
                text: "\uf00c"; color: control.focusColor
                font.family: "Font Awesome 5 Free"; font.pixelSize: 16
            }
        }
        background: Rectangle {
            radius: 10
            color: control.currentIndex === index ? "#0b3b62" : (option.highlighted ? "#183449" : "transparent")
        }
    }

    popup: Popup {
        id: dropdownPopup
        parent: Overlay.overlay
        z: 10000
        function positionInsideWindow() {
            if (!parent) return
            var point = control.mapToItem(parent, 0, 0)
            var below = control.mapToItem(parent, 0, control.height)
            var popupHeight = height * scale
            var popupWidth = width * scale
            x = Math.max(8, Math.min(point.x, parent.width - popupWidth - 8))
            var desiredY = below.y + 4
            if (desiredY + popupHeight > parent.height - 8)
                desiredY = point.y - popupHeight - 4
            y = Math.max(8, Math.min(desiredY, parent.height - popupHeight - 8))
        }
        onAboutToShow: positionInsideWindow()
        width: control.popupWidth
        scale: control.popupScale
        transformOrigin: Item.TopLeft
        implicitHeight: Math.min(contentItem.implicitHeight + 12, 280, parent ? (parent.height - 16) / scale : 280)
        padding: 6
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: {
            positionInsideWindow()
            Qt.callLater(positionInsideWindow)
            popupList.currentIndex = control.currentIndex >= 0 ? control.currentIndex : 0
            popupList.positionViewAtIndex(popupList.currentIndex, ListView.Contain)
            popupList.forceActiveFocus()
        }
        onClosed: control.forceActiveFocus()
        background: Rectangle {
            radius: 14
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
