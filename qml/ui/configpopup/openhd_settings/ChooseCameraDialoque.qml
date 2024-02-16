import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import "../../elements"

// Dialoque to select a camera
Card {
    id: dialoque_choose_camera
    width: 360
    height: 340
    z: 5.0
    anchors.centerIn: parent
    cardName: "Camera Selection"
    cardNameColor: "black"
    visible: false

    // Supported platform types:
    readonly property int mPLATFORM_TYPE_RPI:0;
    readonly property int mPLATFORM_TYPE_ROCK:1;
    readonly property int mPLATFORM_TYPE_X20:2;
    readonly property int mPLATFORM_TYPE_X86:3;
    property int m_platform_type: 0;

    // Secondary camera only supports a few options - we can omit
    // the vendor selection
    property bool m_is_for_secondary_camera: false
    property var m_cam_model : m_is_for_secondary_camera ? _cameraStreamModelSecondary : _cameraStreamModelPrimary;

    property int m_user_selected_camera_type: -100;

    function close(){
        visible=false;
        enabled=false;
    }

    // Returns true if we have a 'NICE UI' for this platform type
    function set_ohd_platform_type(){
        const ohd_platform_type=_ohdSystemAir.ohd_platform_type;
        console.log("Platform:"+ohd_platform_type)
        if(ohd_platform_type>=10 && ohd_platform_type<20){
            m_platform_type=mPLATFORM_TYPE_RPI;
            return true;
        }
        if(ohd_platform_type>=20 && ohd_platform_type<30){
            m_platform_type=mPLATFORM_TYPE_ROCK;
            return true;
        }
        if(ohd_platform_type==1){
            m_platform_type=mPLATFORM_TYPE_X86;
            return true;
        }
        if(ohd_platform_type==30){
            m_platform_type=mPLATFORM_TYPE_X20;
            return true;
        }
        return false;
    }

    function get_platform_name(){
        if(m_platform_type==mPLATFORM_TYPE_RPI){
            return "RPI";
        }else if(m_platform_type==mPLATFORM_TYPE_ROCK){
            return "ROCK";
        }else if(m_platform_type==mPLATFORM_TYPE_X20){
            return "X20";
        }
        return "X86";
    }

    // For debugging
    function on_user_clicked_save(){
        var openhd_core_cam_type=combobox_cameras.model.get(combobox_cameras.currentIndex).value;
        console.log("Current openhd_core_cam_type: "+openhd_core_cam_type)

        var success= false;
        if(m_is_for_secondary_camera){
             success=_airCameraSettingsModel2.try_update_parameter_int("CAMERA_TYPE",openhd_core_cam_type)=="";
        }else{
             success=_airCameraSettingsModel.try_update_parameter_int("CAMERA_TYPE",openhd_core_cam_type)=="";
        }
        if(!success){
            _qopenhd.show_toast("Cannot save, please try again");
        }else{
            _messageBoxInstance.set_text_and_show("Saved, rebooting air unit",10);
            close();
        }
    }

    // The manufacturer model(s) don't need a value
    ListModel{
        id: model_manufacturers_rpi
        ListElement {title: "ARDUCAM"}
        ListElement {title: "VEYE"}
        ListElement {title: "RPI FOUNDATION"}
        ListElement {title: "GEEKWORM"}
        ListElement {title: "USB"}
        ListElement {title: "DEV/DEBUG"}
    }
    ListModel{
        id: model_manufacturers_rock
        ListElement {title: "ARDUCAM"}
        ListElement {title: "RADXA"}
        ListElement {title: "USB"}
        ListElement {title: "DEV/DEBUG"}
    }
    ListModel{
        id: model_manufacturers_x20
        ListElement {title: "RUNCAM"}
    }
    ListModel{ // X86 doesn't reall have manufacturers
        id: model_manufacturers_x86
        ListElement {title: "USB"}
        ListElement {title: "DEV/DEBUG"}
    }
    ListModel{ // Secondary camera doesn't reall have manufacturers
        id: model_manufacturers_secondary_cam
        ListElement {title: "SECONDARY CAM"}
    }

    // Actual CAMERA model(s)
    // Value needs to map to the corrseponding openhd camera type !
    ListModel{
        id: rpi_arducam_cameras
        ListElement {title: "SKYMASTERHDR"; value: 40}
        ListElement {title: "SKYVISIONPRO"; value: 41}
        ListElement {title: "IMX477m"; value: 42}
        ListElement {title: "IMX462"; value: 43}
        ListElement {title: "IMX327"; value: 44}
        ListElement {title: "IMX290"; value: 45}
        ListElement {title: "IMX462_LOWLIGHT_MINI"; value: 46}
    }
    ListModel{
        id: rpi_veye_cameras
        ListElement {title: "2MP"; value: 60}
        ListElement {title: "CSIMX307"; value: 61}
        ListElement {title: "CSSC132"; value: 62}
        ListElement {title: "MVCAM"; value: 63}
    }
    ListModel{
        id: rpi_rpif_cameras
        ListElement {title: "V1 OV5647"; value: 30}
        ListElement {title: "V2 IMX219"; value: 31}
        ListElement {title: "V3 IMX708"; value: 32}
        ListElement {title: "HQ IMX477"; value: 33}
    }
    ListModel{
        id: rpi_geekworm_cameras
        ListElement {title: "HDMI to CSI"; value: 20}
    }
    ListModel{
        id: cameras_usb
        ListElement {title: "INFIRAY USB"; value: 11}
        ListElement {title: "EXP USB GENERIC"; value: 10}
    }
    ListModel{
        id: cameras_debug
        ListElement {title: "Dummy (debug)"; value: 0}
        ListElement {title: "External (DEV)"; value: 2}
        ListElement {title: "External IP (DEV)"; value: 3}
        ListElement {title: "DEV Filecamera"; value: 4}
    }
    ListModel{
        id: x20_runcam_cameras
        ListElement {title: "RUNCAM NANO"; value: 70}
    }
    ListModel{
        id: rock_arducam_cameras
        ListElement {title: "ARDUCAM ROCK 0"; value: 0}
        ListElement {title: "ARDUCAM ROCK 1"; value: 1}
    }
    ListModel{
        id: rock_raxca_cameras
        ListElement {title: "HDMI IN"; value: 0}
    }
    ListModel{
        id: generic_secondary_camera_options
        ListElement {title: "DISABLED (Default)"; value: 255}
        ListElement {title: "INFIRAY USB"; value: 11}
        ListElement {title: "EXP USB GENERIC"; value: 10}
        ListElement {title: "Dummy (debug)"; value: 0}
        ListElement {title: "External (DEV)"; value: 2}
        ListElement {title: "External IP (DEV)"; value: 3}
    }


    function initialize_and_show(){
        console.log("Choose camera dialoque opened with "+get_platform_name());
        comboBoxManufacturers.model=get_manufacturers_model();
        var current_openhd_core_cam_type=m_cam_model.camera_type;
        // Try and find the index (2D) of the currently active camera
        var found=false;
        for(var i=0;i<comboBoxManufacturers.model.count;i++){
            var tmp_model=get_cameras_model(i);
            for(var j=0;j<tmp_model.count;j++){
                if(tmp_model.get(j).value==current_openhd_core_cam_type){
                    found=true;
                    comboBoxManufacturers.currentIndex=i;
                    combobox_cameras.model=get_cameras_model(i);
                    combobox_cameras.currentIndex=j;
                    break;
                }
            }
        }
        if(!found){
            console.log("Cam type not found");
            comboBoxManufacturers.currentIndex=0;
            combobox_cameras.model=get_cameras_model(0);
            combobox_cameras.currentIndex=0;
        }
        if(m_is_for_secondary_camera){
            comboBoxManufacturers.model=model_manufacturers_secondary_cam;
            combobox_cameras.model=generic_secondary_camera_options;
        }else{
            comboBoxManufacturers.enabled=true;
        }
        // If there is only one manufacturer choice, disable the combobox.
        if(comboBoxManufacturers.model.count<=1){
            comboBoxManufacturers.enabled=false;
        }else{
            comboBoxManufacturers.enabled=true;
        }
        m_user_selected_camera_type=-1;
        visible=true;
        enabled=true;
    }
    function get_manufacturers_model(){
        if(m_is_for_secondary_camera){
            return model_manufacturers_secondary_cam
        }
        if(m_platform_type==mPLATFORM_TYPE_RPI){
            return model_manufacturers_rpi;
        }else if(m_platform_type==mPLATFORM_TYPE_ROCK){
            return model_manufacturers_rock
        }else if(m_platform_type==mPLATFORM_TYPE_X20){
            return model_manufacturers_x20
        }else if(m_platform_type==mPLATFORM_TYPE_X86){
            return model_manufacturers_x86
        }
    }

    function get_cameras_model(index_manufacturer){
        if(m_is_for_secondary_camera){
            return generic_secondary_camera_options
        }
        if(m_platform_type==mPLATFORM_TYPE_RPI){
            if(index_manufacturer==0){
                return rpi_arducam_cameras
            }else if(index_manufacturer==1){
                return rpi_veye_cameras
            }else if(index_manufacturer==2){
                return rpi_rpif_cameras;
            }else if(index_manufacturer==3){
                return rpi_geekworm_cameras;
            }else if(index_manufacturer==4){
                return cameras_usb;
            }else{
                return cameras_debug
            }
        }else if(m_platform_type==mPLATFORM_TYPE_ROCK){
            if(index_manufacturer==0){
                return rock_arducam_cameras;
            }else if(index_manufacturer==1){
                return rock_raxca_cameras;
            }else if(index_manufacturer==2){
                return cameras_usb;
            }else{
                return cameras_debug;
            }
        }else if(m_platform_type==mPLATFORM_TYPE_X20){
            return x20_runcam_cameras;
        }else if(m_platform_type==mPLATFORM_TYPE_X86){
            if(index_manufacturer==0){
                return cameras_usb;
            }else{
                return cameras_debug;
            }
        }
    }

    function populate_main_camera_selector(){
        combobox_cameras.currentIndex=0;
        var index_manufacturer=comboBoxManufacturers.currentIndex;
        combobox_cameras.model=get_cameras_model(index_manufacturer)
        m_user_selected_camera_type=combobox_cameras.model.get(combobox_cameras.currentIndex).value;
    }

    cardBody: Column{
        padding: 10
        spacing: 10
        Text{
            width: 300
            text: "Your AIR Platform: "+get_platform_name();
        }
        ComboBox {
            width: 300
            id: comboBoxManufacturers
            model: model_manufacturers_rpi
            textRole: "title"
            implicitWidth:  elementComboBoxWidth
            currentIndex: 0
            onActivated: {
                populate_main_camera_selector();
            }
        }
        ComboBox {
            width: 300
            id: combobox_cameras
            model: rpi_arducam_cameras
            textRole: "title"
            implicitWidth:  elementComboBoxWidth
            currentIndex: 0
            onActivated: {
                m_user_selected_camera_type=model.get(currentIndex).value;
            }
        }
        Text{
            width: 300
            text: "NOTE: Changing your camera automatically\nreboots your air unit";
            visible: button_save.enabled
            font.pixelSize: 13

        }
    }
    hasFooter: true
    cardFooter: Item {
        anchors.fill: parent
        RowLayout{
            anchors.fill: parent

            Button{
                Layout.preferredWidth: 150
                text: "CANCEL"
                onPressed: {
                   close();
                }
            }
            Button{
                id: button_save
                Layout.preferredWidth: 150
                text: "SAVE"
                onPressed: {
                   on_user_clicked_save();
                }
                enabled: {
                    m_user_selected_camera_type>=0 && m_user_selected_camera_type!=(m_is_secondary_cam ? _cameraStreamModelSecondary.camera_type : _cameraStreamModelPrimary.camera_type);
                }
            }
        }
    }
}

