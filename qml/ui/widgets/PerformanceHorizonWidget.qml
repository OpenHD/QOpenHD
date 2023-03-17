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

    visible: settings.show_horizon

    widgetIdentifier: "performance_horizon_widget"

    defaultHCenter: true
    defaultVCenter: true

    hasWidgetDetail: true
    widgetDetailComponent: ScrollView {

        contentHeight: horizonSettingsColumn.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        clip: true

        ColumnLayout {
            id: horizonSettingsColumn
            x: 0
            y: 0
            width: 321
            height: 522
            spacing: 0
            clip: true
            Item {
                width: 230
                height: 42
                Text {
                    id: horizonSettingsTitle
                    text: qsTr("HORIZON")
                    color: "white"
                    height: parent.height - 10
                    width: parent.width
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: detailPanelFontPixels
                    verticalAlignment: Text.AlignVCenter
                }
                Rectangle {
                    id: horizonSettingsTitleUL
                    y: 34
                    width: parent.width
                    height: 3
                    color: "white"
                    radius: 5
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Transparency")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: horizon_opacity_Slider
                    orientation: Qt.Horizontal
                    from: .1
                    value: settings.horizon_opacity
                    to: 1
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.horizon_opacity = horizon_opacity_Slider.value
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
                    id: horizon_size_Slider
                    orientation: Qt.Horizontal
                    from: .7
                    value: settings.horizon_size
                    to: 3
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.horizon_size = horizon_size_Slider.value
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
                        var _hCenter = settings.value(hCenterIdentifier,
                                                      defaultHCenter)
                        // @disable-check M223
                        if (_hCenter === "true" || _hCenter === 1
                                || _hCenter === true) {
                            checked = true
                            // @disable-check M223
                        } else {
                            checked = false
                        }
                    }

                    onCheckedChanged: settings.setValue(hCenterIdentifier,
                                                        checked)
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
                        var _vCenter = settings.value(vCenterIdentifier,
                                                      defaultVCenter)
                        // @disable-check M223
                        if (_vCenter === "true" || _vCenter === 1
                                || _vCenter === true) {
                            checked = true
                            // @disable-check M223
                        } else {
                            checked = false
                        }
                    }

                    onCheckedChanged: settings.setValue(vCenterIdentifier,
                                                        checked)
                }
            }
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
                    value: settings.horizon_width
                    to: 10
                    stepSize: .1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.horizon_width = horizon_width_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                visible: settings.show_horizon_ladder
                Text {
                    text: qsTr("Spacing")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: horizon_spacing_Slider
                    orientation: Qt.Horizontal
                    from: 10
                    value: settings.horizon_ladder_spacing
                    to: 500
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.horizon_ladder_spacing = horizon_spacing_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Range")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: horizon_range_Slider
                    orientation: Qt.Horizontal
                    from: 1
                    value: settings.horizon_range
                    to: 180
                    stepSize: 1
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.horizon_range = horizon_range_Slider.value
                    }
                }
            }
            Item {
                width: 230
                height: 32
                Text {
                    text: qsTr("Step")
                    color: "white"
                    height: parent.height
                    font.bold: true
                    font.pixelSize: detailPanelFontPixels
                    anchors.left: parent.left
                    verticalAlignment: Text.AlignVCenter
                }
                Slider {
                    id: horizon_step_Slider
                    orientation: Qt.Horizontal
                    from: 5
                    value: settings.horizon_step
                    to: 90
                    stepSize: 5
                    height: parent.height
                    anchors.rightMargin: 0
                    anchors.right: parent.right
                    width: parent.width - 96

                    onValueChanged: {
                        settings.horizon_step = horizon_step_Slider.value
                    }
                }
            }
        }
    }

    Item {
        id: widgetInner
        anchors.fill: parent
        opacity: settings.horizon_opacity

        Rectangle {
            id: horizonLadder2
            visible: true
            width: 400
            height: 300
            border.width: 2
            border.color: "green"
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
