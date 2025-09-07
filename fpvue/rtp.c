#include "rtp.h"
#include <string.h>

uint32_t frames_received = 0;
uint32_t in_nal_size = 0;

uint8_t* decode_frame(uint8_t* rx_buffer, uint32_t rx_size,
  uint32_t header_size, uint8_t* nal_buffer, uint32_t* out_nal_size) {
  rx_buffer += header_size;
  rx_size -= header_size;

  // Get NAL type
  uint8_t fragment_type_avc = rx_buffer[0] & 0x1F;
  uint8_t fragment_type_hevc = (rx_buffer[0] >> 1) & 0x3F;

  uint8_t start_bit = 0;
  uint8_t end_bit = 0;
  uint8_t copy_size = 4;

  if (fragment_type_avc == 28 || fragment_type_hevc == 49) {
    if (fragment_type_avc == 28) {
      start_bit = rx_buffer[1] & 0x80;
      end_bit = rx_buffer[1] & 0x40;
      nal_buffer[4] = (rx_buffer[0] & 0xE0) | (rx_buffer[1] & 0x1F);
    } else {
      start_bit = rx_buffer[2] & 0x80;
      end_bit = rx_buffer[2] & 0x40;
      nal_buffer[4] = (rx_buffer[0] & 0x81) | (rx_buffer[2] & 0x3F) << 1;
      nal_buffer[5] = 1;
      copy_size++;
      rx_buffer++;
      rx_size--;
    }

    rx_buffer++;
    rx_size--;

    if (start_bit) {
      // Write NAL header
      nal_buffer[0] = 0;
      nal_buffer[1] = 0;
      nal_buffer[2] = 0;
      nal_buffer[3] = 1;

      // Copy data
      memcpy(nal_buffer + copy_size, rx_buffer, rx_size);
      in_nal_size = rx_size + copy_size;
    } else {
      rx_buffer++;
      rx_size--;
      memcpy(nal_buffer + in_nal_size, rx_buffer, rx_size);
      in_nal_size += rx_size;

      if (end_bit) {
        *out_nal_size = in_nal_size;
        in_nal_size = 0;
        frames_received++;
        return nal_buffer;
      }
    }

    return NULL;
  } else {
    // Write NAL header
    nal_buffer[0] = 0;
    nal_buffer[1] = 0;
    nal_buffer[2] = 0;
    nal_buffer[3] = 1;
    memcpy(nal_buffer + copy_size, rx_buffer, rx_size);
    *out_nal_size = rx_size + copy_size;
    in_nal_size = 0;

    // Return NAL
    frames_received++;
    return nal_buffer;
  }
}
