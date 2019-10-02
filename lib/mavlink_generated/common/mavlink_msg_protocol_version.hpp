// MESSAGE PROTOCOL_VERSION support class

#pragma once

namespace mavlink {
namespace common {
namespace msg {

/**
 * @brief PROTOCOL_VERSION message
 *
 * Version and capability of protocol version. This message is the response to REQUEST_PROTOCOL_VERSION and is used as part of the handshaking to establish which MAVLink version should be used on the network. Every node should respond to REQUEST_PROTOCOL_VERSION to enable the handshaking. Library implementers should consider adding this into the default decoding state machine to allow the protocol core to respond directly.
 */
struct PROTOCOL_VERSION : mavlink::Message {
    static constexpr msgid_t MSG_ID = 300;
    static constexpr size_t LENGTH = 22;
    static constexpr size_t MIN_LENGTH = 22;
    static constexpr uint8_t CRC_EXTRA = 217;
    static constexpr auto NAME = "PROTOCOL_VERSION";


    uint16_t version; /*<  Currently active MAVLink version number * 100: v1.0 is 100, v2.0 is 200, etc. */
    uint16_t min_version; /*<  Minimum MAVLink version supported */
    uint16_t max_version; /*<  Maximum MAVLink version supported (set to the same value as version by default) */
    std::array<uint8_t, 8> spec_version_hash; /*<  The first 8 bytes (not characters printed in hex!) of the git hash. */
    std::array<uint8_t, 8> library_version_hash; /*<  The first 8 bytes (not characters printed in hex!) of the git hash. */


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
        ss << "  version: " << version << std::endl;
        ss << "  min_version: " << min_version << std::endl;
        ss << "  max_version: " << max_version << std::endl;
        ss << "  spec_version_hash: [" << to_string(spec_version_hash) << "]" << std::endl;
        ss << "  library_version_hash: [" << to_string(library_version_hash) << "]" << std::endl;

        return ss.str();
    }

    inline void serialize(mavlink::MsgMap &map) const override
    {
        map.reset(MSG_ID, LENGTH);

        map << version;                       // offset: 0
        map << min_version;                   // offset: 2
        map << max_version;                   // offset: 4
        map << spec_version_hash;             // offset: 6
        map << library_version_hash;          // offset: 14
    }

    inline void deserialize(mavlink::MsgMap &map) override
    {
        map >> version;                       // offset: 0
        map >> min_version;                   // offset: 2
        map >> max_version;                   // offset: 4
        map >> spec_version_hash;             // offset: 6
        map >> library_version_hash;          // offset: 14
    }
};

} // namespace msg
} // namespace common
} // namespace mavlink
