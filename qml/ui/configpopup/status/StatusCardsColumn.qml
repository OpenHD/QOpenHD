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
Item {

    RowLayout {
        width: parent.width
        height: parent.height

        Card {
            id: groundBox
            Layout.fillHeight: true
            Layout.fillWidth: true
            cardName: qsTr("OHD Ground station")

            m_style_error: !_ohdSystemGround.is_alive
            //m_style_error: false

            cardBody: StatusCardBodyOpenHD{
                m_is_ground: true
            }

            hasFooter: true
            cardFooter: StatusCardFooterGenericOHDFC{
                m_type: 0
            }
        }

        Card {
            id: airBox
            Layout.fillHeight: true
            Layout.fillWidth: true
            cardName: qsTr("OHD Air unit")
            m_style_error: !_ohdSystemAir.is_alive
            //m_style_error: false
            cardBody: StatusCardBodyOpenHD{
                m_is_ground: false
            }

            hasFooter: true
            cardFooter: StatusCardFooterGenericOHDFC{
                m_type: 1
            }
        }


        Card {
            id: fcBox
            visible: true
            Layout.fillHeight: true
            Layout.fillWidth: true
            cardName: qsTr("Flight Controller")
            m_style_error: !_fcMavlinkSystem.is_alive
            //m_style_error: false
            cardBody: StatusCardBodyFC{

            }

            hasFooter: true
            cardFooter: StatusCardFooterGenericOHDFC{
                m_type: 2
            }
        }
    } // end OpenHD air, ground, FC status cards layout

}
