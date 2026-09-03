#include "fleetcontrollte.h"

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSaveFile>
#include <QDateTime>
#include <QUrl>

namespace {
QVariantMap licenseMap(const QJsonObject& object) {
  const auto features = object.value(QStringLiteral("features")).toObject();
  QVariantMap result;
  const QString id = object.value(QStringLiteral("id")).toString();
  const QString plan = object.value(QStringLiteral("plan")).toString();
  const QString status = object.value(QStringLiteral("status")).toString();
  result.insert(QStringLiteral("id"), id);
  result.insert(QStringLiteral("plan"), plan);
  result.insert(QStringLiteral("status"), status);
  result.insert(QStringLiteral("expiresAt"), object.value(QStringLiteral("expiresAt")).toString());
  result.insert(QStringLiteral("daysRemaining"), object.value(QStringLiteral("daysRemaining")).toInt());
  result.insert(QStringLiteral("craftId"), object.value(QStringLiteral("craftId")).toString());
  result.insert(QStringLiteral("mavlinkAllowed"), features.value(QStringLiteral("mavlinkTelemetry")).toBool());
  result.insert(QStringLiteral("video1Allowed"), features.value(QStringLiteral("videoStreaming")).toBool());
  result.insert(QStringLiteral("video2Allowed"), features.value(QStringLiteral("videoStreaming")).toBool() &&
                    features.value(QStringLiteral("multiCamera")).toBool() &&
                    features.value(QStringLiteral("videoStreams")).toInt() >= 2);
  result.insert(QStringLiteral("label"), QStringLiteral("%1  ·  %2  ·  %3").arg(plan, status, id.left(18)));
  return result;
}

QVariantMap craftMap(const QJsonObject& object) {
  QVariantMap result;
  const QString id = object.value(QStringLiteral("id")).toString();
  const QString name = object.value(QStringLiteral("name")).toString();
  result.insert(QStringLiteral("id"), id);
  result.insert(QStringLiteral("name"), name);
  result.insert(QStringLiteral("callsign"), object.value(QStringLiteral("callsign")).toString());
  result.insert(QStringLiteral("licenseId"), object.value(QStringLiteral("licenseId")).toString());
  result.insert(QStringLiteral("mavlink"), object.value(QStringLiteral("mavlinkEnabled")).toBool(true));
  bool video1 = false;
  bool video2 = false;
  const auto streams = object.value(QStringLiteral("video")).toObject()
                           .value(QStringLiteral("streams")).toArray();
  for (const auto& value : streams) {
    const auto stream = value.toObject();
    if (stream.value(QStringLiteral("index")).toInt() == 0)
      video1 = stream.value(QStringLiteral("enabled")).toBool();
    if (stream.value(QStringLiteral("index")).toInt() == 1)
      video2 = stream.value(QStringLiteral("enabled")).toBool();
  }
  result.insert(QStringLiteral("video1"), video1);
  result.insert(QStringLiteral("video2"), video2);
  result.insert(QStringLiteral("label"), QStringLiteral("%1  ·  %2").arg(name, id.left(24)));
  return result;
}
}  // namespace

FleetControlLte::FleetControlLte(QObject* parent)
    : QObject(parent), m_network(this) {
  connect(&m_timer, &QTimer::timeout, this, &FleetControlLte::refreshLocalStatus);
  m_timer.start(5000);
  refreshLocalStatus();
}

void FleetControlLte::setBusy(bool value) {
  if (m_busy == value) return;
  m_busy = value;
  emit statusChanged();
}

void FleetControlLte::setStatusText(const QString& value) {
  if (m_status_text == value) return;
  m_status_text = value;
  emit statusChanged();
}

QString FleetControlLte::responseError(const QJsonObject& object,
                                       const QString& fallback) {
  const QString message = object.value(QStringLiteral("message")).toString();
  return message.isEmpty() ? fallback : message;
}

