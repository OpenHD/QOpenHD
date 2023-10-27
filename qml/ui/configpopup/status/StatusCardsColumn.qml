import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

//
// The 3 status cards (OpenHD AIR & GND, FC)
// next to each other
RowLayout{
    width: parent.width
    height: parent.height

    property int m_card_width: parent.width/3;
    property int m_card_height: 350

    Card {
        width: m_card_width
        height:m_card_height
        id: groundBox
        cardName: qsTr("Ground station")

        //visible: _ohdSystemGround.is_alive
        m_style_error: !_ohdSystemGround.is_alive

        cardBody: StatusCardBodyOpenHD{
            m_is_ground: true
        }

        hasFooter: true
        cardFooter: FooterRebootShutdownWarning{
            m_type: 0
        }
    }
    Card {
        width: m_card_width
        height:m_card_height
        id: airBox
        cardName: qsTr("Air unit")
        //visible: _ohdSystemAir.is_alive
        m_style_error: !_ohdSystemAir.is_alive

        cardBody: StatusCardBodyOpenHD{
            m_is_ground: false
        }

        hasFooter: true
        cardFooter: FooterRebootShutdownWarning{
            m_type: 1
        }
    }

    Card {
        width: m_card_width
        height:m_card_height
        id: fcBox
        cardName: qsTr("Flight Controller")
        //visible: _fcMavlinkSystem.is_alive
        m_style_error: !_fcMavlinkSystem.is_alive
        cardBody: StatusCardBodyFC{

        }

        hasFooter: true
        cardFooter: FooterRebootShutdownWarning{
            m_type: 2
        }
    }
}

