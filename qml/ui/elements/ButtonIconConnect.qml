import QtQuick 2.12
import QtQuick.Controls 2.12

import QtQuick.Controls.Material 2.12

// Connect - either wired (wired icon) or wireless (wireless icon)
Button {
    property bool m_type_wired: false
    text: m_type_wired ? "\uf6ff" : "\uf1eb"
    font.family: "Font Awesome 5 Free"
    font.pixelSize: 14
    //highlighted: true
}