void FleetControlLte::request(const QByteArray& method, const QString& path,
                              const QJsonObject& body, ReplyHandler handler) {
  QNetworkRequest networkRequest(QUrl(m_endpoint + path));
  networkRequest.setHeader(QNetworkRequest::ContentTypeHeader,
                           QStringLiteral("application/json"));
  networkRequest.setRawHeader("Accept", "application/json");
  QNetworkReply* reply = nullptr;
  const QByteArray payload = body.isEmpty() ? QByteArray() : QJsonDocument(body).toJson(QJsonDocument::Compact);
  if (method == "GET") reply = m_network.get(networkRequest);
  else if (method == "POST") reply = m_network.post(networkRequest, payload);
  else reply = m_network.sendCustomRequest(networkRequest, method, payload);
  connect(reply, &QNetworkReply::finished, this, [reply, handler = std::move(handler)]() {
    const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    QJsonParseError parseError{};
    const QJsonDocument document = QJsonDocument::fromJson(reply->readAll(), &parseError);
    const QJsonObject object = document.isObject() ? document.object() : QJsonObject{};
    QString error;
    if (reply->error() != QNetworkReply::NoError)
      error = FleetControlLte::responseError(object, reply->errorString());
    else if (parseError.error != QJsonParseError::NoError && status != 204)
      error = QStringLiteral("FleetControl returned an invalid response");
    handler(object, status, error);
    reply->deleteLater();
  });
}

void FleetControlLte::login(const QString& username, const QString& password) {
  if (m_busy) return;
  if (username.trimmed().isEmpty() || password.isEmpty()) {
    setStatusText(QStringLiteral("Enter your operator ID or email and password"));
    return;
  }
  setBusy(true);
  setStatusText(QStringLiteral("Signing in…"));
  request("POST", QStringLiteral("/api/login"),
          {{QStringLiteral("username"), username.trimmed()},
           {QStringLiteral("password"), password}},
          [this](const QJsonObject& object, int, const QString& error) {
    if (!error.isEmpty() || !object.value(QStringLiteral("ok")).toBool()) {
      setBusy(false);
      setStatusText(error.isEmpty() ? QStringLiteral("Sign-in failed") : error);
      return;
    }
    const auto account = object.value(QStringLiteral("account")).toObject();
    m_account_name = account.value(QStringLiteral("displayName")).toString(
        account.value(QStringLiteral("username")).toString());
    m_authenticated = true;
    emit statusChanged();
    setBusy(false);
    refreshAccount();
  });
}

void FleetControlLte::clearSession() {
  m_authenticated = false;
  m_account_name.clear();
  m_licenses.clear();
  m_crafts.clear();
  m_verified_license_id.clear();
  m_license_valid = false;
  m_license_verification.clear();
  m_certificate_installed = false;
  m_certificate_status = QStringLiteral("No video certificate installed");
  m_certificate_expires_at.clear();
  emit statusChanged();
}

void FleetControlLte::logout() {
  if (m_busy) return;
  setBusy(true);
  request("POST", QStringLiteral("/api/logout"), {},
          [this](const QJsonObject&, int, const QString&) {
    clearSession();
    setBusy(false);
    setStatusText(QStringLiteral("Signed out"));
  });
}

void FleetControlLte::refreshAccount() {
  if (!m_authenticated || m_busy) return;
  setBusy(true);
  setStatusText(QStringLiteral("Loading licenses and craft…"));
  request("GET", QStringLiteral("/api/licenses"), {},
          [this](const QJsonObject& object, int status, const QString& error) {
    if (!error.isEmpty()) {
      if (status == 401) clearSession();
      setBusy(false); setStatusText(error); return;
    }
    QVariantList licenses;
    for (const auto& value : object.value(QStringLiteral("licenses")).toArray())
      licenses.append(licenseMap(value.toObject()));
    m_licenses = licenses;
    emit statusChanged();
    request("GET", QStringLiteral("/api/fleet"), {},
            [this](const QJsonObject& fleet, int status, const QString& fleetError) {
      if (!fleetError.isEmpty()) {
        if (status == 401) clearSession();
        setBusy(false); setStatusText(fleetError); return;
      }
      QVariantList crafts;
      for (const auto& value : fleet.value(QStringLiteral("systems")).toArray())
        crafts.append(craftMap(value.toObject()));
      m_crafts = crafts;
      setBusy(false);
      setStatusText(QStringLiteral("FleetControl account ready"));
      emit statusChanged();
      QVariantList eligible;
      for (const QVariant& value : m_licenses) {
        const QVariantMap license = value.toMap();
        if (!license.value(QStringLiteral("craftId")).toString().isEmpty() &&
            license.value(QStringLiteral("status")).toString() !=
                QStringLiteral("expired") &&
            license.value(QStringLiteral("video1Allowed")).toBool()) {
          eligible.append(value);
        }
      }
      if (eligible.size() == 1) {
        requestVideoCertificate(
            eligible.first().toMap().value(QStringLiteral("id")).toString());
      }
    });
  });
}

