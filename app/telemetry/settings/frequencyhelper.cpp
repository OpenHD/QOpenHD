#include "frequencyhelper.h"

FrequencyHelper::FrequencyHelper()
{

}

std::vector<FrequencyHelper::FrequencyItem> FrequencyHelper::get_known_frequency_items()
{
    std::vector<FrequencyItem> ret{
        FrequencyItem{-1,2312,false,false,false,-1},
        FrequencyItem{-1,2332,false,false,false,-1},
        FrequencyItem{-1,2352,false,false,false,-1},
        FrequencyItem{-1,2372,false,false,false,-1},
        FrequencyItem{-1,2392,false,false,false,-1},
        // ACTUAL 2G
        FrequencyItem{1 ,2412,false,true,false,-1},
        FrequencyItem{5 ,2432,false,true,false,-1},
        FrequencyItem{9 ,2452,false,true,false,-1},
        FrequencyItem{13,2472,false,true,false,-1},
        FrequencyItem{14,2484,false,false,false,-1},
        // ACTUAL 2G end
        FrequencyItem{-1,2492,false,false,false,-1},
        FrequencyItem{-1,2512,false,false,false,-1},
        FrequencyItem{-1,2532,false,false,false,-1},
        FrequencyItem{-1,2572,false,false,false,-1},
        FrequencyItem{-1,2592,false,false,false,-1},
        FrequencyItem{-1,2612,false,false,false,-1},
        FrequencyItem{-1,2632,false,false,false,-1},
        FrequencyItem{-1,2652,false,false,false,-1},
        FrequencyItem{-1,2672,false,false,false,-1},
        FrequencyItem{-1,2692,false,false,false,-1},
        FrequencyItem{-1, 2712,false,false,false,-1},
        // 5G begin
        FrequencyItem{ 32,5160,false,false,false,-1},
        FrequencyItem{ 36,5180,false,true ,false,-1},
        FrequencyItem{ 40,5200,false,false,false,-1},
        FrequencyItem{ 44,5220,false,true,false,-1},
        FrequencyItem{ 48,5240,false,false,false,-1},
        FrequencyItem{ 52,5260,true,true ,false,-1},
        FrequencyItem{ 56,5280,true,false,false,-1},
        FrequencyItem{ 60,5300,true,true,false,-1},
        FrequencyItem{ 64,5320,true,false,false,-1},
        // big break / part that is not allowed
        FrequencyItem{100,5500,true,true,false,-1},
        FrequencyItem{104,5520,true,false,false,-1},
        FrequencyItem{108,5540,true,true,false,-1},
        FrequencyItem{112,5560,true,false,false,-1},
        FrequencyItem{116,5580,true,true,false,-1},
        FrequencyItem{120,5600,true,false,false,-1},
        FrequencyItem{124,5620,true,true,false,-1},
        FrequencyItem{128,5640,true,false,false,-1},
        FrequencyItem{132,5660,true,true,false,-1},
        FrequencyItem{136,5680,true,false,false,-1},
        FrequencyItem{140,5700,false,true,false,1},
        FrequencyItem{144,5720,false,false,false,-1},
        // Here is the weird break
        FrequencyItem{149,5745,false,true,true,2},
        FrequencyItem{153,5765,false,false,false,-1},
        FrequencyItem{157,5785,false,true,true,3},
        FrequencyItem{161,5805,false,false,false,-1},
        FrequencyItem{165,5825,false,true,true,4},
        // Depends
        FrequencyItem{169,5845,false,false,false,-1},
        FrequencyItem{173,5865,false,true,true,5},
        FrequencyItem{177,5885,false,false,false,-1},
        FrequencyItem{181,5905,false,false,true,-1}
    };
    return ret;
}

FrequencyHelper::FrequencyItem FrequencyHelper::find_frequency_item(const int frequency)
{
    const auto frequency_items=get_known_frequency_items();
    for(const auto& item:frequency_items){
        if(item.frequency==frequency)return item;
    }
    return FrequencyItem{-1,-1,false,false,false};
}
