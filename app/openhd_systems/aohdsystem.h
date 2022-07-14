#ifndef AOHDSYSTEM_H
#define AOHDSYSTEM_H

#include <QObject>

/**
 * This class contains information (basically like a model) about one OpenHD Air or ground instance (if connected).
 * A (Abstract) because it is only for functionalities that are always supported by both air and ground.
 * NOTE: FC telemetry has nothing to do here, as well as air / ground specific things.
 * For example, both the air and ground unit report the CPU usage and more, and this data has is made available to QT using a instance of this model.
 * Note: In QOpenHD, there are 2 instances of this model, named "_ohdSystemGround" and "_ohdSystemAir" (registered in main)
 * They each correspond to the apropriate singleton instance
 */
class AOHDSystem : public QObject
{
    Q_OBJECT
public:
    explicit AOHDSystem(const bool is_air,QObject *parent = nullptr);
     static AOHDSystem& instanceAir();
     static AOHDSystem& instanceGround();
private:
     const bool _is_air; // either true (for air) or false (for ground)
signals:

};

#endif // AOHDSYSTEM_H
