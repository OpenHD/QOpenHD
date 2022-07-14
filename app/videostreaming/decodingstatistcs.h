#ifndef DECODINGSTATISTCS_H
#define DECODINGSTATISTCS_H

#include <QObject>

/**
 * @brief Simple QT model (signals) to expose QOpenHD decoding statistics to the UI.
 * singleton, corresponding qt name is "_decodingStatistics" (see main)
 */
class DecodingStatistcs : public QObject
{
    Q_OBJECT
public:
    explicit DecodingStatistcs(QObject *parent = nullptr);
    static DecodingStatistcs& instance();
public:
    Q_PROPERTY(int bitrate MEMBER m_bitrate WRITE set_bitrate NOTIFY bitrate_changed)
    void set_bitrate(int bitrate);
signals:
    void bitrate_changed(int bitrate);
public:
    int m_bitrate=100;
};

#endif // DECODINGSTATISTCS_H
