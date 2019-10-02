// MESSAGE ONBOARD_COMPUTER_STATUS support class

#pragma once

namespace mavlink {
namespace common {
namespace msg {

/**
 * @brief ONBOARD_COMPUTER_STATUS message
 *
 * Hardware status sent by an onboard computer.
 */
struct ONBOARD_COMPUTER_STATUS : mavlink::Message {
    static constexpr msgid_t MSG_ID = 390;
    static constexpr size_t LENGTH = 238;
    static constexpr size_t MIN_LENGTH = 238;
    static constexpr uint8_t CRC_EXTRA = 156;
    static constexpr auto NAME = "ONBOARD_COMPUTER_STATUS";


    uint64_t time_usec; /*< [us] Timestamp (UNIX Epoch time or time since system boot). The receiving end can infer timestamp format (since 1.1.1970 or since system boot) by checking for the magnitude the number. */
    uint32_t uptime; /*< [ms] Time since system boot. */
    uint8_t type; /*<  Type of the onboard computer: 0: Mission computer primary, 1: Mission computer backup 1, 2: Mission computer backup 2, 3: Compute node, 4-5: Compute spares, 6-9: Payload computers. */
    std::array<uint8_t, 8> cpu_cores; /*<  CPU usage on the component in percent (100 - idle). A value of UINT8_MAX implies the field is unused. */
    std::array<uint8_t, 10> cpu_combined; /*<  Combined CPU usage as the last 10 slices of 100 MS (a histogram). This allows to identify spikes in load that max out the system, but only for a short amount of time. A value of UINT8_MAX implies the field is unused. */
    std::array<uint8_t, 4> gpu_cores; /*<  GPU usage on the component in percent (100 - idle). A value of UINT8_MAX implies the field is unused. */
    std::array<uint8_t, 10> gpu_combined; /*<  Combined GPU usage as the last 10 slices of 100 MS (a histogram). This allows to identify spikes in load that max out the system, but only for a short amount of time. A value of UINT8_MAX implies the field is unused. */
    int8_t temperature_board; /*< [degC] Temperature of the board. A value of INT8_MAX implies the field is unused. */
    std::array<int8_t, 8> temperature_core; /*< [degC] Temperature of the CPU core. A value of INT8_MAX implies the field is unused. */
    std::array<int16_t, 4> fan_speed; /*< [rpm] Fan speeds. A value of INT16_MAX implies the field is unused. */
    uint32_t ram_usage; /*< [MiB] Amount of used RAM on the component system. A value of UINT32_MAX implies the field is unused. */
    uint32_t ram_total; /*< [MiB] Total amount of RAM on the component system. A value of UINT32_MAX implies the field is unused. */
    std::array<uint32_t, 4> storage_type; /*<  Storage type: 0: HDD, 1: SSD, 2: EMMC, 3: SD card (non-removable), 4: SD card (removable). A value of UINT32_MAX implies the field is unused. */
    std::array<uint32_t, 4> storage_usage; /*< [MiB] Amount of used storage space on the component system. A value of UINT32_MAX implies the field is unused. */
    std::array<uint32_t, 4> storage_total; /*< [MiB] Total amount of storage space on the component system. A value of UINT32_MAX implies the field is unused. */
    std::array<uint32_t, 6> link_type; /*<  Link type: 0-9: UART, 10-19: Wired network, 20-29: Wifi, 30-39: Point-to-point proprietary, 40-49: Mesh proprietary */
    std::array<uint32_t, 6> link_tx_rate; /*< [KiB/s] Network traffic from the component system. A value of UINT32_MAX implies the field is unused. */
    std::array<uint32_t, 6> link_rx_rate; /*< [KiB/s] Network traffic to the component system. A value of UINT32_MAX implies the field is unused. */
    std::array<uint32_t, 6> link_tx_max; /*< [KiB/s] Network capacity from the component system. A value of UINT32_MAX implies the field is unused. */
    std::array<uint32_t, 6> link_rx_max; /*< [KiB/s] Network capacity to the component system. A value of UINT32_MAX implies the field is unused. */


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
        ss << "  uptime: " << uptime << std::endl;
        ss << "  type: " << +type << std::endl;
        ss << "  cpu_cores: [" << to_string(cpu_cores) << "]" << std::endl;
        ss << "  cpu_combined: [" << to_string(cpu_combined) << "]" << std::endl;
        ss << "  gpu_cores: [" << to_string(gpu_cores) << "]" << std::endl;
        ss << "  gpu_combined: [" << to_string(gpu_combined) << "]" << std::endl;
        ss << "  temperature_board: " << +temperature_board << std::endl;
        ss << "  temperature_core: [" << to_string(temperature_core) << "]" << std::endl;
        ss << "  fan_speed: [" << to_string(fan_speed) << "]" << std::endl;
        ss << "  ram_usage: " << ram_usage << std::endl;
        ss << "  ram_total: " << ram_total << std::endl;
        ss << "  storage_type: [" << to_string(storage_type) << "]" << std::endl;
        ss << "  storage_usage: [" << to_string(storage_usage) << "]" << std::endl;
        ss << "  storage_total: [" << to_string(storage_total) << "]" << std::endl;
        ss << "  link_type: [" << to_string(link_type) << "]" << std::endl;
        ss << "  link_tx_rate: [" << to_string(link_tx_rate) << "]" << std::endl;
        ss << "  link_rx_rate: [" << to_string(link_rx_rate) << "]" << std::endl;
        ss << "  link_tx_max: [" << to_string(link_tx_max) << "]" << std::endl;
        ss << "  link_rx_max: [" << to_string(link_rx_max) << "]" << std::endl;

