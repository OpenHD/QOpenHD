import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Item {
    id: root
    implicitHeight: controlType === "slider" ? 66 : 44

    property var settingsModel
    property string paramId: ""
    property string label: paramId
    property string valueSuffix: ""
    property bool preferSlider: false
    property bool preferRadioToggle: false
    property bool editorEnabled: true
    property real preferredStepSize: 1
    property bool overrideSliderRange: false
    property real preferredMinimum: 0
    property real preferredMaximum: 100
    property var metadata: settingsModel ? settingsModel.get_ui_metadata(paramId) : ({control: "unsupported"})
    property string controlType: preferSlider && metadata.control === "dropdown"
                                 ? "slider" : (metadata.control || "unsupported")
    property int modelUpdate: settingsModel ? settingsModel.update_count : 0
    property int cachedValue: settingsModel && settingsModel.param_int_exists(paramId)
                              ? settingsModel.get_cached_int(paramId) : 0
    property real previewValue: cachedValue
    property bool available: controlType !== "unsupported"
    property Item focusControl: controlType === "slider"
                                ? sliderLoader.item
                                : (controlType === "toggle" && preferRadioToggle && editorLoader.item
                                   ? editorLoader.item.keyboardControl : editorLoader.item)
    property var commitHandler: null

    signal moveRequested(int step)
    signal backRequested()

    function commitInt(value) {
        if (value === cachedValue) return
        if (commitHandler)
            commitHandler(value)
        else if (settingsModel)
            settingsModel.try_set_param_int_async(paramId, value, true)
    }

    function focusEditor() {
        if (editorLoader.item) editorLoader.item.forceActiveFocus()
    }

    function handleNavigation(event) {
        if (event.key === Qt.Key_Down) {
            moveRequested(1)
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            moveRequested(-1)
            event.accepted = true
        } else if (event.key === Qt.Key_Left && controlType !== "slider") {
            moveRequested(-1)
            event.accepted = true
        } else if (event.key === Qt.Key_Right && controlType !== "slider") {
            moveRequested(1)
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            backRequested()
            event.accepted = true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            spacing: 10
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    Layout.fillWidth: true
                    text: root.label
                    color: settings_form.primaryText
                    font.pixelSize: 11
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.controlType !== "slider"
                    text: root.metadata.description || ""
                    color: settings_form.secondaryText
                    font.pixelSize: 8
                    elide: Text.ElideRight
                }
            }
            Loader {
                id: editorLoader
                enabled: root.editorEnabled
                opacity: enabled ? 1.0 : 0.5
                Layout.preferredWidth: root.controlType === "toggle"
                                       ? (root.preferRadioToggle ? 122 : 62)
                                       : Math.min(190, root.width * 0.45)
                Layout.preferredHeight: 36
                sourceComponent: root.controlType === "toggle"
                                 ? (root.preferRadioToggle ? radioToggleEditor : toggleEditor)
                                 : (root.controlType === "dropdown" ? dropdownEditor
                                 : (root.controlType === "slider" ? sliderValue : unsupportedEditor))
            }
        }
        Loader {
            id: sliderLoader
            enabled: root.editorEnabled
            opacity: enabled ? 1.0 : 0.5
            Layout.fillWidth: true
            Layout.preferredHeight: root.controlType === "slider" ? 26 : 0
            active: root.controlType === "slider"
            sourceComponent: sliderEditor
        }
    }

    Component {
        id: toggleEditor
        Switch {
            checked: root.cachedValue !== 0
            onClicked: root.commitInt(checked ? 1 : 0)
            Keys.onPressed: root.handleNavigation(event)
        }
    }

    Component {
        id: radioToggleEditor
        RowLayout {
            spacing: 4
            property Item keyboardControl: root.cachedValue !== 0 ? enabledChoice : disabledChoice
            ButtonGroup { id: stateGroup }

            RadioButton {
                id: disabledChoice
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: qsTr("Off")
                checked: root.cachedValue === 0
                ButtonGroup.group: stateGroup
                indicator: Rectangle {
                    width: 14; height: 14; radius: 7
                    x: 4; anchors.verticalCenter: parent.verticalCenter
                    color: "transparent"
                    border.width: 2
                    border.color: disabledChoice.checked || disabledChoice.activeFocus
                                  ? settings_form.accentColor : settings_form.secondaryText
                    Rectangle { anchors.centerIn: parent; width: 6; height: 6; radius: 3; visible: disabledChoice.checked; color: settings_form.accentColor }
                }
                contentItem: Text {
                    leftPadding: 22; text: disabledChoice.text
                    color: disabledChoice.checked ? settings_form.primaryText : settings_form.secondaryText
                    font.pixelSize: 9; font.bold: disabledChoice.checked
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 7
                    color: disabledChoice.activeFocus
                           ? Qt.rgba(0.12, 0.55, 1.0, settings_form.darkMode ? 0.14 : 0.09)
                           : "transparent"
                    border.color: disabledChoice.activeFocus ? settings_form.accentColor : "transparent"
                }
                onClicked: if (root.cachedValue !== 0) root.commitInt(0)
                Keys.onLeftPressed: {
                    disabledChoice.forceActiveFocus()
                }
                Keys.onRightPressed: {
                    enabledChoice.forceActiveFocus()
                }
                Keys.onUpPressed: root.moveRequested(-1)
                Keys.onDownPressed: root.moveRequested(1)
                Keys.onEscapePressed: root.backRequested()
            }
            RadioButton {
                id: enabledChoice
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: qsTr("On")
                checked: root.cachedValue !== 0
                ButtonGroup.group: stateGroup
                indicator: Rectangle {
                    width: 14; height: 14; radius: 7
                    x: 4; anchors.verticalCenter: parent.verticalCenter
                    color: "transparent"
                    border.width: 2
                    border.color: enabledChoice.checked || enabledChoice.activeFocus
                                  ? settings_form.accentColor : settings_form.secondaryText
                    Rectangle { anchors.centerIn: parent; width: 6; height: 6; radius: 3; visible: enabledChoice.checked; color: settings_form.accentColor }
                }
                contentItem: Text {
                    leftPadding: 22; text: enabledChoice.text
                    color: enabledChoice.checked ? settings_form.primaryText : settings_form.secondaryText
                    font.pixelSize: 9; font.bold: enabledChoice.checked
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 7
                    color: enabledChoice.activeFocus
                           ? Qt.rgba(0.12, 0.55, 1.0, settings_form.darkMode ? 0.14 : 0.09)
                           : "transparent"
                    border.color: enabledChoice.activeFocus ? settings_form.accentColor : "transparent"
                }
                onClicked: if (root.cachedValue === 0) root.commitInt(1)
                Keys.onLeftPressed: {
                    disabledChoice.forceActiveFocus()
                }
                Keys.onRightPressed: {
                    enabledChoice.forceActiveFocus()
                }
                Keys.onUpPressed: root.moveRequested(-1)
                Keys.onDownPressed: root.moveRequested(1)
                Keys.onEscapePressed: root.backRequested()
            }
        }
    }

    Component {
        id: dropdownEditor
        CompactLinkComboBox {
            id: combo
            property var optionValues: root.metadata.values || []
            model: root.metadata.keys || []
            currentIndex: {
                var unused = root.modelUpdate
                for (var i = 0; i < optionValues.length; ++i)
                    if (Number(optionValues[i]) === root.cachedValue) return i
                return -1
            }
            onActivated: if (currentIndex >= 0) root.commitInt(Number(optionValues[currentIndex]))
            Keys.onPressed: root.handleNavigation(event)
        }
    }

    Component {
        id: sliderValue
        Text {
            text: Math.round(root.previewValue) + root.valueSuffix
            color: settings_form.accentColor
            font.pixelSize: 11
            font.bold: true
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
    }

    Component {
        id: sliderEditor
        Slider {
            id: slider
            property bool locallyEdited: false
            property int observedRevision: root.modelUpdate
            hoverEnabled: true
            from: root.overrideSliderRange ? root.preferredMinimum : Number(root.metadata.minimum)
            to: root.overrideSliderRange ? root.preferredMaximum : Number(root.metadata.maximum)
            stepSize: root.preferredStepSize

            background: Item {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - 5
                width: slider.availableWidth
                height: 10
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width; height: slider.activeFocus ? 5 : 3; radius: height / 2
                    color: slider.activeFocus
                           ? Qt.rgba(0.12, 0.55, 1.0, settings_form.darkMode ? 0.25 : 0.18)
                           : settings_form.lineColor
                    Behavior on height { NumberAnimation { duration: 100 } }
                    Rectangle {
                        width: slider.visualPosition * parent.width
                        height: parent.height; radius: parent.radius
                        color: settings_form.accentColor
                    }
                }
            }
            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                implicitWidth: 20; implicitHeight: 20; radius: 10
                color: "transparent"
                border.width: slider.activeFocus ? 2 : 0
                border.color: settings_form.accentColor
                Rectangle {
                    anchors.centerIn: parent
                    width: slider.pressed ? 14 : 12
                    height: width; radius: width / 2
                    color: settings_form.accentColor
                    border.width: 2
                    border.color: settings_form.panelBackgroundRaised
                    Behavior on width { NumberAnimation { duration: 90 } }
                }
            }
            Component.onCompleted: {
                value = root.cachedValue
                root.previewValue = value
            }
            onValueChanged: root.previewValue = value
            onObservedRevisionChanged: {
                if (!pressed && !locallyEdited) {
                    value = root.cachedValue
                    root.previewValue = value
                }
            }
            onMoved: locallyEdited = true
            onPressedChanged: {
                if (!pressed && locallyEdited) {
                    root.commitInt(Math.round(value))
                    locallyEdited = false
                }
            }
            Keys.onLeftPressed: {
                locallyEdited = true
                value = Math.max(from, value - stepSize)
            }
            Keys.onRightPressed: {
                locallyEdited = true
                value = Math.min(to, value + stepSize)
            }
            Keys.onReturnPressed: {
                if (locallyEdited) root.commitInt(Math.round(value))
                locallyEdited = false
            }
            Keys.onEnterPressed: {
                if (locallyEdited) root.commitInt(Math.round(value))
                locallyEdited = false
            }
            Keys.onUpPressed: root.moveRequested(-1)
            Keys.onDownPressed: root.moveRequested(1)
            Keys.onEscapePressed: root.backRequested()
        }
    }

    Component {
        id: unsupportedEditor
        Text {
            text: qsTr("N/A")
            color: settings_form.secondaryText
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
    }
}
