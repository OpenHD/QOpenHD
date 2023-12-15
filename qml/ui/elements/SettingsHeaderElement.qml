import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

// Base element for QOpenHD settings.
// NOTE: QOpenHD, not OpenHD/Mavlink settings !
// It does not define the element that is actually then used to edit the QT setting -
// See any implementation for an example how to use.
// This element could be a Switch, a NewSpinBox, ...
// E.g. visualized a single column with this layout:
// ----------------------------------------------------------------------------------
// | [Description]    [opional info popup]          [actuall seting element, empty] |
// ----------------------------------------------------------------------------------
// Description UI element  -> fetched from @property m_short_description
// Optional info popup     -> icon visible when @property m_long_description!=="none"
// actuall seting element  -> fill with e.g. your QT settings element, e.g. a Switch
Rectangle {
    width: parent.width
    height: rowHeight*2 / 3;
    //color: "green"
    //color: "#8cbfd7f3"
    color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

    Rectangle{
        width: parent.width
        height: 2
        color: "black"
        anchors.bottom: parent.bottom
        anchors.left: parent.left
    }

    property string m_description: "FILL ME"


    Text {
        id: description
        text: qsTr(m_description)
        font.weight: Font.Bold
        font.pixelSize: 13
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.fill: parent

        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter

    }
}
