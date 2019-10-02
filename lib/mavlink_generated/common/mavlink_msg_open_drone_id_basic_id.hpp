// MESSAGE OPEN_DRONE_ID_BASIC_ID support class

#pragma once

namespace mavlink {
namespace common {
namespace msg {

/**
 * @brief OPEN_DRONE_ID_BASIC_ID message
 *
 * Data for filling the OpenDroneID Basic ID message.
 */
struct OPEN_DRONE_ID_BASIC_ID : mavlink::Message {
    static constexpr msgid_t MSG_ID = 12900;
    static constexpr size_t LENGTH = 22;
    static constexpr size_t MIN_LENGTH = 22;
    static constexpr uint8_t CRC_EXTRA = 197;
    static constexpr auto NAME = "OPEN_DRONE_ID_BASIC_ID";


    uint8_t id_type; /*<  Indicates the format for the uas_id field of this message. */
    uint8_t ua_type; /*<  Indicates the type of UA (Unmanned Aircraft). */
    std::array<uint8_t, 20> uas_id; /*<  UAS ID following the format specified by id_type. Shall be filled with nulls in the unused portion of the field. */


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
        ss << "  id_type: " << +id_type << std::endl;
        ss << "  ua_type: " << +ua_type << std::endl;
        ss << "  uas_id: [" << to_string(uas_id) << "]" << std::endl;

        return ss.str();
    }

    inline void serialize(mavlink::MsgMap &map) const override
    {
        map.reset(MSG_ID, LENGTH);

        map << id_type;                       // offset: 0
        map << ua_type;                       // offset: 1
        map << uas_id;                        // offset: 2
    }

    inline void deserialize(mavlink::MsgMap &map) override
    {
        map >> id_type;                       // offset: 0
        map >> ua_type;                       // offset: 1
        map >> uas_id;                        // offset: 2
    }
};

} // namespace msg
} // namespace common
} // namespace mavlink
