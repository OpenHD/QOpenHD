#include "pollutionhelper.h"

#include <qdebug.h>

PollutionHelper::PollutionHelper()
{

}

PollutionHelper& PollutionHelper::instance()
{
    static PollutionHelper instance;
    return instance;
}

static std::vector<PollutionHelper::PollutionElement> normalize(const std::vector<PollutionHelper::PollutionElement> &values){
    int max=0;
    for(const auto& value:values){
        max=std::max(max,value.n_foreign_packets);
    }
    if(max==0)return values;
    std::vector<PollutionHelper::PollutionElement> ret;
    for(auto value:values){
        value.n_foreign_packets_normalized=value.n_foreign_packets*100 / max;
        //value.n_foreign_packets=value.n_foreign_packets*100 / max;
        ret.push_back(value);
    }
    return ret;

}

void PollutionHelper::threadsafe_update(const std::vector<PollutionElement> &values)
{
    const auto normalized=normalize(values);
    std::lock_guard<std::mutex> lock(m_pollution_elements_mutex);
    m_pollution_elements.clear();
    //for(const auto& value:values){
    for(const auto& value:normalized){
        m_pollution_elements[value.frequency_mhz]=value;
        //qDebug()<<"Value:"<<value.frequency_mhz;
    }
}

std::optional<PollutionHelper::PollutionElement> PollutionHelper::threadsafe_get_pollution_for_frequency(int frequency)
{
    std::lock_guard<std::mutex> lock(m_pollution_elements_mutex);
    auto search = m_pollution_elements.find(frequency);
    if(search != m_pollution_elements.end()){
        return search->second;
    }
    //qDebug()<<"Cannot find pollution for "<<frequency;
    return std::nullopt;
}
