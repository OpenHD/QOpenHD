#ifndef FREQUENCYHELPER_H
#define FREQUENCYHELPER_H

#include <vector>



class FrequencyHelper
{
public:
    FrequencyHelper();
    struct FrequencyItem{
        int channel_nr;
        int frequency;
        bool radar;
        bool simple;
        bool recommended;
        int openhd_raceband;
    };
    static std::vector<FrequencyItem> get_known_frequency_items();
    static FrequencyItem find_frequency_item(const int frequency);
};

#endif // FREQUENCYHELPER_H
