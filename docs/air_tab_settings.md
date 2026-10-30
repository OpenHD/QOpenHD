# Air tab settings

Source-based inventory of parameters registered on the Air generic settings component (system 101, component 191). This is not a live dump from ORQA.

The redesigned Air tab groups controls under Flight Controller, UART & Telemetry, Peripherals, System, Expert, and a separately enabled Developer settings category. Expert follows the advanced-settings visibility mode. The tables below are the underlying parameter inventory; each UI section appears only when its firmware parameters are reported.

Availability depends on the connected firmware, platform, installed plugins, radios, and camera count. Device metadata controls actual visibility and labels. Advanced/hidden parameters are included below. Camera-specific settings such as image rotation, mirroring, exposure, and camera enable belong to the Camera tab and are not included.

`ACTIVE_LINKS` is displayed in Link rather than duplicated in Air. Individual `CARD_TYPE_<index>` read-only radio identifiers are generated for detected cards.

Audio and ADS-B controls are displayed exclusively under Extras > Audio and Extras > ADS-B. They remain listed here because their parameters are supplied by the Air component.

## One home per setting

The tables are an inventory of the Air telemetry component, not a list of controls to duplicate in the Air tab. Normal settings use one home per control. Advanced settings also provide local link recovery overrides:

- Link owns multiple-link operation, frequency, channel width, MCS, transmit power, pit mode, adaptive link, hopping, ESP analysis and the Artosyn radio controls available there.
- Link allocation owns dynamic bitrate and camera bandwidth shares. Air has no Camera Bandwidth card.
- Camera owns camera swapping and the manual IP-camera reservation.
- Extras owns audio, ADS-B, custom UDP datalink, Lua RC settings and radio developer logging.
- With Advanced settings enabled, Air > Link recovery exposes the reported radio and transport parameters for this Air unit only. Ground retains its own local parameter editors. These direct writes do not synchronize the other unit and can be used to recover mismatched channel, width, MCS, power, FEC, hopping or transport settings. The target unit must still be reachable over a working connection. Developer-only controls remain separately gated.
- Air otherwise retains settings without a dedicated control elsewhere, including FC connection, serial telemetry, SBUS, GPIO, Wi-Fi hotspot/client and system settings. Each has a single subgroup within Air.

## Review rules

Items 1-24 in `air_tab_settings_review.txt` have been applied. KEEP items stay in their normal subgroup; ADVANCED items remain in their subgroup but require advanced settings. DEVELOPER items appear only in Developer settings, unlocked only by the same five-click Credits-star gesture as Logs and MAVLink Debug. REMOVE hides an item from this tab. Unreviewed items retain their existing visibility.

Firmware and detection details remain read-only. Developer mode is off at application startup and is not enabled by advanced settings or the all-advanced preview. The five-click Credits-star gesture also reveals the application Dev tab and enables the hidden Developer Tools entry point.

## Telemetry

| Parameter | Setting / description |
| --- | --- |
| `FC_UART_CONN` | Flight-controller serial port |
| `FC_UART_BAUD` | Flight-controller baud rate |
| `FC_UART_FLWCTL` | Flight-controller flow control |
| `FC_BATT_N_CELLS` | Flight-controller battery cell count |
| `FC_SYS_ID` | Flight-controller MAVLink system ID (advanced setting in Identification) |
| `OHD_UART_TLM` | OpenHD telemetry serial port |
| `OHD_UART_EN` | OpenHD UART telemetry enabled |
| `OHD_UART_BAUD` | OpenHD UART baud rate |
| `OHD_UART_FLW` | OpenHD UART flow control |
| `UART_PRI_RC` | UART priority for RC |
| `UART_PRI_OHD` | UART priority for OpenHD |
| `UART_PRI_FC` | UART priority for flight-controller telemetry |
| `LOG_MAVLINK` | MAVLink recording |
| `LOG_OPENHD` | OpenHD logging |
| `ADSB_ENABLE` | Adsb Enable |
| `SBUS_EN` | SBUS output enabled |
| `SBUS_DEV` | SBUS output serial device |
| `SBUS_HZ` | SBUS output update rate |
| `SIYI_ACTIVE` | SIYI plugin active (read-only) |
| `TOPOTEK_ACTIVE` | Topotek plugin active (read-only) |
| `CAM_CTRL_ACTIVE` | Camera-control plugin active (read-only) |
| `CONFIG_BOOT_AIR` | Boot role: Air/Ground |
| `FC_FW_INFO` | Detected flight-controller firmware information (read-only) |
| `FC_FW_EVID` | Flight-controller detection evidence (read-only) |

