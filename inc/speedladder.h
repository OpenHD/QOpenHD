#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>

#include "openhd.h"

class SpeedLadder : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(bool airspeedOrGps MEMBER m_airspeedOrGps WRITE setAirspeedOrGps NOTIFY airspeedOrGpsChanged)
    Q_PROPERTY(bool imperial MEMBER m_imperial WRITE setImperial NOTIFY imperialChanged)
    Q_PROPERTY(int speedMinimum MEMBER m_speedMinimum WRITE setSpeedMinimum NOTIFY speedMinimumChanged)
    Q_PROPERTY(int speedRange MEMBER m_speedRange WRITE setSpeedRange NOTIFY speedRangeChanged)

    Q_PROPERTY(int airspeed MEMBER m_airspeed WRITE setAirspeed NOTIFY airspeedChanged)
    Q_PROPERTY(int speed MEMBER m_speed WRITE setSpeed NOTIFY speedChanged)

    QML_ELEMENT

public:
    explicit SpeedLadder(QQuickItem* parent = nullptr);

    void paint(QPainter* painter) override;

    QColor color() const;

public slots:
    void setColor(QColor color);
    void setAirspeedOrGps(bool airspeedOrGps);
    void setImperial(bool imperial);
    void setSpeedMinimum(int speedMinimum);
    void setSpeedRange(int speedRange);

    void setSpeed(int speed);
    void setAirspeed(int airspeed);

signals:
    void colorChanged(QColor color);
    void airspeedOrGpsChanged(bool airspeedOrGps);
    void imperialChanged(bool imperial);
    void speedMinimumChanged(int speedMinimum);
    void speedRangeChanged(int speedRange);
    void speedChanged(int speed);
    void airspeedChanged(int airspeed);

private:
    QColor m_color;
    bool m_airspeedOrGps;
    bool m_imperial;
    int m_speedMinimum;
    int m_speedRange;
    int m_speed;
    int m_airspeed;

};
