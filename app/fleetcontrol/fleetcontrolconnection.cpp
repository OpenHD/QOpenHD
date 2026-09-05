#include "fleetcontrolconnection.h"

#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSslConfiguration>
#include <QSslError>
#include <QCryptographicHash>
#include <QSettings>
#include <QRegularExpression>

#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
#include <unistd.h>
#endif

FleetControlConnection::FleetControlConnection(QObject* parent) : QObject(parent) {
  connect(&m_timer, &QTimer::timeout, this, &FleetControlConnection::refresh);
  connect(&m_import_process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this, [this](int code, QProcess::ExitStatus status) {
    const QString output = QString::fromUtf8(m_import_process.readAllStandardOutput()).trimmed();
    const QString error = QString::fromUtf8(m_import_process.readAllStandardError()).trimmed();
    setStatusText(status == QProcess::NormalExit && code == 0 ? (output.isEmpty() ? QStringLiteral("FleetControl LTE profile installed") : output) : (error.isEmpty() ? QStringLiteral("Profile import failed") : error));
    refresh();
  });
  m_timer.start(5000); refresh();
  connect(&m_timer, &QTimer::timeout, this, [this]() {
    if (m_busy || m_device_polling || m_device_host.isEmpty() || m_retry) return;
    m_device_polling = true;
    setBusy(true);
    request(QUrl("https://" + m_device_host + ":8443/api/fleetcontrol/status"), "GET", {},
            [this](const QJsonObject& status, const QString& error) {
      m_device_polling = false;
      setBusy(false);
      if (!error.isEmpty()) m_device_host.clear();
      m_device_status = !error.isEmpty() ? QStringLiteral("Device status unavailable")
          : status.value("active").toBool() ? QStringLiteral("Device VPN connected")
          : status.value("configured").toBool() ? QStringLiteral("Profile installed; waiting for VPN handshake")
          : QStringLiteral("Device has no FleetControl profile");
      emit statusChanged();
    });
  });
}

void FleetControlConnection::setStatusText(const QString& value) {
  if (m_status_text == value) return;
  m_status_text = value; emit statusChanged();
}

void FleetControlConnection::importProfile(const QUrl& fileUrl) {
  if (m_busy || m_retry) return;
  if (m_import_process.state() != QProcess::NotRunning) { setStatusText(QStringLiteral("An LTE profile import is already running")); return; }
  const QString path = fileUrl.toLocalFile(); QFile profile(path);
  if (path.isEmpty() || !profile.open(QIODevice::ReadOnly) || profile.size() > 32768) { setStatusText(QStringLiteral("Select a valid openhd-lte.conf file")); return; }
  const QByteArray data = profile.readAll().replace("\r\n", "\n");
  if (!data.contains("# OpenHD-Profile-Version=1\n") || !data.contains("# OpenHD-Interface=openhd-lte\n") || !data.contains("PrivateKey = ")) { setStatusText(QStringLiteral("This file is not an OpenHD FleetControl device profile")); return; }
  m_profile = data;
  m_profile_craft.clear();
  m_profile_role.clear();
  setStatusText(QStringLiteral("Profile loaded. Enter the device address and password, then install."));
}

void FleetControlConnection::refresh() {
  QFile file(QStringLiteral("/run/openhd/lte-status.json"));
  if (!file.open(QIODevice::ReadOnly)) {
    m_active = false; m_upload_kbit = 0; m_download_kbit = 0; m_configured_max_kbit = 0;
    emit statusChanged();
    return;
  }
  const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
  if (!document.isObject()) { setStatusText(QStringLiteral("OpenHD LTE status is invalid")); return; }
  const QJsonObject value = document.object();
  m_active = value.value(QStringLiteral("active")).toBool();
  m_upload_kbit = value.value(QStringLiteral("uploadKbit")).toInt();
  m_download_kbit = value.value(QStringLiteral("downloadKbit")).toInt();
  m_configured_max_kbit = value.value(QStringLiteral("configuredMaxKbit")).toInt();

  emit statusChanged();
}

void FleetControlConnection::setBusy(bool value) {
  m_busy = value;
  emit statusChanged();
}

