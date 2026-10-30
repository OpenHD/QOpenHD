import "MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Controls 2.12

TabButton { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
    id: control
    // Declare availability independently of effective visibility: a hidden
    // parent page must not make every child tab appear empty.
    property bool hasContent: true
    Keys.forwardTo: TabBar.tabBar ? [TabBar.tabBar] : []
    visible: hasContent
    width: hasContent ? implicitWidth : 0
    onHasContentChanged: {
        if (TabBar.tabBar && typeof TabBar.tabBar.ensureAvailableTab === "function")
            Qt.callLater(TabBar.tabBar.ensureAvailableTab)
    }
    property string iconText: ""
    readonly property bool iconOnly: iconText.length > 0 && TabBar.tabBar && TabBar.tabBar.compactTabs === true
    readonly property real naturalWidth: Math.max(MenuTypography.controlMinWidth, label.implicitWidth + (iconText.length > 0 ? 26 : 0) + MenuTypography.controlPadding * 2)
    Accessible.name: text
    implicitHeight: MenuTypography.controlHeight
    implicitWidth: iconOnly ? MenuTypography.controlHeight : naturalWidth
    hoverEnabled: true
    activeFocusOnTab: true
    padding: 0
    topInset: 0; bottomInset: 0; leftInset: 0; rightInset: 0

    contentItem: Item {
        Row {
            id: tabContent
            anchors.centerIn: parent
            spacing: control.iconText.length > 0 && !control.iconOnly ? 8 : 0

            Text {
                visible: control.iconText.length > 0
                width: visible ? 18 : 0
                height: Math.max(18, label.implicitHeight)
                text: control.iconText
                color: control.checked ? "white" : settings_form.secondaryText
                font.family: "Font Awesome 5 Free"
                font.pixelSize: MenuTypography.controlIcon
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: label
                visible: !control.iconOnly
                height: Math.max(18, implicitHeight)
                text: control.text
                color: control.checked ? "white" : settings_form.primaryText
                font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
    background: Rectangle {
        radius: MenuTypography.controlRadius
        color: control.checked ? settings_form.accentColor
                               : (control.hovered ? settings_form.panelBackgroundRaised : settings_form.panelBackground)
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? settings_form.accentColor : settings_form.lineColor
    }
}
