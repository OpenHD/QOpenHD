import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12

import QtQuick.Controls.Material 2.12

// Base element for QOpenHD settings.
// NOTE: QOpenHD, not OpenHD/Mavlink settings !
// It does not define the element that is actually then used to edit the QT setting -
// See any implementation for an example how to use.
// This element could be a Switch, a SpinBox, ...
// E.g. visualized a single column with this layout:
// ----------------------------------------------------------------------------------
// | [Description]    [opional info popup]          [actuall seting element, empty] |
// ----------------------------------------------------------------------------------
// Description UI element  -> fetched from @property m_short_description
// Optional info popup     -> icon visible when @property m_long_description!=="none"
// actuall seting element  -> fill with e.g. your QT settings element, e.g. a Switch
Rectangle {
    width: parent.width
    height: rowHeight
    radius: 7
    color: (Positioner.index % 2 === 0) ? settings_form.panelBackgroundRaised : "transparent"
    border.color: settings_form.lineColor
    border.width: Positioner.index % 2 === 0 ? 1 : 0

    // Set this to the setting(s) short description.
    // This value is always shown inside a text view on the left
    property string m_short_description: "PLACEHOLDER"

    // Optionally - set this to the setting(s) long descrition.
    // If a long description is set, a "info" icon is shown right next
    // to the setting(s) short description, and clicking it opens up a popup
    // with the long description.
    property string  m_long_description: "none"

    function has_valid_long_description(){
        return m_long_description !== "none"
    }


    Text {
        id: description
        text: qsTr(m_short_description)
        font.weight: Font.Bold
        font.pixelSize: 13
        anchors.leftMargin: 12
        verticalAlignment: Text.AlignVCenter
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(150, Math.min(260, parent.width * 0.45))
        height: elementHeight
        anchors.left: parent.left
        color: settings_form.primaryText
        elide: Text.ElideRight
    }

}
