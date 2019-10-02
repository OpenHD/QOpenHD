// MESSAGE TRAJECTORY_REPRESENTATION_WAYPOINTS support class

#pragma once

namespace mavlink {
namespace common {
namespace msg {

/**
 * @brief TRAJECTORY_REPRESENTATION_WAYPOINTS message
 *
 * Describe a trajectory using an array of up-to 5 waypoints in the local frame.
 */
struct TRAJECTORY_REPRESENTATION_WAYPOINTS : mavlink::Message {
    static constexpr msgid_t MSG_ID = 332;
    static constexpr size_t LENGTH = 239;
    static constexpr size_t MIN_LENGTH = 239;
    static constexpr uint8_t CRC_EXTRA = 236;
    static constexpr auto NAME = "TRAJECTORY_REPRESENTATION_WAYPOINTS";


    uint64_t time_usec; /*< [us] Timestamp (UNIX Epoch time or time since system boot). The receiving end can infer timestamp format (since 1.1.1970 or since system boot) by checking for the magnitude the number. */
    uint8_t valid_points; /*<  Number of valid points (up-to 5 waypoints are possible) */
    std::array<float, 5> pos_x; /*< [m] X-coordinate of waypoint, set to NaN if not being used */
    std::array<float, 5> pos_y; /*< [m] Y-coordinate of waypoint, set to NaN if not being used */
    std::array<float, 5> pos_z; /*< [m] Z-coordinate of waypoint, set to NaN if not being used */
    std::array<float, 5> vel_x; /*< [m/s] X-velocity of waypoint, set to NaN if not being used */
    std::array<float, 5> vel_y; /*< [m/s] Y-velocity of waypoint, set to NaN if not being used */
    std::array<float, 5> vel_z; /*< [m/s] Z-velocity of waypoint, set to NaN if not being used */
    std::array<float, 5> acc_x; /*< [m/s/s] X-acceleration of waypoint, set to NaN if not being used */
    std::array<float, 5> acc_y; /*< [m/s/s] Y-acceleration of waypoint, set to NaN if not being used */
    std::array<float, 5> acc_z; /*< [m/s/s] Z-acceleration of waypoint, set to NaN if not being used */
    std::array<float, 5> pos_yaw; /*< [rad] Yaw angle, set to NaN if not being used */
    std::array<float, 5> vel_yaw; /*< [rad/s] Yaw rate, set to NaN if not being used */
    std::array<uint16_t, 5> command; /*<  Scheduled action for each waypoint, UINT16_MAX if not being used. */


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
        ss << "  valid_points: " << +valid_points << std::endl;
        ss << "  pos_x: [" << to_string(pos_x) << "]" << std::endl;
        ss << "  pos_y: [" << to_string(pos_y) << "]" << std::endl;
        ss << "  pos_z: [" << to_string(pos_z) << "]" << std::endl;
        ss << "  vel_x: [" << to_string(vel_x) << "]" << std::endl;
        ss << "  vel_y: [" << to_string(vel_y) << "]" << std::endl;
        ss << "  vel_z: [" << to_string(vel_z) << "]" << std::endl;
        ss << "  acc_x: [" << to_string(acc_x) << "]" << std::endl;
        ss << "  acc_y: [" << to_string(acc_y) << "]" << std::endl;
        ss << "  acc_z: [" << to_string(acc_z) << "]" << std::endl;
        ss << "  pos_yaw: [" << to_string(pos_yaw) << "]" << std::endl;
        ss << "  vel_yaw: [" << to_string(vel_yaw) << "]" << std::endl;
        ss << "  command: [" << to_string(command) << "]" << std::endl;

        return ss.str();
    }

    inline void serialize(mavlink::MsgMap &map) const override
    {
        map.reset(MSG_ID, LENGTH);

        map << time_usec;                     // offset: 0
        map << pos_x;                         // offset: 8
        map << pos_y;                         // offset: 28
        map << pos_z;                         // offset: 48
        map << vel_x;                         // offset: 68
        map << vel_y;                         // offset: 88
        map << vel_z;                         // offset: 108
        map << acc_x;                         // offset: 128
        map << acc_y;                         // offset: 148
        map << acc_z;                         // offset: 168
        map << pos_yaw;                       // offset: 188
        map << vel_yaw;                       // offset: 208
        map << command;                       // offset: 228
        map << valid_points;                  // offset: 238
    }

    inline void deserialize(mavlink::MsgMap &map) override
    {
        map >> time_usec;                     // offset: 0
        map >> pos_x;                         // offset: 8
        map >> pos_y;                         // offset: 28
        map >> pos_z;                         // offset: 48
        map >> vel_x;                         // offset: 68
        map >> vel_y;                         // offset: 88
        map >> vel_z;                         // offset: 108
        map >> acc_x;                         // offset: 128
        map >> acc_y;                         // offset: 148
        map >> acc_z;                         // offset: 168
        map >> pos_yaw;                       // offset: 188
        map >> vel_yaw;                       // offset: 208
        map >> command;                       // offset: 228
        map >> valid_points;                  // offset: 238
    }
};

} // namespace msg
} // namespace common
} // namespace mavlink
