// MESSAGE MISSION_CHANGED support class

#pragma once

namespace mavlink {
namespace common {
namespace msg {

/**
 * @brief MISSION_CHANGED message
 *
 * A broadcast message to notify any ground station or SDK if a mission, geofence or safe points have changed on the vehicle.
 */
struct MISSION_CHANGED : mavlink::Message {
    static constexpr msgid_t MSG_ID = 52;
    static constexpr size_t LENGTH = 7;
    static constexpr size_t MIN_LENGTH = 7;
    static constexpr uint8_t CRC_EXTRA = 132;
    static constexpr auto NAME = "MISSION_CHANGED";


    int16_t start_index; /*<  Start index for partial mission change (-1 for all items). */
    int16_t end_index; /*<  End index of a partial mission change. -1 is a synonym for the last mission item (i.e. selects all items from start_index). Ignore field if start_index=-1. */
    uint8_t origin_sysid; /*<  System ID of the author of the new mission. */
    uint8_t origin_compid; /*<  Compnent ID of the author of the new mission. */
    uint8_t mission_type; /*<  Mission type. */


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
        ss << "  start_index: " << start_index << std::endl;
        ss << "  end_index: " << end_index << std::endl;
        ss << "  origin_sysid: " << +origin_sysid << std::endl;
        ss << "  origin_compid: " << +origin_compid << std::endl;
        ss << "  mission_type: " << +mission_type << std::endl;

        return ss.str();
    }

    inline void serialize(mavlink::MsgMap &map) const override
    {
        map.reset(MSG_ID, LENGTH);

        map << start_index;                   // offset: 0
        map << end_index;                     // offset: 2
        map << origin_sysid;                  // offset: 4
        map << origin_compid;                 // offset: 5
        map << mission_type;                  // offset: 6
    }

    inline void deserialize(mavlink::MsgMap &map) override
    {
        map >> start_index;                   // offset: 0
        map >> end_index;                     // offset: 2
        map >> origin_sysid;                  // offset: 4
        map >> origin_compid;                 // offset: 5
        map >> mission_type;                  // offset: 6
    }
};

} // namespace msg
} // namespace common
} // namespace mavlink
