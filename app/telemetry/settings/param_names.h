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
static constexpr auto WB_PIT_MODE ="WB_PIT_MODE";
static constexpr auto WB_DEV_AIR_SET_HIGH_RETRANSMIT_COUNT="DEV_HIGH_RETR";
static constexpr auto WB_ENABLE_RETRANSMISSION="WB_ENABLE_RETRA";
static constexpr auto WB_ENABLE_RETRANSMISSION_VIDEO="WB_RTX_VIDEO";
static constexpr auto WB_ENABLE_RETRANSMISSION_TELEMETRY="WB_RTX_TELEM";
static constexpr auto WB_ENABLE_RETRANSMISSION_RC="WB_RTX_RC";
static constexpr auto WB_RETRANSMISSION_HISTORY_VIDEO_MS="WB_RTX_V_MAXMS";
static constexpr auto WB_RETRANSMISSION_HISTORY_TELEMETRY_MS="WB_RTX_T_MAXMS";
static constexpr auto WB_RETRANSMISSION_HISTORY_RC_MS="WB_RTX_R_MAXMS";
static constexpr auto WB_RETRANSMISSION_REQUEST_RETRIES="WB_RTX_REQ_REP";

// Artosyn link parameters (MAVLink param IDs, <= 16 chars)
static constexpr auto AR_ADDR = "AR_ADDR";
static constexpr auto AR_PORT = "AR_PORT";
static constexpr auto AR_SLOT = "AR_SLOT";
static constexpr auto AR_VPORT = "AR_VPORT";
static constexpr auto AR_TPORT = "AR_TPORT";
static constexpr auto AR_DGRAM = "AR_DGRAM";
static constexpr auto AR_RXBUF = "AR_RXBUF";
static constexpr auto AR_TXBUF = "AR_TXBUF";
static constexpr auto AR_RDTMO = "AR_RDTMO";
static constexpr auto AR_MCS_MD = "AR_MCS_MD";
static constexpr auto AR_MCS_VAL = "AR_MCS_VAL";
static constexpr auto AR_MCS_MIN = "AR_MCS_MIN";
static constexpr auto AR_MCS_MAX = "AR_MCS_MAX";
static constexpr auto AR_BW_MD = "AR_BW_MD";
static constexpr auto AR_BW_VAL = "AR_BW_VAL";
static constexpr auto AR_CHN_MD = "AR_CHN_MD";
static constexpr auto AR_CHN_IDX = "AR_CHN_IDX";
static constexpr auto AR_PWR_ATO = "AR_PWR_ATO";
static constexpr auto AR_PWR_DBM = "AR_PWR_DBM";
static constexpr auto AR_BND_MD = "AR_BND_MD";
static constexpr auto AR_BND_VAL = "AR_BND_VAL";
static constexpr auto AR_CMP_MD = "AR_CMP_MD";
static constexpr auto AR_PWR_MD = "AR_PWR_MD";
static constexpr auto AR_LNA_MD = "AR_LNA_MD";
static constexpr auto AR_LNA_BP = "AR_LNA_BP";
static constexpr auto AR_RF_ATX = "AR_RF_ATX";
static constexpr auto AR_RF_ARX = "AR_RF_ARX";
static constexpr auto AR_RF_BTX = "AR_RF_BTX";
static constexpr auto AR_RF_BRX = "AR_RF_BRX";
static constexpr auto AR_LK_STATE = "AR_LK_STATE";
static constexpr auto AR_RX_MCS = "AR_RX_MCS";
static constexpr auto AR_TX_MCS = "AR_TX_MCS";
static constexpr auto AR_BW = "AR_BW";
static constexpr auto AR_RX_BW = "AR_RX_BW";
static constexpr auto AR_PHY_TP = "AR_PHY_TP";
static constexpr auto AR_REAL_TP = "AR_REAL_TP";
static constexpr auto AR_TX_FREQ = "AR_TX_FREQ";
static constexpr auto AR_RX_FREQ = "AR_RX_FREQ";
static constexpr auto AR_SNR = "AR_SNR";
static constexpr auto AR_LDPC_E = "AR_LDPC_E";
static constexpr auto AR_LDPC_N = "AR_LDPC_N";
static constexpr auto AR_GAIN_A = "AR_GAIN_A";
static constexpr auto AR_GAIN_B = "AR_GAIN_B";
static constexpr auto AR_CHN_AUT = "AR_CHN_AUT";
static constexpr auto AR_CHN_CUR = "AR_CHN_CUR";
static constexpr auto AR_CHN_FK = "AR_CHN_FK";
static constexpr auto AR_PWR_CUR = "AR_PWR_CUR";
static constexpr auto AR_BND_AUT = "AR_BND_AUT";
static constexpr auto AR_BND_CUR = "AR_BND_CUR";
static constexpr auto AR_RF_ATX_R = "AR_RF_ATX_R";
static constexpr auto AR_RF_ARX_R = "AR_RF_ARX_R";
static constexpr auto AR_RF_BTX_R = "AR_RF_BTX_R";
static constexpr auto AR_RF_BRX_R = "AR_RF_BRX_R";
static constexpr auto AR_SW_VER = "AR_SW_VER";
static constexpr auto AR_HW_VER = "AR_HW_VER";
static constexpr auto AR_FW_VER = "AR_FW_VER";
static constexpr auto AR_CMP_TM = "AR_CMP_TM";
static constexpr auto AR_UPTIME = "AR_UPTIME";
static constexpr auto AR_RUNSYS = "AR_RUNSYS";
static constexpr auto AR_AP_TIME = "AR_AP_TIME";
static constexpr auto AR_TX_TPTH = "AR_TX_TPTH";
static constexpr auto AR_RX_TPTH = "AR_RX_TPTH";
static constexpr auto AR_P_SNR = "AR_P_SNR";
static constexpr auto AR_P_LDPC_E = "AR_P_LDPC_E";
static constexpr auto AR_P_LDPC_N = "AR_P_LDPC_N";
static constexpr auto AR_P_GAIN_A = "AR_P_GAIN_A";
static constexpr auto AR_P_GAIN_B = "AR_P_GAIN_B";
static constexpr auto AR_ROLE = "AR_ROLE";
static constexpr auto AR_MODE = "AR_MODE";
static constexpr auto AR_SYNC = "AR_SYNC";
static constexpr auto AR_SYNC_M = "AR_SYNC_M";
static constexpr auto AR_CFG_SBM = "AR_CFG_SBM";
static constexpr auto AR_RT_SBM = "AR_RT_SBM";
static constexpr auto AR_LMAC = "AR_LMAC";
static constexpr auto AR_PAIR = "AR_PAIR";
static constexpr auto AR_PMAC = "AR_PMAC";
static constexpr auto AR_TX_RFM = "AR_TX_RFM";
static constexpr auto AR_RX_RFM = "AR_RX_RFM";
static constexpr auto AR_TX_TEN = "AR_TX_TEN";
static constexpr auto AR_RX_TEN = "AR_RX_TEN";
static constexpr auto AR_TX_TNM = "AR_TX_TNM";
static constexpr auto AR_RX_TNM = "AR_RX_TNM";
static constexpr auto AR_TX_TLN = "AR_TX_TLN";
static constexpr auto AR_RX_TLN = "AR_RX_TLN";
static constexpr auto AR1_S_SNR = "AR1_S_SNR";
static constexpr auto AR1_S_LDPT = "AR1_S_LDPT";
static constexpr auto AR1_S_LDPN = "AR1_S_LDPN";
static constexpr auto AR1_S_GNA = "AR1_S_GNA";
static constexpr auto AR1_S_GNB = "AR1_S_GNB";
static constexpr auto AR1_S_MCS = "AR1_S_MCS";
static constexpr auto AR1_S_CHN = "AR1_S_CHN";
static constexpr auto AR1_S_PWR = "AR1_S_PWR";
static constexpr auto AR1_S_LNI = "AR1_S_LNI";
static constexpr auto AR1_S_LNF = "AR1_S_LNF";
static constexpr auto AR1_S_1TX = "AR1_S_1TX";
static constexpr auto AR1_S_TFK = "AR1_S_TFK";
static constexpr auto AR1_S_LSN = "AR1_S_LSN";
static constexpr auto AR1_S_LGA = "AR1_S_LGA";
static constexpr auto AR1_S_LGB = "AR1_S_LGB";
static constexpr auto AR1_S_HSN = "AR1_S_HSN";
static constexpr auto AR1_S_HGA = "AR1_S_HGA";
static constexpr auto AR1_S_HGB = "AR1_S_HGB";
static constexpr auto AR1_P_SNR = "AR1_P_SNR";
static constexpr auto AR1_P_LDPT = "AR1_P_LDPT";
static constexpr auto AR1_P_LDPN = "AR1_P_LDPN";
static constexpr auto AR1_P_GNA = "AR1_P_GNA";
static constexpr auto AR1_P_GNB = "AR1_P_GNB";
static constexpr auto AR1_P_MCS = "AR1_P_MCS";
static constexpr auto AR1_P_CHN = "AR1_P_CHN";
static constexpr auto AR1_P_PWR = "AR1_P_PWR";
static constexpr auto AR1_P_LNI = "AR1_P_LNI";
static constexpr auto AR1_P_LNF = "AR1_P_LNF";
static constexpr auto AR1_P_1TX = "AR1_P_1TX";
static constexpr auto AR1_P_TFK = "AR1_P_TFK";
static constexpr auto AR1_P_LSN = "AR1_P_LSN";
static constexpr auto AR1_P_LGA = "AR1_P_LGA";
static constexpr auto AR1_P_LGB = "AR1_P_LGB";
static constexpr auto AR1_P_HSN = "AR1_P_HSN";
static constexpr auto AR1_P_HGA = "AR1_P_HGA";
static constexpr auto AR1_P_HGB = "AR1_P_HGB";
static constexpr auto AR_V_RX_AV = "AR_V_RX_AV";
static constexpr auto AR_V_RX_OV = "AR_V_RX_OV";
static constexpr auto AR_V_RX_BS = "AR_V_RX_BS";
static constexpr auto AR_V_RX_DS = "AR_V_RX_DS";
static constexpr auto AR_V_TX_AV = "AR_V_TX_AV";
static constexpr auto AR_V_TX_OV = "AR_V_TX_OV";
static constexpr auto AR_V_TX_BS = "AR_V_TX_BS";
static constexpr auto AR_V_TX_DS = "AR_V_TX_DS";
static constexpr auto AR_T_RX_AV = "AR_T_RX_AV";
static constexpr auto AR_T_RX_OV = "AR_T_RX_OV";
static constexpr auto AR_T_RX_BS = "AR_T_RX_BS";
static constexpr auto AR_T_RX_DS = "AR_T_RX_DS";
static constexpr auto AR_T_TX_AV = "AR_T_TX_AV";
static constexpr auto AR_T_TX_OV = "AR_T_TX_OV";
static constexpr auto AR_T_TX_BS = "AR_T_TX_BS";
static constexpr auto AR_T_TX_DS = "AR_T_TX_DS";

// SBUS output (air side)
static constexpr auto SBUS_EN = "SBUS_EN";
static constexpr auto SBUS_DEV = "SBUS_DEV";
static constexpr auto SBUS_HZ = "SBUS_HZ";


}

#endif //QOPENHD_PARAM_NAMES_H
