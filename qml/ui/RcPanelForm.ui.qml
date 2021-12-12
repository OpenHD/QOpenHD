import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../ui" as Ui

import "../ui/elements"




Rectangle {
    id: element2
    Layout.fillHeight: true
    Layout.fillWidth: true

    color: "#eaeaea"

    //
    // Holds the current joystick selected by the combobox
    //
    property int currentJoystick: 0


    //
    // Generates the axes, button and POV indicators when the user selects
    // another joystick from the combobox
    //
    function generateJoystickWidgets (id) {
        /* Clear the joystick indicators */
        axes.model = 0
        povs.model = 0
        buttons.model = 0

        /* Change the current joystick id */
        currentJoystick = id

        /* Get current joystick information & generate indicators */
        if (QJoysticks.joystickExists (id)) {
            axes.model = QJoysticks.getNumAxes (id)
            povs.model = QJoysticks.getNumPOVs (id)
            buttons.model = QJoysticks.getNumButtons (id)
        }

        /* Resize window to minimum size */
        width = minimumWidth
        height = minimumHeight
    }



    //
    // Display all the widgets in a vertical layout
    //
    ColumnLayout {
        spacing: 5
        anchors.margins: 10
        anchors.fill: parent

        //
        // Joystick selector combobox
        //
        ComboBox {
            id: joysticks
            Layout.fillWidth: true
            model: QJoysticks.deviceNames
            onCurrentIndexChanged: generateJoystickWidgets (currentIndex)
            onCurrentTextChanged: generateJoystickWidgets (currentIndex)
        }

        //
        // Axes indicator
        //
        GroupBox {
            title: qsTr ("Axis")
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                spacing:    10
                Layout.fillWidth: true
                Layout.fillHeight: true

                //
                // Generate a progressbar for each joystick axis
                //
                Repeater {
                    id: axes
                    delegate: ProgressBar {
                        id: progressbar
                        from: -100
                        to: 100
                        Layout.fillWidth: true

                        value: 0
                        Behavior on value {NumberAnimation{}}

                        Connections {
                            target: QJoysticks
                            onAxisChanged: {
                                if (currentJoystick === js && index === axis)
                                    progressbar.value = QJoysticks.getAxis (js, index) * 100
                            }
                        }
                    }
                }
            }
        }

        //
        // Buttons indicator
        //
        GroupBox {
            title: qsTr ("Buttons")
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridLayout {
                rows: 6
                rowSpacing: 5
                columnSpacing: 5
                Layout.fillWidth: true
                Layout.fillHeight: true
                flow: GridLayout.TopToBottom

                //
                // Generate a checkbox for each joystick button
                //
                Repeater {
                    id: buttons
                    delegate: CheckBox {
                        enabled: false
                        Layout.fillWidth: true
                        text: qsTr ("Button %1").arg (index)

                        //
                        // React to QJoystick signals
                        //
                        Connections {
                            target: QJoysticks
                            onButtonChanged: {
                                if (currentJoystick === js && button === index)
                                    checked = QJoysticks.getButton (js, index)
                            }
                        }
                    }
                }
            }
        }

        //
        // POVs indicator
        //
        GroupBox {
            title: qsTr ("POVs")
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                spacing: 5
                Layout.fillWidth: true
                Layout.fillHeight: true

                //
                // Generate a spinbox for each joystick POV
                //
                Repeater {
                    id: povs
                    delegate: SpinBox {
                        enabled: false
                        from: 0
                        to: 360
                        Layout.fillWidth: true

                        //
                        // React to QJoystick signals
                        //
                        Connections {
                            target: QJoysticks
                            onPovChanged: {
                                if (currentJoystick === js && pov === index)
                                    value = QJoysticks.getPOV (js, index)
                            }
                        }
                    }
                }
            }
        }

      }

}

    /*##^##
Designer {
    D{i:1;anchors_width:224;anchors_x:71;anchors_y:8}D{i:2;anchors_height:15;anchors_width:488;anchors_x:8;anchors_y:91}
D{i:3;anchors_height:106;anchors_width:282;anchors_x:35;anchors_y:110}
}
##^##*/
