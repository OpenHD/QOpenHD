import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

Item {
    id: mappedMavlinkChoices


    ListModel{
        id: elements_model_brightness
        //ListElement {value: 0; verbose:"0%"}
        //ListElement {value: 25; verbose:"25%"}
        //ListElement {value: 50; verbose:"50%"}
        ListElement {value: 75; verbose:"75%"}
        ListElement {value: 95; verbose:"95%"}
        ListElement {value: 98; verbose:"98%"}
        ListElement {value: 100; verbose:"100%\n(Default)"}
        ListElement {value: 102; verbose:"102%"}
        ListElement {value: 105; verbose:"105%"}
        ListElement {value: 125; verbose:"125%"}
        //ListElement {value: 150; verbose:"150%"}
        //ListElement {value: 175; verbose:"175%"}
        //ListElement {value: 200; verbose:"200%"}
    }
    ListModel{
        id: elements_model_saturation
        ListElement {value: 50; verbose:"50%"}
        ListElement {value: 75; verbose:"75%"}
        ListElement {value: 90; verbose:"90%"}
        ListElement {value: 100; verbose:"100%\n(Default)"}
        ListElement {value: 110; verbose:"110%"}
        ListElement {value: 125; verbose:"125%"}
        ListElement {value: 150; verbose:"150%"}
    }
    ListModel{
        id: elements_model_contrast
        ListElement {value: 50; verbose:"50%"}
        ListElement {value: 75; verbose:"75%"}
         ListElement {value: 90; verbose:"90%"}
        ListElement {value: 100; verbose:"100%\n(Default)"}
        ListElement {value: 125; verbose:"125%"}
        ListElement {value: 150; verbose:"150%"}
    }
    ListModel{
        id: elements_model_sharpness
        ListElement {value: 50; verbose:"50%"}
        ListElement {value: 75; verbose:"75%"}
        ListElement {value: 90; verbose:"90%"}
        ListElement {value: 100; verbose:"100%\n(Default)"}
        ListElement {value: 110; verbose:"110%"}
        ListElement {value: 125; verbose:"125%"}
        ListElement {value: 150; verbose:"150%"}
    }
    ListModel{
        id: elements_model_rotation
        ListElement {value: 50; verbose:"50%"}
        ListElement {value: 75; verbose:"75%"}
        ListElement {value: 90; verbose:"90%"}
        ListElement {value: 100; verbose:"100%\n(Default)"}
        ListElement {value: 110; verbose:"110%"}
        ListElement {value: 125; verbose:"125%"}
        ListElement {value: 150; verbose:"150%"}
    }
    ListModel{
        id: elements_model_on_off
        ListElement {value: 0; verbose:"OFF"}
        ListElement {value: 1; verbose:"ON"}
    }
    ListModel{
        id: elements_model_libcamera_impl
        ListElement {value: 0; verbose:"libcamerasrc\n(GStreamer)"}
        ListElement {value: 1; verbose:"libcamera\n(native)"}
    }
    ListModel{
        id: elements_model_air_recording
        ListElement {value: 0; verbose:"ALWAYS\nOFF"}
        ListElement {value: 1; verbose:"ALWAYS\nON"}
        ListElement {value: 2; verbose:"AUTO\n(WHEN ARMED)"}
    }
    ListModel{
        id: elements_model_hotspot
        ListElement {value: 0; verbose:"AUTO\n(WHEN DISARMED)"}
        ListElement {value: 1; verbose:"ALWAYS\nOFF"}
        ListElement {value: 2; verbose:"ALWAYS\nON"}
    }
    ListModel{
        id: elements_model_wifi_mode
        ListElement {value: 0; verbose:"WIFI\nOFF"}
        ListElement {value: 1; verbose:"HOTSPOT"}
        ListElement {value: 2; verbose:"CLIENT"}
    }
    ListModel{
        id: elements_model_tx_power_level
        ListElement {value: 20; verbose:"20%"}
        ListElement {value: 40; verbose:"40%"}
        ListElement {value: 60; verbose:"60%"}
        ListElement {value: 80; verbose:"80%"}
        ListElement {value: 100; verbose:"100%"}
    }
    ListModel{
        id: elements_model_camera_rotation_degree
        ListElement {value: 0; verbose:"0°\n(Default)"}
        ListElement {value: 1; verbose:"180°\n"}
    }
    ListModel{
        id: elements_model_camera_rotation_flip
        ListElement {value: 0; verbose:"0°\n(Default)"}
        ListElement {value: 1; verbose:"VFLIP\n(mirror)\n"}
        ListElement {value: 2; verbose:"HFLIP\n(180°)"}
        ListElement {value: 3; verbose:"BOTH\n"}
    }

    ListModel{
        id: elements_model_undefined
        ListElement {value: 0; verbose:"0\nUNDEFINED"}
        ListElement {value: 1; verbose:"1\nUNDEFINED"}
        ListElement {value: 2; verbose:"2\nUNDEFINED"}
    }

    // NOTE: This is for a string param !
    ListModel{
        id: elements_model_camera_resolution_bup
        ListElement {value: "640x480@60"; verbose:"VGA 4:3\n60fps"}
        ListElement {value: "1280x720@60"; verbose:"HD 16:9\n60fps"}
        ListElement {value: "1920x1080@30"; verbose:"FHD 16:9\n30fps"}
    }
    ListModel{
        id: elements_model_camera_resolution_dynamic
    }
    // Built dynamically depending on the used camera
    function get_camera_resolution_model(){
        if(_cameraStreamModelPrimary.camera_type<0){
            return elements_model_camera_resolution_bup;
        }
        var supported_resolutions=_cameraStreamModelPrimary.get_supported_resolutions();
        elements_model_camera_resolution_dynamic.clear()
        for(var i=0; i<supported_resolutions.length; i++){
            var tmp=supported_resolutions[i];
            var verbose_str=_cameraStreamModelPrimary.make_resolution_fps_verbose(tmp);
            //console.log("Supported:["+tmp+"]");
            elements_model_camera_resolution_dynamic.append({value: tmp, verbose: verbose_str});
        }
        return elements_model_camera_resolution_dynamic;
    }

    // Built dynamically depending on the settings
    // 5700,5745,5785,5825,5865,5260,5280
    ListModel{
        id: frequencies_model
        ListElement {value: 5700; verbose:"5700Mhz\nOHD 1"}
        ListElement {value: 5745; verbose:"5745Mhz\nOHD 2"}
        ListElement {value: 5785; verbose:"5785Mhz\nOHD 3"}
        ListElement {value: 5825; verbose:"5825Mhz\nOHD 4"}
        ListElement {value: 5865; verbose:"5865Mhz\nOHD 5"}
        ListElement {value: 5260; verbose:"5260Mhz\nOHD 6"}
        ListElement {value: 5280; verbose:"5280Mhz\nOHD 7"}
    }
    ListModel{
        id: frequencies_model_with_5180mhz_lowband
        ListElement {value: 5180; verbose:"5180Mhz\n{CUSTOM LB}"}
        ListElement {value: 5220; verbose:"5220Mhz\n{CUSTOM LB}"}
        ListElement {value: 5260; verbose:"5260Mhz\n{CUSTOM LB}"}
        ListElement {value: 5300; verbose:"5300Mhz\n{CUSTOM LB}"}
        //
        ListElement {value: 5700; verbose:"5700Mhz\nOHD 1"}
        ListElement {value: 5745; verbose:"5745Mhz\nOHD 2"}
        ListElement {value: 5785; verbose:"5785Mhz\nOHD 3"}
        ListElement {value: 5825; verbose:"5825Mhz\nOHD 4"}
        ListElement {value: 5865; verbose:"5865Mhz\nOHD 5"}
        ListElement {value: 5260; verbose:"5260Mhz\nOHD 6"}
        ListElement {value: 5280; verbose:"5280Mhz\nOHD 7"}
    }
    ListModel{
        id: elements_model_channel_width
        ListElement {value: 10; verbose:"10Mhz"}
        ListElement {value: 20; verbose:"20Mhz"}
        ListElement {value: 40; verbose:"40Mhz\n(HIGH BW)"}
    }
    ListModel { id: supported_frequencies_model }

    function get_frequency_model() {
        supported_frequencies_model.clear();
        var frequencies = _frequencyHelper.get_frequencies(settings.qopenhd_frequency_filter_selection);
        for (var i = 0; i < frequencies.length; ++i) {
            supported_frequencies_model.append({
                value: frequencies[i],
                verbose: _frequencyHelper.get_frequency_description(frequencies[i])
            });
        }
        return supported_frequencies_model;
    }
    ListModel{
        id: elements_model_rate
        ListElement {value: 0; verbose:"MCS0\n(LONG RANGE)"}
        ListElement {value: 1; verbose:"MCS1\n(RANGE)"}
        ListElement {value: 2; verbose:"MCS2\n(QUALITY)"}
        ListElement {value: 8; verbose:"MCS8\n(2SS PARTIAL 0)"}
        ListElement {value: 9; verbose:"MCS9\n(2SS PARTIAL 1)"}
        ListElement {value: 10; verbose:"MCS10\n(2SS PARTIAL 2)"}
    }


    ListModel { id: gx_choices }
    function gx_model(param_id) {
        gx_choices.clear();
        var values = [];
        var labels = [];
        if (param_id === "GX_DAYNIGHT") {
            values = [0, 1, 2]; labels = ["Day / IR-cut", "Night / clear", "External trigger"];
        } else if (param_id === "GX_EXPOSURE" || param_id === "GX_WB_MODE") {
            values = [2, 0]; labels = ["Auto", "Manual"];
        } else if (param_id === "GX_IRCUT_DIR") {
            values = [0, 1]; labels = ["Normal", "Reversed"];
        } else if (param_id === "GX_IRCUT_TIMER") {
            values = [0, 1]; labels = ["Off", "On"];
        } else if (param_id === "GX_AE_STRATEGY") {
            values = [0, 1]; labels = ["Highlight priority", "Shadow priority"];
        } else if (param_id === "GX_GAIN" || param_id === "GX_AE_MAX_GAIN") {
            values = [0, 30, 60, 90, 120, 180, 240, 300, 360, 420, 453, 480, 540, 600, 660, 720];
        } else if (param_id === "GX_SHUTTER_US" || param_id === "GX_AE_MAX_US") {
            values = [100, 250, 500, 1000, 2000, 4000, 8000, 10000, 16666, 20000, 33333];
        } else if (param_id === "GX_WB_RED" || param_id === "GX_WB_BLUE") {
            values = [0, 128, 256, 512, 768, 1024, 1536, 2048, 3072, 4095];
        } else if (param_id === "GX_GAMMA") {
            values = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
            labels = ["Linear", "Default", "1.6", "1.8", "2.0", "2.2", "Style 1", "Style 2", "Style 3", "Style 4", "Style 5", "Style 6"];
        } else if (param_id === "GX_SATURATION" || param_id === "GX_CONTRAST" || param_id === "GX_HUE") {
            values = [0, 10, 25, 40, 50, 60, 75, 90, 100];
        } else {
            values = [0, 16, 32, 48, 64, 96, 128, 160, 192, 224, 255];
        }
        for (var i = 0; i < values.length; ++i) {
            var label = labels.length ? labels[i] : String(values[i]);
            if (param_id === "GX_GAIN" || param_id === "GX_AE_MAX_GAIN") label = (values[i] / 10).toFixed(1) + " dB";
            if (param_id === "GX_SHUTTER_US" || param_id === "GX_AE_MAX_US") label = (values[i] / 1000).toFixed(2) + " ms";
            gx_choices.append({value: values[i], verbose: label});
        }
        return gx_choices;
    }
    function get_model(param_id){
        if (param_id.indexOf("GX_") === 0) return gx_model(param_id);
        if(param_id=="BRIGHTNESS"){
            return elements_model_brightness;
        }else if(param_id=="SATURATION"){
            return elements_model_saturation;
        }else if(param_id=="CONTRAST"){
            return elements_model_contrast;
        }else if(param_id=="SHARPNESS"){
            return elements_model_sharpness;
        }else if(param_id=="ROTATION"){
            return elements_model_rotation;
        }else if(param_id=="ENABLE_JOY_RC"){
            return elements_model_on_off;
        }else if(param_id=="AIR_RECORDING_E"){
            return elements_model_air_recording;
        }else if(param_id=="WIFI_HOTSPOT_E"){
            return elements_model_hotspot
        }else if(param_id=="WIFI_MODE"){
            return elements_model_wifi_mode
        }else if(param_id=="TX_PWR_LVL"){
            return elements_model_tx_power_level
        }else if(param_id=="ROTATION_FLIP"){
            return elements_model_camera_rotation_flip
        }else if(param_id=="LIBCAMERA_IMPL"){
            return elements_model_libcamera_impl
        }else if(param_id=="SENSOR_MODE"){
            return get_camera_resolution_model();
        }else if(param_id=="RESOLUTION_FPS"){
            return get_camera_resolution_model();
        }else if(param_id=="FREQUENCY"){
            return get_frequency_model();
        }else if(param_id=="CHANNEL_WIDTH"){
            return elements_model_channel_width;
        }else if(param_id=="RATE"){
            return elements_model_rate;
        }
        return elements_model_undefined;
    }

}
