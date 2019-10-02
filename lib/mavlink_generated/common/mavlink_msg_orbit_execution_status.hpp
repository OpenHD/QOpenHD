// MESSAGE ORBIT_EXECUTION_STATUS support class

#pragma once

namespace mavlink {
namespace common {
namespace msg {

/**
 * @brief ORBIT_EXECUTION_STATUS message
 *
 * Vehicle status report that is sent out while orbit execution is in progress (see MAV_CMD_DO_ORBIT).
 */
struct ORBIT_EXECUTION_STATUS : mavlink::Message {
    static constexpr msgid_t MSG_ID = 360;
    static constexpr size_t LENGTH = 25;
    static constexpr size_t MIN_LENGTH = 25;
    static constexpr uint8_t CRC_EXTRA = 11;
    static constexpr auto NAME = "ORBIT_EXECUTION_STATUS";


    uint64_t time_usec; /*< [us] Timestamp (UNIX Epoch time or time since system boot). The receiving end can infer timestamp format (since 1.1.1970 or since system boot) by checking for the magnitude the number. */
    float radius; /*< [m] Radius of the orbit circle. Positive values orbit clockwise, negative values orbit counter-clockwise. */
    uint8_t frame; /*<  The coordinate system of the fields: x, y, z. */
    int32_t x; /*<  X coordinate of center point. Coordinate system depends on frame field: local = x position in meters * 1e4, global = latitude in degrees * 1e7. */
    int32_t y; /*<  Y coordinate of center point.  Coordinate system depends on frame field: local = x position in meters * 1e4, global = latitude in degrees * 1e7. */
    float z; /*< [m] Altitude of center point. Coordinate system depends on frame field. */


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
        ss << "  time_usec: " << time_usec << std::endl;
        ss << "  radius: " << radius << std::endl;
        ss << "  frame: " << +frame << std::endl;
        ss << "  x: " << x << std::endl;
        ss << "  y: " << y << std::endl;
        ss << "  z: " << z << std::endl;

        return ss.str();
    }

    inline void serialize(mavlink::MsgMap &map) const override
    {
        map.reset(MSG_ID, LENGTH);

        map << time_usec;                     // offset: 0
        map << radius;                        // offset: 8
        map << x;                             // offset: 12
        map << y;                             // offset: 16
        map << z;                             // offset: 20
        map << frame;                         // offset: 24
    }

    inline void deserialize(mavlink::MsgMap &map) override
    {
        map >> time_usec;                     // offset: 0
        map >> radius;                        // offset: 8
        map >> x;                             // offset: 12
        map >> y;                             // offset: 16
        map >> z;                             // offset: 20
        map >> frame;                         // offset: 24
    }
};

} // namespace msg
} // namespace common
} // namespace mavlink
