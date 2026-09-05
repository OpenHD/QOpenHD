#pragma once

#include <QObject>
#include <QProcess>
#include <QTimer>
#include <QUrl>
#include <QNetworkAccessManager>
#include <QJsonObject>
#include <QVariantList>
#include <functional>

class FleetControlConnection : public QObject {
  Q_OBJECT
  Q_PROPERTY(bool active READ active NOTIFY statusChanged)
  Q_PROPERTY(int uploadKbit READ uploadKbit NOTIFY statusChanged)
  Q_PROPERTY(int downloadKbit READ downloadKbit NOTIFY statusChanged)
  Q_PROPERTY(int configuredMaxKbit READ configuredMaxKbit NOTIFY statusChanged)
  Q_PROPERTY(QString statusText READ statusText NOTIFY statusChanged)
  Q_PROPERTY(bool busy READ busy NOTIFY statusChanged)
  Q_PROPERTY(bool authenticated READ authenticated NOTIFY statusChanged)
  Q_PROPERTY(QVariantList crafts READ crafts NOTIFY statusChanged)
  Q_PROPERTY(QString deviceStatus READ deviceStatus NOTIFY statusChanged)

 public:
  explicit FleetControlConnection(QObject* parent = nullptr);
  Q_INVOKABLE void importProfile(const QUrl& fileUrl);
  Q_INVOKABLE void refresh();
  Q_INVOKABLE void login(const QString& server, const QString& username, const QString& password);
  Q_INVOKABLE void createCraft(const QString& name);
  Q_INVOKABLE void loadCrafts();
  Q_INVOKABLE void connectCraft(const QString& craftId, const QString& role, const QString& host, const QString& password);
  Q_INVOKABLE void installOnDevice(const QString& host, const QString& password);
  Q_INVOKABLE void trustDevice(bool trusted);
  bool busy() const { return m_busy; }
  bool authenticated() const { return m_authenticated; }
  QVariantList crafts() const { return m_crafts; }
  QString deviceStatus() const { return m_device_status; }
  bool active() const { return m_active; }
  int uploadKbit() const { return m_upload_kbit; }
  int downloadKbit() const { return m_download_kbit; }
  int configuredMaxKbit() const { return m_configured_max_kbit; }
  QString statusText() const { return m_status_text; }

 signals:
  void statusChanged();
  void deviceTrustRequired(const QString& host, const QString& fingerprint);

 private:
  void setStatusText(const QString& value);
  bool m_active = false;
  int m_upload_kbit = 0;
  int m_download_kbit = 0;
  int m_configured_max_kbit = 0;
  QString m_status_text = QStringLiteral("No local OpenHD LTE status available");
  QTimer m_timer;
  QProcess m_import_process;
  using Reply = std::function<void(const QJsonObject&, const QString&)>;
  void request(const QUrl& url, const QByteArray& method, const QByteArray& data, Reply callback, const QByteArray& authorization = {});
  void setBusy(bool value);
  void uploadProfile(const QString& host, const QString& password);
  bool m_busy = false;
  bool m_authenticated = false;
  QVariantList m_crafts;
  QString m_server;
  QByteArray m_profile;
  QString m_profile_craft;
  QString m_profile_role;
  QString m_trust_host;
  QString m_trust_fingerprint;
  std::function<void()> m_retry;
  QNetworkAccessManager m_network;
  QString m_device_host;
  QString m_device_status;
  bool m_device_polling = false;
};
