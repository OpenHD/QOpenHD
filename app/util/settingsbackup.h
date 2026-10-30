#pragma once
#include <QObject>
#include <QPointer>
#include <QVariantMap>
#include <QVariantList>
#include <QTimer>
#include <functional>

class SettingsBackup : public QObject {
 Q_OBJECT
 Q_PROPERTY(bool busy READ busy NOTIFY changed)
 Q_PROPERTY(bool storageScanning READ storageScanning NOTIFY storageLocationsChanged)
 Q_PROPERTY(int progress READ progress NOTIFY changed)
 Q_PROPERTY(QString message READ message NOTIFY changed)
 Q_PROPERTY(bool restartRequired READ restartRequired NOTIFY changed)
public:
 struct Section { QString id; QString title; QObject* model; };
 explicit SettingsBackup(const QList<Section>& sections={}, QObject* parent=nullptr);
 void setIdentityProvider(std::function<QVariantMap(QString)> provider) { m_identity=std::move(provider); }
 Q_INVOKABLE QVariantMap exportDocument();
 Q_INVOKABLE QString cacheCloudBackup(const QVariantMap& document);
 void setGuard(std::function<QString(bool)> guard) { m_guard=std::move(guard); }
 bool busy() const { return m_busy; }
 bool storageScanning() const { return m_storageScanRunning; }
 int progress() const { return m_progress; }
 QString message() const { return m_message; }
 bool restartRequired() const { return m_restartRequired; }
 Q_INVOKABLE QVariantList sections() const;
 Q_INVOKABLE QVariantList locations() const;
 Q_INVOKABLE void refreshLocations();
 Q_INVOKABLE QVariantMap browse(const QString& directory) const;
 Q_INVOKABLE QString initialDirectory() const;
 Q_INVOKABLE QString parentDirectory(const QString& directory) const;
 Q_INVOKABLE QString joinPath(const QString& directory,const QString& filename) const;
 Q_INVOKABLE bool exists(const QString& path) const;
 Q_INVOKABLE bool exportBackup(const QString& path,bool overwrite=false);
 Q_INVOKABLE QVariantMap inspectBackup(const QString& path);
 Q_INVOKABLE bool restoreBackup(const QString& path,const QStringList& selected);
 static bool restorableParameter(const QString& id);
 static QString applyPendingLocalSettings();
 static bool stageLocalSettingsReset();
signals:
 void changed();
 void storageLocationsChanged();
private slots:
 void onParameterFinished(QString id,bool success);
private:
 struct Job { QPointer<QObject> model; QString section,sectionId,id; QVariant value; };
 QList<Section> m_sections;
 QVariantList m_locations;
 bool m_storageScanRunning=false;
 QList<Job> m_jobs;
 int m_jobIndex=0,m_total=0;
 bool m_busy=false,m_restartRequired=false;
 int m_progress=0;
 QString m_message,m_localIni;
 QVariantMap m_restoreDocument;
 QTimer m_timeout;
 std::function<QString(bool)> m_guard;
 std::function<QVariantMap(QString)> m_identity;
 QVariantMap hardware(const QString& id) const;
 QString compatibility(const QVariantMap& document,const QString& id) const;
 bool fail(const QString& error);
 QVariantMap snapshot(QObject* model) const;
 bool ready(QObject* model) const;
 void next();
 QVariantMap readBackup(const QString& path,QString& error) const;
 static QString pendingPath();
};
