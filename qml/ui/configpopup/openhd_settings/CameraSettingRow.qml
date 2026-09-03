import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

FocusScope {
    id: root

    signal moveRequested(int sourceIndex, int step)
    signal categoryRequested()
    signal exitRequested()
    signal focusRequested(int sourceIndex)

    property var settingsModel
    property string paramId: ""
    property string categoryKey: ""
    property int modelIndex: -1
    property int valueType: 0
    property var paramValue
    property string displayValue: ""
    property string description: ""
    property bool readOnly: false
    property bool whitelisted: false
    property bool busy: false
    property bool raspberryPi: false
    property var streamModel
    property int platformType: -1
    property int modelUpdate: settingsModel ? settingsModel.update_count : 0
    property var uiMetadata: settingsModel && paramId.length > 0
                             ? settingsModel.get_ui_metadata(paramId) : ({})

    readonly property bool compact: width < 650
    readonly property string controlKind: uiMetadata && uiMetadata.control
                                                  ? String(uiMetadata.control) : "unsupported"
    readonly property bool useSlider: ["BITRATE_MBITS", "BRIGHTNESS", "CONTRAST",
                                       "SATURATION", "SHARPNESS"].indexOf(paramId) >= 0
    readonly property bool useToggle: controlKind === "toggle"
    readonly property bool requiresReboot: settingsModel && paramId.length > 0
                                           ? settingsModel.get_param_requires_manual_reboot(paramId) : false

    implicitHeight: contentGrid.implicitHeight + 24
    activeFocusOnTab: true

    function friendlyName(id) {
        var names = {
            "AIR_RECORDING_E": qsTr("Air-unit recording"),
            "STREAMING_E": qsTr("Camera stream"),
            "BITRATE_MBITS": qsTr("Encoder bitrate"),
            "VIDEO_CODEC": qsTr("Video codec"),
            "KEYFRAME_I": qsTr("Keyframe interval"),
            "RESOLUTION_FPS": qsTr("Resolution and frame rate"),
            "CAMERA_TYPE": qsTr("Camera model"),
            "AWB_MODE": qsTr("White balance"),
            "AWB_MODE_LC": qsTr("White balance"),
            "EXP_MODE": qsTr("Exposure preset"),
            "EXPOSURE_MODE_LC": qsTr("Exposure mode"),
            "EXPOSURE_LC": qsTr("Exposure compensation"),
            "METERING_MODE": qsTr("Metering mode"),
            "METERING_MODE_LC": qsTr("Metering mode"),
            "SHUTTER_US_LC": qsTr("Shutter time"),
            "ISO": qsTr("ISO sensitivity"),
            "DENOISE_INDEX_LC": qsTr("Noise reduction"),
            "BRIGHTNESS": qsTr("Brightness"),
            "CONTRAST": qsTr("Contrast"),
            "CONTRAST_LC": qsTr("Contrast"),
            "SATURATION": qsTr("Saturation"),
            "SATURATION_LC": qsTr("Saturation"),
            "SHARPNESS": qsTr("Sharpness"),
            "SHARPNESS_LC": qsTr("Sharpness"),
            "ROTATION_FLIP": qsTr("Image flip"),
            "ROTATION_DEG": qsTr("Image rotation"),
            "FORCE_SW_ENC": qsTr("Force software encoder"),
            "INTRA_REFRESH": qsTr("Intra refresh"),
            "QP_PID_ENABLE": qsTr("QP bitrate controller"),
            "RK_BITRATE_PID": qsTr("Rockchip bitrate controller"),
            "V_SWITCH_CAM": qsTr("Swap camera slots"),
            "HIGH_ENCRYPTION": qsTr("Video encryption")
        }
        if (names[id]) return names[id]

        var words = id.split("_")
        var acronyms = { "AWB": true, "FPS": true, "GOP": true, "HDR": true,
                         "IP": true, "ISO": true, "LC": true, "PID": true,
                         "QP": true, "RTSP": true, "SW": true }
        for (var i = 0; i < words.length; ++i) {
            if (!acronyms[words[i]])
                words[i] = words[i].charAt(0) + words[i].slice(1).toLowerCase()
        }
        return words.join(" ")
    }

    function friendlyDescription(id, fallback) {
        var descriptions = {
            "AIR_RECORDING_E": qsTr("Save footage on the air unit, or record automatically while the aircraft is armed."),
            "STREAMING_E": qsTr("Turn this camera's live video stream on or off."),
            "BITRATE_MBITS": qsTr("Encoder target when variable bitrate is off. Higher values use more link bandwidth."),
            "VIDEO_CODEC": qsTr("H.264 maximizes compatibility; H.265 can save bandwidth on supported hardware."),
            "KEYFRAME_I": qsTr("Shorter intervals recover faster after signal loss; longer intervals compress more efficiently."),
            "RESOLUTION_FPS": qsTr("Choose a format supported by this camera. The stream restarts after a change."),
            "CAMERA_TYPE": qsTr("Select the camera connected to this air-unit slot."),
            "AWB_MODE": qsTr("Adapt image colors to the lighting conditions."),
            "AWB_MODE_LC": qsTr("Adapt image colors to the lighting conditions."),
            "EXP_MODE": qsTr("Choose how the camera adapts exposure to the scene."),
            "EXPOSURE_MODE_LC": qsTr("Choose how the camera adapts exposure to movement."),
            "EXPOSURE_LC": qsTr("Make the automatic exposure darker or brighter."),
            "METERING_MODE": qsTr("Choose which part of the image is used to calculate exposure."),
            "METERING_MODE_LC": qsTr("Choose which part of the image is used to calculate exposure."),
            "SHUTTER_US_LC": qsTr("Leave on Auto for normal use, or set a fixed shutter time in microseconds."),
            "ISO": qsTr("Higher ISO brightens dark scenes but adds image noise. Zero selects Auto."),
            "DENOISE_INDEX_LC": qsTr("Reducing denoise can lower latency by about one frame in exchange for more noise."),
            "BRIGHTNESS": qsTr("Adjust overall image brightness."),
            "CONTRAST": qsTr("Adjust the difference between dark and bright areas."),
            "CONTRAST_LC": qsTr("Adjust the difference between dark and bright areas."),
            "SATURATION": qsTr("Adjust color intensity."),
            "SATURATION_LC": qsTr("Adjust color intensity."),
            "SHARPNESS": qsTr("Adjust edge enhancement and fine detail."),
            "SHARPNESS_LC": qsTr("Adjust edge enhancement and fine detail."),
            "ROTATION_FLIP": qsTr("Mirror the image vertically, horizontally, or both."),
            "ROTATION_DEG": qsTr("Rotate the outgoing camera image."),
            "FORCE_SW_ENC": qsTr("Use CPU encoding. Enable only when required by the camera output format."),
            "INTRA_REFRESH": qsTr("Experimental recovery behavior for compatible encoders."),
            "QP_PID_ENABLE": qsTr("Experimental live bitrate correction using encoder QP limits."),
            "RK_BITRATE_PID": qsTr("Experimental live bitrate correction for Rockchip encoders."),
            "V_SWITCH_CAM": qsTr("Make the secondary camera primary and the primary camera secondary."),
            "HIGH_ENCRYPTION": qsTr("Encrypt the video payload at the cost of additional CPU load.")
        }
        return descriptions[id] || fallback
    }

    function sliderMinimum() {
        if (settingsModel && settingsModel.int_param_has_min_max(paramId))
            return settingsModel.int_param_get_min_value(paramId)
        if (paramId === "BITRATE_MBITS") return 1
        return 0
    }

    function sliderMaximum() {
        if (settingsModel && settingsModel.int_param_has_min_max(paramId))
            return settingsModel.int_param_get_max_value(paramId)
        if (paramId === "BITRATE_MBITS") return 100
        return 200
    }

    function valueSuffix(id) {
        return id === "BITRATE_MBITS" ? qsTr(" Mbit/s") : ""
    }

    function warnIfNeeded() {
        if (!settingsModel) return
        if (whitelisted) {
            _messageBoxInstance.set_text_and_show(
                        qsTr("This expert parameter can break the camera configuration. Change it only if you understand its effect."))
        }
        var warning = settingsModel.get_warning_before_safe(paramId)
        if (warning !== "") _messageBoxInstance.set_text_and_show(warning)
    }

    function commitInt(value) {
        if (!settingsModel || readOnly || busy || Number(value) === Number(paramValue)) return
        warnIfNeeded()
        settingsModel.try_set_param_int_async(paramId, Number(value), true)
    }

    function commitString(value) {
        if (!settingsModel || readOnly || busy || String(value) === String(paramValue)) return
        warnIfNeeded()
        settingsModel.try_set_param_string_async(paramId, String(value), true)
    }

    function gainFocus() {
        if (!controlLoader.item) {
            forceActiveFocus()
            return
        }
        if (controlLoader.item.gainFocus)
            controlLoader.item.gainFocus()
        else if (controlLoader.item.focusControl)
            controlLoader.item.focusControl.forceActiveFocus()
        else
            controlLoader.item.forceActiveFocus()
    }

    function cameraTypeIndex() {
        var values = streamModel ? streamModel.get_supported_camera_types(platformType) : []
        for (var i = 0; i < values.length; ++i)
            if (Number(values[i]) === Number(paramValue)) return i
        return -1
    }

    function resolutionPart(value) { return String(value).split("@")[0] }
    function fpsPart(value) {
        var parts = String(value).split("@")
        return parts.length > 1 ? parts[1] : ""
    }
    function uniqueResolutions() {
        var source = streamModel ? streamModel.get_supported_resolutions() : []
        var result = []
        for (var i = 0; i < source.length; ++i) {
            var value = resolutionPart(source[i])
            if (result.indexOf(value) < 0) result.push(value)
        }
        return result
    }
    function fpsForResolution(resolution) {
        var source = streamModel ? streamModel.get_supported_resolutions() : []
        var result = []
        for (var i = 0; i < source.length; ++i)
            if (resolutionPart(source[i]) === resolution) result.push(fpsPart(source[i]))
        return result
    }

    function handleNavigation(event) {
        if (event.key === Qt.Key_Up) {
            moveRequested(modelIndex, -1)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            moveRequested(modelIndex, 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            exitRequested()
            event.accepted = true
        }
    }

    onActiveFocusChanged: if (activeFocus) focusRequested(modelIndex)
    Keys.priority: Keys.BeforeItem
    Keys.onPressed: handleNavigation(event)

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: root.activeFocus
               ? Qt.rgba(0.15, 0.55, 1.0, settings_form.darkMode ? 0.13 : 0.08)
               : (rowMouse.containsMouse ? settings_form.panelBackground : "transparent")
        border.width: root.activeFocus ? 2 : 0
        border.color: settings_form.accentColor
        Rectangle {
            visible: root.activeFocus
            width: 3; height: parent.height - 18; radius: 2
            anchors.left: parent.left; anchors.leftMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            color: settings_form.accentColor
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.gainFocus()
    }

    GridLayout {
        id: contentGrid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        columns: root.compact ? 1 : 2
        columnSpacing: 24
        rowSpacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: root.compact ? -1 : Math.max(240, contentGrid.width * 0.48)
            spacing: 3
            RowLayout {
                Layout.fillWidth: true
                spacing: 7
                Text {
                    Layout.fillWidth: true
                    text: root.friendlyName(root.paramId)
                    color: settings_form.primaryText
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                }
                Rectangle {
                    visible: root.readOnly
                    implicitWidth: readOnlyLabel.implicitWidth + 12
                    implicitHeight: 20
                    radius: 5
                    color: settings_form.panelBackground
                    border.color: settings_form.lineColor
                    Text {
                        id: readOnlyLabel
                        anchors.centerIn: parent
                        text: qsTr("READ ONLY")
                        color: settings_form.secondaryText
                        font.pixelSize: 8; font.bold: true
                    }
                }
                Rectangle {
                    visible: root.whitelisted
                    implicitWidth: expertLabel.implicitWidth + 12
                    implicitHeight: 20
                    radius: 5
                    color: settings_form.darkMode ? "#3c321d" : "#fff3d6"
                    border.color: settings_form.darkMode ? "#665329" : "#e6bd58"
                    Text {
                        id: expertLabel
                        anchors.centerIn: parent
                        text: qsTr("EXPERT")
                        color: settings_form.darkMode ? "#ffd479" : "#805400"
                        font.pixelSize: 8; font.bold: true
                    }
                }
                Rectangle {
                    visible: root.requiresReboot
                    implicitWidth: rebootLabel.implicitWidth + 12
                    implicitHeight: 20
                    radius: 5
                    color: settings_form.darkMode ? "#3c321d" : "#fff3d6"
                    border.color: settings_form.darkMode ? "#665329" : "#e6bd58"
                    Text {
                        id: rebootLabel
                        anchors.centerIn: parent
                        text: qsTr("RESTART")
                        color: settings_form.darkMode ? "#ffd479" : "#805400"
                        font.pixelSize: 8; font.bold: true
                    }
                }
            }
            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.friendlyDescription(root.paramId, root.description)
                color: settings_form.secondaryText
                font.pixelSize: 10
                lineHeight: 1.15
                wrapMode: Text.WordWrap
                maximumLineCount: root.compact ? 3 : 2
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: root.categoryKey === "ADVANCED"
                text: root.paramId
                color: settings_form.secondaryText
                opacity: 0.72
                font.pixelSize: 8
                font.family: "monospace"
                elide: Text.ElideRight
            }
        }

        Loader {
            id: controlLoader
            Layout.fillWidth: true
            Layout.preferredWidth: root.compact ? -1 : Math.max(270, contentGrid.width * 0.42)
            Layout.preferredHeight: root.useSlider && !root.readOnly ? 54 : 38
            enabled: !root.busy
            opacity: enabled ? 1.0 : 0.52
            sourceComponent: root.readOnly ? inlineControl
                             : (root.paramId === "CAMERA_TYPE" ? cameraTypeControl
                             : (root.paramId === "RESOLUTION_FPS" ? resolutionControl
                             : (root.useSlider ? sliderControl
                             : (root.useToggle ? toggleControl : inlineControl))))
        }
    }

    Component {
        id: resolutionControl
        RowLayout {
            id: formatEditor
            spacing: 8
            property Item focusControl: resolutionBox
            property string selectedResolution: root.resolutionPart(root.paramValue)
            property string selectedFps: root.fpsPart(root.paramValue)
            property bool dirty: selectedResolution + "@" + selectedFps !== String(root.paramValue)
            property int observedRevision: root.modelUpdate
            onObservedRevisionChanged: {
                selectedResolution = root.resolutionPart(root.paramValue)
                selectedFps = root.fpsPart(root.paramValue)
            }
            CompactLinkComboBox {
                id: resolutionBox
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                model: root.uniqueResolutions()
                currentIndex: model.indexOf(formatEditor.selectedResolution)
                displayText: currentIndex >= 0
                             ? String(model[currentIndex]).replace("x", " \u00d7 ")
                             : formatEditor.selectedResolution
                enabled: !root.busy && !root.readOnly && model.length > 0
                popupWidth: Math.max(width, 210)
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Right) {
                        fpsBox.forceActiveFocus()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Left) {
                        root.categoryRequested()
                        event.accepted = true
                    } else {
                        root.handleNavigation(event)
                    }
                }
                onActivated: {
                    formatEditor.selectedResolution = String(model[currentIndex])
                    var fpsValues = root.fpsForResolution(formatEditor.selectedResolution)
                    if (fpsValues.indexOf(formatEditor.selectedFps) < 0 && fpsValues.length > 0)
                        formatEditor.selectedFps = String(fpsValues[0])
                }
            }
            CompactLinkComboBox {
                id: fpsBox
                Layout.preferredWidth: 96
                Layout.preferredHeight: 38
                model: root.fpsForResolution(formatEditor.selectedResolution)
                currentIndex: model.indexOf(formatEditor.selectedFps)
                displayText: (currentIndex >= 0 ? model[currentIndex] : formatEditor.selectedFps) + qsTr(" fps")
                enabled: !root.busy && !root.readOnly && model.length > 0
                popupWidth: Math.max(width, 130)
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Left) {
                        resolutionBox.forceActiveFocus()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Right) {
                        formatApplyButton.forceActiveFocus()
                        event.accepted = true
                    } else {
                        root.handleNavigation(event)
                    }
                }
                onActivated: formatEditor.selectedFps = String(model[currentIndex])
            }
            Button {
                id: formatApplyButton
                Layout.preferredWidth: 68
                Layout.preferredHeight: 38
                text: qsTr("Apply")
                enabled: formatEditor.dirty && !root.busy && !root.readOnly
                hoverEnabled: true
                font.pixelSize: 10
                font.bold: true
                contentItem: Text {
                    text: formatApplyButton.text
                    color: formatApplyButton.enabled ? "white" : settings_form.secondaryText
                    font: formatApplyButton.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 8
                    color: formatApplyButton.enabled ? settings_form.accentColor : settings_form.panelBackground
                    border.width: formatApplyButton.activeFocus ? 2 : 1
                    border.color: formatApplyButton.activeFocus ? "white" : settings_form.lineColor
                }
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Left) {
                        fpsBox.forceActiveFocus()
                        event.accepted = true
                    } else {
                        root.handleNavigation(event)
                    }
                }
                onClicked: root.commitString(formatEditor.selectedResolution + "@" + formatEditor.selectedFps)
            }
        }
    }

    Component {
        id: sliderControl
        Item {
            property Item focusControl: valueSlider
            ColumnLayout {
                anchors.fill: parent
                spacing: 1
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16
                    Text { text: String(Math.round(valueSlider.from)) + root.valueSuffix(root.paramId); color: settings_form.secondaryText; font.pixelSize: 8 }
                    Item { Layout.fillWidth: true }
                    Text { text: String(Math.round(valueSlider.value)) + root.valueSuffix(root.paramId); color: settings_form.accentColor; font.pixelSize: 11; font.bold: true }
                    Item { Layout.fillWidth: true }
                    Text { text: String(Math.round(valueSlider.to)) + root.valueSuffix(root.paramId); color: settings_form.secondaryText; font.pixelSize: 8 }
                }
                Slider {
                    id: valueSlider
                    property bool locallyEdited: false
                    property int observedRevision: root.modelUpdate
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    hoverEnabled: true
                    from: root.sliderMinimum()
                    to: root.sliderMaximum()
                    stepSize: 1
                    snapMode: Slider.SnapAlways
                    enabled: !root.busy && !root.readOnly
                    background: Item {
                        x: valueSlider.leftPadding
                        y: valueSlider.topPadding + valueSlider.availableHeight / 2 - 5
                        width: valueSlider.availableWidth; height: 10
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: valueSlider.activeFocus ? 5 : 3
                            radius: height / 2
                            color: valueSlider.activeFocus
                                   ? Qt.rgba(0.15, 0.55, 1.0, settings_form.darkMode ? 0.25 : 0.16)
                                   : settings_form.lineColor
                            Rectangle {
                                width: valueSlider.visualPosition * parent.width
                                height: parent.height; radius: parent.radius
                                color: settings_form.accentColor
                            }
                        }
                    }
                    handle: Rectangle {
                        x: valueSlider.leftPadding + valueSlider.visualPosition * (valueSlider.availableWidth - width)
                        y: valueSlider.topPadding + valueSlider.availableHeight / 2 - height / 2
                        implicitWidth: 22; implicitHeight: 22; radius: 11
                        color: settings_form.panelBackgroundRaised
                        border.width: valueSlider.activeFocus ? 3 : 2
                        border.color: settings_form.accentColor
                    }
                    Component.onCompleted: value = Number(root.paramValue)
                    onObservedRevisionChanged: if (!pressed && !locallyEdited) value = Number(root.paramValue)
                    onMoved: locallyEdited = true
                    onPressedChanged: {
                        if (!pressed && locallyEdited) {
                            root.commitInt(Math.round(value))
                            locallyEdited = false
                        }
                    }
                    Keys.onLeftPressed: { locallyEdited = true; value = Math.max(from, value - stepSize) }
                    Keys.onRightPressed: { locallyEdited = true; value = Math.min(to, value + stepSize) }
                    Keys.onReturnPressed: { if (locallyEdited) root.commitInt(Math.round(value)); locallyEdited = false }
                    Keys.onEnterPressed: { if (locallyEdited) root.commitInt(Math.round(value)); locallyEdited = false }
                    Keys.onUpPressed: {
                        if (locallyEdited) root.commitInt(Math.round(value))
                        locallyEdited = false
                        root.moveRequested(root.modelIndex, -1)
                    }
                    Keys.onDownPressed: {
                        if (locallyEdited) root.commitInt(Math.round(value))
                        locallyEdited = false
                        root.moveRequested(root.modelIndex, 1)
                    }
                    Keys.onEscapePressed: {
                        if (locallyEdited) root.commitInt(Math.round(value))
                        locallyEdited = false
                        root.exitRequested()
                    }
                }
            }
        }
    }

    Component {
        id: toggleControl
        Switch {
            checked: Number(root.paramValue) !== 0
            enabled: !root.busy && !root.readOnly
            text: checked ? qsTr("On") : qsTr("Off")
            font.pixelSize: 11
            onClicked: root.commitInt(checked ? 1 : 0)
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Left) {
                    root.commitInt(0)
                    event.accepted = true
                } else if (event.key === Qt.Key_Right) {
                    root.commitInt(1)
                    event.accepted = true
                } else {
                    root.handleNavigation(event)
                }
            }
        }
    }

    Component {
        id: cameraTypeControl
        RowLayout {
            id: cameraEditor
            spacing: 8
            property Item focusControl: cameraTypeBox
            property var typeValues: root.streamModel
                                     ? root.streamModel.get_supported_camera_types(root.platformType) : []
            property int selectedIndex: root.cameraTypeIndex()
            property int observedRevision: root.modelUpdate
            property bool dirty: selectedIndex >= 0 && selectedIndex < typeValues.length &&
                                 Number(typeValues[selectedIndex]) !== Number(root.paramValue)
            onObservedRevisionChanged: selectedIndex = root.cameraTypeIndex()

            CompactLinkComboBox {
                id: cameraTypeBox
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                model: root.streamModel
                       ? root.streamModel.get_supported_camera_names(root.platformType) : []
                currentIndex: cameraEditor.selectedIndex
                displayText: currentIndex >= 0 ? String(model[currentIndex]) : root.displayValue
                enabled: !root.busy && !root.readOnly && model.length > 0
                popupWidth: Math.max(width, 390)
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Right) {
                        cameraApplyButton.forceActiveFocus()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Left) {
                        root.categoryRequested()
                        event.accepted = true
                    } else {
                        root.handleNavigation(event)
                    }
                }
                onActivated: cameraEditor.selectedIndex = currentIndex
            }
            Button {
                id: cameraApplyButton
                Layout.preferredWidth: 68
                Layout.preferredHeight: 38
                text: qsTr("Apply")
                enabled: cameraEditor.dirty && !root.busy && !root.readOnly
                hoverEnabled: true
                font.pixelSize: 10
                font.bold: true
                contentItem: Text {
                    text: cameraApplyButton.text
                    color: cameraApplyButton.enabled ? "white" : settings_form.secondaryText
                    font: cameraApplyButton.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 8
                    color: cameraApplyButton.enabled ? settings_form.accentColor : settings_form.panelBackground
                    border.width: cameraApplyButton.activeFocus ? 2 : 1
                    border.color: cameraApplyButton.activeFocus ? "white" : settings_form.lineColor
                }
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Left) {
                        cameraTypeBox.forceActiveFocus()
                        event.accepted = true
                    } else {
                        root.handleNavigation(event)
                    }
                }
                onClicked: {
                    _messageBoxInstance.set_text_and_show(qsTr("Changing the camera restarts the air unit."))
                    root.commitInt(Number(cameraEditor.typeValues[cameraEditor.selectedIndex]))
                }
            }
        }
    }

    Component {
        id: inlineControl
        InlineMavlinkParamControl {
            settingsModel: root.settingsModel
            paramId: root.paramId
            valueType: root.valueType
            paramValue: root.paramValue
            displayValue: root.displayValue
            readOnly: root.readOnly
            busy: root.busy
            blockedEnumValues: root.paramId === "VIDEO_CODEC" && root.raspberryPi ? [1] : []
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: root.handleNavigation(event)
        }
    }
}
