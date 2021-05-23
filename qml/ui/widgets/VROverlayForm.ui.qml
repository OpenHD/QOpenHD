import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0
import QtQuick.Controls.Material 2.12

import OpenHD 1.0



BaseWidget {
    id: vroverlayWidget
    width: 50
    height: 55

    visible: settings.show_vroverlay

    widgetIdentifier: "vroverlay_widget"

    defaultHCenter: true
    defaultVCenter: true

    hasWidgetDetail: true
    widgetDetailComponent: ScrollView {

        contentHeight: vroverlayWidgetColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        ColumnLayout {

            id: vroverlayWidgetColumn
            spacing: 0
            clip: true

            Item {
                width: 230
                height: 32
                Text {
                    id: opacityTitle
                    text: qsTr("Transparency")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: vroverlay_opacity_Slider
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.vroverlay_opacity
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.vroverlay_opacity = vroverlay_opacity_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Size")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: vroverlay_size_Slider
                    orientation: Qt.Horizontal
                    from: .5
                    value: settings.vroverlay_size
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.vroverlay_size = vroverlay_size_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Lock to Horizontal Center")
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
                    checked: {
                        // @disable-check M222
                        var _hCenter = settings.value(hCenterIdentifier, defaultHCenter)
                        // @disable-check M223
                        if (_hCenter === "true" || _hCenter === 1 || _hCenter === true) {
                            checked = true;
                            // @disable-check M223
                        } else {
                            checked = false;
                        }
                    }

                    onCheckedChanged: settings.setValue(hCenterIdentifier, checked)
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Lock to Vertical Center")
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
                    checked: {
                        // @disable-check M222
                        var _vCenter = settings.value(vCenterIdentifier, defaultVCenter)
                        // @disable-check M223
                        if (_vCenter === "true" || _vCenter === 1 || _vCenter === true) {
                            checked = true;
                            // @disable-check M223
                        } else {
                            checked = false;
                        }
                    }

                    onCheckedChanged: settings.setValue(vCenterIdentifier, checked)
                }
            }

            /*
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
                    checked: settings.vroverlay_invert_pitch
                    onCheckedChanged: settings.vroverlay_invert_pitch = checked
                }
            }
            */
            Item {
                width: 230
                height: 50

                Text {
                    text: qsTr("Vertical FOV")
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
                    antialiasing: true;

                    Tumbler {
                        model: 180
                        visibleItemCount : 1
                        anchors.fill: parent

                        currentIndex: settings.vroverlay_vertical_fov;

                        Component.onCompleted: {
                            // rounds it due to int
                            currentIndex= settings.vroverlay_vertical_fov;
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
                            settings.vroverlay_vertical_fov = currentIndex;
                            console.log("verticalFOV=",settings.vroverlay_vertical_fov);
                        }
                    }
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Material.color(Material.Grey ,Material.Shade500) }
                        GradientStop { position: 0.5; color: "transparent" }
                        GradientStop { position: 1.0; color: Material.color(Material.Grey ,Material.Shade500) }
                    }
                }
            }
            Item {
                width: 230
                height: 50

                Text {
                    text: qsTr("Horizontal FOV")
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
                    antialiasing: true;

                    Tumbler {
                        model: 180
                        visibleItemCount : 1
                        anchors.fill: parent

                        currentIndex: settings.vroverlay_horizontal_fov;

                        Component.onCompleted: {
                            // rounds it due to int
                            currentIndex= settings.vroverlay_horizontal_fov;
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
                            settings.vroverlay_horizontal_fov = currentIndex;
                            console.log("horizontalfov=",settings.vroverlay_horizontal_fov);
                        }
                    }
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Material.color(Material.Grey ,Material.Shade500) }
                        GradientStop { position: 0.5; color: "transparent" }
                        GradientStop { position: 1.0; color: Material.color(Material.Grey ,Material.Shade500) }
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

        visible: settings.show_vroverlay
        opacity: settings.vroverlay_opacity

        Text {
            id: vr_text
            color: settings.color_shape
            opacity: settings.vroverlay_opacity
            text: "VR"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
            verticalAlignment: Text.AlignTop
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            style: Text.Outline
            styleColor: settings.color_glow
        }



        Item {
            id: vrOverlay

            anchors.centerIn: parent
            visible: settings.show_vroverlay

            Repeater {
                model: AdsbVehicleManager.adsbVehicles

                VROverlay {
                    id: vroverlayC
                    anchors.centerIn: parent
                    //needs width and height but needs to be dynamic
                    width:applicationWindow.width
                    height:applicationWindow.height

                    //width: 1200
                    //height: 800

                    clip: false
                    color: settings.color_shape
                    glow: settings.color_glow
                    vroverlayInvertPitch: settings.vroverlay_invert_pitch

                    pitch: OpenHD.pitch
                    roll: OpenHD.roll

                    type: "adsb"
                    name: object.callsign
                    lat: object.lat
                    lon: object.lon
                    alt: object.altitude
                    speed: object.velocity
                    vert: object.verticalVel

                    vroverlaySize: settings.vroverlay_size

                    verticalFOV: settings.vroverlay_vertical_fov
                    horizontalFOV: settings.vroverlay_horizontal_fov
                }
            }
            VROverlay {
                id: homeVROverlayC
                anchors.centerIn: parent

                //needs width and height but needs to be dynamic
                //:applicationWindow.width
                //height:applicationWindow.height

                width: 1200
                height: 800

                clip: false
                color: settings.color_shape
                glow: settings.color_glow
                vroverlayInvertPitch: settings.vroverlay_invert_pitch

                pitch: OpenHD.pitch
                roll: OpenHD.roll

                type: "home"
                name: "HOME"
                lat: OpenHD.homelat
                lon: OpenHD.homelon
                alt: 0
                speed: 0
                vert: 0

                vroverlaySize: settings.vroverlay_size

                verticalFOV: settings.vroverlay_vertical_fov
                horizontalFOV: settings.vroverlay_horizontal_fov
            }
            VROverlay {
                id: race1VROverlayC
                anchors.centerIn: parent

                //needs width and height but needs to be dynamic
                width:applicationWindow.width
                height:applicationWindow.height

                //width: 1200
                //height: 800

                clip: false
                color: settings.color_shape
                glow: settings.color_glow
                vroverlayInvertPitch: settings.vroverlay_invert_pitch

                pitch: OpenHD.pitch
                roll: OpenHD.roll

                type: "race"
                name: "START"
                lat: {OpenHD.homelat-.001}
                lon: OpenHD.homelon
                alt: 50
                speed: 0
                vert: 0

                vroverlaySize: settings.vroverlay_size

                verticalFOV: settings.vroverlay_vertical_fov
                horizontalFOV: settings.vroverlay_horizontal_fov
            }
            VROverlay {
                id: race2VROverlayC
                anchors.centerIn: parent

                //needs width and height but needs to be dynamic
                width:applicationWindow.width
                height:applicationWindow.height

                //width: 1200
                //height: 800

                clip: false
                color: settings.color_shape
                glow: settings.color_glow
                vroverlayInvertPitch: settings.vroverlay_invert_pitch

                pitch: OpenHD.pitch
                roll: OpenHD.roll

                type: "race"
                name: "FINISH"
                lat: {OpenHD.homelat-.003}
                lon: OpenHD.homelon
                alt: 50
                speed: 0
                vert: 0

                vroverlaySize: settings.vroverlay_size

                verticalFOV: settings.vroverlay_vertical_fov
                horizontalFOV: settings.vroverlay_horizontal_fov
            }
        }
    }
}


