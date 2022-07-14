#ifndef DECODINGSTATISTCS_H
#define DECODINGSTATISTCS_H

#include <QObject>

/**
 * @brief Simple QT model (signals) to expose QOpenHD decoding statistics to the UI.
 */
class DecodingStatistcs : public QObject
{
    Q_OBJECT
public:
    explicit DecodingStatistcs(QObject *parent = nullptr);
signals:

};

#endif // DECODINGSTATISTCS_H
