#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>

#include "openhd.h"

class SpeedLadder : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(QColor glow READ glow WRITE setGlow NOTIFY glowChanged)
    Q_PROPERTY(bool useGroundspeed MEMBER m_useGroundspeed WRITE setUseGroundspeed NOTIFY useGroundspeedChanged)
    Q_PROPERTY(bool imperial MEMBER m_imperial WRITE setImperial NOTIFY imperialChanged)
    Q_PROPERTY(int speedMinimum MEMBER m_speedMinimum WRITE setSpeedMinimum NOTIFY speedMinimumChanged)
    Q_PROPERTY(int speedRange MEMBER m_speedRange WRITE setSpeedRange NOTIFY speedRangeChanged)

    Q_PROPERTY(int airspeed MEMBER m_airspeed WRITE setAirspeed NOTIFY airspeedChanged)
    Q_PROPERTY(int speed MEMBER m_speed WRITE setSpeed NOTIFY speedChanged)

    Q_PROPERTY(QString fontFamily MEMBER m_fontFamily WRITE setFontFamily NOTIFY fontFamilyChanged)

public:
    explicit SpeedLadder(QQuickItem* parent = nullptr);

    void paint(QPainter* painter) override;

    QColor color() const;

    QColor glow() const;

public slots:
    void setColor(QColor color);
    void setGlow(QColor glow);
    void setUseGroundspeed(bool useGroundspeed);
    void setImperial(bool imperial);
    void setSpeedMinimum(int speedMinimum);
    void setSpeedRange(int speedRange);

    void setSpeed(int speed);
    void setAirspeed(int airspeed);

    void setFontFamily(QString fontFamily);

signals:
    void colorChanged(QColor color);
    void glowChanged(QColor glow);
    void useGroundspeedChanged(bool useGroundspeed);
    void imperialChanged(bool imperial);
    void speedMinimumChanged(int speedMinimum);
    void speedRangeChanged(int speedRange);
    void speedChanged(int speed);
    void airspeedChanged(int airspeed);

    void fontFamilyChanged(QString fontFamily);

private:
    QColor m_color;
    QColor m_glow;
    bool m_useGroundspeed;
    bool m_imperial;
    int m_speedMinimum;
    int m_speedRange;
    int m_speed;
    int m_airspeed;

    QString m_fontFamily;

    QFont m_font;

};
