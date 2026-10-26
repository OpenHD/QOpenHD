#pragma once

#include <cstddef>
#include <cstdint>
#include <functional>
#include <vector>
#include <chrono>

namespace nxp {
// RFC 6184 / RFC 7798, non-interleaved mode (no HEVC DON fields).
// Submit a complete access unit on the RTP marker, never wait for the next frame.
class RtpAccessUnit {
public:
    using Bytes = std::vector<uint8_t>;
    using Output = std::function<void(Bytes, bool)>;
    using Clock = std::chrono::steady_clock;
    explicit RtpAccessUnit(bool hevc, Output output) : hevc_(hevc), output_(output) {}
    void push(const uint8_t* p, size_t n, Clock::time_point now = Clock::now()) {
        if (n < 12 || (p[0] >> 6) != 2) return;
        size_t offset = 12 + (p[0] & 15) * 4;
        if (offset > n) return;
        if (p[0] & 16) {
            if (offset + 4 > n) return;
            offset += 4 + 4 * size_t(be16(p + offset + 2));
            if (offset > n) return;
        }
        if (p[0] & 32) {
            auto padding = p[n - 1];
            if (!padding || padding > n - offset) return;
            n -= padding;
        }
        if (offset >= n) return;
        uint16_t seq = be16(p + 2);
        uint32_t stamp = be32(p + 4), source = be32(p + 8);
        // OpenHD currently reuses SSRC 0 when its RTP sender restarts. After a
        // quiet interval, accept a new sequence epoch and reacquire an IDR.
        const bool restart = initialized_ && now - lastPacket_ > std::chrono::milliseconds(500);
        lastPacket_ = now;
        if (!initialized_ || source != source_ || restart) {
            clear(); waitingKey_ = true; initialized_ = true;
            source_ = source; timestamp_ = stamp; expected_ = seq;
        }
        if (seq != expected_) {
            // Reject duplicates and reordered packets; do not invent a jitter buffer.
            if (int16_t(seq - expected_) < 0) return;
            damaged_ = true; waitingKey_ = true; ++losses;
        }
        expected_ = uint16_t(seq + 1);
        if (stamp != timestamp_) {
            if (!data_.empty() || fragment_) { waitingKey_ = true; ++losses; }
            clear(); timestamp_ = stamp;
            // A gap can include the start of this access unit.
            if (seq != uint16_t(lastSeq_ + 1) && haveLast_) damaged_ = true;
        }
        lastSeq_ = seq; haveLast_ = true;
        auto payload = p + offset; size_t len = n - offset;
        if (hevc_) parseH265(payload, len); else parseH264(payload, len);
        if (data_.size() > maxSize) { clear(); damaged_ = true; waitingKey_ = true; }
        if (p[1] & 128) {
            if (!damaged_ && !fragment_ && !data_.empty()) {
                if (!waitingKey_ || key_) {
                    waitingKey_ = false; output_(std::move(data_), key_);
                } else if (configOnly_) {
                    // Parameter sets may have their own timestamp/marker.
                    output_(std::move(data_), false);
                }
            } else { waitingKey_ = true; ++losses; }
            clear();
        }
    }
    uint64_t losses = 0;
private:
    static constexpr size_t maxSize = 4 * 1024 * 1024;
    static uint16_t be16(const uint8_t* p) { return uint16_t(p[0] << 8 | p[1]); }
    static uint32_t be32(const uint8_t* p) { return uint32_t(p[0]) << 24 | uint32_t(p[1]) << 16 | p[2] << 8 | p[3]; }
    void clear() { data_.clear(); damaged_ = false; fragment_ = false; key_ = false; configOnly_ = true; }
    void nal(const uint8_t* p, size_t n) {
        if (n < (hevc_ ? 2u : 1u) || n > maxSize - 4 || data_.size() > maxSize - n - 4) { damaged_ = true; return; }
        unsigned type = hevc_ ? ((p[0] >> 1) & 63) : (p[0] & 31);
        key_ |= hevc_ ? (type >= 16 && type <= 21) : type == 5;
        bool config = hevc_ ? (type >= 32 && type <= 34) : (type == 7 || type == 8);
        configOnly_ &= config;
        data_.insert(data_.end(), {0, 0, 0, 1}); data_.insert(data_.end(), p, p + n);
    }
    void aggregate(const uint8_t* p, size_t n, size_t offset) {
        while (offset + 2 <= n) {
            size_t len = be16(p + offset); offset += 2;
            if (!len || len > n - offset) { damaged_ = true; return; }
            nal(p + offset, len); offset += len;
        }
        if (offset != n) damaged_ = true;
    }
    void parseH264(const uint8_t* p, size_t n) {
        unsigned type = p[0] & 31;
        if (type >= 1 && type <= 23) { if (fragment_) damaged_ = true; nal(p, n); }
        else if (type == 24) { if (fragment_) damaged_ = true; aggregate(p, n, 1); }
        else if (type == 28 && n >= 3) {
            if (p[1] & 128) {
                if (fragment_ || (p[1] & 64)) damaged_ = true;
                uint8_t header = (p[0] & 0xe0) | (p[1] & 31); nal(&header, 1); fragment_ = true;
            } else if (!fragment_) { damaged_ = true; return; }
            data_.insert(data_.end(), p + 2, p + n);
            if (p[1] & 64) fragment_ = false;
        } else damaged_ = true;
    }
    void parseH265(const uint8_t* p, size_t n) {
        if (n < 2) { damaged_ = true; return; }
        unsigned type = (p[0] >> 1) & 63;
        if (type < 48) { if (fragment_) damaged_ = true; nal(p, n); }
        else if (type == 48) { if (fragment_) damaged_ = true; aggregate(p, n, 2); }
        else if (type == 49 && n >= 4) {
            if (p[2] & 128) {
                if (fragment_ || (p[2] & 64)) damaged_ = true;
                uint8_t header[] = {uint8_t((p[0] & 0x81) | ((p[2] & 63) << 1)), p[1]};
                nal(header, 2); fragment_ = true;
            } else if (!fragment_) { damaged_ = true; return; }
            data_.insert(data_.end(), p + 3, p + n);
            if (p[2] & 64) fragment_ = false;
        } else damaged_ = true;
    }
    bool hevc_, initialized_ = false, waitingKey_ = true, damaged_ = false;
    bool fragment_ = false, key_ = false, configOnly_ = true, haveLast_ = false;
    uint16_t expected_ = 0, lastSeq_ = 0;
    uint32_t timestamp_ = 0, source_ = 0;
    Clock::time_point lastPacket_{};
    Bytes data_;
    Output output_;
};
}
