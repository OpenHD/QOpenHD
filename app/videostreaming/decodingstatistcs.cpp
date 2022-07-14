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

void DecodingStatistcs::set_bitrate(int bitrate)
{
    m_bitrate=bitrate;
    emit bitrate_changed(bitrate);
}
