#ifndef MIGRATION_H
#define MIGRATION_H

#include <QObject>
#include <QtQuick>


class Migration: public QObject {
    Q_OBJECT

public:
    explicit Migration() {}

    static Migration* instance();

    Q_INVOKABLE void run();

signals:
    void migrationsFinished();
};


#endif
