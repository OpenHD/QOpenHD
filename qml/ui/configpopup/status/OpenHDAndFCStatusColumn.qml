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
    width: parent.width
    height: 300


    RowLayout {
        width: parent.width
        height: parent.height

        Card {
            id: groundBox
            Layout.fillHeight: true
            Layout.fillWidth: true
            cardName: qsTr("OHD Ground station")

            m_style_error: !_ohdSystemGround.is_alive

            cardBody: StatusCardBodyOpenHD{
                m_is_ground: true
            }

            hasFooter: true
            cardFooter: Item {
                anchors.fill: parent
                Button {
                    id: groundReboot
                    width: 96
                    height: 48
                    text: qsTr("Reboot")
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    font.pixelSize: 14
                    font.capitalization: Font.MixedCase
                    enabled: _ohdSystemGround.is_alive

                    onPressed: {
                        open_power_action_dialoque(PowerActionDialoque.PowerAction.RebootGround)
                    }
                }

                Button {
                    id: groundShutdown
                    width: 96
                    height: 48
                    text: qsTr("Shutdown")
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    font.pixelSize: 14
                    font.capitalization: Font.MixedCase
                    Material.accent: Material.Red
                    highlighted: true
                    enabled: _ohdSystemGround.is_alive

                    onPressed: {
                        open_power_action_dialoque(PowerActionDialoque.PowerAction.ShutdownGround)
                    }
                }
            }
        }

        Card {
            id: airBox
            Layout.fillHeight: true
            Layout.fillWidth: true
            cardName: qsTr("OHD Air unit")
            m_style_error: !_ohdSystemAir.is_alive
            cardBody: StatusCardBodyOpenHD{
                m_is_ground: false
            }

            hasFooter: true
            cardFooter: Item {
                anchors.fill: parent
                Button {
                    id: airReboot
                    width: 96
                    height: 48
                    text: qsTr("Reboot")
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    font.pixelSize: 14
                    font.capitalization: Font.MixedCase
                    enabled: _ohdSystemAir.is_alive

                    onPressed: {
                        open_power_action_dialoque(PowerActionDialoque.PowerAction.RebootAir)
                    }
                }

                Button {
                    id: airShutdown
                    width: 96
                    height: 48
                    text: qsTr("Shutdown")
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    font.pixelSize: 14
                    font.capitalization: Font.MixedCase
                    Material.accent: Material.Red
                    highlighted: true
                    enabled: _ohdSystemAir.is_alive

                    onPressed: {
                        open_power_action_dialoque(PowerActionDialoque.PowerAction.ShutdownAir);
                    }
                }
            }
        }


        Card {
            id: fcBox
            visible: true
            enabled: _fcMavlinkSystem.is_alive
            Layout.fillHeight: true
            Layout.fillWidth: true
            cardName: qsTr("Flight Controller")
            m_style_error: !_fcMavlinkSystem.is_alive
            cardBody: StatusCardBodyFC{

            }

            hasFooter: true
            cardFooter: Item {
                anchors.fill: parent
                Button {
                    id: fcReboot
                    width: 96
                    height: 48
                    text: qsTr("Reboot")
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    font.pixelSize: 14
                    font.capitalization: Font.MixedCase

                    onPressed: {
                        open_power_action_dialoque(PowerActionDialoque.PowerAction.RebootFC)
                    }
                }
            }
        }
    } // end OpenHD air, ground, FC status cards layout

}
