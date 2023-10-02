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

    ColumnLayout {
        id: ohdCards
        width: parent.width - 24
        height: parent.height
        anchors.centerIn: parent
        property int maximumWidth: width

        RowLayout {
            width: parent.width - 24
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            Card {
                id: groundBox
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.maximumWidth: ohdCards.maximumWidth/3
                cardName: qsTr("Ground station")

                visible: _ohdSystemGround.is_alive

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
                Layout.maximumWidth: ohdCards.maximumWidth/3
                cardName: qsTr("Air unit")
                visible: _ohdSystemAir.is_alive
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
                Layout.fillHeight: true
                Layout.fillWidth: true
                cardName: qsTr("Flight Controller")
                visible: _fcMavlinkSystem.is_alive
                cardBody: StatusCardBodyFC{

                }

                hasFooter: true
                cardFooter: StatusCardFooterGenericOHDFC{
                    m_type: 2
                }
            }
            Image {
                    id: ee1
                    visible: !_ohdSystemAir.is_alive && !_ohdSystemGround.is_alive && !_ohdSystemGround.is_alive
                    source: "../../../resources/noconnection.svg"
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    Layout.topMargin: Layout.preferredWidth * -0.15
                    Layout.preferredWidth: ohdCards.width * 0.5
                    Layout.preferredHeight: Layout.preferredWidth
                }
        }
    }
}
