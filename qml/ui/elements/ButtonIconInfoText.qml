import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

// Same as ButtonIconInfo, but if the user clicks this button,
// a programmer defined text is shown in the workaround message box (popup)
ButtonIconInfo{
    property string m_info_text: "I should never appear" // Intended to be overridden

    onClicked: {
        _messageBoxInstance.set_text_and_show(m_info_text);
    }
}
