#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>

class AoaGauge : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(QColor glow READ glow WRITE setGlow NOTIFY glowChanged)


    Q_PROPERTY(int aoaRange MEMBER m_aoaRange WRITE setAoaRange NOTIFY aoaRangeChanged)

    Q_PROPERTY(int aoa MEMBER m_aoa WRITE setAoa NOTIFY aoaChanged)

    Q_PROPERTY(QString fontFamily MEMBER m_fontFamily WRITE setFontFamily NOTIFY fontFamilyChanged)

public:
    explicit AoaGauge(QQuickItem* parent = nullptr);

    void paint(QPainter* painter) override;

    QColor color() const;

    QColor glow() const;

public slots:
    void setColor(QColor color);
    void setGlow(QColor glow);
    void setAoaRange(int aoaRange);

    void setAoa(int aoa);

    void setFontFamily(QString fontFamily);

signals:
    void colorChanged(QColor color);
    void glowChanged(QColor glow);

    void aoaRangeChanged(int aoaRange);
    void aoaChanged(int aoa);

    void fontFamilyChanged(QString fontFamily);

private:
    QColor m_color;
    QColor m_glow;

    int m_aoaRange;
    int m_aoa;

    QString m_fontFamily;

    QFont m_font;

};