## Network

| Parameter | Setting / description |
| --- | --- |
| `MULTI_LINK_CAP` | Multiple-link capability (read-only) |
| `MULTI_LINK_EN` | Multiple-link operation enabled |
| `WIFI_MODE` | Wi-Fi operating mode |
| `WIFI_IFACES` | Wi-Fi interface information (read-only) |
| `PRIMARY_LINK` | Primary link type (read-only) |
| `WIFI_HOTSPOT_E` | Hotspot mode |
| `WIFI_HS_IFACE` | Hotspot interface |
| `WIFI_HS_SSID` | Hotspot network name |
| `WIFI_HS_PW` | Hotspot password |
| `WIFI_CL_IFACE` | Wi-Fi client interface |
| `WIFI_CL_SSID` | Wi-Fi client network name |
| `WIFI_CL_PW` | Wi-Fi client password |

## WiFiBroadcast

| Parameter | Setting / description |
| --- | --- |
| `WB_N_CARDS` | Wb N Cards |
| `WB_FREQUENCY` | !!!Editing this param manually without care will result in a broken link!!! |
| `WB_CHANNEL_W` | !!!Editing this param manually without care will result in a broken link!!! |
| `WB_MCS_INDEX` | !!!Editing this param manually without care will result in a broken link!!! |
| `WB_V_FEC_PERC` | WB Video FEC overhead, in percent. Increases link stability, but also the required link bandwidth (watch out for tx errors). The best value depends on your rf environment - recommended is about ~20% in low rf enironemnts(e.g. nature), and ~50% in high rf noise environments(populated areas).Note that your rf interference/ packet loss will increase during flight, it is not recommended to decrase this value below 20%. |
| `VARIABLE_BITRATE` | Automatically allocate the WiFiBroadcast video pool using its MCS/FEC-derived capacity, measured priority and fixed traffic, and encoder capabilities. Does not enable loss or TX-drop-driven rate reduction. Disabled preserves manual bitrate settings. |
| `QP_MAX` | Maximum encoder QP. Lower values improve quality but increase required bitrate. |
| `QP_MIN` | Minimum encoder QP. Higher values reduce bitrate but can reduce image quality. |
| `WB_MAX_D_BZ` | Developer only, max FEC block size. |
| `WB_V_RATE_PERC` | Reduce used data rate per mcs index by fixed value (not needed in most cases) |
| `RC_OHD_CTRL` | Enable OpenHD settings commands from the EdgeTX/OpenTX Lua tool. The transport uses four consecutive RC channels. |
| `RC_SET_BASE` | First RC channel used by the Lua settings protocol. The mapping is D2, D1, D0 and CLK; zero disables the protocol. |
| `MCS_VIA_RC` | Dynamically change the MCS Index (Trade range <-> image quality (bitrate)) during flight using your RC and a specific channel (similar to how flight modes work). |
| `BW_VIA_RC` | Dynamically change the BW via RC. NOT ALWAYS SAFE TO USE ! |
| `TXMODE_VIA_RC` | Txmode Via Rc |
| `FHSS_VIA_RC` | Fhss Via Rc |
| `DEV_HIGH_RETR` | DEV ONLY - DO NOT TOUCH (LEAVE DISABLED). Sets a wifi param that needs to be investigated. |
| `ESP_ANALYSE` | Use the connected ESP background RF survey for analysis and prioritize air discovery. Legacy scanning remains the fallback. |
| `WB_ADAPT_CH` | Use the second Devourer radio on Air to survey channels and automatically move the link when a persistently cleaner channel is found. Redundant TX is disabled while active. |
| `WB_FHSS` | Devourer frequency hopping. Devourer handles synchronization and its Wi-Fi control channel; mLRS UART or another live independent telemetry link is required as the OpenHD uplink/recovery path. |
| `WB_FHSS_SLOT` | Devourer FHSS dwell time. 50 ms is recommended. |
| `WB_ENABLE_RETRA` | Enable ARQ retransmission for video. Requires restart to take effect. |
| `WB_RTX_VIDEO` | Enable ARQ retransmission for video packets. Requires restart to take effect. |
| `WB_RTX_TELEM` | Enable ARQ retransmission for telemetry packets. Requires restart to take effect. |
| `WB_RTX_RC` | Enable ARQ retransmission for RC packets. Requires restart to take effect. |
| `WB_RTX_V_MAXMS` | Max retransmission history window for video in milliseconds. Larger values allow longer recovery but use more memory. |
| `WB_RTX_T_MAXMS` | Max retransmission history window for telemetry in milliseconds. Larger values allow longer recovery but use more memory. |
| `WB_RTX_R_MAXMS` | Max retransmission history window for RC in milliseconds. Larger values allow longer recovery but use more memory. |
| `WB_RTX_REQ_REP` | How often each retransmission request is sent. Higher values increase reliability but add overhead. |
| `WB_E_STBC` | !! Advanced users only, changing this param can result in no connection !!. This param is not automatically synchronized between air/ground. Specifies the difference between the number of space-time streams and the number of spatial streams. Use +1 only if you have 2 antennas. |
| `WB_E_LDPC` | !! Advanced users only, changing this param can result in no connection !!. This param is not automatically synchronized between air/ground. Enable Low density parity check. Needs to be supported by both your tx and rxes. |
| `WB_E_SHORT_GUARD` | !! Advanced users only !!. This param is not automatically synchronized between air/ground. A short guard intervall increases throughput, but increases packet collisions. |
| `TX_PWR_LVL` | Normalized TX power target. Values through 100% use the normal calibrated range. Values above 100% are hardware-stressing Devourer overdrive and require Advanced Settings in the link control. |
| `WB_PIT_MODE` | Pit mode: when enabled, disarmed uses the 20% TX power target and armed uses the selected target. |
| `WB_DEV_LOGS` | Wb Dev Logs |
| `WB_UDP_ENABLE` | Wb Udp Enable |
| `WB_UDP_FEC` | Wb Udp Fec |
| `WB_UDP_BUDGET` | Wb Udp Budget |
| `WB_UDP_MAX_KBPS` | Wb Udp Max Kbps |
| `WB_UDP_IN_PORT` | Wb Udp In Port |
| `WB_UDP_OUT_PORT` | Wb Udp Out Port |

