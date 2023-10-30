#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>

#include "../../../lib/lqtutils_master/lqtutils_prop.h"

class AltitudeLadder : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(QColor glow READ glow WRITE setGlow NOTIFY glowChanged)
    Q_PROPERTY(int altitudeRange MEMBER m_altitudeRange WRITE setAltitudeRange NOTIFY altitudeRangeChanged)
    // actual altitude, unit - less
    Q_PROPERTY(int altitude MEMBER m_altitude WRITE set_altitude NOTIFY altitude_changed)
    Q_PROPERTY(QString fontFamily MEMBER m_fontFamily WRITE setFontFamily NOTIFY fontFamilyChanged)
public:
    Q_PROPERTY(double custom_font_scale WRITE set_custom_font_scale)
public:
    explicit AltitudeLadder(QQuickItem* parent = nullptr);

    void paint(QPainter* painter) override;

    QColor color() const;
    QColor glow() const;

public slots:
    void setColor(QColor color);
    void setGlow(QColor glow);
    void setAltitudeRange(int altitudeRange);
    void set_altitude(double alt);
    void setFontFamily(QString fontFamily);
    void set_custom_font_scale(double custom_font_scale);
signals:
    void colorChanged(QColor color);
    void glowChanged(QColor glow);
    void altitudeRangeChanged(int altitudeRange);

    void altitude_changed(double alt);

    void fontFamilyChanged(QString fontFamily);

private:
    QColor m_color;
    QColor m_glow;
    int m_altitudeRange;
    double m_altitude;

    QString m_fontFamily;
    QFont m_font;

    double m_custom_font_scale=1.0;

};
