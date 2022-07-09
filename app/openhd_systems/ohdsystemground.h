#ifndef OHDSYSTEMGROUND_H
#define OHDSYSTEMGROUND_H

#include <QObject>

/**
 * @brief This class contains information (basically like a model) about the OpenHD Air instance (if connected)
 * It uses QT signals to propagate changes of its data member(s) (Like weather the system is connected, usw)
 * QOpenHD can only talk to one OHD Ground system at a time, so we can make this class a singleton.
 */
class OHDSystemGround : public QObject
{
    Q_OBJECT
public:
    explicit OHDSystemGround(QObject *parent = nullptr);
    static OHDSystemGround& instance();
public:
    Q_PROPERTY(int cpuload_gnd MEMBER m_cpuload_gnd WRITE set_cpuload_gnd NOTIFY cpuload_gnd_changed)
    void set_cpuload_gnd(int cpuload_gnd);
    Q_PROPERTY(int temp_gnd MEMBER m_temp_gnd WRITE set_temp_gnd NOTIFY temp_gnd_changed)
    void set_temp_gnd(int temp_gnd);

signals:
    void cpuload_gnd_changed(int cpuload_gnd);
    void temp_gnd_changed(int temp_gnd);
public:
    int m_cpuload_gnd = 0;
    int m_temp_gnd = 0;
};

#endif // OHDSYSTEMGROUND_H
