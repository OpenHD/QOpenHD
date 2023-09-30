#ifndef IMPROVEDSTRINGSETTING_H
#define IMPROVEDSTRINGSETTING_H

#include <QStringList>
#include <string>
#include <vector>
#include <optional>

/**
 * For a string setting it makes less sense to use both a key and value - but we do it anyways for the future.
 * E.g. the following might happen:
 * we display "serial0" to the user, but the param value this refers to is "/dev/ttyS0"
 */
class ImprovedStringSetting{
public:
    struct Item{
        std::string key;
        std::string value;
    };
    ImprovedStringSetting(std::vector<Item> values);
    ImprovedStringSetting(const ImprovedStringSetting& other);
    // if key and value are the same
    static ImprovedStringSetting create_from_keys_only(const std::vector<std::string>& keys);
public:
    QStringList enum_keys()const;

    QStringList enum_values()const;

    std::optional<std::string> value_to_key(const std::string& value)const;
    std::optional<std::string> key_to_value(const std::string& key)const;
private:
    std::vector<Item> m_values_enum{};
};

#endif // IMPROVEDSTRINGSETTING_H
