import QtQuick 2.0

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12
import QtQuick.Controls.Styles 1.4

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

Rectangle {
    width: parent.width
    height: parent.height
    color: "white"

    property bool m_is_secondary_cam: false

    property var m_cam_model : m_is_secondary_cam ? _cameraStreamModelSecondary : _cameraStreamModelPrimary;

    property bool m_is_alive : {
        if(m_is_secondary_cam){
            return _ohdSystemAir.is_alive && _cameraStreamModelPrimary.camera_type > 0 && _cameraStreamModelPrimary.camera_type<255;
        }
        return _ohdSystemAir.is_alive
    }
    property bool m_is_alive_and_enabled:{
         _ohdSystemAir.is_alive && m_cam_model.camera_type>=0 && m_cam_model.camera_type<=255;
    }

    SimpleAdvancedChoiceElement{
        id: simple_advanced_choice_element
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
    }

    // This is when view is not advanced
    Column{
        id:top_part_column
        anchors.top: simple_advanced_choice_element.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        visible: ! simple_advanced_choice_element.m_is_advanced_selected

        SettingBaseElement2{
            m_short_description: "Status"
            m_show_edit_button: false
            m_value: {
                if(!_ohdSystemAir.is_alive){
                    return "AIR NOT ALIVE";
                }
                return m_cam_model.xx_cam_status
            }
        }
        SettingBaseElement2{
            m_short_description: "Cam type"
            m_value: _cameraStreamModelPrimary.camera_type_to_string(m_cam_model.camera_type)
            m_enable_edit_button: _ohdSystemAir.is_alive
            onEditButtonClicked: {
                dialoque_choose_camera.m_is_for_secondary_camera=m_is_secondary_cam
                // TODO the right platform type !
                dialoque_choose_camera.m_platform_type=dialoque_choose_camera.mPLATFORM_TYPE_RPI
                dialoque_choose_camera.initialize_and_show()
            }
        }
        SettingBaseElement2{
            m_short_description: "Resolution"
            m_value: m_cam_model.curr_set_video_format
            m_enable_edit_button: m_is_alive_and_enabled
            onEditButtonClicked: {
                dialoque_choose_resolution.initialize_and_show();
            }
        }
        SettingBaseElement2{
            m_short_description: "Rotation"
            m_value: "TODO"
            m_enable_edit_button: m_is_alive_and_enabled
            onEditButtonClicked: {

            }
        }
    }

    // This is when the view is advanced
    MavlinkParamPanel{
        visible: simple_advanced_choice_element.m_is_advanced_selected
        anchors.top: simple_advanced_choice_element.bottom
        height: parent.height-simple_advanced_choice_element.height
        m_name: m_is_secondary_cam ? "CAMERA2" : "CAMERA1"
        m_instanceMavlinkSettingsModel: m_is_secondary_cam ? _airCameraSettingsModel2 : _airCameraSettingsModel
        m_instanceCheckIsAvlie: _ohdSystemAir
    }

    ChooseCameraDialoque{
        id: dialoque_choose_camera
    }
    ChooseResolutionDialoque{
        id: dialoque_choose_resolution
    }
}
