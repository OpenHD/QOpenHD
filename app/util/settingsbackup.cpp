#include "settingsbackup.h"
#include <QCoreApplication>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>
#include <QSettings>
#include <QStandardPaths>
#include <QStorageInfo>
#include <QTemporaryDir>
#include <QThread>
#include <QSysInfo>
#include <memory>
#include <algorithm>
#include <cmath>
#include <limits>

namespace {
constexpr qint64 MaxBackupBytes=16*1024*1024;
QVariantMap iniValues(const QString& text,QString& error) {
 QTemporaryDir temp;
 if(!temp.isValid()){error=QObject::tr("Cannot create a temporary settings file.");return {};}
 QFile file(temp.filePath("settings.ini"));
 if(!file.open(QIODevice::WriteOnly)||file.write(text.toUtf8())<0){error=file.errorString();return {};}
 file.close();QSettings settings(file.fileName(),QSettings::IniFormat);QVariantMap values;
 for(const auto& key:settings.allKeys())values.insert(key,settings.value(key));
 if(settings.status()!=QSettings::NoError||values.isEmpty())error=QObject::tr("The file contains no valid QOpenHD settings.");
 return values;
}
QString encodeLocal(QString& error) {
 QSettings source;source.sync();QTemporaryDir temp;
 if(source.status()!=QSettings::NoError||!temp.isValid()){error=QObject::tr("Cannot read local settings.");return {};}
 QSettings copy(temp.filePath("settings.ini"),QSettings::IniFormat);
 for(const auto& key:source.allKeys())copy.setValue(key,source.value(key));
 copy.sync();QFile file(copy.fileName());
 if(copy.status()!=QSettings::NoError||!file.open(QIODevice::ReadOnly)){error=QObject::tr("Cannot encode local settings.");return {};}
 return QString::fromUtf8(file.readAll());
}
bool writeAtomic(const QString& path,const QByteArray& bytes,QString& error) {
 QSaveFile file(path);
 if(!file.open(QIODevice::WriteOnly)||file.write(bytes)!=bytes.size()||!file.commit()){
  error=QObject::tr("Cannot save %1: %2").arg(path,file.errorString());return false;
 }
 return true;
}
int restoreOrder(const QString& id) {
 if(id=="CONFIG_BOOT_AIR"||id=="SYS_RUN_MODE"||id=="CAMERA_TYPE")return 3;
 if(id.startsWith("WB_")||id.startsWith("WIFI_")||id.startsWith("AR_")||id.startsWith("OHD_UART_")||id=="TX_PWR_LVL"||id=="MULTI_LINK_EN")return 2;
 return 0;
}
}
SettingsBackup::SettingsBackup(const QList<Section>& sections,QObject* parent):QObject(parent),m_sections(sections) {
 m_locations.append(QVariantMap{{"label",tr("Home")},{"path",QDir::homePath()},{"writable",QFileInfo(QDir::homePath()).isWritable()}});
 for(const QString& path:{QStringLiteral("/Video"),QStringLiteral("/video"),QStringLiteral("/mnt/video"),QStringLiteral("/media/Video")})
  if(QFileInfo(path).isDir()&&QFileInfo(path).isWritable()&&!QStorageInfo(path).isReadOnly())m_locations.prepend(QVariantMap{{"label",tr("Video storage")},{"path",QDir(path).absolutePath()},{"writable",QFileInfo(path).isWritable()}});
 m_timeout.setSingleShot(true);m_timeout.setInterval(45000);
 connect(&m_timeout,&QTimer::timeout,this,[this]{fail(tr("Restore stopped: no acknowledgement. Some settings may already have changed."));});
 for(const auto& section:sections)
  connect(section.model,SIGNAL(backupParameterFinished(QString,bool)),this,SLOT(onParameterFinished(QString,bool)),Qt::QueuedConnection);
}
bool SettingsBackup::restorableParameter(const QString& id) {
 return !QStringList{"JOY_MONITOR","AR_RESET_CMD","AR_PAIR_CMD","AR_PAIR","SYS_REBOOT","SYS_SHUTDOWN"}.contains(id)
     && !id.endsWith("_CMD") && !id.startsWith("CMD_");
}
QVariantMap SettingsBackup::snapshot(QObject* model) const {
 QVariantMap values;if(model)QMetaObject::invokeMethod(model,"backup_parameters",Qt::DirectConnection,Q_RETURN_ARG(QVariantMap,values));return values;
}
bool SettingsBackup::ready(QObject* model) const {
 bool alive=false;
 if(model)QMetaObject::invokeMethod(model,"system_is_alive",Qt::DirectConnection,Q_RETURN_ARG(bool,alive));
 return alive&&model->property("has_params_fetched").toBool()&&!model->property("ui_is_busy").toBool();
}
QVariantList SettingsBackup::sections() const {
 QVariantList result{QVariantMap{{"id","qopenhd"},{"title",tr("QOpenHD / OSD")},{"ready",true}}};
 for(const auto& section:m_sections)result.append(QVariantMap{{"id",section.id},{"title",section.title},{"ready",ready(section.model)}});
 return result;
}
static QVariantList enumerateStorageLocations() {
 QVariantList result;QStringList added;
 auto add=[&](const QString& label,const QString& path){
  const QString clean=QDir(path).absolutePath();if(!QFileInfo(clean).isDir()||added.contains(clean))return;
  const QStorageInfo storage(clean);if(storage.isReadOnly()||!QFileInfo(clean).isWritable())return;added.append(clean);
  result.append(QVariantMap{{"label",label},{"path",clean},{"writable",QFileInfo(clean).isWritable()&&!storage.isReadOnly()}});
 };
 for(const QString& path:{QStringLiteral("/Video"),QStringLiteral("/video"),QStringLiteral("/mnt/video"),QStringLiteral("/media/Video")})
  if(QFileInfo(path).isDir())add(QObject::tr("Video storage"),path);
 for(const auto& storage:QStorageInfo::mountedVolumes()){
  if(!storage.isValid()||!storage.isReady())continue;
  const QString label=storage.name().isEmpty()?storage.displayName():storage.name();
  add(label.isEmpty()?storage.rootPath():label,storage.rootPath());
 }
 add(QObject::tr("Home"),QDir::homePath());
 add(QObject::tr("Documents"),QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation));
 return result;
}
// QThread::create is absent from some Qt Android builds (QT_CONFIG(cxx11_future)).
// Keep storage discovery asynchronous without relying on that optional API.
class StorageLocationsThread final : public QThread {
public:
 QVariantList result;
protected:
 void run() override { result=enumerateStorageLocations(); }
};
QVariantList SettingsBackup::locations() const {return m_locations;}
void SettingsBackup::refreshLocations() {
 if(m_storageScanRunning)return;
 m_storageScanRunning=true;emit storageLocationsChanged();
 auto worker=new StorageLocationsThread;
 connect(worker,&QThread::finished,this,[this,worker]{m_locations=worker->result;m_storageScanRunning=false;emit storageLocationsChanged();});
 connect(worker,&QThread::finished,worker,&QObject::deleteLater);
 worker->start();
}

