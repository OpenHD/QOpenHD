// MESSAGE OPEN_DRONE_ID_SYSTEM support class

#pragma once

namespace mavlink {
namespace common {
namespace msg {

/**
 * @brief OPEN_DRONE_ID_SYSTEM message
 *
 * Data for filling the OpenDroneID System message. The System Message contains general system information including the remote pilot location and possible aircraft group information.
 */
struct OPEN_DRONE_ID_SYSTEM : mavlink::Message {
    static constexpr msgid_t MSG_ID = 12904;
    static constexpr size_t LENGTH = 21;
    static constexpr size_t MIN_LENGTH = 21;
    static constexpr uint8_t CRC_EXTRA = 177;
    static constexpr auto NAME = "OPEN_DRONE_ID_SYSTEM";


    uint8_t flags; /*<  Specifies the location source for the remote pilot location. */
    int32_t remote_pilot_latitude; /*< [degE7] Latitude of the remote pilot. */
    int32_t remote_pilot_longitude; /*< [degE7] Longitude of the remote pilot. */
    uint16_t group_count; /*<  Number of aircraft in group or formation (default 0). */
    uint16_t group_radius; /*< [m] Radius of cylindrical area of group or formation (default 0). */
    float group_ceiling; /*< [m] Group Operations Ceiling relative to WGS84. */
    float group_floor; /*< [m] Group Operations Floor relative to WGS84. */


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
        ss << "  flags: " << +flags << std::endl;
        ss << "  remote_pilot_latitude: " << remote_pilot_latitude << std::endl;
        ss << "  remote_pilot_longitude: " << remote_pilot_longitude << std::endl;
        ss << "  group_count: " << group_count << std::endl;
        ss << "  group_radius: " << group_radius << std::endl;
        ss << "  group_ceiling: " << group_ceiling << std::endl;
        ss << "  group_floor: " << group_floor << std::endl;

        return ss.str();
    }

    inline void serialize(mavlink::MsgMap &map) const override
    {
        map.reset(MSG_ID, LENGTH);

        map << remote_pilot_latitude;         // offset: 0
        map << remote_pilot_longitude;        // offset: 4
        map << group_ceiling;                 // offset: 8
        map << group_floor;                   // offset: 12
        map << group_count;                   // offset: 16
        map << group_radius;                  // offset: 18
        map << flags;                         // offset: 20
    }

    inline void deserialize(mavlink::MsgMap &map) override
    {
        map >> remote_pilot_latitude;         // offset: 0
        map >> remote_pilot_longitude;        // offset: 4
        map >> group_ceiling;                 // offset: 8
        map >> group_floor;                   // offset: 12
        map >> group_count;                   // offset: 16
        map >> group_radius;                  // offset: 18
        map >> flags;                         // offset: 20
    }
};

} // namespace msg
} // namespace common
} // namespace mavlink
