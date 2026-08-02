#include "documentedparam.h"
#include <map>
#include <memory>

#include "param_names.h"
//
// Here we have the mapping (if available) and documentation for all parameters
//
// WAY BIGGER file than one would like, but there is no easy alternative

using namespace DocumentedParam;

// These are util methods for the most common cases for adding parameters to the stored parameters set
static void append_int(std::vector<std::shared_ptr<XParam>>& list,std::string param_name,ImprovedIntSetting improved_int,std::string description,bool requires_reboot=false){
    auto tmp=std::make_shared<XParam>(param_name,improved_int,std::nullopt,description,requires_reboot,false);
    list.push_back(tmp);
}
static void append_string(std::vector<std::shared_ptr<XParam>>& list,std::string param_name,ImprovedStringSetting improved_string,std::string description,bool requires_reboot=false){
    auto tmp=std::make_shared<XParam>(param_name,std::nullopt,improved_string,description,requires_reboot,false);
    list.push_back(tmp);
}
static void append_only_documented(std::vector<std::shared_ptr<XParam>>& list,std::string param_name,std::string description,bool requires_reboot=false){
    auto tmp=std::make_shared<XParam>(param_name,std::nullopt,std::nullopt,description,requires_reboot,false);
    list.push_back(tmp);
}
static void append_documented_read_only(std::vector<std::shared_ptr<XParam>>& list,std::string param_name,std::string description){
    auto tmp=std::make_shared<XParam>(param_name,std::nullopt,std::nullopt,description,false,true);
    list.push_back(tmp);
}

