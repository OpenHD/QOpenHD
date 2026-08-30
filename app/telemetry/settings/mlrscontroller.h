#ifndef MLRSCONTROLLER_H
#define MLRSCONTROLLER_H

#include <QObject>
#include <QElapsedTimer>
#include <QHash>
#include <QTimer>

#include "tutil/mavlink_include.h"

// User-facing controller for the MAVLink component built into an mLRS Tx.
// mLRS uses the legacy, byte-wise PARAM_* microservice on system 51,
// component MAV_COMP_ID_TELEMETRY_RADIO (68).
class MLRSController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool alive READ alive NOTIFY aliveChanged)
    Q_PROPERTY(bool parametersLoaded READ parametersLoaded NOTIFY parametersLoadedChanged)
    Q_PROPERTY(int txPower READ txPower NOTIFY parametersChanged)
    Q_PROPERTY(int rxPower READ rxPower NOTIFY parametersChanged)
    Q_PROPERTY(int mode READ mode NOTIFY parametersChanged)
    Q_PROPERTY(int rfBand READ rfBand NOTIFY parametersChanged)
    Q_PROPERTY(int rfOrtho READ rfOrtho NOTIFY parametersChanged)
    Q_PROPERTY(QString bindPhrase READ bindPhrase NOTIFY parametersChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusTextChanged)

public:
    static MLRSController &instance();

    bool process_message(const mavlink_message_t &msg);

    bool alive() const { return m_alive; }
    bool parametersLoaded() const { return m_parameters_loaded; }
    int txPower() const { return parameter_value("TX_POWER"); }
    int rxPower() const { return parameter_value("RX_POWER"); }
    int mode() const { return parameter_value("MODE"); }
    int rfBand() const { return parameter_value("RF_BAND"); }
    int rfOrtho() const { return parameter_value("RF_ORTHO"); }
    QString bindPhrase() const;
    QString statusText() const { return m_status_text; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE bool applySettings(int tx_power, int rx_power, int mode,
                                   int rf_band, int rf_ortho,
                                   const QString &bind_phrase);
    Q_INVOKABLE bool save();

signals:
    void aliveChanged();
    void parametersLoadedChanged();
    void parametersChanged();
    void statusTextChanged();

private:
    explicit MLRSController(QObject *parent = nullptr);

    struct Parameter {
        qint64 value = 0;
        uint8_t type = MAV_PARAM_TYPE_UINT8;
    };

    static constexpr uint8_t SYSTEM_ID = 51;
    static constexpr uint8_t COMPONENT_ID = MAV_COMP_ID_TELEMETRY_RADIO;

    int parameter_value(const char *name) const;
    void set_alive(bool alive);
    void set_status_text(const QString &text);
    bool set_parameter(const char *name, qint64 value, uint8_t fallback_type);
    static qint64 decode_value(float encoded, uint8_t type);
    static float encode_value(qint64 value, uint8_t type);
    static QString decode_bind_phrase(quint32 value);
    static bool encode_bind_phrase(const QString &phrase, quint32 &value);

    QHash<QString, Parameter> m_parameters;
    QElapsedTimer m_last_seen;
    QTimer m_alive_timer;
    bool m_alive = false;
    bool m_parameters_loaded = false;
    bool m_requested_parameters = false;
    QString m_status_text = QStringLiteral("mLRS not detected");
};

#endif // MLRSCONTROLLER_H
