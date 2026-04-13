#pragma once

namespace openhd {

// Keep in sync with OpenHD/ohd_interface/inc/wifi_card.h
enum class WiFiCardType : int {
    OPENHD_RTL_88X2AU = 0,
    OPENHD_RTL_88X2BU = 1,
    OPENHD_RTL_88X2CU = 2,
    OPENHD_RTL_88X2EU = 3,
    RTL_88X2AU = 4,
    RTL_88X2BU = 5,
    ATHEROS = 6,
    MT_7921u = 7,
    RALINK = 8,
    INTEL = 9,
    BROADCOM = 10,
    OPENHD_RTL_8852BU = 11,
    OPENHD_EMULATED = 12,
    AIC = 13,
    QUALCOMM = 14,
    UNKNOWN = 15,
    ARTOSYN = 16
};

constexpr int wifi_card_type_to_int(const WiFiCardType card_type) {
    return static_cast<int>(card_type);
}

}  // namespace openhd
