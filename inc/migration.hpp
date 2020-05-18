#ifndef MIGRATION_H
#define MIGRATION_H

#include <QObject>
#include <QtQuick>


/*
 * Migrations to prevent issues for existing users with saved settings and other state.
 *
 * Changes requiring migration will be documented here.
 *
 *
 */

class Migration;

Migration* _instance = nullptr;

class Migration: public QObject {
    Q_OBJECT

public:
    explicit Migration() {}

    static Migration* instance() {
        if (_instance == nullptr) {
            _instance = new Migration();
        }
        return _instance;
    }

    Q_INVOKABLE void run() {
        QSettings settings;

        auto migration_level = settings.value("migration_level", 0).toInt();

        emit migrationsFinished();
    }

signals:
    void migrationsFinished();
};


#endif
