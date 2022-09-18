//
// Created by consti10 on 16.02.22.
//

#ifndef HELLO_DRMPRIME_LOGGER_H
#define HELLO_DRMPRIME_LOGGER_H

#include <iostream>
#include <sstream>

class Logger{
public:
    Logger()=default;
    ~Logger(){
        const auto str=stream.str();
        if(!str.empty()){
            if(str.back()!='\n'){
                stream<<"\n";
                std::cout<<stream.str();
            }else{
                std::cout<<str;
            }
        }
    }
    Logger(const Logger& other)=delete;
private:
    std::stringstream stream;
    // the non-member function operator<< will now have access to private members
    template <typename T>
    friend Logger& operator<<(Logger& record, T&& t);
};
template <typename T>
Logger& operator<<(Logger& record, T&& t) {
    record.stream << std::forward<T>(t);
    return record;
}
template <typename T>
Logger& operator<<(Logger&& record, T&& t) {
    return record << std::forward<T>(t);
}

#define MLOGD Logger()

#endif //HELLO_DRMPRIME_LOGGER_H
