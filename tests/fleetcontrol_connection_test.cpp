#include "../app/fleetcontrol/fleetcontrollte.h"
#include <QGuiApplication>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QDebug>
#include <QQuickItem>
#include <QQuickWindow>
#include <QElapsedTimer>
#include <QDir>
#include <QFontDatabase>
#include <QFileInfo>
#include <QTest>

int main(int argc, char** argv) {
  qInstallMessageHandler([](QtMsgType, const QMessageLogContext&, const QString& message) { fprintf(stderr, "%s\n", qPrintable(message)); });
  QGuiApplication app(argc, argv);
#ifdef Q_OS_WIN
  const int fontId = QFontDatabase::addApplicationFont("C:/Windows/Fonts/segoeui.ttf");
  if (fontId >= 0) app.setFont(QFont(QFontDatabase::applicationFontFamilies(fontId).first(), 10));
#endif
  QFontDatabase::addApplicationFont(QFileInfo(QString::fromLocal8Bit(argv[1])).dir().filePath("../../../resources/Font Awesome 5 Free-Solid-900.otf"));
  FleetControlLte account;
  if (account.endpoint() != "https://openhd.tech") return 1;
  account.bindLicense("lic-bench", "bench");
  if (account.busy()) return 2;
  QQmlEngine engine;
  QStringList warnings;
  QObject::connect(&engine, &QQmlEngine::warnings, [&warnings](const QList<QQmlError>& errors) {
    for (const auto& error : errors) warnings.append(error.toString());
  });
  engine.rootContext()->setContextProperty("_fleetControlLte", &account);
  QQmlComponent theme(&engine);
  theme.setData("import QtQuick 2.12\nQtObject { property bool darkMode: true; property color accentColor: '#278cff'; property color primaryText: '#eeeeee'; property color secondaryText: '#aaaaaa'; property color panelBackgroundRaised: '#20262c'; property color panelBackground: '#171c21'; property color lineColor: '#394653'; }", QUrl());
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
    property string certificateLicenseId: ""
    property var crafts: [{id: "bench", name: "Bench craft", licenseId: "lic-bench"}]
    property var licenses: [{id: "lic-bench", craftId: "bench", plan: "Professional", status: "active", expiresAt: "2027-09-05", daysRemaining: 364, video1Allowed: true}]
    property string lastAssignment: ""
    function assignmentFixture() {
        crafts = [{id: "bench", name: "Bench craft", licenseId: "lic-bench"},
                  {id: "survey", name: "Survey craft"}, {id: "rescue", name: "Rescue craft"}]
        licenses = [{id: "lic-bench", craftId: "bench", plan: "Professional", status: "active", expiresAt: "2027-09-05", daysRemaining: 364, video1Allowed: true},
                    {id: "lic-spare", plan: "Professional", status: "active", expiresAt: "2027-09-05", daysRemaining: 364, video1Allowed: true}]
    }
    function bindLicense(id, craftId) {
        lastAssignment = id + ":" + craftId
        licenses = licenses.map(function(l) { return {id: l.id, craftId: l.id === id ? craftId : l.craftId, plan: l.plan, status: l.status, expiresAt: l.expiresAt, daysRemaining: l.daysRemaining, video1Allowed: l.video1Allowed} })
    }
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
    settings->setProperty("panelBackground", QColor(dark ? "#171c21" : "#ffffff"));
    settings->setProperty("lineColor", QColor(dark ? "#394653" : "#bfc8d0"));
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
        // A certificate for a different craft cannot satisfy this request.
        mockAccount->setProperty("certificateInstalled", true);
        mockAccount->setProperty("certificateLicenseId", "lic-another-craft");
        encryptionItem->setProperty("checked", true);
        QMetaObject::invokeMethod(encryptionItem, "clicked");
        if (!mockAccount->property("busy").toBool() || cameraModel->property("encryption").toInt() != 0) return 15; // Wait for certificate before enabling.
        mockAccount->setProperty("certificateInstalled", true);
        mockAccount->setProperty("certificateLicenseId", "lic-bench");
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
  // Actual popup keyboard selection, in both themes. Assigned craft must never
  // be offered for a second certificate, and assignment must survive a refresh.
  for (const bool dark : {true, false}) {
    settings->setProperty("darkMode", dark);
    settings->setProperty("primaryText", QColor(dark ? "#eeeeee" : "#202020"));
    settings->setProperty("secondaryText", QColor(dark ? "#aaaaaa" : "#606060"));
    settings->setProperty("panelBackgroundRaised", QColor(dark ? "#20262c" : "#f4f4f4"));
    settings->setProperty("panelBackground", QColor(dark ? "#171c21" : "#ffffff"));
    settings->setProperty("lineColor", QColor(dark ? "#394653" : "#bfc8d0"));
    window.setColor(QColor(dark ? "#171c21" : "#ffffff"));
    QMetaObject::invokeMethod(mockAccount, "assignmentFixture");
    auto* item = qobject_cast<QQuickItem*>(component.create());
    if (!item) return 21;
    item->setParentItem(window.contentItem()); item->setSize(QSizeF(600, 640));
    window.resize(600, 640); window.show(); window.requestActivate();
    item->setProperty("selectedLicenseId", "lic-spare");
    QTest::qWait(50);
    auto* craftBox = item->findChild<QQuickItem*>("fleetCraft");
    auto* certificateBox = item->findChild<QQuickItem*>("fleetCertificate");
    auto* assign = item->findChild<QQuickItem*>("fleetAssign");
    if (craftBox->property("count").toInt() != 2 || !assign->isEnabled()) return 22;
    for (auto* box : {certificateBox, craftBox}) {
      QMetaObject::invokeMethod(box, "openForKeyboard");
      auto* popup = box->property("popup").value<QObject*>();
      if (!QTest::qWaitFor([popup]() { return popup->property("opened").toBool(); }, 1000)) return 28;
      auto* background = popup->property("background").value<QObject*>();
      if (!popup->property("visible").toBool() || popup->property("height").toDouble() > 280 ||
          background->property("color").value<QColor>() != settings->property("panelBackgroundRaised").value<QColor>()) return 23;
      if (!imageDir.isEmpty()) window.grabWindow().save(imageDir + (dark ? "/dark-" : "/light-") + box->objectName() + ".png");
      auto* keyWindow = QGuiApplication::focusWindow() ? QGuiApplication::focusWindow() : &window;
      if (box == certificateBox) QTest::keyClick(keyWindow, Qt::Key_Escape);
      else {
        QTest::keyClick(keyWindow, Qt::Key_Down);
        QTest::qWait(50);
        QTest::keyClick(keyWindow, Qt::Key_Return);
      }
      QTest::qWait(250);
      if (popup->property("visible").toBool()) {
        auto* focus = QGuiApplication::focusObject();
        fprintf(stderr, "Popup did not close: %s; focus: %s; window: %s\n", qPrintable(box->objectName()), focus ? focus->metaObject()->className() : "none", keyWindow->metaObject()->className());
        return 24;
      }
    }
    if (craftBox->property("displayText").toString() != "Rescue craft") return 25;
    QMetaObject::invokeMethod(assign, "clicked");
    QTest::qWait(50);
    if (mockAccount->property("lastAssignment").toString() != "lic-spare:rescue" ||
        craftBox->isEnabled() || assign->isVisible() || craftBox->property("displayText").toString() != "Rescue craft") return 26;
    item->setSize(QSizeF(420, 400)); window.resize(420, 400);
    QTest::qWait(50);
    if (!imageDir.isEmpty()) window.grabWindow().save(imageDir + (dark ? "/dark-" : "/light-") + "narrow.png");
    mockAccount->setProperty("licenses", QVariantList{});
    mockAccount->setProperty("crafts", QVariantList{});
    QTest::qWait(50);
    if (assign->isVisible() || craftBox->isEnabled() || certificateBox->property("displayText").toString().isEmpty()) return 27;
    delete item;
  }
  delete mockAccount;
  if (!warnings.isEmpty()) { qWarning() << warnings; return 20; }
  delete cameraModel;
  delete settings;
  qInfo() << "FleetControl input handling and QML creation passed";
  return 0;
}
