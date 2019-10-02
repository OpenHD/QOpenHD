// MESSAGE OPEN_DRONE_ID_SELFID support class

#pragma once

namespace mavlink {
namespace common {
namespace msg {

/**
 * @brief OPEN_DRONE_ID_SELFID message
 *
 * Data for filling the OpenDroneID Self-ID message. The Self-ID Message is an opportunity for the Remote Pilot to (optionally) declare their identity and purpose of the flight. This message can provide additional information that could reduce the threat profile of a UA flying in a particular area or manner.
 */
struct OPEN_DRONE_ID_SELFID : mavlink::Message {
    static constexpr msgid_t MSG_ID = 12903;
    static constexpr size_t LENGTH = 24;
    static constexpr size_t MIN_LENGTH = 24;
    static constexpr uint8_t CRC_EXTRA = 207;
    static constexpr auto NAME = "OPEN_DRONE_ID_SELFID";


    uint8_t description_type; /*<  Indicates the type of the description field. */
    std::array<char, 23> description; /*<  Text description or numeric value expressed as ASCII characters. Shall be filled with nulls in the unused portion of the field. */


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
        ss << "  description_type: " << +description_type << std::endl;
        ss << "  description: \"" << to_string(description) << "\"" << std::endl;

        return ss.str();
    }

    inline void serialize(mavlink::MsgMap &map) const override
    {
        map.reset(MSG_ID, LENGTH);

        map << description_type;              // offset: 0
        map << description;                   // offset: 1
    }

    inline void deserialize(mavlink::MsgMap &map) override
    {
        map >> description_type;              // offset: 0
        map >> description;                   // offset: 1
    }
};

} // namespace msg
} // namespace common
} // namespace mavlink
