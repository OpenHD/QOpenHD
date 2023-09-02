#ifndef DOCUMENTEDPARAM_H
#define DOCUMENTEDPARAM_H

#include "improvedintsetting.h"
#include "improvedstringsetting.h"

#include <optional>
#include <string>



namespace DocumentedParam {

struct XParam{
    // each param has a unique name / ID.
    // must be valid string
    std::string param_name;
    // if param is of type int, it can have a mapping with verbose user choices
    std::optional<ImprovedIntSetting> improved_int;
    // if param is of type string, it can have a mapping with verbose user choices
    std::optional<ImprovedStringSetting> improved_string;
    // it has a short description
    std::string description;
    // and this flag (if set) says changing the parameter requires a (manual) reboot
    bool requires_reboot;
    // and this flag (if set) says the parameter is read-only (cannot be changed)
    bool is_read_only;
    XParam(std::string param_name1,std::optional<ImprovedIntSetting> improved_int1,std::optional<ImprovedStringSetting> improved_string1,
           std::string description1,bool requires_reboot1,bool is_read_only1): param_name(param_name1),improved_int(improved_int1),
        improved_string(improved_string1),description(description1),requires_reboot(requires_reboot1),is_read_only(is_read_only1){
    }
};

std::optional<XParam> find_param(const std::string& param_name);

std::optional<ImprovedIntSetting> get_improved_for_int(const std::string& param_id);

std::optional<ImprovedStringSetting> get_improved_for_string(const std::string param_id);

std::optional<std::string> int_param_to_enum_string_if_known(const std::string param_id,int value);
std::optional<std::string> string_param_to_enum_string_if_known(const std::string param_id,std::string value);

// By default, a param is not read-only
bool read_only(const std::string& param_name);

// By default, a param doesn't require reboot
bool requires_reboot(const std::string& param_name);

// Returns the param deocumentation if it exists,
// 'TODO' otherwise
std::string get_short_description(const std::string& param_name);

// extra, we whitelist some params, aka they should not be exposed in the param list to the user
// (since they are changed in a different part in the UI)
bool is_param_whitelisted(const std::string& param_id);

}


#endif // DOCUMENTEDPARAM_H
