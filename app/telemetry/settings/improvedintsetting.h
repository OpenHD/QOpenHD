#ifndef DOCUMENTEDSETTING_H
#define DOCUMENTEDSETTING_H

#include <string>
#include <vector>
#include <limits>
#include <assert.h>
#include <qdebug.h>
#include <sstream>


// This is a "one type fits many class" where we can make changing specific int setting(s)
// more comfortable for the user.
// Int parameters can have a range ([min_value,max_value] or even refer to an enum -
// in which case they have a range and also expose the functionality to convert an int value (e.g. a value that
// is not verbose to the user) into a string that is verbose to the user, or the other way around.
// E.g. For video, 0==h264, 1==h265 and 2==mjpeg. => like a enum ;)
// (but we cannot have compile time safety int this case, because the UI is in .qml)
// We also commonly use a enum if we have an int that has a range of [0,1] -> aka disable / enable
class ImprovedIntSetting{
public:
    // For normal enums, we default to increasing values starting at 0, but some parameters
    // (e.g. baud rate) require a type of enum where the first value is not 0, but (as an example) 9600baud
    struct Item{
        std::string name;
        int value;
    };
    ImprovedIntSetting(int min_value_int,int max_value_int,std::vector<Item> values_enum1);
    ImprovedIntSetting(const ImprovedIntSetting& other);
public:
    // helper to create a mapping where first element =0,second element =1, ...
    static std::vector<Item> convert_to_default_items(const std::vector<std::string>& values);

    //r.n no params that can take negative values
    static ImprovedIntSetting createRangeOnly(int min_value=0,int max_value=std::numeric_limits<int>::max());
    //
    static ImprovedIntSetting createEnum(std::vector<std::string> values);
    // helper for an enum where 0==Disable and 1==Enable
    static ImprovedIntSetting createEnumEnableDisable();

    static ImprovedIntSetting createEnumSimple(std::vector<std::pair<std::string,int>> values);
public:
   // return true if we can do enum mapping for this int (more verbose to the user)
   bool has_enum_mapping()const{
       return !values_enum.empty();
   }
   // enum mapping, returns the int value as a string (wrapped in ?{..}) if we cannot find
   // a mapping for it
   std::string value_to_string(int value)const{
       for(const auto& item:values_enum){
           if(item.value==value)return item.name;
       }
       std::stringstream ss;
       ss<<"?{"<<value<<"}?";
       return ss.str();
   }
   QStringList int_enum_keys()const{
       QStringList ret{};
       for(const auto& item:values_enum){
            ret.append(QString{item.name.c_str()});
       }
       return ret;
   }
   QList<int> int_enum_values()const{
       QList<int> ret;
       for(const auto& item:values_enum){
            ret.append(item.value);
       }
       return ret;
   }
public:
   int min_value_int;
   int max_value_int;
   // wrapped int enum
   std::vector<Item> values_enum{};
};



#endif // DOCUMENTEDSETTING_H
