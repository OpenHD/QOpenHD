// MESSAGE TIME_ESTIMATE_TO_TARGET support class

#pragma once

namespace mavlink {
namespace common {
namespace msg {

/**
 * @brief TIME_ESTIMATE_TO_TARGET message
 *
 * Time/duration estimates for various events and actions given the current vehicle state and position.
 */
struct TIME_ESTIMATE_TO_TARGET : mavlink::Message {
    static constexpr msgid_t MSG_ID = 380;
    static constexpr size_t LENGTH = 20;
    static constexpr size_t MIN_LENGTH = 20;
    static constexpr uint8_t CRC_EXTRA = 232;
    static constexpr auto NAME = "TIME_ESTIMATE_TO_TARGET";


    int32_t safe_return; /*< [s] Estimated time to complete the vehicle's configured "safe return" action from its current position (e.g. RTL, Smart RTL, etc.). -1 indicates that the vehicle is landed, or that no time estimate available. */
    int32_t land; /*< [s] Estimated time for vehicle to complete the LAND action from its current position. -1 indicates that the vehicle is landed, or that no time estimate available. */
    int32_t mission_next_item; /*< [s] Estimated time for reaching/completing the currently active mission item. -1 means no time estimate available. */
    int32_t mission_end; /*< [s] Estimated time for completing the current mission. -1 means no mission active and/or no estimate available. */
    int32_t commanded_action; /*< [s] Estimated time for completing the current commanded action (i.e. Go To, Takeoff, Land, etc.). -1 means no action active and/or no estimate available. */


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
        ss << "  safe_return: " << safe_return << std::endl;
        ss << "  land: " << land << std::endl;
        ss << "  mission_next_item: " << mission_next_item << std::endl;
        ss << "  mission_end: " << mission_end << std::endl;
        ss << "  commanded_action: " << commanded_action << std::endl;

        return ss.str();
    }

    inline void serialize(mavlink::MsgMap &map) const override
    {
        map.reset(MSG_ID, LENGTH);

        map << safe_return;                   // offset: 0
        map << land;                          // offset: 4
        map << mission_next_item;             // offset: 8
        map << mission_end;                   // offset: 12
        map << commanded_action;              // offset: 16
    }

    inline void deserialize(mavlink::MsgMap &map) override
    {
        map >> safe_return;                   // offset: 0
        map >> land;                          // offset: 4
        map >> mission_next_item;             // offset: 8
        map >> mission_end;                   // offset: 12
        map >> commanded_action;              // offset: 16
    }
};

} // namespace msg
} // namespace common
} // namespace mavlink