void FleetControlLte::createCraft(const QString& name) {
  if (!m_authenticated || m_busy || name.trimmed().size() < 2) {
    if (name.trimmed().size() < 2) setStatusText(QStringLiteral("Enter a craft name"));
    return;
  }
  setBusy(true); setStatusText(QStringLiteral("Creating craft identity…"));
  request("POST", QStringLiteral("/api/vehicles"),
          {{QStringLiteral("name"), name.trimmed()}},
          [this](const QJsonObject& object, int, const QString& error) {
    setBusy(false);
    if (!error.isEmpty() || !object.value(QStringLiteral("ok")).toBool()) {
      setStatusText(error.isEmpty() ? QStringLiteral("Could not create craft") : error); return;
    }
    setStatusText(QStringLiteral("Craft ID created"));
    refreshAccount();
  });
}

void FleetControlLte::bindLicense(const QString& licenseId,
                                  const QString& craftId) {
  if (!m_authenticated || m_busy || licenseId.isEmpty() || craftId.isEmpty()) return;
  setBusy(true); setStatusText(QStringLiteral("Binding license to craft…"));
  request("POST", QStringLiteral("/api/licenses/%1/bind").arg(QString::fromUtf8(QUrl::toPercentEncoding(licenseId))),
          {{QStringLiteral("craftId"), craftId}},
          [this](const QJsonObject& object, int, const QString& error) {
    setBusy(false);
    if (!error.isEmpty() || !object.value(QStringLiteral("ok")).toBool()) {
      setStatusText(error.isEmpty() ? QStringLiteral("License binding failed") : error); return;
    }
    setStatusText(QStringLiteral("License permanently bound"));
    refreshAccount();
  });
}

void FleetControlLte::verifyLicense(const QString& licenseId) {
  if (!m_authenticated || m_busy || licenseId.isEmpty()) return;
  setBusy(true); setStatusText(QStringLiteral("Verifying license signature…"));
  request("POST", QStringLiteral("/api/licenses/%1/check").arg(QString::fromUtf8(QUrl::toPercentEncoding(licenseId))), {},
          [this, licenseId](const QJsonObject& object, int, const QString& error) {
    m_verified_license_id = licenseId;
    const auto result = object.value(QStringLiteral("result")).toObject();
    m_license_valid = error.isEmpty() && object.value(QStringLiteral("ok")).toBool() &&
                      result.value(QStringLiteral("valid")).toBool();
    m_license_verification = m_license_valid
        ? QStringLiteral("Valid · signature verified · expires %1").arg(result.value(QStringLiteral("expiresAt")).toString())
        : (error.isEmpty() ? QStringLiteral("License is not valid") : error);
    setBusy(false); setStatusText(m_license_verification); emit statusChanged();
    if (m_license_valid) requestVideoCertificate(licenseId);
  });
}

bool FleetControlLte::installCertificate(const QByteArray& certificate,
                                         QString& installedPath,
                                         QString& error) {
#ifdef Q_OS_LINUX
  const QString path =
      QStringLiteral("/config/openhd/premium_certificate.ohdcert");
  {
    QSaveFile file(path);
    if (!file.open(QIODevice::WriteOnly)) {
      error = file.errorString();
      return false;
    }
    if (file.write(certificate) != certificate.size() || !file.commit()) {
      error = file.errorString();
      return false;
    }
    installedPath = path;
    return true;
  }
#else
  Q_UNUSED(certificate)
  Q_UNUSED(installedPath)
  error = QStringLiteral(
      "QOpenHD is not running on the OpenHD Ground unit");
#endif
  return false;
}

