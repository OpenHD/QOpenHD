import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: horizonWidget
    width: 250
    height: 48

    visible: settings.show_performance_horizon

    widgetIdentifier: "performance_horizon_widget"
    bw_verbose_name: "PERFORMANCE HORIZON"

    defaultHCenter: true
    defaultVCenter: true

    hasWidgetDetail: true

    m_show_grid_when_dragging : true

    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Width")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: horizon_width_Slider
                    orientation: Qt.Horizontal
                    from: 1
                    value: 0
                    to: 10
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {

                    }
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: bw_current_opacity

        Rectangle {
            id: horizonLadder2
            visible: true
            width: 400
            height: 300
            //border.width: 2
            //border.color: "green"
            //color: "green"
            color: "transparent"

            anchors.centerIn: parent

            PerformanceHorizonLadder{
                id: performanceHorizonLadder
                width: 400
                height: 300
                anchors.centerIn: parent

                pitch: _fcMavlinkSystem.pitch
                roll: _fcMavlinkSystem.roll

                Behavior on pitch {NumberAnimation { duration: settings.smoothing }}
                Behavior on roll {NumberAnimation { duration: settings.smoothing }}
            }

        }
    }
}
