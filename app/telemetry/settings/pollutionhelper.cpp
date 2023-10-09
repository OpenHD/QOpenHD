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


void PollutionHelper::threadsafe_update(const std::vector<PollutionElement> &values)
{
    std::lock_guard<std::mutex> lock(m_pollution_elements_mutex);
    m_pollution_elements.clear();
    for(const auto& value:values){
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
