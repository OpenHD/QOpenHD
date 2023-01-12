#include "decodingstatistcs.h"

DecodingStatistcs::DecodingStatistcs(QObject *parent)
    : QObject{parent}
{

}

DecodingStatistcs& DecodingStatistcs::instance()
{
    static DecodingStatistcs stats{};
    return stats;
}

