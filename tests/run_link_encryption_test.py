"""Exercise the shared licensed Link encryption control with two camera models."""
from pathlib import Path
import argparse,os,subprocess,tempfile
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--qt-bin',type=Path,required=True);args=p.parse_args()
fixture='''import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
Item {
 id:scene;width:800;height:200
 QtObject {id:settings_form;property color primaryText:"white"}
 QtObject {id:_qopenhd;property bool debugMenuPreview:false}
 QtObject {id:_ohdSystemAir;property bool is_alive:true}
 QtObject {
  id:_fleetControlLte
  signal statusChanged()
  property bool licenseValid:false
  property string verifiedLicenseId:"lic1"
  property var licenses:[{id:"lic1",craftId:"craft1",status:"active",expiresAt:"2099-01-01T00:00:00Z"}]
  property bool busy:false
  property bool certificateInstalled:true
  property string certificateLicenseId:"lic1"
  property string certificateExpiresAt:"2099-01-01T00:00:00Z"
  property int requests:0
  function requestVideoCertificate(id){requests++;busy=true}
 }
 Component {
  id:camera
  QtObject {
   property bool supported:true
   property bool ui_is_busy:false
   property int update_count:0
   property int encryption:0
   property int writes:0
   function param_int_exists(id){return supported&&id==="HIGH_ENCRYPTION"}
   function get_cached_int(id){return encryption}
   function try_set_param_int_async(id,value,log){encryption=value;writes++;update_count++}
  }
 }
 property var _airCameraSettingsModel:camera.createObject(scene)
 property var _airCameraSettingsModel2:camera.createObject(scene)
 LinkEncryptionControl {id:control;width:parent.width}
 TestCase {
  name:"LinkEncryption";when:windowShown
  function init(){
   _fleetControlLte.licenseValid=true;_fleetControlLte.verifiedLicenseId="lic1";_fleetControlLte.licenses=[{id:"lic1",craftId:"craft1",status:"active",expiresAt:"2099-01-01T00:00:00Z"}]
   _fleetControlLte.busy=false;_fleetControlLte.certificateInstalled=true;_fleetControlLte.certificateLicenseId="lic1";_fleetControlLte.certificateExpiresAt="2099-01-01T00:00:00Z";_fleetControlLte.requests=0
   control.pendingLicence="";_qopenhd.debugMenuPreview=false;_ohdSystemAir.is_alive=true
   var models=[_airCameraSettingsModel,_airCameraSettingsModel2]
   for(var i=0;i<models.length;i++){models[i].supported=true;models[i].ui_is_busy=false;models[i].encryption=0;models[i].writes=0;models[i].update_count++}
  }
  function test_valid_licence_only(){
   verify(control.visible)
   _fleetControlLte.licenseValid=false;verify(!control.visible);control.changeEncryption(true);compare(_airCameraSettingsModel.writes,0)
   _fleetControlLte.licenseValid=true;_fleetControlLte.verifiedLicenseId="other";verify(!control.visible)
   _fleetControlLte.verifiedLicenseId="lic1";_fleetControlLte.licenses=[{id:"lic1",craftId:"craft1",status:"expired",expiresAt:"2000-01-01T00:00:00Z"}];verify(!control.visible)
  }
  function test_one_switch_updates_all_cameras(){
   control.changeEncryption(true);compare(_airCameraSettingsModel.encryption,1);compare(_airCameraSettingsModel2.encryption,1);verify(control.allEncrypted)
   control.changeEncryption(false);compare(_airCameraSettingsModel.encryption,0);compare(_airCameraSettingsModel2.encryption,0)
  }
  function test_single_camera_and_mixed_values(){
   _airCameraSettingsModel2.supported=false;_airCameraSettingsModel2.update_count++
   control.changeEncryption(true);compare(_airCameraSettingsModel.writes,1);compare(_airCameraSettingsModel2.writes,0)
   _airCameraSettingsModel2.supported=true;_airCameraSettingsModel2.update_count++;verify(!control.allEncrypted)
   control.changeEncryption(true);compare(_airCameraSettingsModel.writes,1);compare(_airCameraSettingsModel2.writes,1);verify(control.allEncrypted)
  }
  function test_certificate_before_camera_writes(){
   _fleetControlLte.certificateLicenseId="another-craft"
   control.changeEncryption(true);compare(_fleetControlLte.requests,1);compare(_airCameraSettingsModel.writes,0);compare(_airCameraSettingsModel2.writes,0)
   _fleetControlLte.certificateLicenseId="lic1";_fleetControlLte.busy=false;_fleetControlLte.statusChanged()
   compare(_airCameraSettingsModel.encryption,1);compare(_airCameraSettingsModel2.encryption,1)
  }
  function test_no_writes_after_licence_loss_or_offline(){
   _ohdSystemAir.is_alive=false;control.changeEncryption(true);compare(_airCameraSettingsModel.writes,0)
   _ohdSystemAir.is_alive=true;_qopenhd.debugMenuPreview=true;control.changeEncryption(true);compare(_airCameraSettingsModel.writes,0)
   _qopenhd.debugMenuPreview=false;_fleetControlLte.certificateInstalled=false;control.changeEncryption(true)
   _fleetControlLte.licenseValid=false;_fleetControlLte.certificateInstalled=true;_fleetControlLte.busy=false;_fleetControlLte.statusChanged()
   compare(_airCameraSettingsModel.writes,0);compare(_airCameraSettingsModel2.writes,0)
  }
 }
}
'''
with tempfile.TemporaryDirectory(prefix='qopenhd-link-encryption-') as temp:
 folder=Path(temp)
 menu=ROOT/'qml/ui/configpopup'
 (folder/'MenuTypography.js').write_text((menu/'MenuTypography.js').read_text(encoding='utf-8'),encoding='utf-8')
 source=(menu/'openhd_settings/LinkEncryptionControl.qml').read_text(encoding='utf-8').replace('../MenuTypography.js','MenuTypography.js')
 (folder/'LinkEncryptionControl.qml').write_text(source,encoding='utf-8')
 (folder/'tst_encryption.qml').write_text(fixture,encoding='utf-8')
 env=os.environ.copy();env['PATH']=str(args.qt_bin)+os.pathsep+env.get('PATH','')
 env.update(QT_FORCE_STDERR_LOGGING='1',QT_SCALE_FACTOR='1',QT_QUICK_BACKEND='software',QT_QUICK_CONTROLS_STYLE='Material',QT_QPA_PLATFORM_PLUGIN_PATH=str(args.qt_bin.parent/'plugins/platforms'),QML2_IMPORT_PATH=str(args.qt_bin.parent/'qml'))
 log=ROOT/'build'/('link-encryption-'+args.qt_bin.parent.name+'.txt')
 result=subprocess.run([str(args.qt_bin/'qmltestrunner.exe'),'-input',str(folder),'-o',str(log)+',txt'],env=env,timeout=60)
 print(log.read_text(encoding='utf-8') if log.exists() else 'No test output')
 raise SystemExit(result.returncode)
