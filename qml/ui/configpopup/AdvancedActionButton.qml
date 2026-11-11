/******************************************************************************
 * OpenHD
 *
 * Licensed under the GNU General Public License (GPL) Version 3.
 *
 * This software is provided "as-is," without warranty of any kind, express or
 * implied, including but not limited to the warranties of merchantability,
 * fitness for a particular purpose, and non-infringement. For details, see the
 * full license in the LICENSE file provided with this source code.
 *
 * Non-Military Use Only:
 * This software and its associated components are explicitly intended for
 * civilian and non-military purposes. Use in any military or defense
 * applications is strictly prohibited unless explicitly and individually
 * licensed otherwise by the OpenHD Team.
 *
 * Contributors:
 * A full list of contributors can be found at the OpenHD GitHub repository:
 * https://github.com/OpenHD
 *
 * © OpenHD, All Rights Reserved.
 ******************************************************************************/

import "MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Controls 2.12

Button { font.family: MenuTypography.family; font.pixelSize: MenuTypography.body;
    id: control
    property bool primary: false
    property bool destructive: false
    property string iconText: ""
    implicitHeight: MenuTypography.controlHeight
    implicitWidth: Math.max(MenuTypography.controlMinWidth, buttonLabel.implicitWidth + (control.iconText.length ? MenuTypography.controlIcon + 8 : 0) + MenuTypography.controlPadding * 2)
    topInset: 0; bottomInset: 0; leftInset: 0; rightInset: 0
    leftPadding: MenuTypography.controlPadding; rightPadding: MenuTypography.controlPadding
    topPadding: 0; bottomPadding: 0
    hoverEnabled: true
    activeFocusOnTab: true
    font.capitalization: Font.MixedCase

    readonly property var _sf: { try { return settings_form } catch(e) { return null } }
    QtObject {
        id: _fallback
        readonly property bool darkMode: true
        readonly property color primaryText: "#f2f6fb"
        readonly property color secondaryText: "#aebdcb"
        readonly property color lineColor: "#26394c"
        readonly property color panelBackground: "#102235"
        readonly property color panelBackgroundRaised: "#15283b"
        readonly property color accentColor: "#278cff"
        readonly property color errorColor: "#ff4e5d"
    }
    readonly property var _theme: _sf ? _sf : _fallback

    background: Rectangle {
        radius: MenuTypography.controlRadius
        color: control.primary ? _theme.accentColor
                               : (control.down || control.hovered
                                  ? _theme.panelBackgroundRaised
                                  : _theme.panelBackground)
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? _theme.accentColor
                                         : (control.destructive ? _theme.errorColor : _theme.lineColor)
    }
    contentItem: Item {
        Text {
            id: buttonIcon
            visible: control.iconText.length > 0
            anchors.left: control.text.length ? parent.left : undefined
            anchors.horizontalCenter: control.text.length ? undefined : parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            text: control.iconText
            color: control.primary ? "white" : (control.destructive ? _theme.errorColor : _theme.primaryText)
            font.family: "Font Awesome 5 Free"; font.pixelSize: MenuTypography.controlIcon
        }
        Text {
            id: buttonLabel; objectName: "actionButtonLabel"
            anchors.fill: parent; anchors.leftMargin: buttonIcon.visible ? MenuTypography.controlIcon + 8 : 0
            text: control.text
            color: control.primary ? "white" : (control.destructive ? _theme.errorColor : _theme.primaryText)
            font.pixelSize: MenuTypography.body; font.family: MenuTypography.family; font.bold: true
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap; clip: true
        }
    }
}
