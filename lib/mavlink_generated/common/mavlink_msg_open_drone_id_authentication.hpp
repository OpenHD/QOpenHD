// MESSAGE OPEN_DRONE_ID_AUTHENTICATION support class

#pragma once

namespace mavlink {
namespace common {
namespace msg {

/**
 * @brief OPEN_DRONE_ID_AUTHENTICATION message
 *
 * Data for filling the OpenDroneID Authentication message. The Authentication Message defines a field that can provide a means of authenticity for the identity of the UAS (Unmanned Aircraft System) sending the message.
 */
struct OPEN_DRONE_ID_AUTHENTICATION : mavlink::Message {
    static constexpr msgid_t MSG_ID = 12902;
    static constexpr size_t LENGTH = 25;
    static constexpr size_t MIN_LENGTH = 25;
    static constexpr uint8_t CRC_EXTRA = 254;
    static constexpr auto NAME = "OPEN_DRONE_ID_AUTHENTICATION";


    uint8_t authentication_type; /*<  Indicates the type of authentication. */
    uint8_t data_page; /*<  Allowed range is 0 - 15. */
    std::array<uint8_t, 23> authentication_data; /*<  Opaque authentication data. Sixteen pages are supported for a total of 16 * 23 = 368 bytes. Shall be filled with nulls in the unused portion of the field. */


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
        ss << "  authentication_type: " << +authentication_type << std::endl;
        ss << "  data_page: " << +data_page << std::endl;
        ss << "  authentication_data: [" << to_string(authentication_data) << "]" << std::endl;

        return ss.str();
    }

    inline void serialize(mavlink::MsgMap &map) const override
    {
        map.reset(MSG_ID, LENGTH);

        map << authentication_type;           // offset: 0
        map << data_page;                     // offset: 1
        map << authentication_data;           // offset: 2
    }

    inline void deserialize(mavlink::MsgMap &map) override
    {
        map >> authentication_type;           // offset: 0
        map >> data_page;                     // offset: 1
        map >> authentication_data;           // offset: 2
    }
};

} // namespace msg
} // namespace common
} // namespace mavlink