static std::vector<std::shared_ptr<XParam>> get_parameters_list(){
    std::vector<std::shared_ptr<XParam>> ret;
    // These params do not exist, they are only for testing
    append_int(ret,"TEST_INT_0",
               ImprovedIntSetting::createEnumEnableDisable(),
               "test"
               );
    {
        std::vector<std::string> values{};
        values.push_back("enum0");
        values.push_back("enum1");
        values.push_back("enum2");
        values.push_back("enum3");
        append_int(ret,"TEST_INT_1", ImprovedIntSetting::createEnum(values),"test");
    }

    // -------------------------------------------------------------------------------------------------------------------------------------------------------
    // Wifibroadcast parameters
    // -------------------------------------------------------------------------------------------------------------------------------------------------------
    append_int(ret,openhd::WB_VIDEO_VARIABLE_BITRATE,
               ImprovedIntSetting::createEnumEnableDisable(),
               "Recommend a matching bitrate to the encoder depending on the selected link parameters,and reduce bitrate on TX errors (failed injections). On by default, but only works on select cameras. On Cameras that"
               "don't support changing the bitrate / are bad at targeting a given bitrate, you have to adjust your link according to your camera needs."
               );
    append_int(ret,openhd::WB_QP_MAX,
               ImprovedIntSetting::createRangeOnly(0,51),
               "Maximum encoder QP. Lower values improve quality but increase required bitrate."
               );
    append_int(ret,openhd::WB_QP_MIN,
               ImprovedIntSetting::createRangeOnly(0,51),
               "Minimum encoder QP. Higher values reduce bitrate but can reduce image quality."
               );
    {
        std::vector<std::string> values{};
        values.push_back("Disable");
        values.push_back("+1 (2 antennas)");
        //values.push_back("+2 Spatial streams");
        //values.push_back("+3 Spatial streams");
        append_int(ret,openhd::WB_ENABLE_STBC,
                   ImprovedIntSetting::createEnum(values),
                   "!! Advanced users only, changing this param can result in no connection !!. This param is not automatically synchronized between air/ground. "
                   "Specifies the difference between the number of space-time streams and the number of spatial streams. Use +1 only if you have 2 antennas."
                   );
    }
    append_int(ret,openhd::WB_ENABLE_LDPC,
               ImprovedIntSetting::createEnumEnableDisable(),
               "!! Advanced users only, changing this param can result in no connection !!. This param is not automatically synchronized between air/ground. "
               "Enable Low density parity check. Needs to be supported by both your tx and rxes."
               );
    append_int(ret,openhd::WB_ENABLE_SHORT_GUARD,
               ImprovedIntSetting::createEnum({"LONG_GI (default)","SHORT_GI"}),
               "!! Advanced users only !!. This param is not automatically synchronized between air/ground. A short guard intervall increases throughput, "
               "but increases packet collisions."
               );
    append_int(ret,openhd::WB_PASSIVE_MODE,
               ImprovedIntSetting::createEnumEnableDisable(),
               "Enable passive mode if you want to use your GCS as a passive listener to an existing openhd air-ground link. E.g. if you want to tune into"
               "someone elses openhd link (if encryption is enabled, you need his encryption key) but not interfere with any RC/MAVLINK control."
               );
    append_int(ret,openhd::WB_PIT_MODE,
               ImprovedIntSetting::createEnumEnableDisable(),
               "Pit mode for TX power levels: when enabled and TX power level mode is active, disarmed uses LOWEST and armed uses the selected level."
               );
    append_int(ret,openhd::WB_DEV_AIR_SET_HIGH_RETRANSMIT_COUNT,
               ImprovedIntSetting::createEnumEnableDisable(),
               "DEV ONLY - DO NOT TOUCH (LEAVE DISABLED). Sets a wifi param that needs to be investigated."
               );
    append_int(ret,openhd::WB_ENABLE_REDUNDANT_TX,
               ImprovedIntSetting::createEnumEnableDisable(),
               "Send packets redundantly on all connected TX cards. Increases robustness but also airtime usage."
               );
    append_int(ret,openhd::WB_ENABLE_RETRANSMISSION,
               ImprovedIntSetting::createEnumEnableDisable(),
               "Enable ARQ retransmission for video. Requires restart to take effect.",
               true
               );
    append_int(ret,openhd::WB_ENABLE_RETRANSMISSION_VIDEO,
               ImprovedIntSetting::createEnumEnableDisable(),
               "Enable ARQ retransmission for video packets. Requires restart to take effect.",
               true
               );
    append_int(ret,openhd::WB_ENABLE_RETRANSMISSION_TELEMETRY,
               ImprovedIntSetting::createEnumEnableDisable(),
               "Enable ARQ retransmission for telemetry packets. Requires restart to take effect.",
               true
               );
    append_int(ret,openhd::WB_ENABLE_RETRANSMISSION_RC,
               ImprovedIntSetting::createEnumEnableDisable(),
               "Enable ARQ retransmission for RC packets. Requires restart to take effect.",
               true
               );
    append_int(ret,openhd::WB_RETRANSMISSION_HISTORY_VIDEO_MS,
               ImprovedIntSetting::createRangeOnly(1,100),
               "Max retransmission history window for video in milliseconds. Larger values allow longer recovery but use more memory.",
               false
               );
    append_int(ret,openhd::WB_RETRANSMISSION_HISTORY_TELEMETRY_MS,
               ImprovedIntSetting::createRangeOnly(1,100),
               "Max retransmission history window for telemetry in milliseconds. Larger values allow longer recovery but use more memory.",
               false
               );
    append_int(ret,openhd::WB_RETRANSMISSION_HISTORY_RC_MS,
               ImprovedIntSetting::createRangeOnly(1,100),
               "Max retransmission history window for RC in milliseconds. Larger values allow longer recovery but use more memory.",
               false
               );
    append_int(ret,openhd::WB_RETRANSMISSION_REQUEST_RETRIES,
               ImprovedIntSetting::createRangeOnly(1,10),
               "How often each retransmission request is sent. Higher values increase reliability but add overhead.",
               false
               );
    {
// ---------- TX POWER - only as placeholders, wizzard is recommended !
        // Measurements of @Marcel Essers:
        //19: 10-12 mW
        //25: 25-30 mW
        //30: 45-50 mW
        //35: 70-80 mW
        //37: 100-110 mW
        //40: 120-140 mW
        //45: 200-230 mW
        //50: 280- 320 mW
        //55: 380-400 mW
        //58: 420-450 mW
        // NOTE: We now have the tx power wizzard !
        auto values_WB_TX_PWR_INDEX=std::vector<ImprovedIntSetting::Item>{
            {"Unitless [1]",1},
            {"Unitless [3]",3},
            {"Unitless [6]",6},
            {"Unitless [10]",10},
            {"Unitless [20]",20},
            {"Unitless [26]",26},
            {"Unitless [40]",40},
            {"Unitless [60]",60},
            {"Unitless [63]",63},                                                                   };
        auto values_WB_TX_PWR_INDEX_ARMED=std::vector<ImprovedIntSetting::Item>{
            {"Disabled [0]",0},
            {"Unitless [1]",1},
            {"Unitless [3]",3},
            {"Unitless [6]",6},
            {"Unitless [10]",10},
            {"Unitless [20]",20},
            {"Unitless [26]",26},
            {"Unitless [40]",40},
            {"Unitless [60]",60},
            {"Unitless [63]",63},
        };
        append_int(ret,openhd::WB_RTL8812AU_TX_PWR_IDX_OVERRIDE,
                   ImprovedIntSetting(0,63,values_WB_TX_PWR_INDEX),
                   "Please use the TX POWER wizzard from WB Link to avoid destroying your card ! Unitless Tx power index value applied when the FC is disarmed and no specific armed"
                   "tx power value is set."
                   );
        append_int(ret,openhd::WB_RTL8812AU_TX_PWR_IDX_ARMED,
                   ImprovedIntSetting(0,63,values_WB_TX_PWR_INDEX_ARMED),
                   "Please use the TX POWER wizzard from WB Link to avoid destroying your card ! Unitless Tx power index value applied when the FC is armed, off by default"
                   );
        append_only_documented(ret,openhd::WB_TX_POWER_MILLI_WATT,
                               "Please use the TX POWER wizzard from WB Link to avoid destroying your card ! tx power in mW when FC is disarmed and no specific armed tx power value is set. Actual tx power depends on the manufacturer.");
        append_only_documented(ret,openhd::WB_TX_POWER_MILLI_WATT_ARMED,
                               "Please use the TX POWER wizzard from WB Link to avoid destroying your card ! tx power in mW when FC is armed, off by default. Actual tx power depends on the manufacturer.");
        append_int(ret,openhd::WB_TX_POWER_LEVEL,
                   ImprovedIntSetting::createEnumSimple({{"DISABLED",-1},{"LOWEST",0},{"LOW",1},{"MID",2},{"HIGH",3}}),
                   "Abstract TX power level selection. Uses per-card sysutil profiles when available."
                   );
    }
// -----------------------------------------------------------------------------------------------------------
    {
        auto default_values=std::vector<ImprovedIntSetting::Item>{
                                                                    {"AUTO (Default)",0},
                                                                    {"FEC_K=8",8},
                                                                    {"FEC_K=10",10},
                                                                    {"FEC_K=12",12},
                                                                    {"FEC_K=16",16},
                                                                    {"FEC_K=20",20},
                                                                    {"FEC_K=50",50},
                                                                    };
        append_int(ret,openhd::WB_VIDEO_FEC_BLOCK_LENGTH,
                   ImprovedIntSetting(0,128,default_values),
                   "Default AUTO (Uses biggest block sizes possible while not adding any latency).Otherwise: WB Video FEC block length, previous FEC_K. "
                   "Increasing this value can improve link stability for free, but can create additional latency.");
    }
    {
        auto default_values=std::vector<ImprovedIntSetting::Item>{
                                                                    {"70% (lower)",70},
                                                                    {"80% (lower)",80},
                                                                    {"90% (slightly lower)",90},
                                                                    {"DEFAULT",100},
                                                                    {"110% (slightly higher)",110},
                                                                    {"120% (higher)",120},
                                                                    {"130% (higher)",130},
                                                                    };
        append_int(ret,openhd::WB_VIDEO_RATE_FOR_MCS_ADJUSTMENT_PERC,
                   ImprovedIntSetting(1,500,default_values),
                   "Reduce used data rate per mcs index by fixed value (not needed in most cases)");
    }
    {
        auto default_values=std::vector<ImprovedIntSetting::Item>{
                                                                    {"10%",10},
                                                                    {"20% (low interf)",20},
                                                                    {"30%",30},
                                                                    {"40%",40},
                                                                    {"50% (high interf)",50},
                                                                    {"100%",100},
                                                                    };
        append_int(ret,openhd::WB_VIDEO_FEC_PERCENTAGE,
                   ImprovedIntSetting(0,100,default_values),
                   "WB Video FEC overhead, in percent. Increases link stability, but also the required link bandwidth (watch out for tx errors). "
                   "The best value depends on your rf environment - recommended is about ~20% in low rf enironemnts(e.g. nature), and ~50% in high rf noise environments(populated areas)."
                   "Note that your rf interference/ packet loss will increase during flight, it is not recommended to decrase this value below 20%.");
    }

    {
        std::pair<std::string,int> val1{"10Mhz",10};
        std::pair<std::string,int> val2{"20Mhz",20};
        std::pair<std::string,int> val3{"40Mhz",40};
        append_int(ret,openhd::WB_CHANNEL_WIDTH,
                   ImprovedIntSetting::createEnumSimple({val1,val2,val3}),
                   "!!!Editing this param manually without care will result in a broken link!!!"
                   );
    }
    {
        std::vector<std::string> mcs_values{};
        for(int i=0;i<=31;i++){
            mcs_values.push_back("MCS"+std::to_string(i));
        }
        append_int(ret,openhd::WB_MCS_INDEX,
                   ImprovedIntSetting::createEnum(mcs_values),
                   "!!!Editing this param manually without care will result in a broken link!!!"
                   );
    }
    {
        std::vector<std::string> disable_or_channels{"Disable"};
        for(int i=1;i<=18;i++){
            disable_or_channels.push_back("Channel "+std::to_string(i));
        }
        append_int(ret,openhd::WB_MCS_INDEX_VIA_RC_CHANNEL,
                   ImprovedIntSetting::createEnum(disable_or_channels),
                   "Dynamically change the MCS Index (Trade range <-> image quality (bitrate)) during flight using your RC and a specific channel "
                   "(similar to how flight modes work)."
                   );
        append_int(ret,openhd::WB_BW_VIA_RC_CHANNEL,
                   ImprovedIntSetting::createEnum(disable_or_channels),
                   "Dynamically change the BW via RC. NOT ALWAYS SAFE TO USE !"
                   );
    }

    append_only_documented(ret,openhd::WB_FREQUENCY,"!!!Editing this param manually without care will result in a broken link!!!");
    {
        auto default_values=std::vector<ImprovedIntSetting::Item>{
                                                                    {"AUTO -1",-1},
                                                                    {"LOW 20",20},
                                                                    {"30",30},
                                                                    {"40",40},
                                                                    {"50",50},
                                                                    {"100",100},
                                                                    {"128",128},
                                                                    };
        append_int(ret,openhd::WB_MAX_FEC_BLOCK_SIZE_FOR_PLATFORM,
                   ImprovedIntSetting(-1,128,default_values),
                   "Developer only, max FEC block size.");
    }
    const auto descr_wifi_card="Detected wifi card type used for wifibroadcast.";
    append_documented_read_only(ret,"WIFI_CARD0",descr_wifi_card);
    append_documented_read_only(ret,"WIFI_CARD1",descr_wifi_card);
    append_documented_read_only(ret,"WIFI_CARD2",descr_wifi_card);
    append_documented_read_only(ret,"WIFI_CARD3",descr_wifi_card);
    append_documented_read_only(ret,"HOTSPOT_CARD","Detected card for wifi hotspot");
    append_documented_read_only(ret,"WB_N_RX_CARDS","TODO");
    append_only_documented(ret,"FC_BATT_N_CELLS","Stored locally on your air unit. If set to a nonzero value, overwrites the batt n cells of any connected GS (QOpenHD)"
                                                 "such that you don't have to change the value when swapping around planes.");
    append_int(ret,"FC_SYS_ID",
               ImprovedIntSetting::createRangeOnly(1,254),
               "MAVLink system ID of the flight controller. Avoid using 100 or 101 (reserved for OpenHD air/ground), and keep it within 1-254.");

    // -------------------------------------------------------------------------------------------------------------------------------------------------------
    // Artosyn link parameters
    // -------------------------------------------------------------------------------------------------------------------------------------------------------
    append_string(ret, openhd::AR_ADDR,
                  ImprovedStringSetting::createAnyValue(),
                  "Artosyn daemon address (host/IP). Changing this reconnects to the daemon.");
    append_int(ret, openhd::AR_PORT,
               ImprovedIntSetting::createRangeOnly(1,65535),
               "Artosyn daemon TCP port.");
    append_int(ret, openhd::AR_SLOT,
               ImprovedIntSetting::createRangeOnly(0,7),
               "Artosyn slot index used by the OpenHD link.");
    append_int(ret, openhd::AR_VPORT,
               ImprovedIntSetting::createRangeOnly(0,255),
               "Artosyn video socket port id.");
    append_int(ret, openhd::AR_TPORT,
               ImprovedIntSetting::createRangeOnly(0,255),
               "Artosyn telemetry socket port id.");
    append_int(ret, openhd::AR_DGRAM,
               ImprovedIntSetting::createEnumEnableDisable(),
               "Enable Artosyn datagram socket mode.");
    append_int(ret, openhd::AR_RXBUF,
               ImprovedIntSetting::createRangeOnly(1,2147483647),
               "Artosyn socket RX buffer size (bytes).");
    append_int(ret, openhd::AR_TXBUF,
               ImprovedIntSetting::createRangeOnly(1,2147483647),
               "Artosyn socket TX buffer size (bytes).");
    append_int(ret, openhd::AR_RDTMO,
               ImprovedIntSetting::createRangeOnly(0,2147483647),
               "Artosyn socket read timeout (ms).");
    append_int(ret, openhd::AR_MCS_MD,
               ImprovedIntSetting::createEnum({"Manual","Auto"}),
               "MCS mode. Manual uses AR_MCS_VAL; Auto uses internal adaptation.");
    append_int(ret, openhd::AR_MCS_VAL,
               ImprovedIntSetting::createRangeOnly(-1,25),
               "Manual MCS value (bb_phy_mcs_e). Use -1 to keep current.");
    append_int(ret, openhd::AR_MCS_MIN,
               ImprovedIntSetting::createRangeOnly(-1,25),
               "Auto MCS minimum limit (bb_phy_mcs_e). -1 disables the limit.");
    append_int(ret, openhd::AR_MCS_MAX,
               ImprovedIntSetting::createRangeOnly(-1,25),
               "Auto MCS maximum limit (bb_phy_mcs_e). -1 disables the limit.");
    append_int(ret, openhd::AR_BW_MD,
               ImprovedIntSetting::createEnum({"Manual","Auto"}),
               "Bandwidth mode. Manual uses AR_BW_VAL; Auto uses internal adaptation.");
    {
        auto bw_items=std::vector<ImprovedIntSetting::Item>{
            {"Ignore (-1)",-1},
            {"1.25 MHz",0},
            {"2.5 MHz",1},
            {"5 MHz",2},
            {"10 MHz",3},
            {"20 MHz",4},
            {"40 MHz",5},
        };
        append_int(ret, openhd::AR_BW_VAL,
                   ImprovedIntSetting(-1,5,bw_items),
                   "Manual bandwidth selection (bb_bandwidth_e).");
    }
    append_int(ret, openhd::AR_CHN_MD,
               ImprovedIntSetting::createEnum({"Manual","Auto"}),
               "Channel mode. Manual uses AR_CHN_IDX; Auto uses internal adaptation.");
    append_int(ret, openhd::AR_CHN_IDX,
               ImprovedIntSetting::createRangeOnly(-1,255),
               "Manual channel index. -1 keeps current.");
    append_int(ret, openhd::AR_PWR_ATO,
               ImprovedIntSetting::createEnum({"Manual","Auto"}),
               "Power control mode. Manual uses AR_PWR_DBM.");
    append_int(ret, openhd::AR_PWR_DBM,
               ImprovedIntSetting::createRangeOnly(-1,31),
               "Manual TX power target (dBm). -1 keeps current.");
    {
        auto auto_items=std::vector<ImprovedIntSetting::Item>{
            {"Ignore (-1)",-1},
            {"Manual (0)",0},
            {"Auto (1)",1},
        };
        append_int(ret, openhd::AR_BND_MD,
                   ImprovedIntSetting(-1,1,auto_items),
                   "Band mode control. -1 keeps current.");
    }
    {
        auto band_items=std::vector<ImprovedIntSetting::Item>{
            {"Ignore (-1)",-1},
            {"1G (150-1000 MHz)",0},
            {"2G (1000-4000 MHz)",1},
            {"5G (4000-7000 MHz)",2},
        };
        append_int(ret, openhd::AR_BND_VAL,
                   ImprovedIntSetting(-1,2,band_items),
                   "Manual band selection (bb_band_e). -1 keeps current.");
    }
    {
        auto cmp_items=std::vector<ImprovedIntSetting::Item>{
            {"Ignore (-1)",-1},
            {"Disable (0)",0},
            {"Enable (1)",1},
        };
        append_int(ret, openhd::AR_CMP_MD,
                   ImprovedIntSetting(-1,1,cmp_items),
                   "Compliance mode control. -1 keeps current.");
    }
    {
        auto pwr_mode_items=std::vector<ImprovedIntSetting::Item>{
            {"Ignore (-1)",-1},
            {"Open loop (0)",0},
            {"Closed loop (1)",1},
        };
        append_int(ret, openhd::AR_PWR_MD,
                   ImprovedIntSetting(-1,1,pwr_mode_items),
                   "Power mode (bb_phy_pwr_mode_e). -1 keeps current.");
    }
    {
        auto lna_mode_items=std::vector<ImprovedIntSetting::Item>{
            {"Ignore (-1)",-1},
            {"Manual (0)",0},
            {"Auto (1)",1},
        };
        append_int(ret, openhd::AR_LNA_MD,
                   ImprovedIntSetting(-1,1,lna_mode_items),
                   "LNA mode control. -1 keeps current.");
    }
    {
        auto lna_bp_items=std::vector<ImprovedIntSetting::Item>{
            {"Ignore (-1)",-1},
            {"LNA (0)",0},
            {"Bypass (1)",1},
        };
        append_int(ret, openhd::AR_LNA_BP,
                   ImprovedIntSetting(-1,1,lna_bp_items),
                   "LNA bypass control. -1 keeps current.");
    }
    {
        auto rf_items=std::vector<ImprovedIntSetting::Item>{
            {"Ignore (-1)",-1},
            {"Off (0)",0},
            {"On (1)",1},
        };
        append_int(ret, openhd::AR_RF_ATX,
                   ImprovedIntSetting(-1,1,rf_items),
                   "RF path A TX enable. -1 keeps current.");
        append_int(ret, openhd::AR_RF_ARX,
                   ImprovedIntSetting(-1,1,rf_items),
                   "RF path A RX enable. -1 keeps current.");
        append_int(ret, openhd::AR_RF_BTX,
                   ImprovedIntSetting(-1,1,rf_items),
                   "RF path B TX enable. -1 keeps current.");
        append_int(ret, openhd::AR_RF_BRX,
                   ImprovedIntSetting(-1,1,rf_items),
                   "RF path B RX enable. -1 keeps current.");
    }

    // Read-only Artosyn metrics and status
    {
        const std::vector<std::pair<std::string,std::string>> ro_params{
            {openhd::AR_LK_STATE,"Artosyn link state (bb_link_state_e)."},
            {openhd::AR_RX_MCS,"RX MCS (bb_phy_mcs_e)."},
            {openhd::AR_TX_MCS,"TX MCS (bb_phy_mcs_e)."},
            {openhd::AR_BW,"TX bandwidth (bb_bandwidth_e)."},
            {openhd::AR_RX_BW,"RX bandwidth (bb_bandwidth_e)."},
            {openhd::AR_PHY_TP,"PHY throughput estimate (kbps)."},
            {openhd::AR_REAL_TP,"Measured throughput (kbps)."},
            {openhd::AR_TX_FREQ,"TX center frequency (kHz)."},
            {openhd::AR_RX_FREQ,"RX center frequency (kHz)."},
            {openhd::AR_SNR,"SNR (linear, see bb_api.h for conversion)."},
            {openhd::AR_LDPC_E,"LDPC error blocks."},
            {openhd::AR_LDPC_N,"LDPC total blocks."},
            {openhd::AR_GAIN_A,"RX gain path A."},
            {openhd::AR_GAIN_B,"RX gain path B."},
            {openhd::AR_CHN_AUT,"Channel auto mode flag."},
            {openhd::AR_CHN_CUR,"Current channel index."},
            {openhd::AR_CHN_FK,"Current channel frequency (kHz)."},
            {openhd::AR_PWR_CUR,"Current TX power (dBm)."},
            {openhd::AR_BND_AUT,"Band auto mode flag."},
            {openhd::AR_BND_CUR,"Current band (bb_band_e)."},
            {openhd::AR_RF_ATX_R,"RF path A TX state."},
            {openhd::AR_RF_ARX_R,"RF path A RX state."},
            {openhd::AR_RF_BTX_R,"RF path B TX state."},
            {openhd::AR_RF_BRX_R,"RF path B RX state."},
            {openhd::AR_SW_VER,"Artosyn software version."},
            {openhd::AR_HW_VER,"Artosyn hardware version."},
            {openhd::AR_FW_VER,"Artosyn firmware version."},
            {openhd::AR_CMP_TM,"Artosyn build/compile time."},
            {openhd::AR_UPTIME,"Artosyn uptime (s)."},
            {openhd::AR_RUNSYS,"Running system/app id."},
            {openhd::AR_AP_TIME,"AP time value (device-specific)."},
            {openhd::AR_TX_TPTH,"TX throughput threshold (kbps)."},
            {openhd::AR_RX_TPTH,"RX throughput threshold (kbps)."},
            {openhd::AR_P_SNR,"Peer SNR (linear)."},
            {openhd::AR_P_LDPC_E,"Peer LDPC error blocks."},
            {openhd::AR_P_LDPC_N,"Peer LDPC total blocks."},
            {openhd::AR_P_GAIN_A,"Peer RX gain path A."},
            {openhd::AR_P_GAIN_B,"Peer RX gain path B."},
            {openhd::AR_ROLE,"Device role."},
            {openhd::AR_MODE,"Operating mode (bb_mode_e)."},
            {openhd::AR_SYNC,"Sync mode."},
            {openhd::AR_SYNC_M,"Sync master flag."},
            {openhd::AR_CFG_SBM,"Configured SBMP value."},
            {openhd::AR_RT_SBM,"Runtime SBMP value."},
            {openhd::AR_LMAC,"Local MAC (baseband)."},
            {openhd::AR_PAIR,"Pair state."},
            {openhd::AR_PMAC,"Peer MAC (baseband)."},
            {openhd::AR_TX_RFM,"TX RF mode (bb_tx_mode_e)."},
            {openhd::AR_RX_RFM,"RX RF mode (bb_rx_mode_e)."},
            {openhd::AR_TX_TEN,"TX time interleaving enable."},
            {openhd::AR_RX_TEN,"RX time interleaving enable."},
            {openhd::AR_TX_TNM,"TX time interleaving block count."},
            {openhd::AR_RX_TNM,"RX time interleaving block count."},
            {openhd::AR_TX_TLN,"TX time interleaving length."},
            {openhd::AR_RX_TLN,"RX time interleaving length."},
            {openhd::AR1_S_SNR,"1v1 self SNR (linear)."},
            {openhd::AR1_S_LDPT,"1v1 self LDPC TLV error ratio (x10000)."},
            {openhd::AR1_S_LDPN,"1v1 self LDPC frame error ratio (x10000)."},
            {openhd::AR1_S_GNA,"1v1 self RX gain A."},
            {openhd::AR1_S_GNB,"1v1 self RX gain B."},
            {openhd::AR1_S_MCS,"1v1 self TX MCS."},
            {openhd::AR1_S_CHN,"1v1 self TX channel."},
            {openhd::AR1_S_PWR,"1v1 self TX power."},
            {openhd::AR1_S_LNI,"1v1 self LNA inner bypass."},
            {openhd::AR1_S_LNF,"1v1 self LNA FEM bypass."},
            {openhd::AR1_S_1TX,"1v1 self RF 1TX mode flag."},
            {openhd::AR1_S_TFK,"1v1 self TX frequency (kHz)."},
            {openhd::AR1_S_LSN,"1v1 self low-band channel SNR."},
            {openhd::AR1_S_LGA,"1v1 self low-band gain A."},
            {openhd::AR1_S_LGB,"1v1 self low-band gain B."},
            {openhd::AR1_S_HSN,"1v1 self high-band channel SNR."},
            {openhd::AR1_S_HGA,"1v1 self high-band gain A."},
            {openhd::AR1_S_HGB,"1v1 self high-band gain B."},
            {openhd::AR1_P_SNR,"1v1 peer SNR (linear)."},
            {openhd::AR1_P_LDPT,"1v1 peer LDPC TLV error ratio (x10000)."},
            {openhd::AR1_P_LDPN,"1v1 peer LDPC frame error ratio (x10000)."},
            {openhd::AR1_P_GNA,"1v1 peer RX gain A."},
            {openhd::AR1_P_GNB,"1v1 peer RX gain B."},
            {openhd::AR1_P_MCS,"1v1 peer TX MCS."},
            {openhd::AR1_P_CHN,"1v1 peer TX channel."},
            {openhd::AR1_P_PWR,"1v1 peer TX power."},
            {openhd::AR1_P_LNI,"1v1 peer LNA inner bypass."},
            {openhd::AR1_P_LNF,"1v1 peer LNA FEM bypass."},
            {openhd::AR1_P_1TX,"1v1 peer RF 1TX mode flag."},
            {openhd::AR1_P_TFK,"1v1 peer TX frequency (kHz)."},
            {openhd::AR1_P_LSN,"1v1 peer low-band channel SNR."},
            {openhd::AR1_P_LGA,"1v1 peer low-band gain A."},
            {openhd::AR1_P_LGB,"1v1 peer low-band gain B."},
            {openhd::AR1_P_HSN,"1v1 peer high-band channel SNR."},
            {openhd::AR1_P_HGA,"1v1 peer high-band gain A."},
            {openhd::AR1_P_HGB,"1v1 peer high-band gain B."},
            {openhd::AR_V_RX_AV,"Video socket RX available flag."},
            {openhd::AR_V_RX_OV,"Video socket RX overflow count."},
            {openhd::AR_V_RX_BS,"Video socket RX buffer size (bytes)."},
            {openhd::AR_V_RX_DS,"Video socket RX buffered data size (bytes)."},
            {openhd::AR_V_TX_AV,"Video socket TX available flag."},
            {openhd::AR_V_TX_OV,"Video socket TX overflow count."},
            {openhd::AR_V_TX_BS,"Video socket TX buffer size (bytes)."},
            {openhd::AR_V_TX_DS,"Video socket TX buffered data size (bytes)."},
            {openhd::AR_T_RX_AV,"Telemetry socket RX available flag."},
            {openhd::AR_T_RX_OV,"Telemetry socket RX overflow count."},
            {openhd::AR_T_RX_BS,"Telemetry socket RX buffer size (bytes)."},
            {openhd::AR_T_RX_DS,"Telemetry socket RX buffered data size (bytes)."},
            {openhd::AR_T_TX_AV,"Telemetry socket TX available flag."},
            {openhd::AR_T_TX_OV,"Telemetry socket TX overflow count."},
            {openhd::AR_T_TX_BS,"Telemetry socket TX buffer size (bytes)."},
            {openhd::AR_T_TX_DS,"Telemetry socket TX buffered data size (bytes)."},
        };
        for(const auto& item: ro_params){
            append_documented_read_only(ret,item.first,item.second);
        }
    }

    // -------------------------------------------------------------------------------------------------------------------------------------------------------
    // video / camera parameters
    // -------------------------------------------------------------------------------------------------------------------------------------------------------
    {
        {
            const auto choices_video_res_framerate=std::vector<std::string>{
                "640x480@30",
                "640x480@60",
                "640x480@90",
                //"960x720@30",
                //"960x720@60",
                "1280x720@30",
                "1280x720@49",
                "1280x720@60",
                //"1440x1080@30",
                "1920x1080@30",
            };
            append_string(ret,"RESOLUTION_FPS",ImprovedStringSetting::create_from_keys_only(choices_video_res_framerate),
                          "Video WIDTHxHEIGHT@FPS. You can enter any value you want here, but if you select a video format that is not supported by your camera, the video stream will stop");
        }
        append_string(ret,"IP_CAM_PIPELINE",ImprovedStringSetting::createAnyValue(),
                      "GStreamer source pipeline for an IP camera. Use {IP} for IP_CAM_ADDRESS. It must output elementary H264/H265 matching VIDEO_CODEC; limited to 127 characters.");
        append_string(ret,"IP_CAM_ADDRESS",ImprovedStringSetting::createAnyValue(),
                      "IPv4 address of this IP camera. OpenHD adds a secondary local /24 address when required without replacing the normal Ethernet configuration.");
        append_int(ret,"VIDEO_CODEC",
                   //NOTE: MJPEG has been removed intentionally, since we are going to eventually remove support for it in
                   //favour of h264
                   // ,"mjpeg"
                   ImprovedIntSetting::createEnum( std::vector<std::string>{"h264","h265"}),
                   "Video codec. If your camera/ground station does not support HW accelerated encoding/decoding of the selected codec,it'l default to SW encode/decode. "
                   "A reboot (air&ground) is recommended after changing this parameter."
                   );
        append_int(ret,"AIR_RECORDING_E",
                   ImprovedIntSetting::createEnum( std::vector<std::string>{"DISABLE","ENABLE","AUTO(armed)"}),
                   "Record video data locally on your air unit. You can find the files under /home/openhd/Videos on the SD card and/or download them via the web ui."
                   "When AUTO is set, air recording automatically starts (and stops) when you arm/disarm your drone (requires inav / ardupilot FC)."
                   );
        append_int(ret,"STREAMING_E",
                   ImprovedIntSetting::createEnumEnableDisable(),
                   "Enable / disable streaming for this camera. Note that this setting is persistent at run time - once you disable streaming for a camera, you won't have video"
                   " until you re-enable streaming or reboot your air unit. On by default"
                   );
        {
            auto default_values=std::vector<ImprovedIntSetting::Item>{
                                                                        {"2MBit/s",2},
                                                                        {"4MBit/s",4},
                                                                        {"6MBit/s",6},
                                                                        {"8MBit/s (default)",8},
                                                                        {"10MBit/s (high)",10},
                                                                        {"14MBit/s (high)",14},
                                                                        {"18MBit/s (high)",18},
                                                                        };
            append_int(ret,"BITRATE_MBITS",
                       ImprovedIntSetting(1,100,default_values),
                       "Camera encoder bitrate, does not include FEC overhead. "
                       "!! If variable bitrate is enabled (recommended), this value is ignored.!! Otherwise, you can manually set a fixed camera/encoder bitrate here. "
                       "NOTE: If you are using a camera not listed on the OpenHD recommended cameras list, the bitrate might be fixed by the vendor and not changeable."
                       );
        }
        {
            auto default_values=std::vector<ImprovedIntSetting::Item>{
                                                                        {"2  (best recovery)",2},
                                                                        {"3  (best recovery)",3},
                                                                        {"5  (good recovery)",5},
                                                                        {"8  (good recovery)",8},
                                                                        {"10 (medium recovery)",10},
                                                                        {"15 (medium recovery)",15},
                                                                        {"20 (bad recovery)",20},
                                                                        };
            append_int(ret,"KEYFRAME_I",
                       ImprovedIntSetting(0,100,default_values),
                       "Keyframe / instantaneous decode refresh interval, in frames. E.g. if set to 15, every 15th frame will be a key frame. Higher values result in better image compression, but increase the likeliness of microfreezes."
                       );
        }
        append_int(ret,"QP_PID_ENABLE",
                   ImprovedIntSetting::createEnumEnableDisable(),
                   "Enable experimental runtime QP limit PID control. OpenHD compares measured encoder bitrate against the current target bitrate and adjusts live QP min/max to reduce bitrate over/undershoot. Off by default."
                   );
        append_int(ret,"RK_BITRATE_PID",
                   ImprovedIntSetting::createEnumEnableDisable(),
                   "Enable experimental RK3566/RK3588 MPP VBR bitrate PID control. OpenHD compares measured encoder bitrate against the current target bitrate and adjusts live encoder bps/bps-min/bps-max. On by default for RK3566/RK3588 testing."
                   );
        append_int(ret,"FORCE_SW_ENC",
                   ImprovedIntSetting::createEnumEnableDisable(),
                   "Force SW encode for the given camera, only enable if your camera supports outputting an appropriate raw format."
                   );
        append_int(ret,"V_SWITCH_CAM",
                   ImprovedIntSetting::createEnumEnableDisable(),
                   "Requires reboot. Switch primary and secondary camera.");
        append_only_documented(ret,"V_PRIMARY_PERC",
                               "If Variable bitrate is enabled,your primary camera is given that much percentage of the total available link bandwidth. "
                               "The rest is given to the secondary camera. Default to 60% (60:40 split).");
        append_int(ret,"V_IP_CAM_MBITS",
                   ImprovedIntSetting(1,20,{
                       ImprovedIntSetting::Item{"1 MBit/s",1},
                       ImprovedIntSetting::Item{"2 MBit/s (default)",2},
                       ImprovedIntSetting::Item{"3 MBit/s",3},
                       ImprovedIntSetting::Item{"4 MBit/s",4}
                   }),
                   "Fixed link bitrate reserved for an IP camera in either slot. OpenHD cannot adjust the IP camera encoder: configure its own WebUI to stay at or below this value and keep it low.");

        append_int(ret,"ROTATION_FLIP",
                    ImprovedIntSetting(-1,2130706433,{
                       ImprovedIntSetting::Item{"NONE",0},
                       ImprovedIntSetting::Item{"VFLIP°",1},
                       ImprovedIntSetting::Item{"HFLIP",2},
                       ImprovedIntSetting::Item{"BOTH",3}
                   }),
                   "Flip video vertically / horizontally (ROTATE)"
                   );

        append_int(ret,"ROTATION_DEG",
                   ImprovedIntSetting(0,270,{
                                               ImprovedIntSetting::Item{"0°(disable)",0},
                                               //ImprovedIntSetting::Item{"90 (mmal only)°",90},
                                               ImprovedIntSetting::Item{"180°",180},
                                               //ImprovedIntSetting::Item{"270°(mmal only)",270}
                                      }),
                   "Rotate video"
                   );
        append_int(ret,"INTRA_REFRESH",
                   ImprovedIntSetting(-1,2130706433,{
                                                          ImprovedIntSetting::Item{"NONE",-1},
                                                          ImprovedIntSetting::Item{"CYCLIC",0},
                                                          ImprovedIntSetting::Item{"ADAPTIVE",1},
                                                          ImprovedIntSetting::Item{"BOTH",2},
                                                          ImprovedIntSetting::Item{"CYCLIC_ROWS",2130706433}
                                                      }),
                   "Experimental,Default NONE, Type of Intra Refresh to use"
                   );
        append_only_documented(ret,"BRIGHTNESS","Image capture brightness, [0..200], default 100. Increase for a brighter Image. However, if available, it is recommended to tune AWB or EXP instead.");
        append_only_documented(ret,"ISO","ISO value to use (0 = Auto)");

        {
            // rpicamsrc only for now
            auto gst_awb_modes=std::vector<std::string>{
                "OFF",
                "AUTO",
                "SUNLIGHT",
                "CLOUDY",
                "SHADE",
                "TUNGSTEN",
                "FLUORESCENT",
                "INCANDESCENT",
                "FLASH",
                "HORIZON"
            };
            auto gst_exposure_modes=std::vector<std::string>{
                "OFF",
                "AUTO",
                "NIGHT",
                "NIGHTPREVIEW",
                "BACKLIGHT",
                "SPOTLIGHT",
                "SPORTS",
                "SNOW",
                "BEACH",
                "VERYLONG",
                "FIXEDFPS",
                "ANTISHAKE",
                "FIREWORKS",
            };
            auto values_metering_mode=std::vector<std::string>{
                "AVERAGE","SPOT","BACKLIST","MATRIX"
            };
            append_int(ret,"AWB_MODE",
                       ImprovedIntSetting::createEnum(gst_awb_modes),
                       "AWB Automatic white balance mode"
                       );
            append_int(ret,"EXP_MODE",
                       ImprovedIntSetting::createEnum(gst_exposure_modes),
                       "EXP Exposure mode"
                       );
            append_int(ret,"METERING_MODE",
                       ImprovedIntSetting::createEnum(values_metering_mode),
                       "Camera exposure metering mode to use. Default average."
                       );
        }
        {
            // libcamera only
            auto denoise_modes=std::vector<std::string>{
                "AUTO",
                "OFF",
                "CDN_OFF",
                "CDN_FAST",
                "CDN_HQ",
            };
            append_int(ret,"DENOISE_INDEX_LC",
                       ImprovedIntSetting::createEnum(denoise_modes),
                       "Setting this to off reduces latency by ~1 Frame on the cost of slightly reduced image quality in dark situations."
                       );

            append_int(ret,"METERING_MODE_LC",
                       ImprovedIntSetting::createEnum(std::vector<std::string>{
                           "centre (default)", "spot", "average", //crashes libcamera "custom"
                       }), "Libcamera Metering mode.")
                ;
            append_int(ret,"AWB_MODE_LC",
                       ImprovedIntSetting::createEnum(std::vector<std::string>{
                           "auto (default)", "incandescent", "tungsten", "fluorescent", "indoor", "daylight",
                           "cloudy", "custom"
                       }), "Libcamera AWB mode.")
                ;
            append_int(ret,"EXPOSURE_MODE_LC",
                       ImprovedIntSetting::createEnum(std::vector<std::string>{
                           "normal (default)", "sport"
                       }), "Libcamera exposure mode.")
                ;
            append_int(ret,"SHUTTER_US_LC",
                       ImprovedIntSetting::createEnumSimple(
                           std::vector<std::pair<std::string,int>>{
                                                                    {"auto",0},
                                                                    {"example1 (1000us)",1000},
                                                                    {"example2 (5000us)",5000},
                                                                    {"example3 (16666us)",16666},
                                                                    {"example4 (33333us)",33333},
                                                                    }),"Libcamera shutter in microseconds. Normally seleceted automatically, but you can overwrite this value for more control.");
            append_int(ret,"CONTRAST_LC",
                       ImprovedIntSetting::createEnumSimple(
                           std::vector<std::pair<std::string,int>>{
                                                                    {"default(100)",100},
                                                                    {"higher (120)",120},
                                                                    {"higher (150)",150},
                                                                    {"lower(80)",80},
                                                                    {"lower (50)",50},
                                                                    }),
                       "Libcamera contrast");
            append_int(ret,"SATURATION_LC",
                       ImprovedIntSetting::createEnumSimple(
                           std::vector<std::pair<std::string,int>>{
                                                                    {"default(100)",100},
                                                                    {"higher (120)",120},
                                                                    {"higher (150)",150},
                                                                    {"lower(80)",80},
                                                                    {"lower (50)",50},
                                                                    }),
                       "Libcamera saturation");
            append_int(ret,"SHARPNESS_LC",
                       ImprovedIntSetting::createEnumSimple(
                           std::vector<std::pair<std::string,int>>{
                                                                    {"default(100)",100},
                                                                    {"higher (120)",120},
                                                                    {"higher (150)",150},
                                                                    {"lower(80)",80},
                                                                    {"lower (50)",50},
                                                                    }),
                       "Libcamera sharpness");
            append_int(ret,"EXPOSURE_LC",
                       ImprovedIntSetting::createEnumSimple(
                           std::vector<std::pair<std::string,int>>{
                                                                    {"default(0)",0},
                                                                    {"higher (5)",5},
                                                                    {"higher (10)",10},
                                                                    {"lower(-5)",-5},
                                                                    {"lower (-10)",-10},
                                                                    }),
                       "Libcamera exposure value, [-10,10]");
        }
        append_int(ret,"HIGH_ENCRYPTION",
                   ImprovedIntSetting::createEnumEnableDisable(),
                   "Enable ultra secure - but expensive - video encryption - by default, video is not encrypted (only validated) to save CPU performance (Telemetry is always encrypted though)."
                   "It is recommended to leave video encryption off unless you are using at least RPI 4 on air and are TOTALLY worried about someone listening to your video"
                   " - even with encryption disabled, it is not easy for an attacker to listen in on your openhd video "
                   "(and impossible to attack your video due to always on secure packet validation)."
                   );
    }
    // -------------------------------------------------------------------------------------------------------------------------------------------------------
    // Other stuff
    // -------------------------------------------------------------------------------------------------------------------------------------------------------
    {
        append_documented_read_only(ret,"BOARD_TYPE","TODO");
        append_int(ret,"ENABLE_JOY_RC",ImprovedIntSetting::createEnumEnableDisable(),
                   "Only enable joystick rc if you actually use it to save cpu / bandwidth. If enabled, you can connect a joystick to your ground station for RC. After enabling,"
                   "a reboot is recommended, but not neccessary.");
        append_int(ret,"FC_UART_FLWCTL",ImprovedIntSetting::createEnumEnableDisable(),
                   "Leave disabled, for setups with an additional 4th cable for uart flow control");
        auto baud_rate_items=std::vector<ImprovedIntSetting::Item>{
                                                                     {"9600",9600},
                                                                     {"19200",19200},
                                                                     {"38400",38400},
                                                                     {"57600",57600},
                                                                     {"115200",115200},
                                                                     {"230400",230400},
                                                                     {"460800",460800},
                                                                     {"500000",500000},
                                                                     {"576000",576000},
                                                                     {"921600",921600},
                                                                     {"1000000",1000000},
                                                                     };
        append_int(ret,"FC_UART_BAUD",ImprovedIntSetting(0,1000000,baud_rate_items),
                   "RPI HW UART baud rate, needs to match the UART baud rate set on your FC");
        append_int(ret,"OHD_UART_EN",ImprovedIntSetting::createEnumEnableDisable(),
                   "Enable or disable the dedicated OpenHD telemetry UART. Turn this off to stop forwarding MAVLink over the selected port.");
        append_int(ret,"OHD_UART_BAUD",ImprovedIntSetting(0,1000000,baud_rate_items),
                   "Baud rate for the OpenHD telemetry UART on air and ground. Match this with the connected device's expectation.");
        append_int(ret,"OHD_UART_FLW",ImprovedIntSetting::createEnumEnableDisable(),
                   "Toggle RTS/CTS flow control for the OpenHD telemetry UART.");
        append_int(ret,openhd::SBUS_EN,ImprovedIntSetting::createEnumEnableDisable(),
                   "Enable SBUS output on the air unit (generated from RC override messages).");
        append_string(ret,openhd::SBUS_DEV,ImprovedStringSetting::createAnyValue(),
                      "UART device for SBUS output (e.g. /dev/serial0, /dev/ttyAMA1).");
        append_int(ret,openhd::SBUS_HZ,ImprovedIntSetting::createRangeOnly(1,1000),
                   "SBUS output update rate (Hz).");
        append_int(ret,"TRACK_UART_BAUD",ImprovedIntSetting(0,1000000,baud_rate_items),
                   "Baud rate for the ground side tracker/output UART.");
        append_int(ret,"TRACK_UART_FLOW",ImprovedIntSetting::createEnumEnableDisable(),
                   "Enable RTS/CTS flow control on the ground tracker/output UART.");
        const auto uart_priority_items = std::vector<ImprovedIntSetting::Item>{
            {"0 (lowest)",0},
            {"1",1},
            {"2",2},
            {"3 (default RC)",3},
            {"4",4},
            {"5",5},
            {"6",6},
            {"7",7},
            {"8",8},
            {"9",9},
            {"10 (highest)",10},
        };
        append_int(ret,"UART_PRI_RC",ImprovedIntSetting(0,10,uart_priority_items),
                   "Priority bucket for RC/control messages on the OpenHD UART. Higher values are sent first.");
        append_int(ret,"UART_PRI_OHD",ImprovedIntSetting(0,10,uart_priority_items),
                   "Priority bucket for OpenHD internal telemetry on the OpenHD UART.");
        append_int(ret,"UART_PRI_FC",ImprovedIntSetting(0,10,uart_priority_items),
                   "Priority bucket for FC-originating MAVLink on the OpenHD UART.");
        append_int(ret,"CONFIG_BOOT_AIR",ImprovedIntSetting::createEnumEnableDisable(),"DEV, change boot as air / ground",true);
        append_int(ret,"WIFI_MODE",ImprovedIntSetting::createEnum({"OFF","HOTSPOT","CLIENT"}),
                   "Select how the built-in WiFi card is used. OFF disables WiFi entirely, HOTSPOT enables the access point for nearby devices, and CLIENT connects the unit to an existing WiFi network.");
        append_int(ret,"WIFI_HOTSPOT_E",ImprovedIntSetting::createEnum({"AUTO","ALWAYS_OFF","ALWAYS_ON"}),
                   "Enable/Disable WiFi hotspot such that you can connect to your air/ground unit via normal WiFi. Frequency is always the opposite of your WB link, e.g. "
                   "2.4G if your wb link is 5.8G and opposite. In AUTO (default), the wifi hotspot is automatically disarmed when you arm your FC (to avoid interference).");
        append_documented_read_only(ret,"WIFI_IFACES","Comma separated list of detected WiFi interfaces and their current roles (wb/hotspot/client/idle).");
        append_string(ret,"WIFI_HS_IFACE",ImprovedStringSetting::createAnyValue(),
                      "Optional interface override to use for hotspot mode (empty = auto). Changing this reconfigures the hotspot when WiFi mode is set to HOTSPOT.");
        append_string(ret,"WIFI_CL_IFACE",ImprovedStringSetting::createAnyValue(),
                      "Optional interface to use for WiFi client mode (empty = auto). Only applied when WiFi mode is set to CLIENT.");
        append_string(ret,"WIFI_CL_SSID",ImprovedStringSetting::createAnyValue(),
                      "SSID to join when WiFi mode is set to CLIENT.");
        append_string(ret,"WIFI_CL_PW",ImprovedStringSetting::createAnyValue(),
                      "Password to join when WiFi mode is set to CLIENT.");

        append_int(ret,"ETH_HOTSPOT_E",ImprovedIntSetting::createEnumEnableDisable(),
                   "Enable/Disable ethernet hotspot. When enabled, your rpi becomes a DHCPD server and starts forwarding video & telemetry if you connect a device via ethernet."
                   "However, this doesn't allow you to share your other device(s) internet with the RPI (e.g android) and in general, it is recommended to use ETH_PASSIVE_F instead."
                   "Cannot be used simultanoeusly with ETH_PASSIVE_F. Requires reboot.",true);
        append_int(ret,"ETH_PASSIVE_F",ImprovedIntSetting::createEnumEnableDisable(),
                   "Enable automatic video & telemetry forwarding via ethernet if EITH_HOTSPOT_E is false (Recommended)."
                   "Cannot be used simultaneously with ETH_HOTSPOT_E. Doesn't require reboot.",false);
        {
            auto values=std::vector<std::string>{"UNMANAGED","HOTSPOT","FORWARD+INTERNET"};
            append_int(ret,"ETHERNET",ImprovedIntSetting::createEnum(values),
                       "Specify the intended usage of the ground station ethernet port (for connecting external devices). A reboot might be required after changing this param.");
        }
        {
            auto values=std::vector<std::string>{"untouched","high","low"};
            append_int(ret,"GPIO_2",ImprovedIntSetting::createEnum(values),
                       "Experimental, allows manually controlling a rpi gpio for special uses like a LED, landing gear, ...");
            append_int(ret,"GPIO_26",ImprovedIntSetting::createEnum(values),
                       "Experimental, allows manually controlling a rpi gpio for special uses like a LED, landing gear, ...");
        }
        //
        {
            auto fc_uart_conn_values=std::vector<ImprovedStringSetting::Item>{
                {"DISABLE",""},
                {"DEFAULT","DEFAULT"},
                {"/dev/serial0","/dev/serial0"},
                {"/dev/ttyAMA1","/dev/ttyAMA1"},
                {"/dev/ttyAMA2","/dev/ttyAMA2"},
                {"/dev/ttyAMA3","/dev/ttyAMA3"},
                {"/dev/ttyAMA4","//dev/ttyAMA4"},
                {"/dev/serial1","/dev/serial1"},
                {"/dev/ttyS1","/dev/ttyS1"},
                {"/dev/ttyS2","/dev/ttyS2"},
                {"/dev/ttyUSB0","/dev/ttyUSB0"},
                {"/dev/ttyUSB1","/dev/ttyUSB1"},
                {"/dev/ttyACM0","/dev/ttyACM0"},
                {"/dev/ttyACM1","/dev/ttyACM1"},
                {"/dev/ttyS7","/dev/ttyS7"}
            };
            append_string(ret,"FC_UART_CONN",ImprovedStringSetting{fc_uart_conn_values},
                          "Telemetry FC<->Air unit. Make sure FC_UART_BAUD matches your FC. DEFAULT - primary telemetry serial of this platform (see wiki)."
                          "Otherwise, any linux serial fd filename (dev/testing).");
            //same for ground uart out
            append_string(ret,"TRACKER_UART_OUT",ImprovedStringSetting{fc_uart_conn_values},
                          "Enable mavlink telemetry out via UART on the ground station for connecting a tracker or even an RC with mavlink lua script.");
            append_string(ret,"OHD_UART_TLM",ImprovedStringSetting{fc_uart_conn_values},
                          "OpenHD UART telemetry bridge for air and ground units. Configure the second UART device exactly like the tracker or FC UART ports.");
        }
        // Channel mapping presets for device(s)
        {
            /*auto values=std::vector<ImprovedStringSetting::Item>{
            {"default"       ,"0,1,2,3,4,5,6,7"},
            {"Steamdeck AETR","3,4,0,1,2,5,6,7"},
            {"Steamdeck EXP","0,1,3,4,2,5,6,7"},
            {"EX1",           "0,1,3,2,4,5,6,7"},
            {"EX2",           "0,1,4,5,2,3,6,7"},
            {"EX3",           "3,2,1,0,4,5,6,7"},
        };*/
            auto values=std::vector<ImprovedStringSetting::Item>{ // 4,5,1,2,3
                                                                   {"default"       ,"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18"},
                                                                   {"Steamdeck AETR","4,5,1,2,3,6,7,8,9,10,11,12,13,14,15,16,17,18"},
                                                                   {"EX1"           ,"2,1,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18"},
                                                                   {"EX2"           ,"2,1,4,3,5,6,7,8,9,10,11,12,13,14,15,16,17,18"},
                                                                   };
            append_string(ret,"RC_CHAN_MAP",ImprovedStringSetting{values},
                          "Change which joystick 'channel' is taken for each RC channel. This is a list of numbers, where each number X at position N means take joystick input nr X for channel N."
                          " For example, 1,4,... means take channel number 1 for the first channel, and channel number 4 for the second channel. Needs to have ! all! 18 channel elements seperated by a ','");
        }
        {
            auto infiray_colorpalete_items=std::vector<ImprovedIntSetting::Item>{
                    {"CMD Shutter calibration",32768},
                    {"CMD YUYV output",32773},
                    {"CMD save configurations",33022},
                    // Color palete
                    {"White Hot",34816},
                    {"Black Hot",34817},
                    {"Iron Rainbow",34818},
                    {"Lava",34819},
                    {"Rainbow2",34820},
                    {"Rainbow3",34821},
                    {"Red Hot",34822},
                    {"Iron gray",34823},
                    {"HCR1",34824},
                    {"HCR2",34825},
                    {"Black hot 2",34826},
                                                                         };
            append_int(ret,"COLOR_PALETE",ImprovedIntSetting(34816,34826,infiray_colorpalete_items),
                       "Infiray thermal colors");
        }
        append_only_documented(ret,"RC_UPDATE_HZ",
                               "Specify the update rate of RC over wifibroadcast. A higher update rate gives lower RC latency, but takes more bandwidth away from the downlink."
                               "No effect if joy rc is disabled.");
    }
    {
        /*append_int(ret,"AUDIO_ENABLE",
                   ImprovedIntSetting::createEnumEnableDisable(),
                   "enables / disables audio streaming from air to ground. In development. Enabling automatically restarts the air unit !"
                   );*/
        auto audio_items=std::vector<ImprovedIntSetting::Item>{
         {"DISABLE",1},
         {"ENABLE",0},
         {"TEST",100},
         };
        append_int(ret,"AUDIO_ENABLE",ImprovedIntSetting(0,1000000,audio_items),
                "enables / disables audio streaming from air to ground. In development. Use test mode to validate your ground audio output."
                   );
    }
    return ret;
}

