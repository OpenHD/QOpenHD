#ifndef WIFIBROADCAST_H
#define WIFIBROADCAST_H

#include "stdint.h"
#include "time.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    uint32_t received_packet_cnt;
    int8_t current_signal_dbm;
    int8_t type; // 0 = Atheros, 1 = Ralink
    int8_t signal_good;
} __attribute__((packed)) wifi_adapter_rx_status_forward_t;

typedef struct {
    uint32_t damaged_block_cnt; // number bad blocks video downstream
    uint32_t lost_packet_cnt; // lost packets video downstream
    uint32_t skipped_packet_cnt; // skipped packets video downstream
    uint32_t injection_fail_cnt;  // Video injection failed downstream
    uint32_t received_packet_cnt; // packets received video downstream
    uint32_t kbitrate; // live video kilobitrate per second video downstream
    uint32_t kbitrate_measured; // max measured kbitrate during tx startup
    uint32_t kbitrate_set; // set kilobitrate (measured * bitrate_percent) during tx startup
    uint32_t lost_packet_cnt_telemetry_up; // lost packets telemetry uplink
    uint32_t lost_packet_cnt_telemetry_down; // lost packets telemetry downlink
    uint32_t lost_packet_cnt_msp_up; // lost packets msp uplink (not used at the moment)
    uint32_t lost_packet_cnt_msp_down; // lost packets msp downlink (not used at the moment)
    uint32_t lost_packet_cnt_rc; // lost packets rc link
    int8_t current_signal_joystick_uplink; // signal strength in dbm at air pi (telemetry upstream and rc link)
    int8_t current_signal_telemetry_uplink;
    int8_t joystick_connected; // 0 = no joystick connected, 1 = joystick connected
    float HomeLat;
    float HomeLon;
    uint8_t cpuload_gnd; // CPU load Ground Pi
    uint8_t temp_gnd; // CPU temperature Ground Pi
    uint8_t cpuload_air; // CPU load Air Pi
    uint8_t temp_air; // CPU temperature Air Pi
    uint32_t wifi_adapter_cnt; // number of wifi adapters
    wifi_adapter_rx_status_forward_t adapter[6]; // same struct as in wifibroadcast lib.h
} __attribute__((packed)) wifibroadcast_rx_status_forward_t;


#if defined(__rasp_pi__)
typedef struct {
        uint32_t received_packet_cnt;
        uint32_t wrong_crc_cnt;
        int8_t current_signal_dbm;
    int8_t type;
    int signal_good;
} wifi_adapter_rx_status_t;

typedef struct {
        uint32_t received_packet_cnt;
        uint32_t wrong_crc_cnt;
        int8_t current_signal_dbm;
    int8_t type;
    int signal_good;
} wifi_adapter_rx_status_t_osd;

typedef struct {
        uint32_t received_packet_cnt;
        uint32_t wrong_crc_cnt;
        int8_t current_signal_dbm;
    int8_t type;
    int signal_good;
} wifi_adapter_rx_status_t_uplink;

typedef struct {
        time_t last_update;
        uint32_t received_block_cnt;
        uint32_t damaged_block_cnt;
    uint32_t lost_packet_cnt;
    uint32_t received_packet_cnt;
    uint32_t lost_per_block_cnt;
        uint32_t tx_restart_cnt;
    uint32_t kbitrate;
        uint32_t wifi_adapter_cnt;
        wifi_adapter_rx_status_t adapter[8];
} wifibroadcast_rx_status_t;

typedef struct {
        time_t last_update;
        uint32_t received_block_cnt;
        uint32_t damaged_block_cnt;
    uint32_t lost_packet_cnt;
    uint32_t received_packet_cnt;
    uint32_t lost_per_block_cnt;
        uint32_t tx_restart_cnt;
    uint32_t kbitrate;
        uint32_t wifi_adapter_cnt;
        wifi_adapter_rx_status_t adapter[8];
} wifibroadcast_rx_status_t_osd;

typedef struct {
        time_t last_update;
        uint32_t received_block_cnt;
        uint32_t damaged_block_cnt;
    uint32_t lost_packet_cnt;
    uint32_t received_packet_cnt;
    uint32_t lost_per_block_cnt;
        uint32_t tx_restart_cnt;
    uint32_t kbitrate;
        uint32_t wifi_adapter_cnt;
        wifi_adapter_rx_status_t adapter[8];
} wifibroadcast_rx_status_t_rc;

typedef struct {
        time_t last_update;
        uint32_t received_block_cnt;
        uint32_t damaged_block_cnt;
    uint32_t lost_packet_cnt;
    uint32_t received_packet_cnt;
    uint32_t lost_per_block_cnt;
        uint32_t tx_restart_cnt;
    uint32_t kbitrate;
        uint32_t wifi_adapter_cnt;
        wifi_adapter_rx_status_t adapter[8];
} wifibroadcast_rx_status_t_uplink;

typedef struct {
    time_t last_update;
    uint8_t cpuload;
    uint8_t temp;
    uint32_t injected_block_cnt;
    uint32_t skipped_fec_cnt;
    uint32_t injection_fail_cnt;
    long long injection_time_block;
    uint16_t bitrate_kbit;
    uint16_t bitrate_measured_kbit;
    uint8_t cts;
    uint8_t undervolt;
} wifibroadcast_rx_status_t_sysair;

wifibroadcast_rx_status_t *telemetry_wbc_status_memory_open(void);
wifibroadcast_rx_status_t_osd *telemetry_wbc_status_memory_open_osd(void);
wifibroadcast_rx_status_t_rc *telemetry_wbc_status_memory_open_rc(void);
wifibroadcast_rx_status_t_uplink *telemetry_wbc_status_memory_open_uplink(void);
wifibroadcast_rx_status_t_sysair *telemetry_wbc_status_memory_open_sysair(void);
#endif //__raspi_pi__

#ifdef __cplusplus
}
#endif

#endif // WIFIBROADCAST_H
