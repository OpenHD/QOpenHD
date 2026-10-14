#include "pollutionhelper.h"

#include <qdebug.h>
#include <sstream>

PollutionHelper::PollutionHelper(QObject *parent) : QObject{parent}
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
        value.n_foreign_packets_normalized=value.n_foreign_packets < 0 ? -1 :
            (value.rf_sampled_busy ? value.n_foreign_packets : value.n_foreign_packets*100 / max);
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

QStringList PollutionHelper::pollution_frequencies_int_to_qstringlist(QList<int> frequencies)
{
    QStringList ret;
    for(auto& freq:frequencies){
        std::stringstream ss;
        ss<<freq<<"Mhz";
        auto pollution=threadsafe_get_pollution_for_frequency(freq);
        if(pollution.has_value()){
            /*if(pollution.value().n_foreign_packets<1){
                ss<<"\nFREE";
            }else{
                ss<<"\nPOLLUTED";
            }*/
            ret.push_back(QString(ss.str().c_str()));
        }else{
            //ss<<" N/A";
            //ret.push_back(QString(ss.str().c_str()));
            ret.push_back(" ");
        }
    }
    return ret;
}

QVariantList PollutionHelper::pollution_frequencies_int_get_pollution(QList<int> frequencies, bool normalize)
{
    QVariantList ret;
    for(auto& freq: frequencies){
        auto pollution=threadsafe_get_pollution_for_frequency(freq);
        if(pollution.has_value()){
            if(normalize){
                ret.push_back(static_cast<int>(pollution.value().n_foreign_packets_normalized));
            }else{
                /*if(pollution.value().n_foreign_packets<1){
                    ret.push_back(static_cast<int>(0));
                }else{
                    ret.push_back(static_cast<int>(100));
                }*/
                ret.push_back(static_cast<int>(pollution.value().n_foreign_packets));
            }

        }else{
            ret.push_back(static_cast<int>(0));
        }
    }
    return ret;
}

int PollutionHelper::pollution_get_last_scan_pollution_for_frequency(int frequency)
{
    auto tmp=threadsafe_get_pollution_for_frequency(frequency);
    if(tmp.has_value()){
        return tmp.value().n_foreign_packets;
    }
    return -1;
}

QVariantList PollutionHelper::survey_values(QList<int> frequencies, int metric)
{
    QVariantList values;
    for (int frequency : frequencies) {
        const auto sample = threadsafe_get_pollution_for_frequency(frequency);
        int value = -1;
        if (sample) {
            if (metric == 0) value = sample->nhm_env_percent;
            else if (metric == 1) value = sample->busy_percent;
            else if (metric == 2) value = sample->n_foreign_packets;
            else if (metric == 3) value = sample->n_foreign_packets_normalized;
        }
        values.push_back(value);
    }
    return values;
}

void PollutionHelper::decode_survey_metrics(PollutionElement& sample, uint16_t packed)
{
    sample.devourer_survey = true;
    if (packed == 0x3fff) {
        sample.n_foreign_packets = -1;
        sample.n_foreign_packets_normalized = -1;
    }
    const int nhm = (packed >> 7) & 0x7f;
    const int busy = packed & 0x7f;
    sample.nhm_env_percent = (packed & 0x8000) && nhm <= 100 ? nhm : -1;
    sample.busy_percent = (packed & 0x4000) && busy <= 100 ? busy : -1;
}

QStringList PollutionHelper::survey_labels(QList<int> frequencies, int metric)
{
    const auto values = survey_values(frequencies, metric);
    QStringList labels;
    for (int i = 0; i < frequencies.size(); ++i) {
        labels.push_back(QString::number(frequencies[i]) +
                         (values[i].toInt() < 0 ? " N/A" : " MHz"));
    }
    return labels;
}