static std::map<std::string,std::shared_ptr<XParam>> create_param_map(){
    //qWarning("Create param map");
    auto param_list=get_parameters_list();
    //qWarning("X");
    std::map<std::string,std::shared_ptr<XParam>> ret;
    for(auto param:param_list){
        //qWarning("Y %s",param.param_name.c_str());
        if(ret.find(param->param_name)!=ret.end()){
            //qWarning("Param %s already exists !",param.param_name.c_str());
            assert(false);
        }
        ret[param->param_name]=param;
        //qDebug()<<"YY"<<param.param_name.c_str();
        //qWarning("Z");
    }
    //qDebug()<<"create_param_map()"<<tmp.size()<<", "<<tmp.size();
    return ret;
}

std::optional<DocumentedParam::XParam> DocumentedParam::find_param(const std::string &param_name)
{
    //qDebug()<<"find_param"<<param_name.c_str();
    // we use static to create a cache - we only read from the map anyways
    static std::map<std::string,std::shared_ptr<XParam>> cached=create_param_map();
    if(cached.find(param_name)!=cached.end()){
        auto ret=cached.at(param_name);
        //qDebug()<<"XXX Found "<<param_name.c_str()<<" "<<ret->param_name.c_str();
        return *ret;
    }else{
        //qDebug()<<"XXX Didn't find "<<param_name.c_str();
    }
    return std::nullopt;
}



