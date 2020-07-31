#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>

#include "openhd.h"

class AltitudeLadder : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(bool altitudeRelMsl MEMBER m_altitudeRelMsl WRITE setAltitudeRelMsl NOTIFY altitudeRelMslChanged)
    Q_PROPERTY(bool imperial MEMBER m_imperial WRITE setImperial NOTIFY imperialChanged)
    Q_PROPERTY(int altitudeRange MEMBER m_altitudeRange WRITE setAltitudeRange NOTIFY altitudeRangeChanged)


    Q_PROPERTY(int altMsl MEMBER m_altMsl WRITE setAltMsl NOTIFY altMslChanged)
    Q_PROPERTY(int altRel MEMBER m_altRel WRITE setAltRel NOTIFY altRelChanged)

    QML_ELEMENT

public:
    explicit AltitudeLadder(QQuickItem* parent = nullptr);

    void paint(QPainter* painter) override;

    QColor color() const;

public slots:
    void setColor(QColor color);
    void setAltitudeRelMsl(bool altitudeRelMsl);
    void setImperial(bool imperial);
    void setAltitudeRange(int altitudeRange);
    void setAltMsl(double altMsl);
    void setAltRel(double altRel);

signals:
    void colorChanged(QColor color);
    void altitudeRelMslChanged(bool altitudeRelMsl);
    void imperialChanged(bool imperial);
    void altitudeRangeChanged(int altitudeRange);

    void altMslChanged(double altMsl);
    void altRelChanged(double altRel);

private:
    QColor m_color;
    bool m_altitudeRelMsl;
    bool m_imperial;
    int m_altitudeRange;

    double m_altMsl;
    double m_altRel;

};
