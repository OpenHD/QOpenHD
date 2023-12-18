#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>

//#include "openhd.h"

class DrawingCanvas : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(QColor glow READ glow WRITE setGlow NOTIFY glowChanged)
    Q_PROPERTY(bool fpvInvertPitch MEMBER m_fpvInvertPitch WRITE setFpvInvertPitch NOTIFY fpvInvertPitchChanged)
    Q_PROPERTY(bool fpvInvertRoll MEMBER m_fpvInvertRoll WRITE setFpvInvertRoll NOTIFY fpvInvertRollChanged)

    Q_PROPERTY(int alt MEMBER m_alt WRITE setAlt NOTIFY altChanged)
    Q_PROPERTY(QString alt_text MEMBER m_alt_text WRITE setAltText NOTIFY altTextChanged)
    Q_PROPERTY(int drone_alt MEMBER m_drone_alt WRITE setDroneAlt NOTIFY droneAltChanged)
    Q_PROPERTY(int speed MEMBER m_speed WRITE setSpeed NOTIFY speedChanged)
    Q_PROPERTY(QString speed_text MEMBER m_speed_text WRITE setSpeedText NOTIFY speedTextChanged)
    Q_PROPERTY(int vert_spd MEMBER m_vert_spd WRITE setVertSpd NOTIFY vertSpdChanged)
    Q_PROPERTY(int heading MEMBER m_heading WRITE setHeading NOTIFY headingChanged)
    Q_PROPERTY(int drone_heading MEMBER m_drone_heading WRITE setDroneHeading NOTIFY droneHeadingChanged)
    Q_PROPERTY(int roll MEMBER m_roll WRITE setRoll NOTIFY rollChanged)
    Q_PROPERTY(int pitch MEMBER m_pitch WRITE setPitch NOTIFY pitchChanged)

    Q_PROPERTY(int lateral MEMBER m_lateral WRITE setLateral NOTIFY lateralChanged)
    Q_PROPERTY(int vertical MEMBER m_vertical WRITE setVertical NOTIFY verticalChanged)

    Q_PROPERTY(int horizonSpacing MEMBER m_horizonSpacing WRITE setHorizonSpacing NOTIFY horizonSpacingChanged)
    Q_PROPERTY(double horizonWidth MEMBER m_horizonWidth WRITE setHorizonWidth NOTIFY horizonWidthChanged)
    Q_PROPERTY(double size MEMBER m_size WRITE setSize NOTIFY sizeChanged)

    Q_PROPERTY(QString name MEMBER m_name WRITE setName NOTIFY nameChanged)

    Q_PROPERTY(double verticalLimit MEMBER m_verticalLimit WRITE setVerticalLimit NOTIFY verticalLimitChanged)
    Q_PROPERTY(double lateralLimit MEMBER m_lateralLimit WRITE setLateralLimit NOTIFY lateralLimitChanged)

    Q_PROPERTY(QString fontFamily MEMBER m_fontFamily WRITE setFontFamily NOTIFY fontFamilyChanged)

public:
    explicit DrawingCanvas(QQuickItem* parent = nullptr);

    void paint(QPainter* painter) override;

    QColor color() const;
    QColor glow() const;

public slots:
    void setColor(QColor color);
    void setGlow(QColor glow);
    void setFpvInvertPitch(bool fpvInvertPitch);
    void setFpvInvertRoll(bool fpvInvertRoll);

    void setAlt(int alt);
    void setAltText(QString alt_text);
    void setDroneAlt(int drone_alt);
    void setSpeed(int speed);
    void setSpeedText(QString speed_text);
    void setVertSpd(int vert_spd);
    void setHeading(int heading);
    void setDroneHeading(int drone_heading);
    void setRoll(int roll);
    void setPitch(int pitch);

    void setLateral(int lateral);
    void setVertical(int vertical);

    void setHorizonSpacing(int horizonSpacing);
    void setHorizonWidth(double horizonWidth);
    void setSize(double size);

    void setName(QString name);

    void setVerticalLimit(double verticalLimit);
    void setLateralLimit(double lateralLimit);

    void setFontFamily(QString fontFamily);

signals:
    void colorChanged(QColor color);
    void glowChanged(QColor glow);
    void fpvInvertPitchChanged(bool fpvInvertPitch);
    void fpvInvertRollChanged(bool fpvInvertRoll);

    void altChanged(int alt);
    void altTextChanged(QString alt_text);
    void droneAltChanged(int drone_alt);
    void speedChanged(int speed);
    void speedTextChanged(QString speed_text);
    void vertSpdChanged(int vert_spd);
    void headingChanged(int heading);
    void droneHeadingChanged(int drone_heading);
    void rollChanged(int roll);
    void pitchChanged(int pitch);

    void lateralChanged(int lateral);
    void verticalChanged(int vertical);

    void horizonSpacingChanged(int horizonSpacing);
    void horizonWidthChanged(double horizonWidth);
    void sizeChanged(double size);

    void nameChanged(QString name);

    void verticalLimitChanged(double verticalLimit);
    void lateralLimitChanged(double lateralLimit);

    void fontFamilyChanged(QString fontFamily);

private:
    QColor m_color;
    QColor m_glow;
    bool m_fpvInvertPitch;
    bool m_fpvInvertRoll;

    int m_heading;
    int m_drone_heading;
    int m_alt;
    QString m_alt_text;
    int m_drone_alt;
    int m_speed;
    QString m_speed_text;
    int m_vert_spd;
    int m_roll;
    int m_pitch;

    int m_lateral;
    int m_vertical;

    int m_horizonSpacing;
    double m_horizonWidth;
    double m_size;

    QString m_name;

    double m_verticalLimit;
    double m_lateralLimit;
//TODO fix setting reference
    //QSettings settings;
    bool imperial;

    int m_orientation=0;

    QString m_fontFamily;

    QString m_draw_request="adsb"; //for future build out of more draw requests

    QFont m_font = QFont("Font Awesome 5 Free", 10, QFont::Bold, false);
    QFont m_fontNormal = QFont("osdicons", 25 , QFont::PreferAntialias, true);
    //QFont m_fontBig = QFont("osdicons", 25*1.1, QFont::PreferAntialias, true);

};
