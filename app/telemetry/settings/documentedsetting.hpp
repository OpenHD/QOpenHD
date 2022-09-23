#ifndef DOCUMENTEDSETTING_H
#define DOCUMENTEDSETTING_H

#include <string>
#include <vector>
#include <limits>
#include <assert.h>
#include <qdebug.h>
#include <sstream>


// This is a "one type fits all class" where we can make changing specific setting(s)
// more comfortable for the user.
// Int: We can either specify a range (min and max value) or we can additionally make this an enum

// Int parameters can have a range ([min_value,max_value] or even refer to an enum -
// in which case they have a range and also expose the functionality to convert an int value (e.g. a value that
// is not verbose to the user) into a string that is verbose to the user, or the other way around.
// E.g. For video, 0==h264, 1==h265 and 2==mjpeg. => like a enum ;)
// (but we cannot have compile time safety int this case, because the UI is in .qml)
// We also commonly use a enum if we have an int that has a range of [0,1] -> aka disable / enable
class ImprovedIntSetting{
public:
    //r.n no params that can take negative values
    static ImprovedIntSetting createRangeOnly(int min_value=0,int max_value=std::numeric_limits<int>::max()){
        return ImprovedIntSetting(min_value,max_value,{});
    }
    static ImprovedIntSetting createEnum(std::vector<std::string> values){
        // single enum would make no sense ?!
        assert(values.size()>1);
        return ImprovedIntSetting(0,values.size()-1,values);
    }
    static ImprovedIntSetting createEnumEnableDisable(){
        std::vector<std::string> values{};
        values.push_back("Disable"); // False == disabled == 0
        values.push_back("Enable"); // 1==enabled
        return createEnum(values);
    }
public:
    ImprovedIntSetting(int min_value_int,int max_value_int,std::vector<std::string> values_enum):
        min_value_int(min_value_int),max_value_int(max_value_int),values_enum(values_enum){
    }
    ImprovedIntSetting()=default;
   int min_value_int;
   int max_value_int;
   // wrapped int enum
   std::vector<std::string> values_enum;
   //
   bool is_in_range(int value)const{
       return value>=min_value_int && value <=max_value_int;
   }
   // return true if we can do enum mapping for this int (more verbose to the user)
   bool has_enum_mapping()const{
       return !values_enum.empty();
   }
   // enum mapping, returns "unknwon" if value is not in range.
   std::string enum_value_to_string(int value)const{
       if(!is_in_range(value)){
           std::stringstream ss;
           ss<<"?{"<<value<<"}?";
           return ss.str();
       }
       return values_enum.at(value);
   }
   int enum_value_from_string(std::string value)const{
       for(int i=0;i<values_enum.size();i++){
           if(values_enum.at(i)==value)return i;
       }
       qDebug()<<"ImprovedIntSetting::enum_value_to_string not found, return 0";
       return 0;
   }
};



#endif // DOCUMENTEDSETTING_H
