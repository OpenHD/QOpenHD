import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

ScrollView {
    id: appScreenSettingsView
    width: parent.width
    height: parent.height
    contentHeight: screenColumn.height
    visible: appSettingsBar.currentIndex == 3

    clip: true

    Item {
        anchors.fill: parent

        Column {
            id: screenColumn
            spacing: 0
            anchors.left: parent.left
            anchors.right: parent.right

            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("Screen Scale")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }

                Text {
                    text: Number(settings.global_scale).toLocaleString(Qt.locale(), 'f', 1) + "x";
                    font.pixelSize: 16
                    anchors.right: screenScaleSpinBox.left
                    anchors.rightMargin: 12
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: elementHeight

                }

                Slider {
                    id: screenScaleSpinBox
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    to : 2.0
                    from : 1.0

                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                    value: settings.global_scale

                    // @disable-check M223
                    onValueChanged: {
                        // @disable-check M222
                        settings.global_scale = value
                    }
                }
            }
            //Issue from @Norbert, rotating OSD can break things irreversible
            /*Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("Video Rotation (untested)")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }

                Text {
                    text: Number(settings.video_rotation).toLocaleString(Qt.locale(), 'f', 1) + "x";
                    font.pixelSize: 16
                    anchors.right: videoRotationSpinBox.left
                    anchors.rightMargin: 12
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: elementHeight

                }

                Slider {
                    id: videoRotationSpinBox
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    to : 270
                    from : 0
                    stepSize: 90

                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                    value: settings.video_rotation

                    // @disable-check M223
                    onValueChanged: {
                        // @disable-check M222
                        settings.video_rotation = value
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    //TODO on some platforms might not be able to nav back
                    text: qsTr("OSD rotation")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }

                Text {
                    text: Number(settings.osd_rotation).toLocaleString(Qt.locale(), 'f', 1) + "x";
                    font.pixelSize: 16
                    anchors.right: osdRotationSpinBox.left
                    anchors.rightMargin: 12
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: elementHeight

                }

                Slider {
                    id: osdRotationSpinBox
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    to : 270
                    from : 0
                    stepSize: 90

                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                    value: settings.osd_rotation

                    // @disable-check M223
                    onValueChanged: {
                        // @disable-check M222
                        settings.osd_rotation = value
                    }
                }
            }*/
            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("Screen rotation")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }
                // anything other than 0 and 180 breaks things
                ComboBox {
                    height: elementHeight
                    anchors.right: parent.right
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizonatalCenter
                    width: 320
                    popup.contentItem {
                        transform: [ Rotation { angle: settings.general_screen_rotation } ]
                        transformOrigin: Item.TopLeft
                    }
                    popup.background {
                        transform: [ Rotation { angle: settings.general_screen_rotation } ]
                        transformOrigin: Item.TopLeft
                    }
                    model: ListModel {
                        id: screen_rotations
                        ListElement { text: qsTr("0°") ; value: 0 }
                        ListElement { text: qsTr("90° (WARNING)") ; value: 90 }
                        ListElement { text: qsTr("180°") ; value: 180 }
                        ListElement { text: qsTr("270° (WARNING)") ; value: 270 }
                    }
                    textRole: "text"
                    Component.onCompleted: {
                        for (var i = 0; i < model.count; i++) {
                            var choice = model.get(i);
                            if (choice.value == settings.general_screen_rotation) {
                                currentIndex = i;
                            }
                        }
                    }
                    onCurrentIndexChanged: {
                        settings.general_screen_rotation = screen_rotations.get(currentIndex).value
                    }
                }
            }
        }
    }
}
