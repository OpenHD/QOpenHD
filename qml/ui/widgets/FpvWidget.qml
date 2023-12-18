import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import QtQuick.Controls.Material 2.12

import OpenHD 1.0

BaseWidget {
    id: fpvWidget
    width: 50
    height: 55

    visible: settings.show_flight_path_vector

    widgetIdentifier: "fpv_widget"
    bw_verbose_name: "FLIGHT PATH VECTOR"

    defaultHCenter: true
    defaultVCenter: true

    hasWidgetDetail: true
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
                    text: qsTr("Dynamic")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.fpv_dynamic
                    onCheckedChanged: settings.fpv_dynamic = checked
                }
            }

            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Invert Pitch")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Switch {
                    width: 32
                    height: parent.height
                    anchors.rightMargin: 6
                    anchors.right: parent.right
                    checked: settings.fpv_invert_pitch
                    onCheckedChanged: settings.fpv_invert_pitch = checked
                }
            }


            /* not really needed
        Item {
            width: 230
            height: 32
            Text {
                id: invertTitle
                text: qsTr("Invert Roll")
                color: "white"
                height: parent.height
                font.bold: true
                font.pixelSize: detailPanelFontPixels
                anchors.left: parent.left
                verticalAlignment: Text.AlignVCenter
            }
            Switch {
                width: 32
                height: parent.height
                anchors.rightMargin: 6
                anchors.right: parent.right
                checked: settings.fpv_invert_roll
                onCheckedChanged: settings.fpv_invert_roll = checked
            }
        }
        */
            Item {
                width: 230
                height: 50
                visible: settings.fpv_dynamic ? true : false

                Text {
                    text: qsTr("Vertical Limit")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    height: 40
                    width: 30
                    anchors.rightMargin: 15
                    anchors.right: parent.right
                    antialiasing: true

                    Tumbler {
                        model: 90
                        visibleItemCount: 1
                        anchors.fill: parent

                        currentIndex: settings.fpv_vertical_limit

                        Component.onCompleted: {
                            // rounds it due to int
                            currentIndex = settings.fpv_vertical_limit
                        }
                        delegate: Text {
                            text: modelData
                            color: "white"

                            font.family: "Arial"
                            font.weight: Font.Thin
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            //opacity: 1.0 - Math.abs(Tumbler.displacement) / root.visibleItemCount
                            scale: opacity
                        }
                        onCurrentIndexChanged: {
                            settings.fpv_vertical_limit = currentIndex
                            //   console.log("vert limit-",settings.fpv_vertical_limit);
                        }
                    }
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: Material.color(Material.Grey,
                                                  Material.Shade500)
                        }
                        GradientStop {
                            position: 0.5
                            color: "transparent"
                        }
                        GradientStop {
                            position: 1.0
                            color: Material.color(Material.Grey,
                                                  Material.Shade500)
                        }
                    }
                }
            }
            Item {
                width: 230
                height: 50
                visible: settings.fpv_dynamic ? true : false

                Text {
                    text: qsTr("Lateral Limit")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    height: 40
                    width: 30
                    anchors.rightMargin: 15
                    anchors.right: parent.right
                    antialiasing: true

                    Tumbler {
                        model: 90
                        visibleItemCount: 1
                        anchors.fill: parent

                        currentIndex: settings.fpv_lateral_limit

                        Component.onCompleted: {
                            // rounds it due to int
                            currentIndex = settings.fpv_lateral_limit
                        }
                        delegate: Text {
                            text: modelData
                            color: "white"

                            font.family: "Arial"
                            font.weight: Font.Thin
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            //opacity: 1.0 - Math.abs(Tumbler.displacement) / root.visibleItemCount
                            scale: opacity
                        }
                        onCurrentIndexChanged: {
                            settings.fpv_lateral_limit = currentIndex
                            //   console.log("vert limit-",settings.fpv_vertical_limit);
                        }
                    }
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: Material.color(Material.Grey,
                                                  Material.Shade500)
                        }
                        GradientStop {
                            position: 0.5
                            color: "transparent"
                        }
                        GradientStop {
                            position: 1.0
                            color: Material.color(Material.Grey,
                                                  Material.Shade500)
                        }
                    }
                }
            }
        }
    }

    Item {
        id: widgetInner
        height: 40

        width: 40

        anchors.centerIn: parent

        visible: settings.show_flight_path_vector
        opacity: bw_current_opacity

        Item {
            id: flightPathVector

            anchors.centerIn: parent

            visible: settings.show_flight_path_vector

            //transform: Scale { origin.x: 0; origin.y: 0; xScale: bw_current_scale ; yScale: bw_current_scale}
            FlightPathVector {
                id: fpvC
                anchors.centerIn: parent

                /* could turn the width and height into settings and thereby clip the fpv
                  *even theough clipping is false it still clips
                */
                width: 1200
                height: 800
                clip: false
                color: settings.color_shape
                glow: settings.color_glow
                fpvInvertPitch: settings.fpv_invert_pitch
                fpvInvertRoll: settings.fpv_invert_roll

                /*
                fpvSensitivity:
                fpvActual:
                fpvPipper:
*/
                Behavior on pitch {NumberAnimation { duration: settings.smoothing }}
                pitch: settings.fpv_dynamic ? _fcMavlinkSystem.pitch : 0.0
                Behavior on roll {NumberAnimation { duration: settings.smoothing }}
                roll: settings.fpv_dynamic ? _fcMavlinkSystem.roll : 0.0

                Behavior on lateral {NumberAnimation { duration: settings.smoothing }}
                lateral: settings.fpv_dynamic ? _fcMavlinkSystem.vehicle_vx_angle : 0.0
                Behavior on vertical {NumberAnimation { duration: settings.smoothing }}
                vertical: settings.fpv_dynamic ? _fcMavlinkSystem.vehicle_vz_angle : 0.0

                // referencing the horizon so that fpv moves accurately
                horizonSpacing: settings.horizon_ladder_spacing
                horizonWidth: settings.horizon_width
                fpvSize: bw_current_scale

                verticalLimit: settings.fpv_vertical_limit
                lateralLimit: settings.fpv_lateral_limit
            }
        }
    }
}
