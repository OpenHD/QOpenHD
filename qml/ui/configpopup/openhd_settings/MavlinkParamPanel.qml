import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

// Contains a list of all the settings on the left, and opens up a parameter editor instance on
// the right if the user wants to edit any mavlink settings
Rectangle {
    width: parent.width
    height: parent.height
    property int paramEditorWidth: 300

    // We set a the ground pi instance as default (such that the qt editor code completion helps us a bit),
    // but this should be replaced by the proper instance for air or camera
    property var m_instanceMavlinkSettingsModel: _ohdSystemGroundSettings
    // figure out if the system is alive
    property var m_instanceCheckIsAvlie: _ohdSystemGround
    // unly used for camera 1 / camera2
    property bool m_is_secondary_cam: false

    property string m_name: "undefined"
    property bool m_requires_alive_air: false
    property bool m_ip_camera_settings_available: m_instanceMavlinkSettingsModel.has_params_fetched &&
                                                   m_instanceMavlinkSettingsModel.param_string_exists("IP_CAM_PIPELINE")

    //color: "red"
    //color: "transparent"
    color: settings.screen_settings_openhd_parameters_transparent ? "transparent" : "white"

    property int m_progress_perc : m_instanceMavlinkSettingsModel.curr_get_all_progress_perc;

    property bool m_any_param_eitor_opened: parameterEditor.visible || dialoque_choose_camera.visible || dialoque_choose_resolution.visible;
    property bool m_any_param_busy: _ohdSystemGroundSettings.ui_is_busy || _ohdSystemAirSettingsModel.ui_is_busy || _airCameraSettingsModel.ui_is_busy ||
                                    _airCameraSettingsModel2.ui_is_busy;

    onVisibleChanged: {
        if(visible){
            if(!m_instanceCheckIsAvlie.is_alive){
                var message = m_requires_alive_air
                    ? qsTr("AIR not alive, parameters unavailable")
                    : qsTr("GND not alive, parameters unavailable");
                _qopenhd.show_toast(message);
            }else{
                if(! m_instanceMavlinkSettingsModel.has_params_fetched){
                   m_instanceMavlinkSettingsModel.try_refetch_all_parameters_async()
                }
            }
        }
    }

    function open_apropiate_param_editor(model){
        // For a few params we have extra ui elements, otherwise, use the generic param editor
        var init_special_ui_element_success=false;
        if(model.unique_id==="CAMERA_TYPE"){
            dialoque_choose_camera.m_is_for_secondary_camera=m_is_secondary_cam;
            if(dialoque_choose_camera.set_ohd_platform_type()){
                dialoque_choose_camera.initialize_and_show()
                init_special_ui_element_success=true;
            }
        }else if(model.unique_id==="RESOLUTION_FPS"){
            dialoque_choose_resolution.m_current_resolution_fps=model.value;
            dialoque_choose_resolution.m_is_for_secondary=m_is_secondary_cam;
            dialoque_choose_resolution.initialize_and_show();
            init_special_ui_element_success=true;
        }
        if(!init_special_ui_element_success){
            // generic editor
            parameterEditor.setup_for_parameter(model.unique_id,model)
        }
    }

    Rectangle{
        id: upper_action_row
        width: parent.width
        height: rowHeight;//*2 / 3;
        color: "#8cbfd7f3"
        Button {
            text: m_instanceCheckIsAvlie.is_alive ?  qsTr("\uf2f1") : qsTr("\uf127");
            font.family: "Font Awesome 5 Free"
            anchors.left: parent.left
            anchors.leftMargin: 10
            onClicked: {
                parameterEditor.visible=false
                m_instanceMavlinkSettingsModel.try_refetch_all_parameters_async()
            }
            anchors.verticalCenter: parent.verticalCenter
            enabled: m_instanceCheckIsAvlie.is_alive && (!m_any_param_busy)
        }
        Text{
            text: qsTr("FULL %1 PARAM SET").arg(m_name)
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            font.bold: true
            font.pixelSize: 13
        }
        CheckBox{
            anchors.right: down_button.left
            anchors.rightMargin: 3
            checked: settings.screen_settings_openhd_parameters_transparent
            onCheckedChanged: settings.screen_settings_openhd_parameters_transparent = checked
            anchors.verticalCenter: parent.verticalCenter
        }
        Button{
            id: up_button
            anchors.right: down_button.left
            anchors.leftMargin: 3
            text: "\uf0d8" //UP
            font.family: "Font Awesome 5 Free";
            anchors.verticalCenter: parent.verticalCenter
            onClicked: {
                paramListScrollView.ScrollBar.vertical.position -= 0.1
            }
        }
        Button{
            id: down_button
            font.family: "Font Awesome 5 Free";
            text: "\uf0d7" //DOWN
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            onClicked: {
                paramListScrollView.ScrollBar.vertical.position += 0.1
            }
        }
        Rectangle{
            width: parent.width
            height: 2
            color: "black"
            anchors.bottom: parent.bottom
            anchors.left: parent.left
        }
        SimpleProgressBar{
            width: parent.width
            height: 15
            anchors.top: parent.top
            visible: m_progress_perc>=0 && m_progress_perc<100
            impl_curr_progress_perc: m_progress_perc
            impl_curr_color: "#333c4c"
        }
    }

    Component {
        id: delegateMavlinkSettingsValue

        Rectangle{
            //color: (index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
            //color: "transparent"
            color: settings.screen_settings_openhd_parameters_transparent ? "transparent" : ((index % 2 == 0) ? "#8cbfd7f3" : "#00000000")
            property bool isIpCameraQuickSetting: model.unique_id === "IP_CAM_ADDRESS" || model.unique_id === "IP_CAM_PIPELINE"
            height: isIpCameraQuickSetting ? 0 : 64
            width: listView.width-12
            visible: !isIpCameraQuickSetting
            Row {
                spacing: 30
                height: parent.height
                width: parent.width
                anchors.left: parent.left
                anchors.leftMargin: 12
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width:180
                    text: model.unique_id
                    font.bold: true
                    font.pixelSize: 14
                    color: settings.screen_settings_openhd_parameters_transparent ? settings.color_text : "black"
                    style:  settings.screen_settings_openhd_parameters_transparent ? Text.Outline : Text.Normal
                    styleColor: settings.color_glow
                }
                /*Text {
                    width:180
                    text: model.extraValue
                    font.bold: true
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: settings.screen_settings_openhd_parameters_transparent ? settings.color_text : "black"
                    style:  settings.screen_settings_openhd_parameters_transparent ? Text.Outline : Text.Normal
                    styleColor: settings.color_glow
                }*/
                //Button {
                ButtonIconInfo{
                    anchors.verticalCenter: parent.verticalCenter
                    //text: "INFO"
                    //Material.background: Material.LightBlue
                    onClicked: {
                        var text = model.shortDescription
                        if(text==="TODO"){
                            text = qsTr("This parameter is not documented yet");
                         }
                        if(model.read_only){
                            text = qsTr("This parameter is read-only (cannot be edited)\n%1").arg(text);
                        }
                        _messageBoxInstance.set_text_and_show(text)
                    }
                }
                BigClickableText{
                    text: model.extraValue
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {
                       open_apropiate_param_editor(model);
                    }
                    // gray out the button for read-only params
                    enabled: !model.read_only && m_instanceCheckIsAvlie.is_alive && (!m_any_param_eitor_opened) && (!m_any_param_busy)
                }
                /*MavlinkParamValueEditElement{
                    m_display_text: model.extraValue
                    m_is_int: model.valueType===0
                    anchors.verticalCenter: parent.verticalCenter
                }*/
                ButtonIconGear {
                    anchors.verticalCenter: parent.verticalCenter
                    //text: "EDIT"
                    onClicked: {
                        open_apropiate_param_editor(model);
                    }
                    // gray out the button for read-only params
                    enabled: !model.read_only && m_instanceCheckIsAvlie.is_alive && (!m_any_param_eitor_opened) && (!m_any_param_busy)
                }
                ButtonIconWarning{
                    id: warning_whitelisted
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {
                        _messageBoxInstance.set_text_and_show(qsTr("This param is whitelisted (You should not edit it from here / editing can break things))"))
                    }
                    visible: model.whitelisted
                }
            }
        }
    }

    // Left part: multiple colums of param value
    Rectangle{
        id: scrollViewRectangle
        width: parent.width
        height: parent.height - upper_action_row.height
        anchors.top: upper_action_row.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        //color: "green"
        //opacity: 0.5
        color: settings.screen_settings_openhd_parameters_transparent ? "transparent" :  "white"

        ScrollView{
            id: paramListScrollView
            width: parent.width
            height: parent.height
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            // Always show the scroll bar (sometimes the interactive might not work) but allow interactive also
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn
            ScrollBar.vertical.interactive: true

            ListView {
                id: listView
                width: parent.width
                model: m_instanceMavlinkSettingsModel
                delegate: delegateMavlinkSettingsValue
                visible: !please_fetch_item.visible && m_instanceCheckIsAvlie.is_alive
                header: Rectangle {
                    width: listView.width - 12
                    height: m_ip_camera_settings_available ? 290 : 0
                    visible: m_ip_camera_settings_available
                    color: settings.screen_settings_openhd_parameters_transparent ? "#aa102131" : "#e8f3f8"
                    radius: 6

                    Text {
                        text: qsTr("IP CAMERA SETUP")
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        font.bold: true
                        color: settings.screen_settings_openhd_parameters_transparent ? settings.color_text : "black"
                    }
                    TextField {
                        id: ipCameraAddressField
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: saveIpAddressButton.left
                        anchors.rightMargin: 8
                        anchors.top: parent.top
                        anchors.topMargin: 38
                        placeholderText: qsTr("Camera IPv4 address")
                        text: m_instanceMavlinkSettingsModel.get_cached_string("IP_CAM_ADDRESS")
                        maximumLength: 15
                    }
                    Button {
                        id: saveIpAddressButton
                        text: qsTr("Save IP")
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: ipCameraAddressField.verticalCenter
                        enabled: !m_any_param_busy && ipCameraAddressField.text.length > 0
                        onClicked: m_instanceMavlinkSettingsModel.try_set_param_string_async("IP_CAM_ADDRESS", ipCameraAddressField.text, true)
                    }
                    TextField {
                        id: ipCameraPipelineField
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: savePipelineButton.left
                        anchors.rightMargin: 8
                        anchors.top: ipCameraAddressField.bottom
                        anchors.topMargin: 8
                        placeholderText: qsTr("GStreamer source pipeline")
                        text: m_instanceMavlinkSettingsModel.get_cached_string("IP_CAM_PIPELINE")
                        maximumLength: 127
                    }
                    Button {
                        id: savePipelineButton
                        text: qsTr("Save pipeline")
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: ipCameraPipelineField.verticalCenter
                        enabled: !m_any_param_busy && ipCameraPipelineField.text.length > 0
                        onClicked: m_instanceMavlinkSettingsModel.try_set_param_string_async("IP_CAM_PIPELINE", ipCameraPipelineField.text, true)
                    }
                    Button {
                        id: saveIpBitrateButton
                        text: qsTr("Save reserve")
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.top: ipCameraPipelineField.bottom
                        anchors.topMargin: 8
                        enabled: _ohdSystemAirSettingsModel.param_int_exists("V_IP_CAM_MBITS") && !m_any_param_busy
                        onClicked: _ohdSystemAirSettingsModel.try_set_param_int_async("V_IP_CAM_MBITS", ipCameraBitrateField.value, true)
                    }
                    SpinBox {
                        id: ipCameraBitrateField
                        from: 1
                        to: 20
                        value: _ohdSystemAirSettingsModel.param_int_exists("V_IP_CAM_MBITS") ? _ohdSystemAirSettingsModel.get_cached_int("V_IP_CAM_MBITS") : 2
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: saveIpBitrateButton.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: saveIpBitrateButton.verticalCenter
                        editable: true
                    }
                    Text {
                        text: qsTr("Fixed IP-camera reservation (Mbit/s); OpenHD cannot change the camera encoder.")
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.top: ipCameraBitrateField.bottom
                        anchors.topMargin: 2
                        color: settings.screen_settings_openhd_parameters_transparent ? settings.color_text : "#b35a00"
                    }
                    Button {
                        text: qsTr("Open Camera WebUI")
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.top: ipCameraBitrateField.bottom
                        anchors.topMargin: 28
                        enabled: ipCameraAddressField.text.length > 0
                        onClicked: Qt.openUrlExternally("http://" + ipCameraAddressField.text)
                    }
                    Text {
                        text: qsTr("Settings are sent directly to %1 via MAVLink.").arg(m_name)
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10
                        color: settings.screen_settings_openhd_parameters_transparent ? settings.color_text : "#455a64"
                    }
                }
            }
        }
        Item{
            id: please_fetch_item
            width: scrollViewRectangle.width
            height: scrollViewRectangle.height
            visible: !m_instanceMavlinkSettingsModel.has_params_fetched && m_instanceCheckIsAvlie.is_alive
            Text{
                anchors.centerIn: parent
                text: qsTr("Please fetch");
                font.bold: true
            }
        }
        Item{
            id: not_connected_overlay
            width: scrollViewRectangle.width
            height: scrollViewRectangle.height
            visible: !m_instanceCheckIsAvlie.is_alive
            /*Rectangle{
                anchors.fill: parent
                color: "gray"
                opacity: 0.5
            }*/
            Text {
                anchors.fill: parent
                text: qsTr("\uf127");
                font.family: "Font Awesome 5 Free";
                color: "black"
                //fontSizeMode: Text.Fit
                //font.pointSize: 100000
                font.pixelSize: 100
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                opacity: 0.5
            }
        }
    }

    // Right part: the parameter edit element.
    // Drawn over the parameters list if needed
    MavlinkParamEditor{
        id: parameterEditor
        total_width: paramEditorWidth
        instanceMavlinkSettingsModel: m_instanceMavlinkSettingsModel
    }

    // For (as of now, 2) Settings we have their own custom UI elements to change them
    // (Since they do not really fit into a 'generic fits all' type
    ChooseCameraDialoque{
        id: dialoque_choose_camera
    }
    ChooseResolutionDialoque{
        id: dialoque_choose_resolution
    }
}
