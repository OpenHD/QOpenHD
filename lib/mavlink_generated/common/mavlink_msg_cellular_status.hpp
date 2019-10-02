// MESSAGE CELLULAR_STATUS support class

#pragma once

namespace mavlink {
namespace common {
namespace msg {

/**
 * @brief CELLULAR_STATUS message
 *
 * Report current used cellular network status
 */
struct CELLULAR_STATUS : mavlink::Message {
    static constexpr msgid_t MSG_ID = 334;
    static constexpr size_t LENGTH = 14;
    static constexpr size_t MIN_LENGTH = 14;
    static constexpr uint8_t CRC_EXTRA = 135;
    static constexpr auto NAME = "CELLULAR_STATUS";


    uint16_t status; /*<  Status bitmap */
    uint8_t type; /*<  Cellular network radio type: gsm, cdma, lte... */
    uint8_t quality; /*<  Cellular network RSSI/RSRP in dBm, absolute value */
    uint16_t mcc; /*<  Mobile country code. If unknown, set to: UINT16_MAX */
    uint16_t mnc; /*<  Mobile network code. If unknown, set to: UINT16_MAX */
    uint16_t lac; /*<  Location area code. If unknown, set to: 0 */
    uint32_t cid; /*<  Cell ID. If unknown, set to: UINT32_MAX */


    inline std::string get_name(void) const override
    {
            return NAME;
    }

    inline Info get_message_info(void) const override
    {
            return { MSG_ID, LENGTH, MIN_LENGTH, CRC_EXTRA };
    }

    inline std::string to_yaml(void) const override
    {
        std::stringstream ss;

        ss << NAME << ":" << std::endl;
        ss << "  status: " << status << std::endl;
        ss << "  type: " << +type << std::endl;
        ss << "  quality: " << +quality << std::endl;
        ss << "  mcc: " << mcc << std::endl;
        ss << "  mnc: " << mnc << std::endl;
        ss << "  lac: " << lac << std::endl;
        ss << "  cid: " << cid << std::endl;

        return ss.str();
    }

    inline void serialize(mavlink::MsgMap &map) const override
    {
        map.reset(MSG_ID, LENGTH);

        map << cid;                           // offset: 0
        map << status;                        // offset: 4
        map << mcc;                           // offset: 6
        map << mnc;                           // offset: 8
        map << lac;                           // offset: 10
        map << type;                          // offset: 12
        map << quality;                       // offset: 13
    }

    inline void deserialize(mavlink::MsgMap &map) override
    {
        map >> cid;                           // offset: 0
        map >> status;                        // offset: 4
        map >> mcc;                           // offset: 6
        map >> mnc;                           // offset: 8
        map >> lac;                           // offset: 10
        map >> type;                          // offset: 12
        map >> quality;                       // offset: 13
    }
};

} // namespace msg
} // namespace common
} // namespace mavlink
