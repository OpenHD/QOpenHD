import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12


Button {

    property bool m_is_visible: true


    //text: "INFO"
    text: "\uf05a"
    font.family: "Font Awesome 5 Free"
    Material.background:Material.LightBlue
    visible: m_is_visible


    /*onClicked: {
        _messageBoxInstance.set_text_and_show(m_long_description)
    }*/
}
