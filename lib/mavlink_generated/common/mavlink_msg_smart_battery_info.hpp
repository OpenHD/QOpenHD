// MESSAGE SMART_BATTERY_INFO support class

#pragma once

namespace mavlink {
namespace common {
namespace msg {

/**
 * @brief SMART_BATTERY_INFO message
 *
 * Smart Battery information (static/infrequent update). Use for updates from: smart battery to flight stack, flight stack to GCS. Use instead of BATTERY_STATUS for smart batteries.
 */
struct SMART_BATTERY_INFO : mavlink::Message {
    static constexpr msgid_t MSG_ID = 370;
    static constexpr size_t LENGTH = 73;
    static constexpr size_t MIN_LENGTH = 73;
    static constexpr uint8_t CRC_EXTRA = 98;
    static constexpr auto NAME = "SMART_BATTERY_INFO";


    uint8_t id; /*<  Battery ID */
    int32_t capacity_full_specification; /*< [mAh] Capacity when full according to manufacturer, -1: field not provided. */
    int32_t capacity_full; /*< [mAh] Capacity when full (accounting for battery degradation), -1: field not provided. */
    uint16_t cycle_count; /*<  Charge/discharge cycle count. -1: field not provided. */
    int32_t serial_number; /*<  Serial number. -1: field not provided. */
    std::array<char, 50> device_name; /*<  Static device name. Encode as manufacturer and product names separated using an underscore. */
    uint16_t weight; /*< [g] Battery weight. 0: field not provided. */
    uint16_t discharge_minimum_voltage; /*< [mV] Minimum per-cell voltage when discharging. If not supplied set to UINT16_MAX value. */
    uint16_t charging_minimum_voltage; /*< [mV] Minimum per-cell voltage when charging. If not supplied set to UINT16_MAX value. */
    uint16_t resting_minimum_voltage; /*< [mV] Minimum per-cell voltage when resting. If not supplied set to UINT16_MAX value. */


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
        ss << "  id: " << +id << std::endl;
        ss << "  capacity_full_specification: " << capacity_full_specification << std::endl;
        ss << "  capacity_full: " << capacity_full << std::endl;
        ss << "  cycle_count: " << cycle_count << std::endl;
        ss << "  serial_number: " << serial_number << std::endl;
        ss << "  device_name: \"" << to_string(device_name) << "\"" << std::endl;
        ss << "  weight: " << weight << std::endl;
        ss << "  discharge_minimum_voltage: " << discharge_minimum_voltage << std::endl;
        ss << "  charging_minimum_voltage: " << charging_minimum_voltage << std::endl;
        ss << "  resting_minimum_voltage: " << resting_minimum_voltage << std::endl;

        return ss.str();
    }

    inline void serialize(mavlink::MsgMap &map) const override
    {
        map.reset(MSG_ID, LENGTH);

        map << capacity_full_specification;   // offset: 0
        map << capacity_full;                 // offset: 4
        map << serial_number;                 // offset: 8
        map << cycle_count;                   // offset: 12
        map << weight;                        // offset: 14
        map << discharge_minimum_voltage;     // offset: 16
        map << charging_minimum_voltage;      // offset: 18
        map << resting_minimum_voltage;       // offset: 20
        map << id;                            // offset: 22
        map << device_name;                   // offset: 23
    }

    inline void deserialize(mavlink::MsgMap &map) override
    {
        map >> capacity_full_specification;   // offset: 0
        map >> capacity_full;                 // offset: 4
        map >> serial_number;                 // offset: 8
        map >> cycle_count;                   // offset: 12
        map >> weight;                        // offset: 14
        map >> discharge_minimum_voltage;     // offset: 16
        map >> charging_minimum_voltage;      // offset: 18
        map >> resting_minimum_voltage;       // offset: 20
        map >> id;                            // offset: 22
        map >> device_name;                   // offset: 23
    }
};

} // namespace msg
} // namespace common
} // namespace mavlink
