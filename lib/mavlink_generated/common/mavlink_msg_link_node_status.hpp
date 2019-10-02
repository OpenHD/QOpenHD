// MESSAGE LINK_NODE_STATUS support class

#pragma once

namespace mavlink {
namespace common {
namespace msg {

/**
 * @brief LINK_NODE_STATUS message
 *
 * Status generated in each node in the communication chain and injected into MAVLink stream.
 */
struct LINK_NODE_STATUS : mavlink::Message {
    static constexpr msgid_t MSG_ID = 8;
    static constexpr size_t LENGTH = 36;
    static constexpr size_t MIN_LENGTH = 36;
    static constexpr uint8_t CRC_EXTRA = 117;
    static constexpr auto NAME = "LINK_NODE_STATUS";


    uint64_t timestamp; /*< [ms] Timestamp (time since system boot). */
    uint8_t tx_buf; /*< [%] Remaining free transmit buffer space */
    uint8_t rx_buf; /*< [%] Remaining free receive buffer space */
    uint32_t tx_rate; /*< [bytes/s] Transmit rate */
    uint32_t rx_rate; /*< [bytes/s] Receive rate */
    uint16_t rx_parse_err; /*< [bytes] Number of bytes that could not be parsed correctly. */
    uint16_t tx_overflows; /*< [bytes] Transmit buffer overflows. This number wraps around as it reaches UINT16_MAX */
    uint16_t rx_overflows; /*< [bytes] Receive buffer overflows. This number wraps around as it reaches UINT16_MAX */
    uint32_t messages_sent; /*<  Messages sent */
    uint32_t messages_received; /*<  Messages received (estimated from counting seq) */
    uint32_t messages_lost; /*<  Messages lost (estimated from counting seq) */


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
        ss << "  timestamp: " << timestamp << std::endl;
        ss << "  tx_buf: " << +tx_buf << std::endl;
        ss << "  rx_buf: " << +rx_buf << std::endl;
        ss << "  tx_rate: " << tx_rate << std::endl;
        ss << "  rx_rate: " << rx_rate << std::endl;
        ss << "  rx_parse_err: " << rx_parse_err << std::endl;
        ss << "  tx_overflows: " << tx_overflows << std::endl;
        ss << "  rx_overflows: " << rx_overflows << std::endl;
        ss << "  messages_sent: " << messages_sent << std::endl;
        ss << "  messages_received: " << messages_received << std::endl;
        ss << "  messages_lost: " << messages_lost << std::endl;

        return ss.str();
    }

    inline void serialize(mavlink::MsgMap &map) const override
    {
        map.reset(MSG_ID, LENGTH);

        map << timestamp;                     // offset: 0
        map << tx_rate;                       // offset: 8
        map << rx_rate;                       // offset: 12
        map << messages_sent;                 // offset: 16
        map << messages_received;             // offset: 20
        map << messages_lost;                 // offset: 24
        map << rx_parse_err;                  // offset: 28
        map << tx_overflows;                  // offset: 30
        map << rx_overflows;                  // offset: 32
        map << tx_buf;                        // offset: 34
        map << rx_buf;                        // offset: 35
    }

    inline void deserialize(mavlink::MsgMap &map) override
    {
        map >> timestamp;                     // offset: 0
        map >> tx_rate;                       // offset: 8
        map >> rx_rate;                       // offset: 12
        map >> messages_sent;                 // offset: 16
        map >> messages_received;             // offset: 20
        map >> messages_lost;                 // offset: 24
        map >> rx_parse_err;                  // offset: 28
        map >> tx_overflows;                  // offset: 30
        map >> rx_overflows;                  // offset: 32
        map >> tx_buf;                        // offset: 34
        map >> rx_buf;                        // offset: 35
    }
};

} // namespace msg
} // namespace common
} // namespace mavlink
