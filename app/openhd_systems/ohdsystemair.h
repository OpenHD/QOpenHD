#ifndef OHDSYSTEMAIR_H
#define OHDSYSTEMAIR_H

#include <QObject>


/**
 * @brief This class contains information (basically like a model) about the OpenHD Air instance (if connected)
 * It uses QT signals to propagate changes of its data member(s) (Like weather the system is connected, usw).
 * QOpenHD can only talk to one OHD Air system at a time, so we can make this class a singleton.
 */
class OHDSystemAir : public QObject
{
    Q_OBJECT
public:
    explicit OHDSystemAir(QObject *parent = nullptr);
    static OHDSystemAir& instance();
public:
    Q_PROPERTY(int cpuload_air MEMBER m_cpuload_air WRITE set_cpuload_air NOTIFY cpuload_air_changed)
    void set_cpuload_air(int cpuload_air);
    Q_PROPERTY(int temp_air MEMBER m_temp_air WRITE set_temp_air NOTIFY temp_air_changed)
    void set_temp_air(int temp_air);
signals:
    void cpuload_air_changed(int cpuload_air);
    void temp_air_changed(int temp_air);
public:
    int m_cpuload_air = 0;
    int m_temp_air = 0;
};

#endif // OHDSYSTEMAIR_H
