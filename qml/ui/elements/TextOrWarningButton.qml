import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0


// Shows a green text if everything is okay
// Otherwise, shows a button the user can click on to find out why the given
// warning is showing
Item {

    property bool m_show_warning: false

    property string m_info_text: "BLA"
    property string m_warning_text: "HERE A WARNING SHOULD STAND"

    ButtonRed{
        width: parent.width
        height: parent.height
        onClicked: {
            _messageBoxInstance.set_text_and_show(m_warning_text);
        }
        visible: m_show_warning
    }

    Text{
        width: parent.width
        height: parent.height
        text: m_info_text
        color: "green"
    }

}
