#include <QtTest>
#include <QColor>
#include <QSettings>
#include <QSysInfo>
#include <QStandardPaths>
#include <QTemporaryDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include "settingsbackup.h"
class FakeSettings : public QObject {
 Q_OBJECT
 Q_PROPERTY(bool has_params_fetched MEMBER complete)
 Q_PROPERTY(bool ui_is_busy MEMBER busy)
public:
 bool connected=true,complete=true,busy=false;
 QString reject;
 QVariantMap values{{"EXPOSURE",1},{"WB_FREQUENCY",5700},{"NAME",QString("original")}};
 QStringList writes;
 Q_INVOKABLE bool system_is_alive(){return connected;}
 Q_INVOKABLE QVariantMap backup_parameters(){return values;}
 Q_INVOKABLE QString request_backup_restore(QString id,QVariant value){
  QTimer::singleShot(0,this,[this,id,value]{writes.append(id);if(id==reject)emit backupParameterFinished(id,false);else{values[id]=value;emit backupParameterFinished(id,true);}});
  return {};
 }
signals:
 void backupParameterFinished(QString id,bool success);
};
static QVariantMap identity(QString id,int platform=11){
 if(id=="qopenhd")return {{"os",QSysInfo::kernelType()},{"architecture",QSysInfo::currentCpuArchitecture()},{"family","desktop"}};
 return {{"platformId",platform},{"name",platform==11?"RPI 4":"ROCK 5A"},{"radioTypes",QVariantList{2}}};
}
class BackupTest : public QObject {
 Q_OBJECT
 QTemporaryDir m_dir;
private slots:
 void initTestCase(){
  QCoreApplication::setOrganizationName("OpenHDBackupTests");QCoreApplication::setApplicationName("SettingsBackupTest");
  QStandardPaths::setTestModeEnabled(true);QSettings::setDefaultFormat(QSettings::IniFormat);QSettings::setPath(QSettings::IniFormat,QSettings::UserScope,m_dir.path());
 }
 void init(){QSettings settings;settings.clear();settings.setValue("shape_color",QColor("#38a5ff"));settings.setValue("show_map",true);settings.setValue("camera_name",QString::fromUtf8("Cam \xc3\xa4"));settings.setValue("global_scale",1.2);settings.sync();}
 void test_storage_and_arbitrary_paths(){
  SettingsBackup backup;QString folder=m_dir.filePath("USB/Video/backups");QVERIFY(QDir().mkpath(folder));
  QVERIFY(!backup.locations().isEmpty());QVERIFY(backup.browse(folder).value("writable").toBool());
  const auto file=backup.joinPath(folder,"my settings.ohdsettings");QVERIFY(file.startsWith(folder));QVERIFY(backup.exportBackup(file));QVERIFY(QFileInfo::exists(file));
  QVERIFY(backup.joinPath(folder,"../escape").isEmpty());QVERIFY(backup.joinPath(folder,"C:escape").isEmpty());
  QVERIFY(!backup.browse(m_dir.filePath("missing")).value("error").toString().isEmpty());
  QFile read(file);QVERIFY(read.open(QIODevice::ReadOnly));const auto before=read.readAll();read.close();
  QVERIFY(!backup.exportBackup(file));QVERIFY(read.open(QIODevice::ReadOnly));QCOMPARE(read.readAll(),before);read.close();
  QVERIFY(backup.exportBackup(file,true));
 }
 void test_remote_restore_acknowledgements(){
  FakeSettings air;SettingsBackup backup({{"air","Air",&air}});backup.setIdentityProvider([](QString id){return identity(id);});
  const QString file=m_dir.filePath("remote.ohdsettings");QVERIFY(backup.exportBackup(file));
  air.values["EXPOSURE"]=2;air.values["WB_FREQUENCY"]=5800;air.values["NAME"]=QString("changed");
  const auto inspection=backup.inspectBackup(file);QVERIFY(!inspection.contains("error"));QCOMPARE(inspection.value("sections").toList().size(),2);
  QVERIFY(backup.restoreBackup(file,{"air"}));QTRY_VERIFY(!backup.busy());QCOMPARE(backup.progress(),100);
  QCOMPARE(air.values["EXPOSURE"].toInt(),1);QCOMPARE(air.values["NAME"].toString(),QString("original"));QCOMPARE(air.values["WB_FREQUENCY"].toInt(),5700);QCOMPARE(air.writes.last(),QString("WB_FREQUENCY"));
 }
 void test_local_roundtrip_is_staged(){
  SettingsBackup backup;const QString file=m_dir.filePath("local.ohdsettings");QVERIFY(backup.exportBackup(file));
  {QSettings settings;settings.setValue("global_scale",2.0);settings.sync();}
  QVERIFY(backup.restoreBackup(file,{"qopenhd"}));QTRY_VERIFY(!backup.busy());QVERIFY(backup.restartRequired());
  {QSettings settings;QCOMPARE(settings.value("global_scale").toDouble(),2.0);}
  QCOMPARE(SettingsBackup::applyPendingLocalSettings(),QString());
  QSettings settings;QCOMPARE(settings.value("global_scale").toDouble(),1.2);QCOMPARE(settings.value("shape_color").value<QColor>(),QColor("#38a5ff"));QVERIFY(settings.value("show_map").toBool());QCOMPARE(settings.value("camera_name").toString(),QString::fromUtf8("Cam \xc3\xa4"));
 }
 void test_rejection_disconnect_and_guard(){
  FakeSettings ground;SettingsBackup backup({{"ground","Ground",&ground}});backup.setIdentityProvider([](QString id){return identity(id);});const QString file=m_dir.filePath("reject.ohdsettings");QVERIFY(backup.exportBackup(file));
  ground.values["EXPOSURE"]=2;ground.reject="EXPOSURE";
  QVERIFY(backup.restoreBackup(file,{"ground"}));QTRY_VERIFY(!backup.busy());QVERIFY(backup.message().contains("rejected"));QCOMPARE(ground.values["EXPOSURE"].toInt(),2);QVERIFY(!backup.restartRequired());
  ground.connected=false;QVERIFY(!backup.restoreBackup(file,{"ground"}));
  backup.setGuard([](bool){return QString("Simulation is active");});QVERIFY(!backup.exportBackup(m_dir.filePath("blocked.ohdsettings")));QVERIFY(!QFileInfo::exists(m_dir.filePath("blocked.ohdsettings")));QVERIFY(!backup.restoreBackup(file,{"qopenhd"}));
 }
 void test_hardware_mismatch_blocks_before_writes(){
  FakeSettings air;int platform=11;SettingsBackup backup({{"air","Air",&air}});
  backup.setIdentityProvider([&](QString id){return identity(id,platform);});
  const auto file=m_dir.filePath("pi.ohdsettings");QVERIFY(backup.exportBackup(file));
  platform=21;const auto review=backup.inspectBackup(file).value("sections").toList();
  QVERIFY(!review[1].toMap().value("ready").toBool());QVERIFY(review[1].toMap().value("reason").toString().contains("mismatch"));
  QVERIFY(!backup.restoreBackup(file,{"qopenhd","air"}));QVERIFY(air.writes.isEmpty());QVERIFY(!backup.restartRequired());
  platform=11;QVERIFY(backup.inspectBackup(file).value("sections").toList()[1].toMap().value("ready").toBool());
 }
 void test_camera_radio_and_local_identity_mismatch(){
  FakeSettings camera;int cameraType=10,radio=2;QString family="desktop";
  SettingsBackup backup({{"camera1","Camera 1",&camera},{"air","Air",&camera}});
  backup.setIdentityProvider([&](QString id){auto result=identity(id);if(id=="qopenhd")result["family"]=family;else if(id=="camera1")result["cameraType"]=cameraType;else result["radioTypes"]=QVariantList{radio};return result;});
  const auto file=m_dir.filePath("hardware.ohdsettings");QVERIFY(backup.exportBackup(file));
  cameraType=20;QVERIFY(!backup.restoreBackup(file,{"camera1"}));QVERIFY(camera.writes.isEmpty());
  cameraType=10;radio=3;QVERIFY(!backup.restoreBackup(file,{"air"}));QVERIFY(camera.writes.isEmpty());
  family="rockchip";QVERIFY(!backup.restoreBackup(file,{"qopenhd"}));
 }
 void test_legacy_and_invalid_files(){
  SettingsBackup backup;const auto legacy=m_dir.filePath("QOpenHD.conf");{QFile file(legacy);QVERIFY(file.open(QIODevice::WriteOnly));file.write("[General]\nshow_map=true\n");}
  QCOMPARE(backup.inspectBackup(legacy).value("sections").toList().size(),1);
  QVERIFY(!backup.inspectBackup(legacy).value("sections").toList()[0].toMap().value("ready").toBool());
  QVERIFY(!backup.restoreBackup(legacy,{"qopenhd"}));
  const auto invalid=m_dir.filePath("bad.json");{QFile file(invalid);QVERIFY(file.open(QIODevice::WriteOnly));file.write("{\"format\":\"QOpenHD-settings\",\"version\":99}");}
  QVERIFY(backup.inspectBackup(invalid).contains("error"));QVERIFY(!backup.restoreBackup(invalid,{"qopenhd"}));
  QVERIFY(!SettingsBackup::restorableParameter("AR_PAIR_CMD"));QVERIFY(!SettingsBackup::restorableParameter("JOY_MONITOR"));QVERIFY(SettingsBackup::restorableParameter("WB_FREQUENCY"));
 }
};
QTEST_GUILESS_MAIN(BackupTest)
#include "test_settings_backup.moc"
