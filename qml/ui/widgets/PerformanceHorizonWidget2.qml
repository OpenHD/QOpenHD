import QtQuick 2.15
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import QtQuick.Shapes 1.0

import OpenHD 1.0

BaseWidget {
    id: horizonWidget
    width: 250
    height: 48

    visible: settings.show_performance_horizon

    widgetIdentifier: "horizon_performance2"
    bw_verbose_name: "ARTIFICIAL HORIZON 2"

    defaultHCenter: true
    defaultVCenter: true

    hasWidgetDetail: true
    widgetDetailHeight: 250+250

    m_show_grid_when_dragging : true

    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements

            show_vertical_lock: true
            show_horizontal_lock: true

        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: bw_current_opacity

        // actual horizon
        Item{
            id: horizon_item
            width: parent.width;
            height: 4
            anchors.centerIn: parent
            // Left line
            Rectangle{
                width: parent.width/3
                height: parent.height
                anchors.left: parent.left
                color: "green"
                //color:  settings.color_text
                //border.color: settings.color_glow
                //border.width: 1
            }
            //
            // Here is the middle, which isn't rotated and therefore not placed in here
            //
            // Right line
            Rectangle{
                width: parent.width/3
                height: parent.height
                anchors.right: parent.right
                color: "green"
            }
            transform: [
                // First rotate (roll)
                Rotation {
                    origin.x: horizon_item.width/2;
                    origin.y: horizon_item.height/2;
                    //angle: _fcMavlinkSystem.roll*-1
                    angle: 0
                },
                // Then translate (pitch)
                Translate{
                    y: 0
                }
            ]
        }
        // The middle indicator
        Rectangle {
           id: middle_indicator
           height: 20
           width: 20
           radius: width/2;
           anchors.centerIn: parent
           color: "transparent"
           border.color: "green"
           border.width: 2
        }
        Rectangle{
            id: middle_indicator2
            height: 2;
            width: 30
            anchors.centerIn: parent
            color: "green"
        }

        /*Rectangle{
            width: 3;
            height: 2;
            color: "green"
            anchors.left: middle_indicator.left
            anchors.top: middle_indicator.top
        }*/
    }
    /*Rectangle{
        id: debug_rect
        implicitWidth: widgetInner.width
        implicitHeight: widgetInner.height
        color: "red"
        opacity: 0.8
    }*/
}
