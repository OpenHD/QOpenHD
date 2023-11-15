#ifndef QOPENHD_HORIZON_LADDER
#define QOPENHD_HORIZON_LADDER

#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>
#include "../../lib/lqtutils_master/lqtutils_prop.h"

class HorizonLadder : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(QColor glow READ glow WRITE setGlow NOTIFY glowChanged)
    Q_PROPERTY(bool horizonInvertPitch MEMBER m_horizonInvertPitch WRITE setHorizonInvertPitch NOTIFY horizonInvertPitchChanged)
    Q_PROPERTY(bool horizonInvertRoll MEMBER m_horizonInvertRoll WRITE setHorizonInvertRoll NOTIFY horizonInvertRollChanged)
    Q_PROPERTY(double horizonWidth MEMBER m_horizonWidth WRITE setHorizonWidth NOTIFY horizonWidthChanged)
    Q_PROPERTY(int horizonSpacing MEMBER m_horizonSpacing WRITE setHorizonSpacing NOTIFY horizonSpacingChanged)
    Q_PROPERTY(bool horizonShowLadder MEMBER m_horizonShowLadder WRITE setHorizonShowLadder NOTIFY horizonShowLadderChanged)
    Q_PROPERTY(int horizonRange MEMBER m_horizonRange WRITE setHorizonRange NOTIFY horizonRangeChanged)
    Q_PROPERTY(int horizonStep MEMBER m_horizonStep WRITE setHorizonStep NOTIFY horizonStepChanged)
    Q_PROPERTY(int roll MEMBER m_roll WRITE setRoll NOTIFY rollChanged)
    Q_PROPERTY(int pitch MEMBER m_pitch WRITE setPitch NOTIFY pitchChanged)

    Q_PROPERTY(int heading MEMBER m_heading WRITE setHeading NOTIFY headingChanged)
    Q_PROPERTY(int homeHeading MEMBER m_homeHeading WRITE setHomeHeading NOTIFY homeHeadingChanged)
    Q_PROPERTY(bool showHeadingLadderText MEMBER m_showHeadingLadderText WRITE setShowHeadingLadderText NOTIFY showHeadingLadderTextChanged)
    Q_PROPERTY(bool showHorizonHeadingLadder MEMBER m_showHorizonHeadingLadder WRITE setShowHorizonHeadingLadder NOTIFY showHorizonHeadingLadderChanged)
    Q_PROPERTY(bool showHorizonHome MEMBER m_showHorizonHome WRITE setShowHorizonHome NOTIFY showHorizonHomeChanged)

    Q_PROPERTY(QString fontFamily MEMBER m_fontFamily WRITE setFontFamily NOTIFY fontFamilyChanged)

    // Indicates the center
    L_RW_PROP(bool,show_center_indicator, set_show_center_indicator, true)
    // Adjust the stroke strength of the lines, in percent
    //L_RW_PROP(double,line_stroke_strength_perc, set_line_stroke_strength_perc, 100)
public:
    Q_PROPERTY(double custom_font_scale WRITE set_custom_font_scale)
public:
    explicit HorizonLadder(QQuickItem* parent = nullptr);

    void paint(QPainter* painter) override;

    QColor color() const;
    QColor glow() const;

public slots:
    void setColor(QColor color);
    void setGlow(QColor glow);
    void setHorizonInvertPitch(bool horizonInvertPitch);
    void setHorizonInvertRoll(bool horizonInvertRoll);
    void setHorizonWidth(double horizonWidth);
    void setHorizonSpacing(int horizonSpacing);
    void setHorizonShowLadder(bool horizonShowLadder);
    void setHorizonRange(int horizonRange);
    void setHorizonStep(int horizonStep);
    void setRoll(int roll);
    void setPitch(int pitch);

    void setHeading(int heading);
    void setHomeHeading(int homeHeading);
    void setShowHeadingLadderText(bool showHeadingLadderText);
    void setShowHorizonHeadingLadder(bool showHorizonHeadingLadder);
    void setShowHorizonHome(bool showHorizonHome);

    void setFontFamily(QString fontFamily);
    void set_custom_font_scale(double custom_font_scale);
signals:
    void colorChanged(QColor color);
    void glowChanged(QColor glow);
    void horizonInvertPitchChanged(bool horizonInvertPitch);
    void horizonInvertRollChanged(bool horizonInvertRoll);
    void horizonWidthChanged(double horizonWidth);
    void horizonSpacingChanged(int horizonSpacing);
    void horizonShowLadderChanged(bool horizonShowLadder);
    void horizonRangeChanged(int horizonRange);
    void horizonStepChanged(int horizonStep);
    void rollChanged(int roll);
    void pitchChanged(int pitch);

    void headingChanged(int heading);
    void homeHeadingChanged(int homeHeading);
    void showHeadingLadderTextChanged(bool showHeadingLadderText);
    void showHorizonHeadingLadderChanged(bool showHorizonHeadingLadder);
    void showHorizonHomeChanged(bool showHorizonHome);

    void fontFamilyChanged(QString fontFamily);

private:
    QColor m_color;
    QColor m_glow;
    bool m_horizonInvertPitch;
    bool m_horizonInvertRoll;
    double m_horizonWidth;
    int m_horizonSpacing;
    int m_horizonStep;
    bool m_horizonShowLadder;
    int m_horizonRange;

    int m_roll;
    int m_pitch;

    int m_heading;
    int m_homeHeading;
    bool m_showHeadingLadderText;
    bool m_showHorizonHeadingLadder;
    bool m_showHorizonHome;

    QString m_fontFamily;

    QFont m_font;

    QFont m_fontAwesome = QFont("Font Awesome 5 Free", 11, QFont::Bold, false);
    double m_custom_font_scale=1.0;
};
#endif //QOPENHD_HORIZON_LADDER
