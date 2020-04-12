import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import OpenHD 1.0

BaseWidget {
    id: fpvWidget
    width: 50
    height: 50

    visible: settings.show_fpv

    widgetIdentifier: "fpv_widget"

    defaultHCenter: true
    defaultVCenter: true

    hasWidgetDetail: true
    widgetDetailComponent: Column {
        Item {
            width: parent.width
            height: 32
            Text {
                text: "Dynamic (off) / (on)"
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels;
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 12
                anchors.right: parent.right
                checked: settings.fpv_dynamic
                onCheckedChanged: settings.fpv_dynamic = checked
            }
        }
        Item {
            width: parent.width
            height: 32            
            Text {
                id: sensitivityTitle
                text: "Sensitivity"
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Slider {
                id: fpvSlider
                orientation: Qt.Horizontal
                from: 1
                value: settings.fpv_sensitivity
                to: 20
                stepSize: 1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.fpv_sensitivity = fpvSlider.value
                }
            }
        }
        Item {
            width: parent.width
            height: 32
            Text {
                id: opacityTitle
                text: "Opacity"
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Slider {
                id: fpv_opacity_Slider
                orientation: Qt.Horizontal
                from: .1
                value: settings.fpv_opacity
                to: 1
                stepSize: .1
                height: parent.height
                anchors.rightMargin: 0
                anchors.right: parent.right
                width: parent.width - 96

                onValueChanged: {
                    settings.fpv_opacity = fpv_opacity_Slider.value
                }
            }
        }
    }

    function getLateralSpeed() {
            /*this function can be leveraged later to determine wind direction/speed

              magnitude of our motion vector */
            var resultant_magnitude = Math.sqrt(OpenHD.vx * OpenHD.vx + OpenHD.vy * OpenHD.vy);

            //direction of motion vector in radians then converted to degree
            var resultant_angle = Math.atan2 (OpenHD.vy , OpenHD.vx)*(180/Math.PI);

            //converted from degrees to a compass heading
            if (resultant_angle < 0.0){
                resultant_angle += 360;
            }

            //Compare the motion heading to the vehicle heading
            var left = OpenHD.hdg - resultant_angle;
            var right = resultant_angle - OpenHD.hdg;
            if (left < 0) left += 360;
            if (right < 0) right += 360;
            var heading_diff = left < right ? -left : right;

            var vehicle_vx
            var vehicle_vy

            if (heading_diff > 0 && heading_diff <= 90){
                //console.log("we are moving forward and or right");
                vehicle_vx=(heading_diff/90)*resultant_magnitude;
            }
            else if (heading_diff > 90 && heading_diff <= 180){
                //console.log("we are moving backwards and or right");
                vehicle_vx=((heading_diff*-1)+180)/90*resultant_magnitude;
            }
            else if (heading_diff > -180 && heading_diff <= -90){
                //console.log("we are moving backwards and or left");
                vehicle_vx=((heading_diff+180)/90)*-1*resultant_magnitude;
            }
            else{
                //console.log("we are moving forward and or left");
                vehicle_vx=(heading_diff/90)*resultant_magnitude;
            }
            return vehicle_vx * settings.fpv_sensitivity
        }

    Item {
        id: widgetInner
        height: 40
        anchors.horizontalCenter: parent.horizontalCenter
        width: 40
        anchors.verticalCenter: parent.verticalCenter

        rotation: settings.horizon_invert_roll ? OpenHD.roll : -OpenHD.roll

        //had to add another item to compensate for rotation above
        Item {
            id: fpvInner

            height: 40
            anchors.horizontalCenter: parent.horizontalCenter
            width: 40
            anchors.verticalCenter: parent.verticalCenter

            transformOrigin: Item.Center
            transform: Translate {

                x: settings.fpv_dynamic ? getLateralSpeed() : 0

                //to get pitch relative to ahi add pitch in
                y: settings.fpv_dynamic ? (settings.horizon_invert_pitch ? (-OpenHD.vz * settings.fpv_sensitivity) - OpenHD.pitch :
                                               (OpenHD.vz * settings.fpv_sensitivity) + OpenHD.pitch) : 0
             }


            antialiasing: true

            Glow {
                anchors.fill: widgetGlyph
                radius: 4
                samples: 17
                color: settings.color_glow
                opacity: settings.fpv_opacity
                source: widgetGlyph
            }

            Text {
                id: widgetGlyph
                width: 24
                height: 24
                color: settings.color_shape
                opacity: settings.fpv_opacity
                text: "\ufdd5"
                bottomPadding: 17
                leftPadding: 33
                horizontalAlignment: Text.AlignHCenter
                font.capitalization: Font.MixedCase
                renderType: Text.QtRendering
                textFormat: Text.AutoText
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                font.family: "Font Awesome 5 Free"
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 24
            }
        }
    }
}



