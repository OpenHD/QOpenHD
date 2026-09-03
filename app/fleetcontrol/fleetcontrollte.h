#pragma once

#include <functional>

#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QObject>
#include <QTimer>
#include <QVariantList>

class QNetworkReply;

class FleetControlLte : public QObject {
  Q_OBJECT
  Q_PROPERTY(bool configured READ configured NOTIFY statusChanged)
  Q_PROPERTY(bool active READ active NOTIFY statusChanged)
  Q_PROPERTY(int uploadKbit READ uploadKbit NOTIFY statusChanged)
  Q_PROPERTY(int downloadKbit READ downloadKbit NOTIFY statusChanged)
  Q_PROPERTY(int configuredMaxKbit READ configuredMaxKbit NOTIFY statusChanged)
  Q_PROPERTY(QString statusText READ statusText NOTIFY statusChanged)
  Q_PROPERTY(bool authenticated READ authenticated NOTIFY statusChanged)
  Q_PROPERTY(bool busy READ busy NOTIFY statusChanged)
  Q_PROPERTY(QString endpoint READ endpoint NOTIFY statusChanged)
  Q_PROPERTY(QString accountName READ accountName NOTIFY statusChanged)
  Q_PROPERTY(QVariantList licenses READ licenses NOTIFY statusChanged)
  Q_PROPERTY(QVariantList crafts READ crafts NOTIFY statusChanged)
  Q_PROPERTY(QString verifiedLicenseId READ verifiedLicenseId NOTIFY statusChanged)
  Q_PROPERTY(bool licenseValid READ licenseValid NOTIFY statusChanged)
  Q_PROPERTY(QString licenseVerification READ licenseVerification NOTIFY statusChanged)
  Q_PROPERTY(bool certificateInstalled READ certificateInstalled NOTIFY statusChanged)
  Q_PROPERTY(QString certificateStatus READ certificateStatus NOTIFY statusChanged)
  Q_PROPERTY(QString certificateExpiresAt READ certificateExpiresAt NOTIFY statusChanged)

 public:
  explicit FleetControlLte(QObject* parent = nullptr);

  Q_INVOKABLE void login(const QString& username, const QString& password);
  Q_INVOKABLE void logout();
  Q_INVOKABLE void refreshAccount();
  Q_INVOKABLE void createCraft(const QString& name);
  Q_INVOKABLE void bindLicense(const QString& licenseId,
                               const QString& craftId);
  Q_INVOKABLE void verifyLicense(const QString& licenseId);
  Q_INVOKABLE void requestVideoCertificate(const QString& licenseId);
  Q_INVOKABLE void saveStreams(const QString& craftId, bool mavlink,
                               bool video1, bool video2);

  bool configured() const { return m_configured; }
  bool active() const { return m_active; }
  int uploadKbit() const { return m_upload_kbit; }
  int downloadKbit() const { return m_download_kbit; }
  int configuredMaxKbit() const { return m_configured_max_kbit; }
  QString statusText() const { return m_status_text; }
  bool authenticated() const { return m_authenticated; }
  bool busy() const { return m_busy; }
  QString endpoint() const { return m_endpoint; }
  QString accountName() const { return m_account_name; }
  QVariantList licenses() const { return m_licenses; }
  QVariantList crafts() const { return m_crafts; }
  QString verifiedLicenseId() const { return m_verified_license_id; }
  bool licenseValid() const { return m_license_valid; }
  QString licenseVerification() const { return m_license_verification; }
  bool certificateInstalled() const { return m_certificate_installed; }
  QString certificateStatus() const { return m_certificate_status; }
  QString certificateExpiresAt() const { return m_certificate_expires_at; }

 signals:
  void statusChanged();

 private:
  using ReplyHandler =
      std::function<void(const QJsonObject&, int, const QString&)>;

  void request(const QByteArray& method, const QString& path,
               const QJsonObject& body, ReplyHandler handler);
  void setBusy(bool value);
  void setStatusText(const QString& value);
  void clearSession();
  void refreshLocalStatus();
  static QString responseError(const QJsonObject& object,
                               const QString& fallback);
  bool installCertificate(const QByteArray& certificate, QString& path,
                          QString& error);

  bool m_configured = false;
  bool m_active = false;
  int m_upload_kbit = 0;
  int m_download_kbit = 0;
  int m_configured_max_kbit = 0;
  QString m_status_text = QStringLiteral("Sign in to FleetControl");
  bool m_authenticated = false;
  bool m_busy = false;
  QString m_endpoint = QStringLiteral("https://openhd.tech");
  QString m_account_name;
  QVariantList m_licenses;
  QVariantList m_crafts;
  QString m_verified_license_id;
  bool m_license_valid = false;
  QString m_license_verification;
  bool m_certificate_installed = false;
  QString m_certificate_status = QStringLiteral("No video certificate installed");
  QString m_certificate_expires_at;
  QTimer m_timer;
  QNetworkAccessManager m_network;
};
