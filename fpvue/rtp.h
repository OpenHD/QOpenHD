#ifndef RTP_FRAME_H
#define RTP_FRAME_H

#include <stdint.h>

// RTP frame handling.

uint8_t* decode_frame(uint8_t* rx_buffer, uint32_t rx_size, uint32_t header_size, uint8_t* nal_buffer, uint32_t* out_nal_size);

#endif
