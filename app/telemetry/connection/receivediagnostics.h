// SPDX-License-Identifier: GPL-3.0-only
#pragma once
#include <QDebug>
#include <QStringList>
#include <array>
#include <chrono>
#include <map>
#include <tuple>
#include "../tutil/mavlink_include.h"

// Owned by one connection's receive thread. No payloads or locations logged.
class ReceiveDiagnostics {
public:
    bool parse(uint8_t byte, mavlink_message_t* message, mavlink_status_t* status) {
        const auto result = mavlink_frame_char_buffer(&buffer, &parser, byte, message, status);
        if (result != MAVLINK_FRAMING_INCOMPLETE) {
            const std::tuple<uint8_t,uint8_t,uint32_t> key{
                uint8_t(message->sysid), uint8_t(message->compid), uint32_t(message->msgid)};
            if (counts.size() < 128 || counts.count(key)) {
                const int column = result == MAVLINK_FRAMING_OK ? 0 :
                    result == MAVLINK_FRAMING_BAD_CRC ? 1 : 2;
                ++counts[key][column];
            } else ++untracked;
        }
        if (result == MAVLINK_FRAMING_BAD_CRC || result == MAVLINK_FRAMING_BAD_SIGNATURE) {
            // Same recovery as mavlink_parse_char(), with instance-owned state.
            ++parser.parse_error;
            parser.msg_received = MAVLINK_FRAMING_INCOMPLETE;
            parser.parse_state = MAVLINK_PARSE_STATE_IDLE;
            if (byte == MAVLINK_STX) {
                parser.parse_state = MAVLINK_PARSE_STATE_GOT_STX;
                buffer.len = 0;
                mavlink_start_checksum(&buffer);
            }
        }
        return result == MAVLINK_FRAMING_OK;
    }
    void log(const QString& connection) {
        const auto now = std::chrono::steady_clock::now();
        if (now - lastLog < std::chrono::seconds(5)) return;
        lastLog = now;
        QStringList rows;
        for (const auto& entry : counts) {
            rows << QString("%1/%2/%3:%4,%5,%6")
                .arg(std::get<0>(entry.first)).arg(std::get<1>(entry.first))
                .arg(std::get<2>(entry.first)).arg(entry.second[0])
                .arg(entry.second[1]).arg(entry.second[2]);
        }
        qInfo().noquote() << "telemetry-receive-v1 connection=" << connection
            << "untracked=" << untracked
            << "counts=sys/comp/id:received,bad_crc,bad_signature" << rows.join(' ');
    }
private:
    mavlink_message_t buffer{};
    mavlink_status_t parser{};
    std::map<std::tuple<uint8_t,uint8_t,uint32_t>,std::array<quint64,3>> counts;
    quint64 untracked = 0;
    std::chrono::steady_clock::time_point lastLog = std::chrono::steady_clock::now();
};
