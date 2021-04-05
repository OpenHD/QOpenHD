#include <QQuickItem>
#include <QQuickPaintedItem>
#include <QPainter>

#include "openhd.h"

class VROverlay : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(QColor glow READ glow WRITE setGlow NOTIFY glowChanged)
    Q_PROPERTY(bool vroverlayInvertPitch MEMBER m_vroverlayInvertPitch WRITE setVROverlayInvertPitch NOTIFY vroverlayInvertPitchChanged)
    Q_PROPERTY(bool vroverlayInvertRoll MEMBER m_vroverlayInvertRoll WRITE setVROverlayInvertRoll NOTIFY vroverlayInvertRollChanged)

    Q_PROPERTY(int roll MEMBER m_roll WRITE setRoll NOTIFY rollChanged)
    Q_PROPERTY(int pitch MEMBER m_pitch WRITE setPitch NOTIFY pitchChanged)

    Q_PROPERTY(QString type MEMBER m_type WRITE setType NOTIFY typeChanged)
    Q_PROPERTY(QString name MEMBER m_name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(double lat MEMBER m_lat WRITE setLat NOTIFY latChanged)
    Q_PROPERTY(double lon MEMBER m_lon WRITE setLon NOTIFY lonChanged)
    Q_PROPERTY(int alt MEMBER m_alt WRITE setAlt NOTIFY altChanged)
    Q_PROPERTY(int speed MEMBER m_speed WRITE setSpeed NOTIFY speedChanged)
    Q_PROPERTY(double vert MEMBER m_vert WRITE setVert NOTIFY vertChanged)

    Q_PROPERTY(double vroverlaySize MEMBER m_vroverlaySize WRITE setVROverlaySize NOTIFY vroverlaySizeChanged)

    Q_PROPERTY(double verticalFOV MEMBER m_verticalFOV WRITE setVerticalFOV NOTIFY verticalFOVChanged)
    Q_PROPERTY(double horizontalFOV MEMBER m_horizontalFOV WRITE setHorizontalFOV NOTIFY horizontalFOVChanged)

    Q_PROPERTY(QString fontFamily MEMBER m_fontFamily WRITE setFontFamily NOTIFY fontFamilyChanged)

public:
    explicit VROverlay(QQuickItem* parent = nullptr);

    void paint(QPainter* painter) override;

    QColor color() const;
    QColor glow() const;

public slots:
    void setColor(QColor color);
    void setGlow(QColor glow);
    void setVROverlayInvertPitch(bool vroverlayInvertPitch);
    void setVROverlayInvertRoll(bool vroverlayInvertRoll);

    void setRoll(int roll);
    void setPitch(int pitch);

    void setType(QString type);
    void setName(QString name);
    void setLat(double lat);
    void setLon(double lon);
    void setAlt(int alt);
    void setSpeed(int speed);
    void setVert(double vert);

    void setVROverlaySize(double vroverlaySize);

    void setVerticalFOV(double verticalFOV);
    void setHorizontalFOV(double horizontalFOV);

    void setFontFamily(QString fontFamily);

signals:
    void colorChanged(QColor color);
    void glowChanged(QColor glow);
    void vroverlayInvertPitchChanged(bool vroverlayInvertPitch);
    void vroverlayInvertRollChanged(bool vroverlayInvertRoll);

    void rollChanged(int roll);
    void pitchChanged(int pitch);

    void typeChanged(QString type);
    void nameChanged(QString name);
    void latChanged(double lat);
    void lonChanged(double lon);
    void altChanged(int alt);
    void speedChanged(int speed);
    void vertChanged(double vert);

    void vroverlaySizeChanged(double vroverlaySize);

    void verticalFOVChanged(double verticalFOV);
    void horizontalFOVChanged(double horizontalFOV);

    void fontFamilyChanged(QString fontFamily);

private:
    QColor m_color;
    QColor m_glow;
    bool m_vroverlayInvertPitch;
    bool m_vroverlayInvertRoll;

    int m_roll;
    int m_pitch;

    QString m_type;
    QString m_name;
    double m_lat;
    double m_lon;
    int m_alt;
    int m_speed;
    double m_vert;

    double m_vroverlaySize;

    double m_verticalFOV=90;
    double m_horizontalFOV=90;

    QString m_fontFamily;

    QFont m_font;

    QFont m_fontAwesome = QFont("Font Awesome 5 Free", 14, QFont::Bold, false);

    int findX(double lat , double lon , int horizontalFOV);
    int findY(double distance  , double altAdsb, int verticalFOV);

    double calculateMeterDistance(double lat_2, double lon_2);
    double deg2rad(double deg);

    //racing stuff
    int m_current_gate;
    int m_gate_int;
    double m_alt_diff;
};
