// MESSAGE OPEN_DRONE_ID_LOCATION support class

#pragma once

namespace mavlink {
namespace common {
namespace msg {

/**
 * @brief OPEN_DRONE_ID_LOCATION message
 *
 * Data for filling the OpenDroneID Location message. The float data types are 32-bit IEEE 754. The Location message provides the location, altitude, direction and speed of the aircraft.
 */
struct OPEN_DRONE_ID_LOCATION : mavlink::Message {
    static constexpr msgid_t MSG_ID = 12901;
    static constexpr size_t LENGTH = 37;
    static constexpr size_t MIN_LENGTH = 37;
    static constexpr uint8_t CRC_EXTRA = 16;
    static constexpr auto NAME = "OPEN_DRONE_ID_LOCATION";


    uint8_t status; /*<  Indicates whether the Unmanned Aircraft is on the ground or in the air. */
    uint16_t direction; /*< [cdeg] Direction over ground (not heading, but direction of movement) in degrees * 100: 0.0 - 359.99 degrees. */
    uint16_t speed_horizontal; /*< [cm/s] Ground speed. */
    int16_t speed_vertical; /*< [cm/s] The vertical speed. Up is positive. */
    int32_t latitude; /*< [degE7] Current latitude of the UA. */
    int32_t longitude; /*< [degE7] Current longitude of the UA. */
    float altitude_barometric; /*< [m] The altitude calculated from the barometric pressue. Reference is against 29.92inHg or 1013.2mb. */
    float altitude_geodetic; /*< [m] The geodetic altitude as defined by WGS84. */
    uint8_t height_reference; /*<  Indicates the reference point for the height field. */
    float height; /*< [m] The current height of the UA above the take-off location or the ground as indicated by height_reference. */
    uint8_t horizontal_accuracy; /*<  The accuracy of the horizontal position. */
    uint8_t vertical_accuracy; /*<  The accuracy of the vertical position. */
    uint8_t barometer_accuracy; /*<  The accuracy of the barometric altitude. */
    uint8_t speed_accuracy; /*<  The accuracy of the horizontal and vertical speed. */
    float timestamp; /*< [s] Seconds after the full hour. Typically the GPS outputs a time of week value in milliseconds. That value can be easily converted for this field using ((float) (time_week_ms % (60*60*1000))) / 1000. */
    uint8_t timestamp_accuracy; /*<  The accuracy of the timestamps. */


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
        ss << "  status: " << +status << std::endl;
        ss << "  direction: " << direction << std::endl;
        ss << "  speed_horizontal: " << speed_horizontal << std::endl;
        ss << "  speed_vertical: " << speed_vertical << std::endl;
        ss << "  latitude: " << latitude << std::endl;
        ss << "  longitude: " << longitude << std::endl;
        ss << "  altitude_barometric: " << altitude_barometric << std::endl;
        ss << "  altitude_geodetic: " << altitude_geodetic << std::endl;
        ss << "  height_reference: " << +height_reference << std::endl;
        ss << "  height: " << height << std::endl;
        ss << "  horizontal_accuracy: " << +horizontal_accuracy << std::endl;
        ss << "  vertical_accuracy: " << +vertical_accuracy << std::endl;
        ss << "  barometer_accuracy: " << +barometer_accuracy << std::endl;
        ss << "  speed_accuracy: " << +speed_accuracy << std::endl;
        ss << "  timestamp: " << timestamp << std::endl;
        ss << "  timestamp_accuracy: " << +timestamp_accuracy << std::endl;

        return ss.str();
    }

    inline void serialize(mavlink::MsgMap &map) const override
    {
        map.reset(MSG_ID, LENGTH);

        map << latitude;                      // offset: 0
        map << longitude;                     // offset: 4
        map << altitude_barometric;           // offset: 8
        map << altitude_geodetic;             // offset: 12
        map << height;                        // offset: 16
        map << timestamp;                     // offset: 20
        map << direction;                     // offset: 24
        map << speed_horizontal;              // offset: 26
        map << speed_vertical;                // offset: 28
        map << status;                        // offset: 30
        map << height_reference;              // offset: 31
        map << horizontal_accuracy;           // offset: 32
        map << vertical_accuracy;             // offset: 33
        map << barometer_accuracy;            // offset: 34
        map << speed_accuracy;                // offset: 35
        map << timestamp_accuracy;            // offset: 36
    }

    inline void deserialize(mavlink::MsgMap &map) override
    {
        map >> latitude;                      // offset: 0
        map >> longitude;                     // offset: 4
        map >> altitude_barometric;           // offset: 8
        map >> altitude_geodetic;             // offset: 12
        map >> height;                        // offset: 16
        map >> timestamp;                     // offset: 20
        map >> direction;                     // offset: 24
        map >> speed_horizontal;              // offset: 26
        map >> speed_vertical;                // offset: 28
        map >> status;                        // offset: 30
        map >> height_reference;              // offset: 31
        map >> horizontal_accuracy;           // offset: 32
        map >> vertical_accuracy;             // offset: 33
        map >> barometer_accuracy;            // offset: 34
        map >> speed_accuracy;                // offset: 35
        map >> timestamp_accuracy;            // offset: 36
    }
};

} // namespace msg
} // namespace common
} // namespace mavlink