QString SettingsBackup::initialDirectory() const {
 for(const auto& item:locations()){
  const auto volume=item.toMap();
  if(volume.value("writable").toBool()&&(volume.value("label").toString().contains("video",Qt::CaseInsensitive)||volume.value("path").toString().contains("/video",Qt::CaseInsensitive)))return volume.value("path").toString();
 }
 const QString docs=QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
 return QFileInfo(docs).isDir()?docs:QDir::homePath();
}
QVariantMap SettingsBackup::browse(const QString& directory) const {
 QDir dir(directory);
 if(directory.isEmpty()||!dir.exists())return {{"error",tr("Folder not found.")}};
 QVariantList entries;
 for(const auto& item:dir.entryInfoList(QDir::AllDirs|QDir::Files|QDir::NoDotAndDotDot|QDir::Readable,QDir::DirsFirst|QDir::Name|QDir::IgnoreCase))
  entries.append(QVariantMap{{"name",item.fileName()},{"path",item.absoluteFilePath()},{"directory",item.isDir()}});
 const QStorageInfo storage(dir.absolutePath());
 return {{"path",dir.absolutePath()},{"entries",entries},{"writable",QFileInfo(dir.absolutePath()).isWritable()&&!storage.isReadOnly()}};
}
QString SettingsBackup::parentDirectory(const QString& path) const {QDir dir(path);dir.cdUp();return dir.absolutePath();}
QString SettingsBackup::joinPath(const QString& directory,const QString& filename) const {
 // A name field cannot escape the explicitly chosen folder.
 if(filename.isEmpty()||filename=="."||filename==".."||filename.contains('/')||filename.contains('\\')||filename.contains(':'))return {};
 return QDir(directory).absoluteFilePath(filename);
}
bool SettingsBackup::exists(const QString& path) const {return QFileInfo::exists(path);}
bool SettingsBackup::fail(const QString& error) {m_timeout.stop();m_busy=false;m_message=error;emit changed();return false;}
QVariantMap SettingsBackup::hardware(const QString& id) const {
 if(m_identity)return m_identity(id);
 if(id=="qopenhd")return {{"os",QSysInfo::kernelType()},{"architecture",QSysInfo::currentCpuArchitecture()},{"family","desktop"}};
 return {};
}
QString SettingsBackup::compatibility(const QVariantMap& document,const QString& id) const {
 const auto saved=document.value("hardware").toMap().value(id).toMap();const auto current=hardware(id);
 if(saved.isEmpty()||current.isEmpty())return tr("Hardware identity unavailable; restore blocked.");
 if(id=="qopenhd"){
  for(const QString& key:{QStringLiteral("os"),QStringLiteral("architecture"),QStringLiteral("family")})
   if(saved.value(key).toString().isEmpty()||saved.value(key)!=current.value(key))return tr("Different QOpenHD platform or architecture.");
  if(saved.value("board")!=current.value("board"))return tr("Local board hardware does not match.");
 } else {
  if(saved.value("platformId").toInt()<=0||current.value("platformId").toInt()<=0)return tr("Board type is not identified.");
  if(saved.value("platformId").toInt()!=current.value("platformId").toInt())return tr("Board mismatch: backup %1; connected %2.").arg(saved.value("name").toString(),current.value("name").toString());
  if(id.startsWith("camera")&&((!saved.contains("cameraType")||saved.value("cameraType").toInt()<0)||saved.value("cameraType")!=current.value("cameraType")))return tr("Camera hardware does not match.");
  if(saved.contains("radioTypes")&&saved.value("radioTypes")!=current.value("radioTypes"))return tr("Wi-Fi module hardware does not match.");
  const auto parameters=document.value("devices").toMap().value(id).toMap();
  if((parameters.contains("WB_FREQUENCY")||parameters.contains("WB_MCS_INDEX"))&&(!saved.contains("radioTypes")||!current.contains("radioTypes")))return tr("Wi-Fi hardware is not identified; restore blocked.");
 }
 return {};
}
QVariantMap SettingsBackup::exportDocument() {
 if(m_busy)return {};
 if(m_guard){const auto error=m_guard(false);if(!error.isEmpty()){fail(error);return {};}}
 QString error;const QString local=encodeLocal(error);if(!error.isEmpty()){fail(error);return {};}
 QVariantMap devices,identities;identities.insert("qopenhd",hardware("qopenhd"));
 for(const auto& section:m_sections)if(ready(section.model)){devices.insert(section.id,snapshot(section.model));identities.insert(section.id,hardware(section.id));}
 return {{"format","QOpenHD-settings"},{"version",2},{"createdUtc",QDateTime::currentDateTimeUtc().toString(Qt::ISODate)},{"qopenhdVersion",QCoreApplication::applicationVersion()},{"localIni",local},{"devices",devices},{"hardware",identities}};
}
bool SettingsBackup::exportBackup(const QString& path,bool overwrite) {
 if(m_busy)return false;
 if(path.isEmpty()||QFileInfo(path).isDir())return fail(tr("Choose a settings filename."));
 if(QFileInfo::exists(path)&&!overwrite)return fail(tr("The file already exists. Confirm overwrite or choose another name."));
 const auto document=exportDocument();if(document.isEmpty())return false;
 QString error;if(!writeAtomic(path,QJsonDocument::fromVariant(document).toJson(),error))return fail(error);
 QStringList included{tr("QOpenHD / OSD")};const auto devices=document.value("devices").toMap();for(const auto& section:m_sections)if(devices.contains(section.id))included.append(section.title);
 m_message=tr("Saved %1. Included: %2.").arg(path,included.join(", "));emit changed();return true;
}
QString SettingsBackup::cacheCloudBackup(const QVariantMap& document) {
 if(m_guard){const auto error=m_guard(false);if(!error.isEmpty()){fail(error);return {};}}
 const auto folder=QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
 if(!QDir().mkpath(folder)){fail(tr("Cannot create the backup cache."));return {};}
 const auto path=QDir(folder).filePath("fleetcontrol-settings.ohdsettings");QString error;
 if(!writeAtomic(path,QJsonDocument::fromVariant(document).toJson(),error)){fail(error);return {};}
 readBackup(path,error);if(!error.isEmpty()){QFile::remove(path);fail(error);return {};}
 return path;
}
QVariantMap SettingsBackup::readBackup(const QString& path,QString& error) const {
 QFile file(path);if(!file.open(QIODevice::ReadOnly)){error=file.errorString();return {};}
 if(file.size()<=0||file.size()>MaxBackupBytes){error=tr("Invalid settings file size.");return {};}
 const QByteArray bytes=file.readAll();QVariantMap result;
 if(bytes.trimmed().startsWith('{')){
  QJsonParseError parse;const auto json=QJsonDocument::fromJson(bytes,&parse);
  if(parse.error!=QJsonParseError::NoError||!json.isObject()){error=tr("Invalid settings JSON.");return {};}
  result=json.object().toVariantMap();
  if(result.value("format").toString()!="QOpenHD-settings"||(result.value("version").toInt()!=1&&result.value("version").toInt()!=2)){error=tr("Unsupported settings backup format.");return {};}
  if(!result.value("localIni").canConvert<QString>()||!result.value("devices").canConvert<QVariantMap>()){error=tr("Incomplete settings backup.");return {};}
 }else{
  // Import the previous QOpenHD.conf backup as a local-only backup.
  result={{"localIni",QString::fromUtf8(bytes)},{"devices",QVariantMap{}}};
 }
 iniValues(result.value("localIni").toString(),error);if(!error.isEmpty())return {};
 const auto devices=result.value("devices").toMap();
 for(auto section=devices.cbegin();section!=devices.cend();++section){
  if(!QStringList{"air","ground","camera1","camera2"}.contains(section.key())||!section.value().canConvert<QVariantMap>()){error=tr("Invalid device section.");return {};}
  const auto values=section.value().toMap();
  for(auto value=values.cbegin();value!=values.cend();++value){
   if(value.key().isEmpty()||value.key().size()>16||value.key().contains('/')||value.key().contains('\\')){error=tr("Invalid parameter name.");return {};}
   if(value.value().userType()==QMetaType::QString){if(value.value().toString().toUtf8().size()>128){error=tr("Parameter string is too long.");return {};}}
   else {bool numeric=false;double number=value.value().toDouble(&numeric);if(!numeric||!std::isfinite(number)||std::floor(number)!=number||number<std::numeric_limits<qint32>::min()||number>std::numeric_limits<qint32>::max()){error=tr("Invalid parameter value.");return {};}}
  }
 }
 return result;
}
QVariantMap SettingsBackup::inspectBackup(const QString& path) {
 QString error;const auto document=readBackup(path,error);if(!error.isEmpty()){fail(error);return {{"error",error}};}
 const auto devices=document.value("devices").toMap();QVariantList choices;
 const auto localIssue=compatibility(document,"qopenhd");
 choices.append(QVariantMap{{"id","qopenhd"},{"title",tr("QOpenHD / OSD")},{"ready",localIssue.isEmpty()},{"selected",localIssue.isEmpty()},{"reason",localIssue}});
 for(const auto& section:m_sections)if(devices.contains(section.id)){
  const auto issue=compatibility(document,section.id);const bool available=ready(section.model)&&issue.isEmpty();
  choices.append(QVariantMap{{"id",section.id},{"title",section.title},{"ready",available},{"selected",available},{"count",devices.value(section.id).toMap().size()},{"reason",issue}});
 }
 return {{"sections",choices},{"created",document.value("createdUtc")}};
}
bool SettingsBackup::restoreBackup(const QString& path,const QStringList& selected) {
 if(m_busy)return false;
 if(m_guard){const auto error=m_guard(true);if(!error.isEmpty())return fail(error);}
 if(selected.isEmpty())return fail(tr("Choose at least one settings section."));
 QString error;const auto document=readBackup(path,error);if(!error.isEmpty())return fail(error);
 for(const auto& id:selected){const auto issue=compatibility(document,id);if(!issue.isEmpty())return fail(id+": "+issue);}
 const auto devices=document.value("devices").toMap();m_restoreDocument=document;m_jobs.clear();m_jobIndex=0;
 m_localIni=selected.contains("qopenhd")?document.value("localIni").toString():QString();
 for(const auto& id:selected){
  if(id=="qopenhd")continue;
  auto section=std::find_if(m_sections.cbegin(),m_sections.cend(),[&](const Section& s){return s.id==id;});
  if(section==m_sections.cend()||!devices.contains(id)||!ready(section->model))return fail(tr("%1 is not connected with a complete parameter set.").arg(id));
  const auto current=snapshot(section->model);const auto values=devices.value(id).toMap();
  for(auto value=values.cbegin();value!=values.cend();++value){
   if(!restorableParameter(value.key())||!current.contains(value.key()))continue;
   QVariant nextValue=value.value();const QVariant now=current.value(value.key());
   if(now.userType()==QMetaType::QString){if(nextValue.userType()!=QMetaType::QString)return fail(tr("Parameter type mismatch: %1.").arg(value.key()));}
   else {if(nextValue.userType()==QMetaType::QString)return fail(tr("Parameter type mismatch: %1.").arg(value.key()));nextValue=nextValue.toInt();}
   if(now!=nextValue)m_jobs.append({section->model,section->title,id,value.key(),nextValue});
  }
 }
 std::stable_sort(m_jobs.begin(),m_jobs.end(),[](const Job& a,const Job& b){return restoreOrder(a.id)<restoreOrder(b.id);});
 m_total=m_jobs.size();m_progress=0;m_busy=true;m_message=tr("Restoring settings...");emit changed();QTimer::singleShot(0,this,[this]{next();});return true;
}
void SettingsBackup::next() {
 if(!m_busy)return;
 if(m_guard){const auto error=m_guard(true);if(!error.isEmpty()){fail(error);return;}}
 if(m_jobIndex>=m_jobs.size()){
  if(!m_localIni.isEmpty()){
   QString error;const QString pending=pendingPath();
   if(!QDir().mkpath(QFileInfo(pending).absolutePath())||!writeAtomic(pending,m_localIni.toUtf8(),error)){fail(error.isEmpty()?tr("Cannot stage local settings."):error);return;}
   m_restartRequired=true;
  }
  m_busy=false;m_progress=100;m_message=m_restartRequired?tr("Settings restored. Restart QOpenHD to load the imported application and OSD settings."):tr("Settings restored.");emit changed();return;
 }
 const auto job=m_jobs.at(m_jobIndex);
 const auto hardwareIssue=compatibility(m_restoreDocument,job.sectionId);if(!hardwareIssue.isEmpty()){fail(tr("Restore stopped: %1").arg(hardwareIssue));return;}
 if(!job.model||!ready(job.model)){fail(tr("Restore stopped at %1 / %2: connection unavailable. Earlier changes remain applied.").arg(job.section,job.id));return;}
 m_message=tr("Restoring %1 / %2 (%3 of %4)").arg(job.section,job.id).arg(m_jobIndex+1).arg(m_total);emit changed();
 QString error;m_timeout.start();
 if(!QMetaObject::invokeMethod(job.model,"request_backup_restore",Qt::DirectConnection,Q_RETURN_ARG(QString,error),Q_ARG(QString,job.id),Q_ARG(QVariant,job.value)))error=tr("This settings source does not support restore.");
 if(!error.isEmpty())fail(tr("Restore stopped at %1 / %2: %3. Earlier changes remain applied.").arg(job.section,job.id,error));
}
void SettingsBackup::onParameterFinished(QString id,bool success) {
 if(!m_busy||m_jobIndex>=m_jobs.size())return;
 const auto& job=m_jobs.at(m_jobIndex);if(sender()!=job.model||id!=job.id)return;
 m_timeout.stop();if(!success){fail(tr("Restore stopped: %1 rejected %2. Earlier changes remain applied.").arg(job.section,id));return;}
 ++m_jobIndex;m_progress=m_total?m_jobIndex*100/m_total:100;emit changed();QTimer::singleShot(0,this,[this]{next();});
}
QString SettingsBackup::pendingPath(){return QDir(QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation)).filePath("pending-settings-restore.ini");}
bool SettingsBackup::stageLocalSettingsReset() {
 const QString path=pendingPath()+".reset";
 QString error;
 return QDir().mkpath(QFileInfo(path).absolutePath()) && writeAtomic(path,QByteArray("reset\n"),error);
}
QString SettingsBackup::applyPendingLocalSettings() {
 const QString reset=pendingPath()+".reset";
 if(QFile::exists(reset)) {
  QSettings settings;
  if(!settings.isWritable())return QObject::tr("Local settings are not writable.");
  settings.clear();settings.sync();
  if(settings.status()!=QSettings::NoError)return QObject::tr("Cannot reset local settings.");
  if(QFile::exists(pendingPath())&&!QFile::remove(pendingPath()))return QObject::tr("Cannot discard pending settings restore.");
  if(!QFile::remove(reset))return QObject::tr("Cannot finish local settings reset.");
  return {};
 }

 const QString path=pendingPath();QFile file(path);if(!file.exists())return {};
 if(!file.open(QIODevice::ReadOnly)||file.size()>MaxBackupBytes)return QObject::tr("Cannot open pending settings restore.");
 QString error;const auto values=iniValues(QString::fromUtf8(file.readAll()),error);file.close();if(!error.isEmpty())return error;
 QSettings settings;if(!settings.isWritable())return QObject::tr("Local settings are not writable.");
 settings.clear();for(auto value=values.cbegin();value!=values.cend();++value)settings.setValue(value.key(),value.value());settings.sync();
 if(settings.status()!=QSettings::NoError)return QObject::tr("Cannot apply pending settings restore.");
 if(!QFile::remove(path))return QObject::tr("Cannot remove applied pending settings file.");
 return {};
}
