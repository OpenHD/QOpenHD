import QtQuick 2.12
import QtQuick.Controls 2.12
import "../MenuTypography.js" as MenuTypography
import "../../elements"
Item {
 width:parent.width;implicitHeight:legacyColumn.height
 Column {id:legacyColumn;width:parent.width;spacing:5
            SettingBaseElement {
                m_short_description: qsTr("Show advanced settings")
                Switch {
                    anchors.right: parent.right
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.dev_show_advanced_button
                    onToggled: {
                        settings.dev_show_whitelisted_params = checked
                        settings.dev_show_advanced_button = checked
                    }
                }
            }

            SettingBaseElement{
                m_short_description: qsTr("Ground Battery Cells")

                SpinBox {
                    id: gndBatteryCellspinBox
                    height: elementHeight
                    width: 210
                    font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    from: 1
                    to: 6
                    stepSize: 1
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                    value: settings.ground_battery_cells
                    onValueChanged: settings.ground_battery_cells = value
                }
            }

            // exp
            SettingBaseElement{
                m_short_description: qsTr("Mavlink sys id")
                m_long_description: qsTr("Mavlink sys id of QOpenHD (this Ground control station application). Leave default (255) ! . Change requires restart.")

                SpinBox {
                    id: mavlinkSysIDSpinBox
                    height: elementHeight
                    width: 210
                    font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    from: 1
                    to: 255
                    stepSize: 1
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                    value: settings.qopenhd_mavlink_sysid
                    onValueChanged: {
                        if(value==100 || value==101){
                            // openhd air and ground unit sys id are hard coded, one should never use them
                            _messageBoxInstance.set_text_and_show(qsTr("Do not use 100 or 101 for QOpenHD sys id"))
                        }
                        settings.qopenhd_mavlink_sysid = value
                    }
                }
            }
            SettingBaseElement{
                m_short_description: qsTr("Latitude GPS offset")
                m_long_description: qsTr("Set this to a random value only you know to hide lat identity")

                /*SpinBox {
                    height: elementHeight
                    width: 210
                    font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                    from: -10
                    to: 10
                    stepSize: 1
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                    value: settings.hide_identity_latitude_offset
                    onValueChanged: {
                        settings.hide_identity_latitude_offset = value
                    }
                }*/
                XDecimalSpinBox{
                    height: elementHeight
                    width: 210
                    font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                    m_default_value: settings.hide_identity_latitude_offset

                    onRealValueChanged: {
                        if(settings.hide_identity_latitude_offset!=realValue){
                            settings.hide_identity_latitude_offset=realValue
                            console.log("Value is: "+settings.hide_identity_latitude_offset)
                        }
                    }
                }

            }
            SettingBaseElement{
                m_short_description: qsTr("Longitude GPS offset")
                m_long_description: qsTr("Set this to a random value only you know to hide lon identity")

                XDecimalSpinBox{
                    height: elementHeight
                    width: 210
                    font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                    m_default_value: settings.hide_identity_longitude_offset

                    onRealValueChanged: {
                        if(settings.hide_identity_longitude_offset!=realValue){
                            settings.hide_identity_longitude_offset=realValue
                            console.log("Value is: "+settings.hide_identity_longitude_offset)
                        }
                    }
                }
            }

 }
}
