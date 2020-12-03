#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>

#include "openhd.h"

class HeadingLadder : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(QColor glow READ glow WRITE setGlow NOTIFY glowChanged)
    Q_PROPERTY(bool showHeadingLadderText MEMBER m_showHeadingLadderText WRITE setShowHeadingLadderText NOTIFY showHeadingLadderTextChanged)
    Q_PROPERTY(bool imperial MEMBER m_imperial WRITE setImperial NOTIFY imperialChanged)
    Q_PROPERTY(bool showHorizonHome MEMBER m_showHorizonHome WRITE setShowHorizonHome NOTIFY showHorizonHomeChanged)
    Q_PROPERTY(bool showHorizonHeadingLadder MEMBER m_showHorizonHeadingLadder WRITE setShowHorizonHeadingLadder NOTIFY showHorizonHeadingLadderChanged)

    Q_PROPERTY(int heading MEMBER m_heading WRITE setHeading NOTIFY headingChanged)
    Q_PROPERTY(int homeHeading MEMBER m_homeHeading WRITE setHomeHeading NOTIFY homeHeadingChanged)

    Q_PROPERTY(QString fontFamily MEMBER m_fontFamily WRITE setFontFamily NOTIFY fontFamilyChanged)


//show_horizon_heading_ladder

public:
    explicit HeadingLadder(QQuickItem* parent = nullptr);

    void paint(QPainter* painter) override;

    QColor color() const;
    QColor glow() const;

public slots:
    void setColor(QColor color);
    void setGlow(QColor glow);
    void setShowHeadingLadderText(bool showHeadingLadderText);
    void setImperial(bool imperial);
    void setShowHorizonHome(bool showHorizonHome);
    void setShowHorizonHeadingLadder(bool showHorizonHeadingLadder);

    void setHeading(int heading);
    void setHomeHeading(int homeHeading);

    void setFontFamily(QString fontFamily);

signals:
    void colorChanged(QColor color);
    void glowChanged(QColor glow);
    void imperialChanged(bool imperial);
    void showHeadingLadderTextChanged(bool showHeadingLadderText);
    void showHorizonHomeChanged(bool showHorizonHome);
    void showHorizonHeadingLadderChanged(bool showHorizonHeadingLadder);

    void headingChanged(int heading);
    void homeHeadingChanged(int homeHeading);

    void fontFamilyChanged(QString fontFamily);

private:
    QColor m_color;
    QColor m_glow;
    bool m_showHeadingLadderText;
    bool m_imperial;
    bool m_showHorizonHome;
    bool m_showHorizonHeadingLadder;

    int m_heading;
    int m_homeHeading;

    QString m_fontFamily;

    QFont m_font;

    QFont m_fontAwesome = QFont("Font Awesome 5 Free", 14, QFont::Bold, false);
};
