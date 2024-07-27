import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

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
        m_platform_type=ohd_platform_type;
        if(ohd_platform_type>=1){
            return true;
        }
        return false;
    }

    function get_platform_name(){
        return _ohdSystemAir.ohd_platform_type_as_string
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
        id: model_manufacturers
        ListElement {title: "DUMMY_MANUFACTURER"}
    }
    ListModel{
        id: model_cameras_for_this_manufacturer
        ListElement {title: "CAM TYPE"; value: 0}
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
        comboBoxManufacturers.enabled=true;
        // If there is only one manufacturer choice, disable the combobox.
        if(comboBoxManufacturers.model.count<=1){
            comboBoxManufacturers.enabled=false;
        }else{
            comboBoxManufacturers.enabled=true;
        }
        m_user_selected_camera_type=-1;
        visible=true;
        enabled=true;
        populate_main_camera_selector()
    }

    function get_manufacturers_model(){
        var manufacturers=m_cam_model.get_manufacturer_choices(m_platform_type);
        model_manufacturers.clear();
        for(var i=0;i<manufacturers.length;i++){
            //var x_title="XX"+manufacturers[i];
            var x_title=manufacturers[i];
            model_manufacturers.append({title: x_title});
        }
        return model_manufacturers;
    }

    function get_cameras_model(index_manufacturer){
        model_cameras_for_this_manufacturer.clear();
        var names=m_cam_model.get_manufacturer_cameras_names(m_platform_type,index_manufacturer);
        var types=m_cam_model.get_manufacturer_cameras_type(m_platform_type,index_manufacturer);
        for(var i=0;i<names.length;i++){
            model_cameras_for_this_manufacturer.append({title: names[i], value: types[i]});
        }
        return model_cameras_for_this_manufacturer;
    }

    function populate_main_camera_selector(){
        var index_manufacturer=comboBoxManufacturers.currentIndex;
        combobox_cameras.model=get_cameras_model(index_manufacturer)
        combobox_cameras.currentIndex=0;
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
            model: model_manufacturers
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
            model: model_cameras_for_this_manufacturer
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
Item {
    anchors.fill: parent
    anchors.top: parent.top
    anchors.topMargin: 285

    Rectangle {
        width: parent.width
        height: parent.height
        color: "transparent"

        RowLayout {
            anchors.centerIn: parent

            Button {
                Layout.preferredWidth: 150
                text: "CANCEL"
                onPressed: {
                    close();
                }
            }

            Button {
                id: button_save
                Layout.preferredWidth: 150
                text: "SAVE"
                onPressed: {
                    on_user_clicked_save();
                }
                enabled: m_user_selected_camera_type >= 0 && m_user_selected_camera_type != (m_is_secondary_cam ? _cameraStreamModelSecondary.camera_type : _cameraStreamModelPrimary.camera_type)
            }
        }
    }
}

}

