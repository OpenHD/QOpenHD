#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>

#include "openhd.h"

class FlightPathVector : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(QColor glow READ glow WRITE setGlow NOTIFY glowChanged)
    Q_PROPERTY(bool fpvInvertPitch MEMBER m_fpvInvertPitch WRITE setFpvInvertPitch NOTIFY fpvInvertPitchChanged)
    Q_PROPERTY(bool fpvInvertRoll MEMBER m_fpvInvertRoll WRITE setFpvInvertRoll NOTIFY fpvInvertRollChanged)

    Q_PROPERTY(int roll MEMBER m_roll WRITE setRoll NOTIFY rollChanged)
    Q_PROPERTY(int pitch MEMBER m_pitch WRITE setPitch NOTIFY pitchChanged)

    Q_PROPERTY(int lateral MEMBER m_lateral WRITE setLateral NOTIFY lateralChanged)
    Q_PROPERTY(int vertical MEMBER m_vertical WRITE setVertical NOTIFY verticalChanged)

    Q_PROPERTY(int horizonSpacing MEMBER m_horizonSpacing WRITE setHorizonSpacing NOTIFY horizonSpacingChanged)
    Q_PROPERTY(double horizonWidth MEMBER m_horizonWidth WRITE setHorizonWidth NOTIFY horizonWidthChanged)
    Q_PROPERTY(double fpvSize MEMBER m_fpvSize WRITE setFpvSize NOTIFY fpvSizeChanged)

    Q_PROPERTY(double verticalLimit MEMBER m_verticalLimit WRITE setVerticalLimit NOTIFY verticalLimitChanged)
    Q_PROPERTY(double lateralLimit MEMBER m_lateralLimit WRITE setLateralLimit NOTIFY lateralLimitChanged)

    Q_PROPERTY(QString fontFamily MEMBER m_fontFamily WRITE setFontFamily NOTIFY fontFamilyChanged)

public:
    explicit FlightPathVector(QQuickItem* parent = nullptr);

    void paint(QPainter* painter) override;

    QColor color() const;
    QColor glow() const;

public slots:
    void setColor(QColor color);
    void setGlow(QColor glow);
    void setFpvInvertPitch(bool fpvInvertPitch);
    void setFpvInvertRoll(bool fpvInvertRoll);

    void setRoll(int roll);
    void setPitch(int pitch);

    void setLateral(int lateral);
    void setVertical(int vertical);

    void setHorizonSpacing(int horizonSpacing);
    void setHorizonWidth(double horizonWidth);
    void setFpvSize(double fpvSize);

    void setVerticalLimit(double verticalLimit);
    void setLateralLimit(double lateralLimit);

    void setFontFamily(QString fontFamily);

signals:
    void colorChanged(QColor color);
    void glowChanged(QColor glow);
    void fpvInvertPitchChanged(bool fpvInvertPitch);
    void fpvInvertRollChanged(bool fpvInvertRoll);

    void rollChanged(int roll);
    void pitchChanged(int pitch);

    void lateralChanged(int lateral);
    void verticalChanged(int vertical);

    void horizonSpacingChanged(int horizonSpacing);
    void horizonWidthChanged(double horizonWidth);
    void fpvSizeChanged(double fpvSize);

    void verticalLimitChanged(double verticalLimit);
    void lateralLimitChanged(double lateralLimit);

    void fontFamilyChanged(QString fontFamily);

private:
    QColor m_color;
    QColor m_glow;
    bool m_fpvInvertPitch;
    bool m_fpvInvertRoll;

    int m_roll;
    int m_pitch;

    int m_lateral;
    int m_vertical;

    int m_horizonSpacing;
    double m_horizonWidth;
    double m_fpvSize;

    double m_verticalLimit;
    double m_lateralLimit;

    QString m_fontFamily;

    QFont m_font;

    QFont m_fontAwesome = QFont("Font Awesome 5 Free", 14, QFont::Bold, false);
};