bool DocumentedParam::read_only(const std::string &param_name)
{
    bool ret=false;
    const auto tmp=find_param(param_name);
    if(tmp.has_value()){
        ret=tmp.value().is_read_only;
    }
    //qDebug()<<"Param"<<param_id.c_str()<<"Read-only:"<<(ret==false ? "N":"Y");
    return ret;
}

std::optional<ImprovedIntSetting> DocumentedParam::get_improved_for_int(const std::string &param_id)
{
    const auto tmp=DocumentedParam::find_param(param_id);
    if(tmp.has_value()){
        const auto& param=tmp.value();
        if(param.improved_int.has_value()){
            return param.improved_int.value();
        }
    }
    return std::nullopt;
}

std::optional<ImprovedStringSetting> DocumentedParam::get_improved_for_string(const std::string param_id)
{
    const auto tmp=DocumentedParam::find_param(param_id);
    if(tmp.has_value()){
        const auto& param=tmp.value();
        if(param.improved_string.has_value()){
            return param.improved_string.value();
        }
    }
    return std::nullopt;
}

std::optional<std::string> DocumentedParam::int_param_to_enum_string_if_known(const std::string param_id, int value){
    const auto improved_opt=get_improved_for_int(param_id);
    if(improved_opt.has_value()){
        const auto& improved=improved_opt.value();
        if(improved.has_enum_mapping()){
            return improved.value_to_string(value);
        }
    }
    return std::nullopt;
}

