import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"

SideBarBasePanel{
    id: cameraPanel
    override_title: "Camera"
    property int cameraParamUpdates: _airCameraSettingsModel.update_count
    property bool arducam_camera: _cameraStreamModelPrimary.camera_type === 152 ||
        (cameraParamUpdates >= 0 && _airCameraSettingsModel.param_int_exists("ISP_EXPOSURE_US"))
    property bool gx_camera: _cameraStreamModelPrimary.camera_type === 64
    property bool manualExposure: cameraParamUpdates >= 0 &&
        (!_airCameraSettingsModel.param_int_exists("ISP_AE_MODE") ||
         _airCameraSettingsModel.get_cached_int("ISP_AE_MODE") !== 0)
    property bool manualWhiteBalance: cameraParamUpdates >= 0 &&
        _airCameraSettingsModel.param_int_exists("ISP_WB_AUTO") &&
        _airCameraSettingsModel.get_cached_int("ISP_WB_AUTO") === 0
    property int arducamAeProfile: cameraParamUpdates >= 0 &&
        _airCameraSettingsModel.param_int_exists("ISP_AE_PROFILE") ?
        _airCameraSettingsModel.get_cached_int("ISP_AE_PROFILE") : 0
    function focusIsp(index, direction) {
        for (var i = index; i >= 0 && i < ispControls.count; i += direction) {
            var control = ispControls.itemAt(i);
            if (control && control.visible) {
                control.takeover_control();
                return true;
            }
        }
        return false;
    }

    // Opening camera controls must request missing parameters even when the
    // radio-uplink status used by background autofetch is unavailable.
    Timer {
        interval: 2000
        repeat: true
        triggeredOnStart: true
        running: cameraPanel.visible && !_airCameraSettingsModel.has_params_fetched
        onTriggered: {
            if (_airCameraSettingsModel.system_is_alive()
                    && !_ohdSystemGroundSettings.ui_is_busy
                    && !_ohdSystemAirSettingsModel.ui_is_busy
                    && !_airCameraSettingsModel.ui_is_busy
                    && !_airCameraSettingsModel2.ui_is_busy)
                _airCameraSettingsModel.ensure_parameters_available()
        }
    }

    property int air_settings_update_count: _ohdSystemAirSettingsModel.update_count
    property bool camera_plugin_active: {
        var unused = air_settings_update_count
        if (!_ohdSystemAirSettingsModel.has_params_fetched) return false
        return (_ohdSystemAirSettingsModel.param_int_exists("CAM_CTRL_ACTIVE")
                && _ohdSystemAirSettingsModel.get_cached_int("CAM_CTRL_ACTIVE") === 1)
                || (_ohdSystemAirSettingsModel.param_int_exists("TOPOTEK_ACTIVE")
                    && _ohdSystemAirSettingsModel.get_cached_int("TOPOTEK_ACTIVE") === 1)
                || (_ohdSystemAirSettingsModel.param_int_exists("SIYI_ACTIVE")
                    && _ohdSystemAirSettingsModel.get_cached_int("SIYI_ACTIVE") === 1)
    }

    function takeover_control(){
        if (arducam_camera && ispControls.count) ispControls.itemAt(0).takeover_control();
        else if (_qopenhd.is_windows()) colourPreview.takeover_control();
        else if (gx_camera && gxControls.count) gxControls.itemAt(0).takeover_control();
        else brightness.takeover_control();
    }

    Column {
        anchors.top: parent.top
        anchors.topMargin: 0
        spacing: 5
        width: secondaryUiWidth
        Label {
            visible: cameraPanel.arducam_camera
            text: qsTr("Live camera controls")
            color: "white"
            font.bold: true
            leftPadding: 6
        }
        Label {
            visible: cameraPanel.arducam_camera
            width: parent.width - 12
            leftPadding: 6
            wrapMode: Text.WordWrap
            color: "white"
            font.pixelSize: 12
            text: cameraPanel.manualExposure ?
                qsTr("Exposure mode changes may briefly pause video. Other adjustments apply live.") :
                cameraPanel.arducamAeProfile === 1 ?
                qsTr("Sport limits shutter to 2 ms to reduce motion blur. Gain rises when needed; low light can look noisier.") :
                cameraPanel.arducamAeProfile === 2 ?
                qsTr("Fly prioritizes the lower part of the displayed image and allows bright sky to clip. Experimental; outdoor testing is pending.") :
                qsTr("Auto adjusts shutter and gain. Select Manual to set them. Turn off auto white balance to set color temperature.")
        }
        Repeater {
            id: ispControls
            // Keep delegates alive when AE/AWB changes: ChoiceSelector returns
            // focus to the row that opened it after saving a selection.
            model: cameraPanel.arducam_camera ? [
                ["Exposure mode", "ISP_AE_MODE"],
                ["Auto exposure profile", "ISP_AE_PROFILE"],
                ["Exposure (us)", "ISP_EXPOSURE_US"],
                ["Gain (%)", "ISP_GAIN"],
                ["Auto white balance", "ISP_WB_AUTO"],
                ["Color temperature (K)", "ISP_WB_K"],
                ["Gamma (%)", "ISP_GAMMA"]
            ] : []
            delegate: MavlinkChoiceElement2 {
                visible: (m_param_id !== "ISP_AE_PROFILE" ||
                          (!cameraPanel.manualExposure && cameraPanel.cameraParamUpdates >= 0 &&
                           _airCameraSettingsModel.param_int_exists("ISP_AE_PROFILE"))) &&
                         (m_param_id !== "ISP_EXPOSURE_US" && m_param_id !== "ISP_GAIN" || cameraPanel.manualExposure) &&
                         (m_param_id !== "ISP_WB_K" || cameraPanel.manualWhiteBalance)
                m_title: modelData[0]
                m_param_id: modelData[1]
                m_settings_model: _airCameraSettingsModel
                onGoto_previous: {
                    if (!cameraPanel.focusIsp(index - 1, -1)) sidebar.regain_control_on_sidebar_stack();
                }
                onGoto_next: {
                    if (!cameraPanel.focusIsp(index + 1, 1)) brightness.takeover_control();
                }
            }
        }
        ColorPreviewControls {
            id: colourPreview
            width: parent.width - 20
            x: 10
            visible: _qopenhd.is_windows()
            onControlFocused: cameraPanel.ensure_body_item_visible(item)
        }
        MavlinkChoiceElement2{
            id: brightness
            visible: !cameraPanel.gx_camera
            m_title: "Brightness"
            m_param_id: "BRIGHTNESS"
            m_settings_model: _airCameraSettingsModel
            onGoto_previous: {
                if (cameraPanel.arducam_camera && ispControls.count) ispControls.itemAt(ispControls.count-1).takeover_control();
                else sidebar.regain_control_on_sidebar_stack();
            }
            onGoto_next: {
                saturation.takeover_control();
            }
        }
        MavlinkChoiceElement2{
            id: saturation
            visible: !cameraPanel.gx_camera
            m_title: "Saturation"
            m_param_id: "SATURATION"
            m_settings_model: _airCameraSettingsModel
            onGoto_previous: {
               brightness.takeover_control();
            }
            onGoto_next: {
                contrast.takeover_control();
            }
        }
        MavlinkChoiceElement2{
            id: contrast
            visible: !cameraPanel.gx_camera
            m_title: "Contrast"
            m_param_id: "CONTRAST"
            m_settings_model: _airCameraSettingsModel
            onGoto_previous: {
               saturation.takeover_control();
            }
            onGoto_next: {
                if (cameraPanel.arducam_camera) sidebar.regain_control_on_sidebar_stack();
                else sharpness.takeover_control();
            }
        }
        MavlinkChoiceElement2{
            id: sharpness
            visible: !cameraPanel.gx_camera && !cameraPanel.arducam_camera
            m_title: "Sharpness"
            m_param_id: "SHARPNESS"
            m_settings_model: _airCameraSettingsModel
            onGoto_previous: {
               contrast.takeover_control();
            }
            onGoto_next: {
                sidebar.regain_control_on_sidebar_stack()
            }
        }

        Repeater {
            id: gxControls
            model: cameraPanel.gx_camera ? [
                ["Day/night & IR-cut", "GX_DAYNIGHT"],
                ["IR-cut direction", "GX_IRCUT_DIR"],
                ["IR-cut periodic control", "GX_IRCUT_TIMER"],
                ["Exposure mode", "GX_EXPOSURE"],
                ["Manual gain (dB)", "GX_GAIN"],
                ["Manual shutter", "GX_SHUTTER_US"],
                ["AE target brightness", "GX_AE_TARGET"],
                ["AE maximum shutter", "GX_AE_MAX_US"],
                ["AE maximum gain (dB)", "GX_AE_MAX_GAIN"],
                ["AE strategy", "GX_AE_STRATEGY"],
                ["White balance mode", "GX_WB_MODE"],
                ["Manual WB red gain", "GX_WB_RED"],
                ["Manual WB blue gain", "GX_WB_BLUE"],
                ["Sharpness", "GX_SHARPNESS"],
                ["2D noise reduction", "GX_DENOISE_2D"],
                ["3D noise reduction", "GX_DENOISE_3D"],
                ["Saturation", "GX_SATURATION"],
                ["Contrast", "GX_CONTRAST"],
                ["Hue", "GX_HUE"],
                ["Gamma", "GX_GAMMA"],
                ["Dynamic range compression", "GX_DRC"]
            ] : []
            delegate: MavlinkChoiceElement2 {
                m_title: modelData[0]
                m_param_id: modelData[1]
                m_settings_model: _airCameraSettingsModel
                onGoto_previous: {
                    if (index > 0) gxControls.itemAt(index - 1).takeover_control();
                    else sidebar.regain_control_on_sidebar_stack();
                }
                onGoto_next: {
                    if (index + 1 < gxControls.count) gxControls.itemAt(index + 1).takeover_control();
                    else sidebar.regain_control_on_sidebar_stack();
                }
            }
        }

        ColumnLayout {
            visible: camera_plugin_active
            width: secondaryUiWidth
            spacing: 4

            Label {
                Layout.fillWidth: true
                text: qsTr("IP camera controls")
                color: "white"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                topPadding: 8
            }

            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                columns: 3
                rowSpacing: 3
                columnSpacing: 3

                Item { width: 72; height: 36 }
                Button {
                    text: "Up"
                    onPressed: _ohdAction.siyi_gimbal_rate(45, 0)
                    onReleased: _ohdAction.siyi_gimbal_rate(0, 0)
                    onCanceled: _ohdAction.siyi_gimbal_rate(0, 0)
                }
                Item { width: 72; height: 36 }
                Button {
                    text: "Left"
                    onPressed: _ohdAction.siyi_gimbal_rate(0, -45)
                    onReleased: _ohdAction.siyi_gimbal_rate(0, 0)
                    onCanceled: _ohdAction.siyi_gimbal_rate(0, 0)
                }
                Button {
                    text: qsTr("Center")
                    onClicked: _ohdAction.siyi_gimbal_center()
                }
                Button {
                    text: "Right"
                    onPressed: _ohdAction.siyi_gimbal_rate(0, 45)
                    onReleased: _ohdAction.siyi_gimbal_rate(0, 0)
                    onCanceled: _ohdAction.siyi_gimbal_rate(0, 0)
                }
                Item { width: 72; height: 36 }
                Button {
                    text: "Down"
                    onPressed: _ohdAction.siyi_gimbal_rate(-45, 0)
                    onReleased: _ohdAction.siyi_gimbal_rate(0, 0)
                    onCanceled: _ohdAction.siyi_gimbal_rate(0, 0)
                }
                Item { width: 72; height: 36 }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Button {
                    text: qsTr("Zoom -")
                    onPressed: _ohdAction.siyi_zoom(-1)
                    onReleased: _ohdAction.siyi_zoom(0)
                    onCanceled: _ohdAction.siyi_zoom(0)
                }
                Button {
                    text: qsTr("Zoom +")
                    onPressed: _ohdAction.siyi_zoom(1)
                    onReleased: _ohdAction.siyi_zoom(0)
                    onCanceled: _ohdAction.siyi_zoom(0)
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Button {
                    text: qsTr("Focus -")
                    onPressed: _ohdAction.siyi_focus(-1)
                    onReleased: _ohdAction.siyi_focus(0)
                    onCanceled: _ohdAction.siyi_focus(0)
                }
                Button {
                    text: qsTr("AF")
                    onClicked: _ohdAction.siyi_autofocus()
                }
                Button {
                    text: qsTr("Focus +")
                    onPressed: _ohdAction.siyi_focus(1)
                    onReleased: _ohdAction.siyi_focus(0)
                    onCanceled: _ohdAction.siyi_focus(0)
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Button {
                    text: qsTr("Photo")
                    onClicked: _ohdAction.siyi_take_photo()
                }
                Button {
                    text: qsTr("Rec")
                    onClicked: _ohdAction.siyi_set_recording(true)
                }
                Button {
                    text: qsTr("Stop")
                    onClicked: _ohdAction.siyi_set_recording(false)
                }
            }
        }

    }
}
