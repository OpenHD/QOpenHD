#include "../app/fleetcontrol/fleetcontrolconnection.h"
#include <QGuiApplication>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QTemporaryFile>
#include <QDebug>

int main(int argc, char** argv) {
  QGuiApplication app(argc, argv);
  FleetControlConnection fleet;
  fleet.login("http://example.com", "user", "password");
  if (fleet.busy() || fleet.authenticated() || !fleet.statusText().contains("HTTPS")) return 1;
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
  QObject air;
  air.setProperty("is_alive", false);
  air.setProperty("fleetcontrol_lte_active", false);
  air.setProperty("fleetcontrol_lte_upload_kbit", 0);
  engine.rootContext()->setContextProperty("_ohdSystemAir", &air);
  QQmlComponent component(&engine, QUrl::fromLocalFile(QString::fromLocal8Bit(argv[1])));
  auto* view = component.create();
  if (!view) { qWarning() << component.errors(); return 6; }
  delete view;
  qInfo() << "FleetControl input handling and QML creation passed";
  return 0;
}
