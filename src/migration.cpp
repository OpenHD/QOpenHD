
#include "migration.hpp"

#include <QObject>
#include <QtQuick>


/*
 * Migrations to prevent issues for existing users with saved settings and other state.
 *
 * Changes requiring migration will be documented here.
 *
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


    emit migrationsFinished();
}