void FleetControlConnection::request(const QUrl& url, const QByteArray& method,
                              const QByteArray& data, Reply callback,
                              const QByteArray& authorization) {
  QNetworkRequest req(url);
  req.setTransferTimeout(method == "GET" ? 5000 : 120000);
  req.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::ManualRedirectPolicy);
  req.setHeader(QNetworkRequest::ContentTypeHeader, authorization.isEmpty() ? "application/json" : "text/plain");
  if (!authorization.isEmpty()) req.setRawHeader("Authorization", authorization);
  auto* reply = method == "GET" ? m_network.get(req) : m_network.post(req, data);
  // Device certificates are explicitly approved once, then pinned per address.
  // Public FleetControl certificates always use the normal CA validation.
  if (url.port() == 8443 && url.path().startsWith("/api/fleetcontrol/")) {
    connect(reply, &QNetworkReply::encrypted, this, [this, reply, url, method, data, callback, authorization]() {
      if (reply->property("trustPending").toBool()) return;
      const QString fingerprint = QString::fromLatin1(reply->sslConfiguration().peerCertificate().digest(QCryptographicHash::Sha256).toHex());
      if (QSettings().value(QStringLiteral("fleetcontrol/devicePins/") + url.host()).toString() == fingerprint) return;
      reply->setProperty("trustPending", true);
      m_trust_host = url.host(); m_trust_fingerprint = fingerprint;
      m_retry = [this, url, method, data, callback, authorization]() { setBusy(true); request(url, method, data, callback, authorization); };
      reply->abort(); setBusy(false);
      emit deviceTrustRequired(m_trust_host, fingerprint);
    });
    connect(reply, &QNetworkReply::sslErrors, this,
            [this, reply, url, method, data, callback, authorization](const QList<QSslError>& errors) {
      const auto certificate = reply->sslConfiguration().peerCertificate();
      const auto fingerprint = QString::fromLatin1(certificate.digest(QCryptographicHash::Sha256).toHex());
      if (certificate.isNull()) return;
      for (const auto& error : errors) {
        if (error.error() != QSslError::SelfSignedCertificate && error.error() != QSslError::HostNameMismatch) return;
      }
      QSettings settings;
      const QString key = QStringLiteral("fleetcontrol/devicePins/") + url.host();
      if (settings.value(key).toString() == fingerprint) {
        reply->ignoreSslErrors(errors);
        return;
      }
      reply->setProperty("trustPending", true);
      m_trust_host = url.host();
      m_trust_fingerprint = fingerprint;
      m_retry = [this, url, method, data, callback, authorization]() { setBusy(true); request(url, method, data, callback, authorization); };
      reply->abort();
      setBusy(false);
      emit deviceTrustRequired(m_trust_host, fingerprint);
    });
  }
  connect(reply, &QNetworkReply::finished, this, [reply, callback]() {
    if (reply->property("trustPending").toBool()) { reply->deleteLater(); return; }
    const auto document = QJsonDocument::fromJson(reply->readAll());
    const auto object = document.object();
    const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    QString error;
    if (reply->error() != QNetworkReply::NoError || status < 200 || status >= 300)
      error = object.value("message").toString(reply->errorString());
    else if (!document.isObject()) error = QStringLiteral("Invalid server response");
    callback(object, error);
    reply->deleteLater();
  });
}

void FleetControlConnection::trustDevice(bool trusted) {
  auto retry = std::move(m_retry);
  m_retry = {};
  if (trusted && retry) {
    QSettings().setValue(QStringLiteral("fleetcontrol/devicePins/") + m_trust_host, m_trust_fingerprint);
    retry();
  } else {
    m_device_polling = false; m_device_host.clear();
    setStatusText(QStringLiteral("Device connection cancelled"));
  }
}

void FleetControlConnection::login(const QString& server, const QString& username, const QString& password) {
  if (m_busy) return;
  const QUrl url(server.trimmed());
  if (url.scheme() != "https" || url.host().isEmpty() || !url.userInfo().isEmpty() || url.hasQuery() || url.hasFragment() || (url.path() != "" && url.path() != "/")) {
    setStatusText(QStringLiteral("Enter the FleetControl HTTPS address, for example https://openhd.tech")); return;
  }
  m_server = url.adjusted(QUrl::RemovePath).toString();
  m_authenticated = false;
  m_crafts.clear();
  setBusy(true); setStatusText(QStringLiteral("Signing in to FleetControl…"));
  request(QUrl(m_server + "/api/login"), "POST", QJsonDocument(QJsonObject{{"username", username}, {"password", password}}).toJson(),
          [this](const QJsonObject& object, const QString& error) {
    setBusy(false);
    if (!error.isEmpty() || !object.value("ok").toBool()) { setStatusText(error.isEmpty() ? QStringLiteral("Sign-in failed") : error); return; }
    m_authenticated = true;
    emit statusChanged();
    loadCrafts();
  });
}

