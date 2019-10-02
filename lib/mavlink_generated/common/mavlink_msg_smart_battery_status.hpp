// MESSAGE SMART_BATTERY_STATUS support class

#pragma once

namespace mavlink {
namespace common {
namespace msg {

/**
 * @brief SMART_BATTERY_STATUS message
 *
 * Smart Battery information (dynamic). Use for updates from: smart battery to flight stack, flight stack to GCS. Use instead of BATTERY_STATUS for smart batteries.
 */
struct SMART_BATTERY_STATUS : mavlink::Message {
    static constexpr msgid_t MSG_ID = 371;
    static constexpr size_t LENGTH = 50;
    static constexpr size_t MIN_LENGTH = 50;
    static constexpr uint8_t CRC_EXTRA = 161;
    static constexpr auto NAME = "SMART_BATTERY_STATUS";


    uint16_t id; /*<  Battery ID */
    int16_t capacity_remaining; /*< [%] Remaining battery energy. Values: [0-100], -1: field not provided. */
    int16_t current; /*< [cA] Battery current (through all cells/loads). Positive if discharging, negative if charging. UINT16_MAX: field not provided. */
    int16_t temperature; /*< [cdegC] Battery temperature. -1: field not provided. */
    int32_t fault_bitmask; /*<  Fault/health indications. */
    int32_t time_remaining; /*< [s] Estimated remaining battery time. -1: field not provided. */
    uint16_t cell_offset; /*<  The cell number of the first index in the 'voltages' array field. Using this field allows you to specify cell voltages for batteries with more than 16 cells. */
    std::array<uint16_t, 16> voltages; /*< [mV] Individual cell voltages. Batteries with more 16 cells can use the cell_offset field to specify the cell offset for the array specified in the current message . Index values above the valid cell count for this battery should have the UINT16_MAX value. */


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
        ss << "  id: " << id << std::endl;
        ss << "  capacity_remaining: " << capacity_remaining << std::endl;
        ss << "  current: " << current << std::endl;
        ss << "  temperature: " << temperature << std::endl;
        ss << "  fault_bitmask: " << fault_bitmask << std::endl;
        ss << "  time_remaining: " << time_remaining << std::endl;
        ss << "  cell_offset: " << cell_offset << std::endl;
        ss << "  voltages: [" << to_string(voltages) << "]" << std::endl;

        return ss.str();
    }

    inline void serialize(mavlink::MsgMap &map) const override
    {
        map.reset(MSG_ID, LENGTH);

        map << fault_bitmask;                 // offset: 0
        map << time_remaining;                // offset: 4
        map << id;                            // offset: 8
        map << capacity_remaining;            // offset: 10
        map << current;                       // offset: 12
        map << temperature;                   // offset: 14
        map << cell_offset;                   // offset: 16
        map << voltages;                      // offset: 18
    }

    inline void deserialize(mavlink::MsgMap &map) override
    {
        map >> fault_bitmask;                 // offset: 0
        map >> time_remaining;                // offset: 4
        map >> id;                            // offset: 8
        map >> capacity_remaining;            // offset: 10
        map >> current;                       // offset: 12
        map >> temperature;                   // offset: 14
        map >> cell_offset;                   // offset: 16
        map >> voltages;                      // offset: 18
    }
};

} // namespace msg
} // namespace common
} // namespace mavlink
