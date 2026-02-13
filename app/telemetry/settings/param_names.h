//
// Created by consti10 on 21.06.23.
//

#ifndef QOPENHD_PARAM_NAMES_H
#define QOPENHD_PARAM_NAMES_H

namespace openhd{

// Note: max 16 char for id limit
static constexpr auto WB_FREQUENCY="WB_FREQUENCY";
static constexpr auto WB_CHANNEL_WIDTH="WB_CHANNEL_W";
static constexpr auto WB_MCS_INDEX="WB_MCS_INDEX";
static constexpr auto WB_VIDEO_FEC_BLOCK_LENGTH="WB_V_FEC_BLK_L";
static constexpr auto WB_VIDEO_FEC_PERCENTAGE="WB_V_FEC_PERC";
static constexpr auto WB_VIDEO_RATE_FOR_MCS_ADJUSTMENT_PERC="WB_V_RATE_PERC"; //wb_video_rate_for_mcs_adjustment_percent
static constexpr auto WB_MAX_FEC_BLOCK_SIZE_FOR_PLATFORM="WB_MAX_D_BZ";
static constexpr auto WB_TX_POWER_MILLI_WATT="TX_POWER_MW";
static constexpr auto WB_TX_POWER_MILLI_WATT_ARMED="TX_POWER_MW_ARM";
static constexpr auto WB_TX_POWER_LEVEL="TX_PWR_LVL";
// annoying 16 char settings limit
static constexpr auto WB_RTL8812AU_TX_PWR_IDX_OVERRIDE="TX_POWER_I";
static constexpr auto WB_RTL8812AU_TX_PWR_IDX_ARMED="TX_POWER_I_ARMED";
//
static constexpr auto WB_VIDEO_VARIABLE_BITRATE="VARIABLE_BITRATE";
//
static constexpr auto WB_ENABLE_STBC="WB_E_STBC";
static constexpr auto WB_ENABLE_LDPC="WB_E_LDPC";
static constexpr auto WB_ENABLE_SHORT_GUARD="WB_E_SHORT_GUARD";
static constexpr auto WB_MCS_INDEX_VIA_RC_CHANNEL="MCS_VIA_RC";
static constexpr auto WB_POWER_VIA_RC_CHANNEL="PWR_VIA_RC";
static constexpr auto WB_BW_VIA_RC_CHANNEL = "BW_VIA_RC";
static constexpr auto WB_PASSIVE_MODE ="WB_PASSIVE_MODE";
static constexpr auto WB_DEV_AIR_SET_HIGH_RETRANSMIT_COUNT="DEV_HIGH_RETR";
static constexpr auto WB_ENABLE_RETRANSMISSION="WB_ENABLE_RETRA";
static constexpr auto WB_ENABLE_RETRANSMISSION_VIDEO="WB_RTX_VIDEO";
static constexpr auto WB_ENABLE_RETRANSMISSION_TELEMETRY="WB_RTX_TELEM";
static constexpr auto WB_ENABLE_RETRANSMISSION_RC="WB_RTX_RC";
static constexpr auto WB_RETRANSMISSION_HISTORY_VIDEO_MS="WB_RTX_V_MAXMS";
static constexpr auto WB_RETRANSMISSION_HISTORY_TELEMETRY_MS="WB_RTX_T_MAXMS";
static constexpr auto WB_RETRANSMISSION_HISTORY_RC_MS="WB_RTX_R_MAXMS";
static constexpr auto WB_RETRANSMISSION_REQUEST_RETRIES="WB_RTX_REQ_REP";


}

#endif //QOPENHD_PARAM_NAMES_H
