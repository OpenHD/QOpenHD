import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
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

    //color: "red"
    //color: "transparent"
    color: settings.screen_settings_openhd_parameters_transparent ? "transparent" : "white"

    property int m_progress_perc : m_instanceMavlinkSettingsModel.curr_get_all_progress_perc;

    onVisibleChanged: {
        if(visible){
            if(!m_instanceCheckIsAvlie.is_alive){
                var message= m_requires_alive_air ? "AIR not alive" : "GND not alive";
                message+=", parameters unavailable";
                _qopenhd.show_toast(message);
            }else{
                if(! m_instanceMavlinkSettingsModel.has_params_fetched){
                   m_instanceMavlinkSettingsModel.try_refetch_all_parameters_async()
                }
            }
        }
    }

    Rectangle{
        id: upper_action_row
        width: parent.width
        height: rowHeight*2 / 3;
        color: "#8cbfd7f3"
        Button {
            text: m_instanceCheckIsAvlie.is_alive ?  qsTr("\uf2f1") : qsTr("\uf127");
            font.family: "Font Awesome 5 Free"
            anchors.left: parent.left
            anchors.leftMargin: 3
            onClicked: {
                parameterEditor.visible=false
                m_instanceMavlinkSettingsModel.try_refetch_all_parameters_async()
            }
            anchors.verticalCenter: parent.verticalCenter
            enabled: m_instanceCheckIsAvlie.is_alive
        }
        Text{
            text: "FULL "+m_name+" PARAM SET"
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
            id: down_button
            anchors.right: up_button.left
            anchors.leftMargin: 3
            text:"\uf0d7" //DOWN
            font.family: "Font Awesome 5 Free";
            anchors.verticalCenter: parent.verticalCenter
            onClicked: {
                paramListScrollView.ScrollBar.vertical.position += 0.1
            }
        }
        Button{
            id: up_button
            font.family: "Font Awesome 5 Free";
            text: "\uf0d8" //UP
            anchors.right: parent.right
            anchors.rightMargin: 3
            anchors.verticalCenter: parent.verticalCenter
            onClicked: {
                paramListScrollView.ScrollBar.vertical.position -= 0.1
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
            height: 64
            width: listView.width-12
            Row {
                spacing: 10
                height: parent.height
                width: parent.width
                anchors.left: parent.left
                anchors.leftMargin: 12
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width:160
                    text: model.unique_id
                    font.bold: true
                    font.pixelSize: 14
                    color: settings.screen_settings_openhd_parameters_transparent ? settings.color_text : "black"
                    style:  settings.screen_settings_openhd_parameters_transparent ? Text.Outline : Text.Normal
                    styleColor: settings.color_glow
                }
                Text {
                    width:160
                    text: model.extraValue
                    font.bold: true
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: settings.screen_settings_openhd_parameters_transparent ? settings.color_text : "black"
                    style:  settings.screen_settings_openhd_parameters_transparent ? Text.Outline : Text.Normal
                    styleColor: settings.color_glow
                }
                //Button {
                ButtonIconInfo{
                    anchors.verticalCenter: parent.verticalCenter
                    //text: "INFO"
                    //Material.background: Material.LightBlue
                    onClicked: {
                        var text = model.shortDescription
                        if(text==="TODO"){
                            text = "This parameter is not documented yet";
                         }
                        if(model.read_only){
                            text ="This parameter is read-only (cannot be edited)\n"+text;
                        }
                        _messageBoxInstance.set_text_and_show(text)
                    }
                }
                ButtonIconWarning{
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {
                        _messageBoxInstance.set_text_and_show("This param is whitelisted (You should not edit it from here / editing can break things))")
                    }
                    visible: model.whitelisted
                }
                Button {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "EDIT"
                    onClicked: {
                        // For a few params we have extra ui elements, otherwise, use the generic param editor
                        if(model.unique_id==="CAMERA_TYPE"){
                            dialoque_choose_camera.m_is_for_secondary_camera=m_is_secondary_cam;
                            dialoque_choose_camera.m_platform_type=dialoque_choose_camera.mPLATFORM_TYPE_RPI
                            dialoque_choose_camera.initialize_and_show()
                        }else if(model.unique_id==="CAMERA_TYPE"){
                            dialoque_choose_camera.m_is_for_secondary_camera=m_is_secondary_cam;
                            dialoque_choose_camera.m_platform_type=dialoque_choose_camera.mPLATFORM_TYPE_RPI
                            dialoque_choose_camera.initialize_and_show()
                        }else if(model.unique_id==="RESOLUTION_FPS"){
                            dialoque_choose_resolution.m_current_resolution_fps=model.value;
                            dialoque_choose_resolution.m_is_for_secondary=m_is_secondary_cam;
                            dialoque_choose_resolution.initialize_and_show();
                        }else{
                            // this initializes and opens up the (generic) param editor
                            parameterEditor.setup_for_parameter(model.unique_id,model)
                        }
                    }
                    // gray out the button for read-only params
                    enabled: !model.read_only && m_instanceCheckIsAvlie.is_alive
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
            }
        }
        Item{
            id: please_fetch_item
            width: scrollViewRectangle.width
            height: scrollViewRectangle.height
            visible: !m_instanceMavlinkSettingsModel.has_params_fetched && m_instanceCheckIsAvlie.is_alive
            Text{
                anchors.centerIn: parent
                text: "Please fetch";
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

    BusyIndicator{
        width: 96
        height: 96
        anchors.centerIn: parent
        running: m_instanceMavlinkSettingsModel.ui_is_busy
        //visible: _xParamUI.is_busy
    }
}
