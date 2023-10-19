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
Item{
    width: parent.width
    height: parent.height

    property int m_padding_between: 4

    property int m_card_width: parent.width/3 - (m_padding_between)

    Rectangle{
        id: background1
        width: m_card_width
        height: parent.height
        anchors.left: parent.left
        anchors.leftMargin: m_padding_between
        color: "red"
        //
        Card {
            width: parent.width
            height:parent.height
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
    }

    Rectangle{
        id: background2
        width: m_card_width
        height: parent.height
        anchors.left: background1.right
        anchors.leftMargin: m_padding_between
        color: "green"
        //
        Card {
            width: parent.width
            height:parent.height
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

    }

    Rectangle{
        id: background3
        //width: m_card_width
        height: parent.height
        anchors.rightMargin: m_padding_between
        anchors.leftMargin: m_padding_between
        anchors.right: parent.right
        anchors.left: background2.right
        color: "orange"
        Card {
            width: parent.width
            height:parent.height
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

}