std::optional<std::string> DocumentedParam::string_param_to_enum_string_if_known(const std::string param_id, std::string value){
    const auto improved_opt=get_improved_for_string(param_id);
    if(improved_opt.has_value()){
        const auto& improved=improved_opt.value();
        return improved.value_to_key(value);
    }
    return std::nullopt;
}

bool DocumentedParam::requires_reboot(const std::string &param_name)
{
    const auto tmp=DocumentedParam::find_param(param_name);
    if(tmp.has_value()){
        return tmp.value().requires_reboot;
    }
    return false;
}

std::string DocumentedParam::get_short_description(const std::string &param_name)
{
    const auto tmp=DocumentedParam::find_param(param_name);
    if(tmp.has_value()){
        return tmp.value().description.c_str();
    }
    return "TODO";
}

// ----------
static std::map<std::string, void *> get_whitelisted_params()
{
    std::map<std::string,void*> ret{};
    ret[openhd::WB_FREQUENCY]=nullptr;
    ret[openhd::WB_CHANNEL_WIDTH]=nullptr;
    ret[openhd::WB_MCS_INDEX]=nullptr;
    ret["CONFIG_BOOT_AIR"]=nullptr;
    ret[openhd::WB_MAX_FEC_BLOCK_SIZE_FOR_PLATFORM]=nullptr;
    ret[openhd::WB_DEV_AIR_SET_HIGH_RETRANSMIT_COUNT]=nullptr;
    // TX POWER Whitelisted, since they should be changed from the quick wizzard
    ret[openhd::WB_TX_POWER_MILLI_WATT]=nullptr;
    ret[openhd::WB_TX_POWER_MILLI_WATT_ARMED]=nullptr;
    ret[openhd::WB_RTL8812AU_TX_PWR_IDX_OVERRIDE]=nullptr;
    ret[openhd::WB_RTL8812AU_TX_PWR_IDX_ARMED]=nullptr;
    // STBC / LDPC - Whitelisted, since they should be changed from the quick wizzard
    ret[openhd::WB_ENABLE_LDPC]=nullptr;
    ret[openhd::WB_ENABLE_STBC]=nullptr;
    // Whitelisted since normally it should not be changed / has no effect anyways
    ret[openhd::WB_ENABLE_SHORT_GUARD]=nullptr;
    ret[openhd::WB_ENABLE_REDUNDANT_TX]=nullptr;
    ret[openhd::WB_MCS_INDEX_VIA_RC_CHANNEL]=nullptr;
    ret[openhd::WB_BW_VIA_RC_CHANNEL]=nullptr;
    ret[openhd::WB_QP_MAX]=nullptr;
    ret[openhd::WB_QP_MIN]=nullptr;
    ret[openhd::WB_TX_POWER_LEVEL]=nullptr;
    ret[openhd::WB_PASSIVE_MODE]=nullptr;
    ret[openhd::WB_PIT_MODE]=nullptr;
    ret[openhd::WB_ENABLE_RETRANSMISSION]=nullptr;
    ret[openhd::WB_ENABLE_RETRANSMISSION_VIDEO]=nullptr;
    ret[openhd::WB_ENABLE_RETRANSMISSION_TELEMETRY]=nullptr;
    ret[openhd::WB_ENABLE_RETRANSMISSION_RC]=nullptr;
    ret[openhd::WB_RETRANSMISSION_HISTORY_VIDEO_MS]=nullptr;
    ret[openhd::WB_RETRANSMISSION_HISTORY_TELEMETRY_MS]=nullptr;
    ret[openhd::WB_RETRANSMISSION_HISTORY_RC_MS]=nullptr;
    ret[openhd::WB_RETRANSMISSION_REQUEST_RETRIES]=nullptr;
    //
    ret[openhd::WB_VIDEO_FEC_PERCENTAGE]=nullptr;
    ret[openhd::WB_VIDEO_RATE_FOR_MCS_ADJUSTMENT_PERC]=nullptr;
    ret[openhd::WB_VIDEO_VARIABLE_BITRATE]=nullptr;
    //
    ret["TYPE_CAM0"]=nullptr;
    ret["TYPE_CAM1"]=nullptr;
    // The actual 'camera' parameters
    // Whitelisted since r.n we don't really know
    // what happens on a platform if h265 is selected
    ret["VIDEO_CODEC"]=nullptr;
    ret["AIR_RECORDING"]=nullptr;
    ret["FORCE_SW_ENC"]=nullptr;
    ret["BITRATE_MBITS"]=nullptr;
    ret["KEYFRAME_I"]=nullptr;
    ret["INTRA_REFRESH"]=nullptr;
    ret["N_SLICES"]=nullptr;
    //

    ret["STREAMING_E"]=nullptr;
    ret["AUDIO_ENABLE"]=nullptr;


    ret[""]=nullptr;
    ret[""]=nullptr;
    ret[""]=nullptr;
    ret[""]=nullptr;
    //ret[""]=nullptr;
    return ret;
}

bool DocumentedParam::is_param_whitelisted(const std::string &param_id)
{
    const auto tmp=get_whitelisted_params();
    if(tmp.find(param_id)!=tmp.end()){
        return true;
    }
    return false;
}
