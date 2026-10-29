import QtQuick 2.12
import QtTest 1.2
import "../../qml/ui/elements" as Elements
Item {
 QtObject { id:_qopenhd;property bool debugMenuPreview:false }
 QtObject { id:_ohdSystemAir;property bool is_alive:true }
 QtObject { id:_cameraStreamModelSecondary;property int camera_status:0 }
 QtObject { id:_airCameraSettingsModel2
 property bool has_params_fetched:false;property bool supported:true;property int streaming:0
 function param_int_exists(id){return supported && id==='STREAMING_E'}
 function get_cached_int(id){return streaming}
 }
 Elements.AppSettings { id:appSettings }
 Elements.CameraAutoDetection { settingsObject: appSettings }
 TestCase {name:'CameraAutodetection';when:windowShown
 function test_confirmed_state(){
 verify(!appSettings.secondary_camera_available)
 appSettings.dev_qopenhd_n_cameras=2
 verify(!appSettings.secondary_camera_available)
 appSettings.dev_qopenhd_n_cameras=1
 _cameraStreamModelSecondary.camera_status=2
 wait(600);compare(appSettings.dev_qopenhd_n_cameras,1)
 _cameraStreamModelSecondary.camera_status=1
 tryCompare(appSettings,'dev_qopenhd_n_cameras',2,1800)
 verify(appSettings.secondary_camera_available)
 _cameraStreamModelSecondary.camera_status=2
 wait(600);compare(appSettings.dev_qopenhd_n_cameras,2)
 verify(!appSettings.secondary_camera_available)
 _airCameraSettingsModel2.has_params_fetched=true;_airCameraSettingsModel2.streaming=0
 appSettings.qopenhd_switch_primary_secondary=true
 tryCompare(appSettings,'dev_qopenhd_n_cameras',1,1800)
 verify(!appSettings.secondary_camera_available)
 verify(!appSettings.qopenhd_switch_primary_secondary)
 _airCameraSettingsModel2.streaming=1
 tryCompare(appSettings,'dev_qopenhd_n_cameras',2,1800)
 verify(!appSettings.secondary_camera_available)
 _cameraStreamModelSecondary.camera_status=1
 tryCompare(appSettings,'secondary_camera_available',true,1800)
 _qopenhd.debugMenuPreview=true;_airCameraSettingsModel2.streaming=0
 wait(600);compare(appSettings.dev_qopenhd_n_cameras,2)
 _qopenhd.debugMenuPreview=false;_ohdSystemAir.is_alive=false
 wait(600);compare(appSettings.dev_qopenhd_n_cameras,2)
 verify(!appSettings.secondary_camera_available)
 _ohdSystemAir.is_alive=true
 tryCompare(appSettings,'dev_qopenhd_n_cameras',1,1800)
 verify(!appSettings.secondary_camera_available)
 }
 }
}
