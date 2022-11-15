#include "improvedstringsetting.h"

ImprovedStringSetting::ImprovedStringSetting(std::vector<Item> values):m_values_enum(values)
{

}

ImprovedStringSetting ImprovedStringSetting::create_from_keys_only(const std::vector<std::string> &keys){
    std::vector<Item> values{};
    for(const auto& key:keys){
        values.emplace_back(Item{key,key});
    }
    return ImprovedStringSetting{values};
}


QStringList ImprovedStringSetting::enum_keys() const{
    QStringList ret{};
    for(const auto& item:m_values_enum){
        ret.append(QString{item.key.c_str()});
    }
    return ret;
}

QStringList ImprovedStringSetting::enum_values() const{
    QStringList ret{};
    for(const auto& item:m_values_enum){
        ret.append(QString{item.value.c_str()});
    }
    return ret;
}