void FleetControlLte::requestVideoCertificate(const QString& licenseId) {
  if (!m_authenticated || m_busy || licenseId.isEmpty()) return;
  setBusy(true);
  setStatusText(QStringLiteral("Issuing 30-day craft certificate..."));
  request("POST", QStringLiteral("/api/licenses/%1/video-certificate")
                      .arg(QString::fromUtf8(QUrl::toPercentEncoding(licenseId))),
          {}, [this](const QJsonObject& object, int, const QString& error) {
    if (!error.isEmpty() || !object.value(QStringLiteral("ok")).toBool()) {
      m_certificate_installed = false;
      m_certificate_status = error.isEmpty()
          ? QStringLiteral("Certificate could not be issued") : error;
      setBusy(false); setStatusText(m_certificate_status); emit statusChanged();
      return;
    }
    const QByteArray certificate =
        object.value(QStringLiteral("certificate")).toString().toUtf8();
    QString path;
    QString installError;
    m_certificate_installed = installCertificate(certificate, path, installError);
    if (m_certificate_installed) {
      const qint64 serverTime = QDateTime::fromString(
          object.value(QStringLiteral("serverTime")).toString(),
          Qt::ISODate).toSecsSinceEpoch();
      if (serverTime >= 1704067200LL && serverTime <= 2114380800LL) {
        const QString anchorPath =
            QStringLiteral("/config/openhd/trusted_time_anchor");
        QFile existingAnchor(anchorPath);
        qint64 existingTime = 0;
        if (existingAnchor.open(QIODevice::ReadOnly))
          existingTime = existingAnchor.readAll().trimmed().toLongLong();
        if (serverTime > existingTime) {
          QSaveFile anchor(anchorPath);
          if (anchor.open(QIODevice::WriteOnly)) {
            anchor.write(QByteArray::number(serverTime));
            anchor.write("\n");
            (void)anchor.commit();
          }
        }
      }
    }
    m_certificate_expires_at =
        object.value(QStringLiteral("notAfter")).toString();
    m_certificate_status = m_certificate_installed
        ? QStringLiteral("Certificate installed: %1").arg(path)
        : QStringLiteral("Certificate issued but local install failed: %1")
              .arg(installError);
    setBusy(false); setStatusText(m_certificate_status); emit statusChanged();
  });
}

void FleetControlLte::saveStreams(const QString& craftId, bool mavlink,
                                  bool video1, bool video2) {
  if (!m_authenticated || m_busy || craftId.isEmpty()) return;
  setBusy(true); setStatusText(QStringLiteral("Updating Air uplink streams…"));
  request("PATCH", QStringLiteral("/api/vehicles/%1/streams").arg(QString::fromUtf8(QUrl::toPercentEncoding(craftId))),
          {{QStringLiteral("mavlink"), mavlink},
           {QStringLiteral("video1"), video1},
           {QStringLiteral("video2"), video2}},
          [this](const QJsonObject& object, int, const QString& error) {
    setBusy(false);
    if (!error.isEmpty() || !object.value(QStringLiteral("ok")).toBool()) {
      setStatusText(error.isEmpty() ? QStringLiteral("Stream update failed") : error); return;
    }
    setStatusText(QStringLiteral("Streaming selection saved"));
    refreshAccount();
  });
}

void FleetControlLte::refreshLocalStatus() {
  QFile file(QStringLiteral("/run/openhd/lte-status.json"));
  if (!file.open(QIODevice::ReadOnly)) return;
  const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
  if (!document.isObject()) return;
  const QJsonObject value = document.object();
  m_configured = value.value(QStringLiteral("configured")).toBool(true);
  m_active = value.value(QStringLiteral("active")).toBool();
  m_upload_kbit = value.value(QStringLiteral("uploadKbit")).toInt();
  m_download_kbit = value.value(QStringLiteral("downloadKbit")).toInt();
  m_configured_max_kbit = value.value(QStringLiteral("configuredMaxKbit")).toInt();
  emit statusChanged();
}
