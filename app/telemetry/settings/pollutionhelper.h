#ifndef POLLUTIONHELPER_H
#define POLLUTIONHELPER_H

#include <map>
#include <mutex>
#include <optional>
#include <qobject.h>
#include <vector>
#include <qvariant.h>
#include <qstringlist.h>

// Written by telemetry, read by UI
// This atomic behaviour is enough for us - we signal the ui to rebuild itself every time the data changes
// The OpenHD ground unit broadcast the whole pollution set during channel scan, filling it as the scan proceeds.
class PollutionHelper: public QObject
{
    Q_OBJECT
public:
    explicit PollutionHelper(QObject *parent = nullptr);
    static PollutionHelper& instance();
public:
    struct PollutionElement{
        int frequency_mhz;
        int width_mhz;
        int n_foreign_packets;
        int n_foreign_packets_normalized;
    };
    void threadsafe_update(const std::vector<PollutionElement>& values);
    std::optional<PollutionElement> threadsafe_get_pollution_for_frequency(int frequency);
public:
    Q_INVOKABLE QStringList pollution_frequencies_int_to_qstringlist(QList<int> frequencies);
    Q_INVOKABLE QVariantList pollution_frequencies_int_get_pollution(QList<int> frequencies,bool normalize=false);
    Q_INVOKABLE int pollution_get_last_scan_pollution_for_frequency(int frequency);
private:
    // Written by telemetry, read by UI
    std::map<int,PollutionElement> m_pollution_elements;
    std::mutex m_pollution_elements_mutex;
};


#endif // POLLUTIONHELPER_H
