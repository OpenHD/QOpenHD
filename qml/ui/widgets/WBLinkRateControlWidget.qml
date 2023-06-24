import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

BaseWidget {

    id: wblinkratewidget
    width: 96
    height: 25

    visible: settings.wb_link_rate_control_widget_show

    widgetIdentifier: "wb_link_rate_control_widget"
    bw_verbose_name: "WB LIVE RATE CONTROL"

    defaultAlignment: 0
    defaultXOffset: 400
    defaultYOffset: 2
    defaultHCenter: false
    defaultVCenter: false

    hasWidgetDetail: true
    hasWidgetAction: true

    property int m_curr_mcs_index: _ohdSystemAir.curr_mcs_index

    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements
        }
    }

    //---------------------------ACTION WIDGET COMPONENT BELOW-----------------------------
    widgetActionComponent: ScrollView {

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        ColumnLayout {
            width: 200
            spacing: 10

            Item {
                height: 32
                width: parent.width
                Text {
                    id: simpleDescription
                    text: "Trade Range/Quality"
                    color: "white"
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                }
                /*Button{
                    height: 32
                    width: 32
                    text: "\uf05a"
                    anchors.left: simpleDescription.right
                    anchors.top: simpleDescription.top
                    Material.background:Material.LightBlue
                    leftPadding: 5
                }*/
            }
            Item{
                width: parent.width
                height: parent.height - 32
                //color: "green"
                GridLayout{
                    width: parent.width
                    height: parent.height
                    rows: 2
                    columns: 2
                    Button{
                        text: "MCS0"
                        onClicked: {
                             _synchronizedSettings.change_param_air_only_mcs(0,true)
                        }
                        highlighted: m_curr_mcs_index==0
                    }
                    Button{
                        text: "MCS1"
                        onClicked: {
                             _synchronizedSettings.change_param_air_only_mcs(1,true)
                        }
                        highlighted: m_curr_mcs_index==1
                    }
                    Button{
                        text: "MCS2"
                        onClicked: {
                             _synchronizedSettings.change_param_air_only_mcs(2,true)
                        }
                        highlighted: m_curr_mcs_index==2
                    }
                    Button{
                        text: "MCS3"
                        onClicked: {
                             _synchronizedSettings.change_param_air_only_mcs(3,true)
                        }
                        highlighted: m_curr_mcs_index==3
                    }
                    /*Button{
                        text: "MCS4"
                        onClicked: {
                             _synchronizedSettings.change_param_air_only_mcs(4,true)
                        }
                    }*/
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        scale: bw_current_scale

        Item {
            anchors.fill: parent
            anchors.centerIn: parent

            Text {
                y: 0
                width: parent.width
                height: 14
                color: settings.color_text
                text: m_curr_mcs_index==-1 ? "MCS:NA" : "MCS: "+m_curr_mcs_index;
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 0
                verticalAlignment: Text.AlignBottom
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 14
                font.family: settings.font_text
                style: Text.Outline
                styleColor: settings.color_glow
            }
        }
    }
}
