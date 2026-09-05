#include "../app/fleetcontrol/fleetcontrolconnection.h"
#include "../app/fleetcontrol/fleetcontrollte.h"
#include <QGuiApplication>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QTemporaryFile>
#include <QDebug>
#include <QQuickItem>
#include <QQuickWindow>
#include <QElapsedTimer>
#include <QDir>
#include <QFontDatabase>

int main(int argc, char** argv) {
  QGuiApplication app(argc, argv);
#ifdef Q_OS_WIN
  const int fontId = QFontDatabase::addApplicationFont("C:/Windows/Fonts/segoeui.ttf");
  if (fontId >= 0) app.setFont(QFont(QFontDatabase::applicationFontFamilies(fontId).first(), 10));
#endif
  FleetControlConnection fleet;
  FleetControlLte account;
  fleet.setAccount(&account);
  if (account.endpoint() != "https://openhd.tech") return 1;
  fleet.connectCraft("craft", "air", "bad/address", "password");
  if (fleet.busy()) return 2;
  QTemporaryFile profile;
  if (!profile.open()) return 3;
  profile.write("# OpenHD-Profile-Version=1\r\n# OpenHD-Interface=openhd-lte\r\nPrivateKey = example\r\n");
  profile.flush();
  fleet.importProfile(QUrl::fromLocalFile(profile.fileName()));
  if (!fleet.statusText().contains("Profile loaded")) return 4;
  fleet.refresh();
  if (!fleet.statusText().contains("Profile loaded")) return 5;
  QQmlEngine engine;
  engine.rootContext()->setContextProperty("_fleetControlConnection", &fleet);
  engine.rootContext()->setContextProperty("_fleetControlLte", &account);
  QQmlComponent theme(&engine);
  theme.setData("import QtQuick 2.12\nQtObject { property bool darkMode: true; property color accentColor: '#00a6f2'; property color primaryText: '#eeeeee'; property color secondaryText: '#aaaaaa'; property color panelBackgroundRaised: '#20262c'; }", QUrl());
  auto* settings = theme.create();
  engine.rootContext()->setContextProperty("settings_form", settings);
  QQmlComponent camera(&engine);
  camera.setData("import QtQuick 2.12\nQtObject { property bool available: false; property int encryption: 0; function param_int_exists(id) { return available; } function get_cached_int(id) { return encryption; } function try_set_param_int_async(id, value, log) { encryption = value; } }", QUrl());
  auto* cameraModel = camera.create();
  engine.rootContext()->setContextProperty("_airCameraSettingsModel", cameraModel);
  QObject air;
  air.setProperty("is_alive", false);
  air.setProperty("fleetcontrol_lte_active", false);
  air.setProperty("fleetcontrol_lte_upload_kbit", 0);
  engine.rootContext()->setContextProperty("_ohdSystemAir", &air);
  QQmlComponent component(&engine, QUrl::fromLocalFile(QString::fromLocal8Bit(argv[1])));
  auto* view = component.create();
  if (!view) { qWarning() << component.errors(); return 6; }
  if (!view->findChild<QObject*>("fleetUsername") || !view->findChild<QObject*>("fleetPassword")) return 7;
  // Exercise both UI states without authenticating or modifying real devices.
  delete view;
  QQmlComponent fixture(&engine);
  fixture.setData(R"(
import QtQuick 2.12
QtObject {
    property bool authenticated: false
    property bool busy: false
    property bool active: false
    property string accountName: "Bench operator"
    property string statusText: ""
    property string certificateExpiresAt: ""
    property bool certificateInstalled: false
    property var crafts: [{id: "bench", name: "Bench craft", licenseId: "lic-bench"}]
    property var licenses: [{id: "lic-bench", plan: "Professional", status: "active", expiresAt: "2027-09-05", daysRemaining: 364, video1Allowed: true}]
    signal statusChanged()
    function requestVideoCertificate(id) { busy = true; }
})", QUrl());
  auto* mockAccount = fixture.create();
  engine.rootContext()->setContextProperty("_fleetControlLte", mockAccount);
  QQuickWindow window;
  window.setColor(QColor("#171c21"));
  const QString imageDir = qEnvironmentVariable("FLEET_QML_SCREENSHOTS");
  if (!imageDir.isEmpty()) QDir().mkpath(imageDir);
  for (const bool dark : {true, false}) {
    settings->setProperty("darkMode", dark);
    settings->setProperty("primaryText", QColor(dark ? "#eeeeee" : "#202020"));
    settings->setProperty("secondaryText", QColor(dark ? "#aaaaaa" : "#606060"));
    settings->setProperty("panelBackgroundRaised", QColor(dark ? "#20262c" : "#f4f4f4"));
    window.setColor(QColor(dark ? "#171c21" : "#ffffff"));
    for (const bool signedIn : {false, true}) {
      mockAccount->setProperty("authenticated", signedIn);
      auto* item = qobject_cast<QQuickItem*>(component.create());
      if (!item) return 8;
      window.resize(600, 640);
      item->setParentItem(window.contentItem()); item->setSize(QSizeF(600, 640));
      window.show();
      QElapsedTimer timer; timer.start();
      while (timer.elapsed() < 200) app.processEvents();
      auto* usernameItem = item->findChild<QQuickItem*>("fleetUsername");
      auto* encryptionItem = item->findChild<QQuickItem*>("fleetEncryption");
      if (usernameItem->isVisible() == signedIn || encryptionItem->isVisible() != signedIn || encryptionItem->isEnabled()) return 9;
      if (!imageDir.isEmpty()) window.grabWindow().save(imageDir + (dark ? "/dark-" : "/light-") + (signedIn ? "settings.png" : "login.png"));
      item->setSize(QSizeF(420, 400)); window.resize(420, 400);
      app.processEvents();
      if (!item->findChild<QObject*>("fleetLicenceExpiry")->property("text").toString().contains("364")) return 10;
      if (signedIn) {
        cameraModel->setProperty("available", true);
        QMetaObject::invokeMethod(item, "syncEncryption");
        if (!encryptionItem->isEnabled()) return 11;
        encryptionItem->setProperty("checked", true);
        QMetaObject::invokeMethod(encryptionItem, "clicked");
        if (!mockAccount->property("busy").toBool() || cameraModel->property("encryption").toInt() != 0) return 15; // Wait for certificate before enabling.
        mockAccount->setProperty("certificateInstalled", true);
        mockAccount->setProperty("busy", false);
        QMetaObject::invokeMethod(mockAccount, "statusChanged");
        if (!encryptionItem->isEnabled()) return 12;
        encryptionItem->setProperty("checked", true);
        QMetaObject::invokeMethod(encryptionItem, "clicked");
        if (cameraModel->property("encryption").toInt() != 1) return 13;
        QMetaObject::invokeMethod(item, "syncEncryption");
        mockAccount->setProperty("certificateInstalled", false);
        if (!encryptionItem->isEnabled()) return 14; // Always permit turning encryption off.
        cameraModel->setProperty("available", false);
        cameraModel->setProperty("encryption", 0);
      }
      delete item;
    }
  }
  delete mockAccount;
  delete cameraModel;
  delete settings;
  qInfo() << "FleetControl input handling and QML creation passed";
  return 0;
}
