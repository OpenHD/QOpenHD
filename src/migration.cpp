
#include "migration.hpp"

#include <QObject>
#include <QtQuick>


/*
 * Migrations to prevent issues for existing users with saved settings and other state.
 *
 * Changes requiring migration will be documented here.
 *
 * 1: reset the bitrate and downlink rssi widget sizes since they became larger and changed location
 *
 *
 */


Migration* _instance = nullptr;


Migration* Migration::instance() {
    if (_instance == nullptr) {
        _instance = new Migration();
    }
    return _instance;
}

void Migration::run() {
    QSettings settings;

    auto migration_level = settings.value("migration_level", 0).toInt();

    if (migration_level < 1) {
        settings.remove("bitrate_widget_x_offset");
        settings.remove("bitrate_widget_y_offset");
        settings.remove("bitrate_widget_h_center");
        settings.remove("bitrate_widget_v_center");
        settings.remove("bitrate_widget_align");

        settings.remove("downlink_rssi_widget_x_offset");
        settings.remove("downlink_rssi_widget_y_offset");
        settings.remove("downlink_rssi_widget_h_center");
        settings.remove("downlink_rssi_widget_v_center");
        settings.remove("downlink_rssi_widget_align");

        settings.setValue("migration_level", 1);
    }

    emit migrationsFinished();
}