## Video/audio

| Parameter | Setting / description |
| --- | --- |
| `V_SWITCH_CAM` | Swap primary/secondary cameras |
| `V_IP_CAM_MBITS` | IP-camera bitrate reservation |
| `V_PRIMARY_PERC` | Primary-camera share of video bandwidth |
| `AUDIO_ENABLE` | Audio capture mode |
| `AUDIO_EXAMPLE` | Example-audio capability (read-only) |
| `AUDIO_GAIN` | Microphone gain |
| `AUDIO_USB_COUNT` | USB audio device count (read-only) |
| `AUD_USB_NAMES` | USB audio device names (read-only) |
| `AUDIO_DEV_COUNT` | Audio capture device count (read-only) |
| `AUDIO_DEVICE` | Audio capture device |

## Hardware-specific GPIO

| Parameter | Setting / description |
| --- | --- |
| `GPIO_2` | Experimental, allows manually controlling a rpi gpio for special uses like a LED, landing gear, ... |
| `GPIO_26` | Experimental, allows manually controlling a rpi gpio for special uses like a LED, landing gear, ... |

## Hardware-specific Artosyn

| Parameter | Setting / description |
| --- | --- |
| `AR_ADDR` | Artosyn daemon address (host/IP). Changing this reconnects to the daemon. |
| `AR_PORT` | Artosyn daemon TCP port. |
| `AR_SLOT` | Artosyn slot index used by the OpenHD link. |
| `AR_VPORT` | Artosyn video socket port id. |
| `AR_TPORT` | Artosyn telemetry socket port id. |
| `AR_DGRAM` | Enable Artosyn datagram socket mode. |
| `AR_RXBUF` | Artosyn socket RX buffer size (bytes). |
| `AR_TXBUF` | Artosyn socket TX buffer size (bytes). |
| `AR_RDTMO` | Artosyn socket read timeout (ms). |
| `AR_RESET_CMD` | Ar Reset Cmd |
| `AR_PAIR_CMD` | Ar Pair Cmd |
| `AR_MCS_MD` | MCS mode. Manual uses AR_MCS_VAL; Auto uses internal adaptation. |
| `AR_MCS_VAL` | Manual MCS value (bb_phy_mcs_e). Use -1 to keep current. |
| `AR_MCS_MIN` | Auto MCS minimum limit (bb_phy_mcs_e). -1 disables the limit. |
| `AR_MCS_MAX` | Auto MCS maximum limit (bb_phy_mcs_e). -1 disables the limit. |
| `AR_BW_MD` | Bandwidth mode. Manual uses AR_BW_VAL; Auto uses internal adaptation. |
| `AR_BW_VAL` | Manual bandwidth selection (bb_bandwidth_e). |
| `AR_CHN_MD` | Channel mode. Manual uses AR_CHN_IDX; Auto uses internal adaptation. |
| `AR_CHN_IDX` | Manual channel index. -1 keeps current. |
| `AR_PWR_ATO` | Power control mode. Manual uses AR_PWR_DBM. |
| `AR_PWR_DBM` | Manual TX power target (dBm). -1 keeps current. |
| `AR_BND_MD` | Band mode control. -1 keeps current. |
| `AR_BND_VAL` | Manual band selection (bb_band_e). -1 keeps current. |
| `AR_CMP_MD` | Compliance mode control. -1 keeps current. |
| `AR_PWR_MD` | Power mode (bb_phy_pwr_mode_e). -1 keeps current. |
| `AR_LNA_MD` | LNA mode control. -1 keeps current. |
| `AR_LNA_BP` | LNA bypass control. -1 keeps current. |
| `AR_RF_ATX` | RF path A TX enable. -1 keeps current. |
| `AR_RF_ARX` | RF path A RX enable. -1 keeps current. |
| `AR_RF_BTX` | RF path B TX enable. -1 keeps current. |
| `AR_RF_BRX` | RF path B RX enable. -1 keeps current. |

## Hardware-specific Microhard

| Parameter | Setting / description |
| --- | --- |
| `MICROHARD_DUMMY0` | Legacy placeholder; has no functional setting effect |

## IP camera connection controls

Shown when an external IP camera is available:

- Camera preset: SIYI, generic RTSP, or custom.
- Camera IP address.
- RTSP port.
- RTSP path.
- Save camera connection.
- IP-camera link reservation in Mbit/s, with a Save action.
- Open camera WebUI.
- Expert GStreamer pipeline editing.

## Sources

- `OpenHD/ohd_telemetry/src/AirTelemetry.cpp`: Air telemetry settings.
- `OpenHD/ohd_interface/src/ohd_interface.cpp`: network settings.
- `OpenHD/ohd_interface/src/wb_link.cpp`: WiFiBroadcast settings.
- `OpenHD/ohd_video/src/ohd_video_air.cpp`: shared video/audio settings.
- `QOpenHD/qml/ui/configpopup/openhd_settings/MavlinkParamPanel.qml`: Air tab presentation.
