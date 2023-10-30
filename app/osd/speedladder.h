#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>

#include "../../../lib/lqtutils_master/lqtutils_prop.h"

class SpeedLadder : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(QColor glow READ glow WRITE setGlow NOTIFY glowChanged)
    Q_PROPERTY(int speedMinimum MEMBER m_speedMinimum WRITE setSpeedMinimum NOTIFY speedMinimumChanged)
    Q_PROPERTY(int speedRange MEMBER m_speedRange WRITE setSpeedRange NOTIFY speedRangeChanged)
    // Unit - less since exposed as ladder
    Q_PROPERTY(int speed MEMBER m_speed WRITE setSpeed NOTIFY speedChanged)

    Q_PROPERTY(QString fontFamily MEMBER m_fontFamily WRITE setFontFamily NOTIFY fontFamilyChanged)
public:
    Q_PROPERTY(double custom_font_scale WRITE set_custom_font_scale)
public:
    explicit SpeedLadder(QQuickItem* parent = nullptr);

    void paint(QPainter* painter) override;

    QColor color() const;

    QColor glow() const;

public slots:
    void setColor(QColor color);
    void setGlow(QColor glow);
    void setSpeedMinimum(int speedMinimum);
    void setSpeedRange(int speedRange);

    void setSpeed(int speed);
    void setFontFamily(QString fontFamily);
    void set_custom_font_scale(double custom_font_scale);
signals:
    void colorChanged(QColor color);
    void glowChanged(QColor glow);
    void speedMinimumChanged(int speedMinimum);
    void speedRangeChanged(int speedRange);
    void speedChanged(int speed);

    void fontFamilyChanged(QString fontFamily);

private:
    QColor m_color;
    QColor m_glow;
    int m_speedMinimum;
    int m_speedRange;
    int m_speed;

    QString m_fontFamily;

    QFont m_font;
    double m_custom_font_scale=1.0;
};
