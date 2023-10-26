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

    //property color line_fill_color: "green"
    //property color line_outline_color: "yellow"
    //property color middle_element_color: "green"
    property color line_fill_color: settings.color_shape
    property color line_outline_color: settings.color_glow
    property color middle_element_color: settings.color_shape

    widgetDetailComponent: ScrollView {

        contentHeight: idBaseWidgetDefaultUiControlElements.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        BaseWidgetDefaultUiControlElements{
            id: idBaseWidgetDefaultUiControlElements

            show_vertical_lock: true
            show_horizontal_lock: true
            show_transparency: true

        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        // There is no point in making this one opaque
        opacity: 1.0
        //opacity: bw_current_opacity
        scale: bw_current_scale

        // actual horizon
        Item{
            id: horizon_item
            width: parent.width;
            height: 4
            anchors.centerIn: parent
            // Left line
            Rectangle{
                id: left_line
                width: (parent.width/2) - 20
                height: parent.height
                anchors.left: parent.left
                color: line_fill_color
                border.color: line_outline_color
                border.width: 1
                antialiasing: true
            }
            //
            // Here is the middle, which isn't rotated and therefore not placed in here
            //
            // Right line
            Rectangle{
                id: right_line
                width: left_line.width
                height: parent.height
                anchors.right: parent.right
                color: line_fill_color
                border.color: line_outline_color
                border.width: 1
                antialiasing: true
            }
            transform: [
                // First rotate (roll)
                Rotation {
                    origin.x: horizon_item.width/2;
                    origin.y: horizon_item.height/2;
                    angle: _fcMavlinkSystem.roll*-1
                    //angle: 0
                },
                // Then translate (pitch)
                Translate{
                    y: _fcMavlinkSystem.pitch*4
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
           //border.color: "green"
           border.color: middle_element_color
           border.width: 2
        }
        Rectangle{
            id: middle_indicator2
            height: 2;
            width: 30
            anchors.centerIn: parent
            color: middle_element_color
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