        return ss.str();
    }

    inline void serialize(mavlink::MsgMap &map) const override
    {
        map.reset(MSG_ID, LENGTH);

        map << time_usec;                     // offset: 0
        map << uptime;                        // offset: 8
        map << ram_usage;                     // offset: 12
        map << ram_total;                     // offset: 16
        map << storage_type;                  // offset: 20
        map << storage_usage;                 // offset: 36
        map << storage_total;                 // offset: 52
        map << link_type;                     // offset: 68
        map << link_tx_rate;                  // offset: 92
        map << link_rx_rate;                  // offset: 116
        map << link_tx_max;                   // offset: 140
        map << link_rx_max;                   // offset: 164
        map << fan_speed;                     // offset: 188
        map << type;                          // offset: 196
        map << cpu_cores;                     // offset: 197
        map << cpu_combined;                  // offset: 205
        map << gpu_cores;                     // offset: 215
        map << gpu_combined;                  // offset: 219
        map << temperature_board;             // offset: 229
        map << temperature_core;              // offset: 230
    }

    inline void deserialize(mavlink::MsgMap &map) override
    {
        map >> time_usec;                     // offset: 0
        map >> uptime;                        // offset: 8
        map >> ram_usage;                     // offset: 12
        map >> ram_total;                     // offset: 16
        map >> storage_type;                  // offset: 20
        map >> storage_usage;                 // offset: 36
        map >> storage_total;                 // offset: 52
        map >> link_type;                     // offset: 68
        map >> link_tx_rate;                  // offset: 92
        map >> link_rx_rate;                  // offset: 116
        map >> link_tx_max;                   // offset: 140
        map >> link_rx_max;                   // offset: 164
        map >> fan_speed;                     // offset: 188
        map >> type;                          // offset: 196
        map >> cpu_cores;                     // offset: 197
        map >> cpu_combined;                  // offset: 205
        map >> gpu_cores;                     // offset: 215
        map >> gpu_combined;                  // offset: 219
        map >> temperature_board;             // offset: 229
        map >> temperature_core;              // offset: 230
    }
};

} // namespace msg
} // namespace common
} // namespace mavlink