void FleetControlConnection::loadCrafts() {
  if (!m_authenticated || m_busy) return;
  setBusy(true);
  request(QUrl(m_server + "/api/vehicles/bindable"), "GET", {}, [this](const QJsonObject& object, const QString& error) {
    setBusy(false);
    if (!error.isEmpty()) { setStatusText(error); return; }
    m_crafts.clear();
    for (const auto& craft : object.value("systems").toArray()) m_crafts.append(craft.toObject().toVariantMap());
    setStatusText(m_crafts.isEmpty() ? QStringLiteral("Create your first craft below") : QStringLiteral("Choose a craft and connect its Air unit. Ground is optional."));
    emit statusChanged();
  });
}

void FleetControlConnection::createCraft(const QString& name) {
  if (m_busy || !m_authenticated || name.trimmed().size() < 2) return;
  setBusy(true);
  request(QUrl(m_server + "/api/vehicles"), "POST", QJsonDocument(QJsonObject{{"name", name.trimmed()}}).toJson(),
          [this](const QJsonObject&, const QString& error) {
    setBusy(false);
    if (!error.isEmpty()) { setStatusText(error); return; }
    loadCrafts();
  });
}

void FleetControlConnection::connectCraft(const QString& craftId, const QString& role,
                                   const QString& host, const QString& password) {
  if (m_busy || !m_authenticated || craftId.isEmpty() || (role != "air" && role != "ground")) return;
  if (!QRegularExpression(QStringLiteral("^[A-Za-z0-9.-]{1,253}$")).match(host).hasMatch() || password.isEmpty()) {
    setStatusText(QStringLiteral("Enter the OpenHD device address and its password")); return;
  }
  setBusy(true); setStatusText(QStringLiteral("Checking OpenHD device…"));
  request(QUrl("https://" + host + ":8443/api/fleetcontrol/status"), "GET", {},
          [this, craftId, role, host, password](const QJsonObject& device, const QString& error) {
    if (!error.isEmpty() || device.value("role").toString() != role) {
      setBusy(false); setStatusText(error.isEmpty() ? QStringLiteral("Device role does not match. Choose Air or Ground to match the device.") : QStringLiteral("Device setup unavailable. Check the address and install an OpenHD build with FleetControl setup support. ") + error); return;
    }
    if (role == "air" && device.value("videoProfile").toString() != "480p15-h264-udp") {
      setBusy(false); setStatusText(QStringLiteral("Update OpenHD on Air first. This firmware does not support the 480p15 FleetControl video output.")); return;
    }
    if (!m_profile.isEmpty() && m_profile_craft == craftId && m_profile_role == role) { uploadProfile(host, password); return; }
    if (!m_profile.isEmpty()) {
      setBusy(false); setStatusText(QStringLiteral("A profile is still waiting to be installed. Finish installing it before creating another.")); return;
    }
    setStatusText(QStringLiteral("Creating a device profile for this craft…"));
    request(QUrl(m_server + "/api/vpn/vehicles/" + QString::fromUtf8(QUrl::toPercentEncoding(craftId))), "POST",
            QJsonDocument(QJsonObject{{"role", role}}).toJson(),
            [this, craftId, role, host, password](const QJsonObject& profile, const QString& error) {
      if (!error.isEmpty()) { setBusy(false); setStatusText(error); return; }
      m_profile = profile.value("config").toString().toUtf8();
      m_profile_craft = craftId; m_profile_role = role;
      uploadProfile(host, password);
    });
  });
}

void FleetControlConnection::uploadProfile(const QString& host, const QString& password) {
  if (m_profile.isEmpty()) { setBusy(false); setStatusText(QStringLiteral("No profile to install")); return; }
  setStatusText(QStringLiteral("Installing profile and restarting the OpenHD link…"));
  request(QUrl("https://" + host + ":8443/api/fleetcontrol/profile"), "POST", m_profile,
          [this, host](const QJsonObject& object, const QString& error) {
    setBusy(false);
    if (!error.isEmpty()) { setStatusText(error + QStringLiteral(" — profile retained; press Connect to retry.")); return; }
    m_profile.fill('\0'); m_profile.clear(); m_profile_craft.clear(); m_profile_role.clear();
    m_device_host = host;
    m_device_status = QStringLiteral("Checking device VPN…");
    setStatusText(object.value("message").toString(QStringLiteral("Device profile installed")));
  }, "Basic " + ("openhd:" + password.toUtf8()).toBase64());
}

void FleetControlConnection::installOnDevice(const QString& host, const QString& password) {
  if (m_busy || m_profile.isEmpty()) return;
  if (!QRegularExpression(QStringLiteral("^[A-Za-z0-9.-]{1,253}$")).match(host).hasMatch() || password.isEmpty()) {
    setStatusText(QStringLiteral("Enter the device address and password")); return;
  }
  setBusy(true);
  uploadProfile(host, password);
}
