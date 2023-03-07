#include "mavlinksettingsmodel.h"
#include "qdebug.h"
#include "../openhd_defines.hpp"
#include "../models/aohdsystem.h"
#include "../models/camerastreammodel.h"

#include "../../util/WorkaroundMessageBox.h"
#include "improvedintsetting.h"
#include "improvedstringsetting.h"
#include "../../vs_util/QOpenHDVideoHelper.hpp"

#include <QSettings>
#include <QVariant>

MavlinkSettingsModel &MavlinkSettingsModel::instanceAirCamera()
{
    static MavlinkSettingsModel* instanceAirCamera=new MavlinkSettingsModel(OHD_SYS_ID_AIR,OHD_COMP_ID_AIR_CAMERA_PRIMARY);
    return *instanceAirCamera;
}

MavlinkSettingsModel &MavlinkSettingsModel::instanceAirCamera2()
{
    static MavlinkSettingsModel instanceAirCamera2{OHD_SYS_ID_AIR, OHD_COMP_ID_AIR_CAMERA_SECONDARY};
    return instanceAirCamera2;
}

MavlinkSettingsModel &MavlinkSettingsModel::instanceAir()
{
    static MavlinkSettingsModel* instanceAir=new MavlinkSettingsModel(OHD_SYS_ID_AIR,OHD_COMP_ID_LINK_PARAM);
    return *instanceAir;
}
MavlinkSettingsModel &MavlinkSettingsModel::instanceGround()
{
    static MavlinkSettingsModel* instanceGround=new MavlinkSettingsModel(OHD_SYS_ID_GROUND,OHD_COMP_ID_LINK_PARAM);
    return *instanceGround;
}

/*MavlinkSettingsModel &MavlinkSettingsModel::instanceFC()
{
    static MavlinkSettingsModel* instanceFc=new MavlinkSettingsModel(1,1);
    return *instanceFc;
}*/

std::map<std::string, void *> MavlinkSettingsModel::get_whitelisted_params()
{
    std::map<std::string,void*> ret{};
    //dev_show_whitelisted_params
    QSettings settings;
    const auto dev_show_whitelisted_params =settings.value("dev_show_whitelisted_params", false).toBool();
    if(dev_show_whitelisted_params){
        // no param whitelisted
        return ret;
    }
    ret["WB_FREQUENCY"]=nullptr;
    ret["WB_CHANNEL_W"]=nullptr;
    ret["WB_MCS_INDEX"]=nullptr;
    //
    ret["CONFIG_BOOT_AIR"]=nullptr;
    ret["WB_MAX_D_BZ"]=nullptr;
    // Not whitelisted anymore
    //ret["VARIABLE_BITRATE"]=nullptr;
    ret["V_AIR_RECORDING"]=nullptr;
    //ret[""]=nullptr;
    return ret;
}

bool MavlinkSettingsModel::is_param_whitelisted(const std::string param_id)const
{
    if(param_id.empty()){
        return false;
    }
    const auto tmp=get_whitelisted_params();
    if(tmp.find(param_id)!=tmp.end()){
        return true;
    }
    return false;
}

bool MavlinkSettingsModel::is_param_read_only(const std::string param_id)const
{
    bool ret=false;
    if(param_id.compare("V_CAM_TYPE") == 0)ret=true;
    if(param_id.compare("V_CAM_SENSOR") == 0)ret=true;
    if(param_id.compare("BOARD_TYPE") == 0)ret=true;
    if(param_id.compare("WB_N_RX_CARDS")== 0)ret=true;
	if(param_id.compare("V_CAM_NAME")==0 )ret=true;
    if(param_id=="WIFI_CARD0" || param_id=="WIFI_CARD1" || param_id=="WIFI_CARD2" || param_id=="WIFI_CARD3"){
        ret=true;
    }
    if(param_id=="HOTSPOT_CARD"){
         ret=true;
    }
    //qDebug()<<"Param"<<param_id.c_str()<<"Read-only:"<<(ret==false ? "N":"Y");
    return ret;
}

static std::optional<ImprovedIntSetting> get_improved_for_int(const std::string& param_id){
    std::map<std::string,ImprovedIntSetting> map_improved_params;
    map_improved_params["TEST_INT_0"]=ImprovedIntSetting::createEnumEnableDisable();
    map_improved_params["ENABLE_JOY_RC"]=ImprovedIntSetting::createEnumEnableDisable();
    map_improved_params["VARIABLE_BITRATE"]=ImprovedIntSetting::createEnumEnableDisable();
    map_improved_params["FC_UART_FLWCTL"]=ImprovedIntSetting::createEnumEnableDisable();
    //
    map_improved_params["WB_E_STBC"]=ImprovedIntSetting::createEnumEnableDisable();
    map_improved_params["WB_E_LDPC"]=ImprovedIntSetting::createEnumEnableDisable();
    map_improved_params["WB_E_SHORT_GUARD"]=ImprovedIntSetting::createEnumEnableDisable();
    //map_improved_params["RTL8812AU_PWR_I"]=ImprovedIntSetting::createRangeOnly(0,63);
    {
        std::vector<std::string> values{};
        values.push_back("enum0");
        values.push_back("enum1");
        values.push_back("enum2");
        values.push_back("enum3");
        map_improved_params["TEST_INT_1"]=ImprovedIntSetting::createEnum(values);
    }
    {
        map_improved_params["VIDEO_CODEC"]=ImprovedIntSetting::createEnum( std::vector<std::string>{"h264","h265","mjpeg"});
        map_improved_params["V_AIR_RECORDING"]=ImprovedIntSetting::createEnumEnableDisable();
        map_improved_params["V_E_STREAMING"]=ImprovedIntSetting::createEnumEnableDisable();
        map_improved_params["V_HORIZ_FLIP"]=ImprovedIntSetting::createEnumEnableDisable();
        map_improved_params["V_VERT_FLIP"]=ImprovedIntSetting::createEnumEnableDisable();

        map_improved_params["V_CAM_ROT_DEG"]=ImprovedIntSetting(0,270,{
           ImprovedIntSetting::Item{"0°(disable)",0},
           ImprovedIntSetting::Item{"90°",90},
           ImprovedIntSetting::Item{"180°",180},
           ImprovedIntSetting::Item{"270°",270}
       });
        map_improved_params["V_INTRA_REFRESH"]=ImprovedIntSetting(-1,2130706433,{
           ImprovedIntSetting::Item{"NONE",-1},
           ImprovedIntSetting::Item{"CYCLIC",0},
           ImprovedIntSetting::Item{"ADAPTIVE",1},
           ImprovedIntSetting::Item{"BOTH",2},
           ImprovedIntSetting::Item{"CYCLIC_ROWS",2130706433}
       });
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
        map_improved_params["V_AWB_MODE"]=ImprovedIntSetting::createEnum(gst_awb_modes);
        map_improved_params["V_EXP_MODE"]=ImprovedIntSetting::createEnum(gst_exposure_modes);
        {
            auto values_metering_mode=std::vector<std::string>{
                    "AVERAGE","SPOT","BACKLIST","MATRIX"
            };
            map_improved_params["V_METERING_MODE"]=ImprovedIntSetting::createEnum(values_metering_mode);
        }
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
        map_improved_params["FC_UART_BAUD"]=ImprovedIntSetting(0,1000000,baud_rate_items);
        //
        {
            // Needs to match OpenHD
            //   MMAL = 0, // raspivid / gst-rpicamsrc
            //   LIBCAMERA, // "normal" libcamera (autodetect)
            //   LIBCAMERA_IMX477, // "normal" libcamera, explicitly set to imx477 detection only
            //   LIBCAMERA_ARDUCAM, // pivariety libcamera (arducam special)
            //   LIBCAMERA_IMX519, // Arducam imx519 without autofocus
            //   VEYE_327, // Veye IMX290/IMX327 (older versions)
            //   VEYE_CSIMX307, // Veye IMX307
            //   VEYE_CSSC132, //Veye SC132
            //   VEYE_MVCAM, // Veye MV Cameras
            //   VEYE_CAM2M // Veye IMX327 (never versions), VEYE series with 200W resolution
            auto cam_config_items=std::vector<std::string>{
                    "Legacy(MMAL)",
                    "LIBCAMERA",
                    "LIBCAMERA_IMX477",
                    "LIBCAMERA_ARDU",
                    "LIBCAMERA_IMX519",
                    "LIBCAMERA_IMX290",
                    "LIBCAMERA_IMX327",
                    "LIBCAMERA_IMX462",
                    "VEYE_327",
                    "VEYE_CSIMX307",
                    "VEYE_CSSC132",
                    "VEYE_MVCAM",
                    "VEYE_CAM2M"
            };
            map_improved_params["V_OS_CAM_CONFIG"]=ImprovedIntSetting::createEnum(cam_config_items);
        }
        map_improved_params["CONFIG_BOOT_AIR"]=ImprovedIntSetting::createEnumEnableDisable();
        map_improved_params["I_WIFI_HOTSPOT_E"]=ImprovedIntSetting::createEnumEnableDisable();
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
        auto values_WB_TX_PWR_LEVEL=std::vector<ImprovedIntSetting::Item>{
            {"LOW(~25mW)[22]",22},
            {"MEDIUM [37]",37},
            {"HIGH [53]",53},
            {"MAX1(!DANGER!)[58]",58},
            // Intentionally disabled, since it creates unusably high packet loss
            // (e.g. the rf circuit is over-amplified)
            //{"MAX2(!DANGER!)[63]",63},
        };
        map_improved_params["WB_TX_PWR_IDX_O"]=ImprovedIntSetting(0,63,values_WB_TX_PWR_LEVEL);
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
            map_improved_params["WB_V_FEC_BLK_L"]=ImprovedIntSetting(0,128,default_values);
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
            map_improved_params["WB_V_FEC_PERC"]=ImprovedIntSetting(0,100,default_values);
        }
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
            map_improved_params["V_BITRATE_MBITS"]=ImprovedIntSetting(1,100,default_values);
        }
        {
            auto default_values=std::vector<ImprovedIntSetting::Item>{
                {"5  (good recovery)",5},
                {"8  (good recovery)",8},
                {"10 (medium recovery)",10},
                {"15 (medium recovery)",15},
                {"20 (bad recovery)",20},
                {"30 (bad recovery)",30},
            };
            map_improved_params["V_KEYFRAME_I"]=ImprovedIntSetting(0,100,default_values);
        }
        map_improved_params["V_FORCE_SW_ENC"]=ImprovedIntSetting::createEnumEnableDisable();
        map_improved_params["V_SWITCH_CAM"]=ImprovedIntSetting::createEnumEnableDisable();

        map_improved_params["I_ETH_HOTSPOT_E"]=ImprovedIntSetting::createEnumEnableDisable();
        {
            auto values=std::vector<std::string>{"untouched","high","low"};
            map_improved_params["GPIO_2"]=ImprovedIntSetting::createEnum(values);
        }
        {
            std::pair<std::string,int> val1{"20Mhz",20};
            std::pair<std::string,int> val2{"40Mhz",40};
            map_improved_params["WB_CHANNEL_W"]=ImprovedIntSetting::createEnumSimple({val1,val2});
            map_improved_params["WB_MCS_INDEX"]=ImprovedIntSetting::createEnum({"MCS0","MCS1","MCS2","MCS3","MCS4","MCS5","MCS6","MCS7"});
        }
        {
            map_improved_params["V_N_CAMERAS"]=ImprovedIntSetting(1,2,{
               ImprovedIntSetting::Item{"SINGLE (default)",1},
               ImprovedIntSetting::Item{"DUALCAM",2}
           });
        }
    }
    if(map_improved_params.find(param_id)!=map_improved_params.end()){
        return map_improved_params[param_id];
    }
    return std::nullopt;
}

static std::optional<ImprovedStringSetting> get_improved_for_string(const std::string param_id){
    std::map<std::string,ImprovedStringSetting> map_improved_params;
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
    map_improved_params["V_FORMAT"]=ImprovedStringSetting::create_from_keys_only(choices_video_res_framerate);
    {
        auto fc_uart_conn_values=std::vector<ImprovedStringSetting::Item>{
            {"disable",""},
            {"serial0","/dev/serial0"},
            {"serial1","/dev/serial1"},
            {"ttyUSB0","/dev/ttyUSB0"},
            {"ttyACM0","/dev/ttyACM0"},
            {"ttyACM1","/dev/ttyACM1"},
            {"ttyS7","/dev/ttyS7"}
        };
        map_improved_params["FC_UART_CONN"]=ImprovedStringSetting{fc_uart_conn_values};
        //same for ground uart out
        map_improved_params["TRACKER_UART_OUT"]=ImprovedStringSetting{fc_uart_conn_values};
    }
    //
    if(map_improved_params.find(param_id)!=map_improved_params.end()){
        return map_improved_params[param_id];
    }
    return std::nullopt;
}

static std::optional<std::string> int_param_to_enum_string_if_known(const std::string param_id,int value){
    const auto improved_opt=get_improved_for_int(param_id);
    if(improved_opt.has_value()){
        const auto& improved=improved_opt.value();
        if(improved.has_enum_mapping()){
            return improved.value_to_string(value);
        }
    }
    return std::nullopt;
}
static std::optional<std::string> string_param_to_enum_string_if_known(const std::string param_id,std::string value){
    const auto improved_opt=get_improved_for_string(param_id);
    if(improved_opt.has_value()){
        const auto& improved=improved_opt.value();
        return improved.value_to_key(value);
    }
    return std::nullopt;
}


MavlinkSettingsModel::MavlinkSettingsModel(uint8_t sys_id,uint8_t comp_id,QObject *parent)
    : QAbstractListModel(parent),m_sys_id(sys_id),m_comp_id(comp_id)
{
    //m_data.push_back({"VIDEO_WIDTH",0});
    //m_data.push_back({"VIDEO_HEIGHT",1});
    //m_data.push_back({"VIDEO_FPS",1});
}

void MavlinkSettingsModel::set_param_client(std::shared_ptr<mavsdk::System> system,bool autoload_all_params)
{
    // only allow adding the param client once it is discovered, do not overwrite it once discovered.
    // DO NOT REMOVE THIS NECCESSARY CHECK - this class is written under the assumption that the "param_client" pointer becomes valid
    // at some point and then stays valid
    assert(this->param_client==nullptr);
    assert(system->get_system_id()==m_sys_id);
    m_system=system;
    param_client=std::make_shared<mavsdk::Param>(system,m_comp_id,true);
    if(autoload_all_params){
        try_fetch_all_parameters();
    }
}

bool MavlinkSettingsModel::try_fetch_all_parameters()
{
    qDebug()<<"MavlinkSettingsModel::try_fetch_all_parameters()";
    if(param_client==nullptr){
        // not discovered yet
        workaround::makePopupMessage("OHD System not found");
    }
    if(param_client){
        // first, remove anything the QT model has cached
        while(rowCount()>0){
            removeData(rowCount()-1);
        }
        qDebug()<<"Done removing old params";
        // now fetch all params using mavsdk (this talks to the OHD system(s).
        //param_client->set_timeout(10);
        const auto params=param_client->get_all_params(true);
        // The order in which params show up is r.n controlled by how they are added here -
        // TODO could be improved. For some reason, string params are generally the most important ones r.n, though
        for(const auto& string_param:params.custom_params){
            MavlinkSettingsModel::SettingData data{QString(string_param.name.c_str()),string_param.value};
            addData(data);
        }
        for(const auto& int_param:params.int_params){
            MavlinkSettingsModel::SettingData data{QString(int_param.name.c_str()),int_param.value};
            addData(data);
        }
        if(!params.int_params.empty()){
            return true;
        }
    }else{
        // not dscovered yet
    }
    return false;
}

std::optional<int> MavlinkSettingsModel::try_get_param_int_impl(const QString param_id)
{
    qDebug()<<"try_get_param_int_impl:"<<param_id;
    if(param_client){
        const auto result=param_client->get_param_int(param_id.toStdString());
        if(result.first==mavsdk::Param::Result::Success){
             auto new_value=result.second;
             return new_value;
        }
    }
    return std::nullopt;
}

std::optional<std::string> MavlinkSettingsModel::try_get_param_string_impl(const QString param_id)
{
    qDebug()<<"try_get_param_string_impl:"<<param_id;
    if(param_client){
        const auto result=param_client->get_param_custom(param_id.toStdString());
        if(result.first==mavsdk::Param::Result::Success){
             auto new_value=result.second;
             return new_value;
        }
    }
    return std::nullopt;
}

bool MavlinkSettingsModel::try_refetch_parameter_int(QString param_id)
{
    qDebug()<<"try_fetch_parameter:"<<param_id;
    auto new_value=try_get_param_int_impl(param_id);
    if(new_value.has_value()){
        MavlinkSettingsModel::SettingData tmp{param_id,new_value.value()};
        updateData(std::nullopt,tmp);
        return true;
    }
    return false;
}
bool MavlinkSettingsModel::try_refetch_parameter_string(QString param_id)
{
    qDebug()<<"try_fetch_parameter:"<<param_id;
    auto new_value=try_get_param_string_impl(param_id);
    if(new_value.has_value()){
        MavlinkSettingsModel::SettingData tmp{param_id,new_value.value()};
        updateData(std::nullopt,tmp);
        return true;
    }
    return false;
}

std::string MavlinkSettingsModel::set_param_result_as_string(const SetParamResult &res)
{
    if(res==SetParamResult::NO_CONNECTION)return "NO_CONNECTION";
    if(res==SetParamResult::VALUE_UNSUPPORTED)return "VALUE_UNSUPPORTED";
    if(res==SetParamResult:: SUCCESS)return " SUCCESS";
    return "UNKNOWN";
}

MavlinkSettingsModel::SetParamResult MavlinkSettingsModel::try_set_param_int_impl(const QString param_id, int value,std::optional<ExtraRetransmitParams> extra_retransmit_params)
{
    if(!param_client)return SetParamResult::NO_CONNECTION;
    if(extra_retransmit_params.has_value()){
        const double timeout_s=std::chrono::duration_cast<std::chrono::milliseconds>(extra_retransmit_params.value().retransmit_timeout).count()/1000.0;
        param_client->set_timeout(timeout_s);
        param_client->set_n_retransmissions(extra_retransmit_params.value().n_retransmissions);
    }
    const auto result=param_client->set_param_int(param_id.toStdString(),value);
    if(extra_retransmit_params.has_value()){
        // restores defaults
        param_client->set_timeout(-1);
        param_client->set_n_retransmissions(3);
    }
    if(result==mavsdk::Param::Result::ValueUnsupported)return SetParamResult::VALUE_UNSUPPORTED;
    if(result==mavsdk::Param::Result::Timeout)return SetParamResult::NO_CONNECTION;
    if(result==mavsdk::Param::Result::Success)return SetParamResult::SUCCESS;
    if(result==mavsdk::Param::Result::ParamNameTooLong || result==mavsdk::Param::Result::ParamValueTooLong || result==mavsdk::Param::Result::WrongType){
        qDebug()<<"Improper use, fix your code!";
    }
    return SetParamResult::UNKNOWN;
}

MavlinkSettingsModel::SetParamResult MavlinkSettingsModel::try_set_param_string_impl(const QString param_id,QString value,std::optional<ExtraRetransmitParams> extra_retransmit_params)
{
    if(!param_client)return SetParamResult::NO_CONNECTION;
    if(extra_retransmit_params.has_value()){
        const double timeout_s=std::chrono::duration_cast<std::chrono::milliseconds>(extra_retransmit_params.value().retransmit_timeout).count()/1000.0;
        param_client->set_timeout(timeout_s);
        param_client->set_n_retransmissions(extra_retransmit_params.value().n_retransmissions);
    }
    const auto result=param_client->set_param_custom(param_id.toStdString(),value.toStdString());
    if(extra_retransmit_params.has_value()){
        // restores defaults
        param_client->set_timeout(-1);
        param_client->set_n_retransmissions(3);
    }
    if(result==mavsdk::Param::Result::ValueUnsupported)return SetParamResult::VALUE_UNSUPPORTED;
    if(result==mavsdk::Param::Result::Timeout)return SetParamResult::NO_CONNECTION;
    if(result==mavsdk::Param::Result::Success)return SetParamResult::SUCCESS;
    if(result==mavsdk::Param::Result::ParamNameTooLong || result==mavsdk::Param::Result::ParamValueTooLong || result==mavsdk::Param::Result::WrongType){
        qDebug()<<"Improper use, fix your code!";
    }
    return SetParamResult::UNKNOWN;
}

QString MavlinkSettingsModel::try_update_parameter_int(const QString param_id,int value)
{
    qDebug()<<"try_update_parameter_int:"<<param_id<<","<<value;
    const auto result=try_set_param_int_impl(param_id,value);
    if(result==SetParamResult::SUCCESS){
        MavlinkSettingsModel::SettingData tmp{param_id,value};
        updateData(std::nullopt,tmp);
        return "";
    }
    qDebug()<<"Failure code:"<<set_param_result_as_string(result).c_str();
    if(result==SetParamResult::VALUE_UNSUPPORTED){
        std::stringstream ss;
        ss<<"Your HW does not support "<<param_id.toStdString()<<"="<<value;
        return ss.str().c_str();
    }
    if(result==SetParamResult::NO_CONNECTION){
        return "Update failed,please try again";
    }
    return "Update failed, unknown error";
}

QString MavlinkSettingsModel::try_update_parameter_string(const QString param_id,QString value)
{
    qDebug()<<"try_update_parameter_string:"<<param_id<<","<<value;
    const auto result=try_set_param_string_impl(param_id,value);
    if(result==SetParamResult::SUCCESS){
        MavlinkSettingsModel::SettingData tmp{param_id,value.toStdString()};
        updateData(std::nullopt,tmp);
        return "";
    }
    qDebug()<<"Failure code:"<<set_param_result_as_string(result).c_str();
    if(result==SetParamResult::VALUE_UNSUPPORTED){
        std::stringstream ss;
        ss<<"Your HW does not support "<<param_id.toStdString()<<"="<<value.toStdString();
        return ss.str().c_str();
    }
    if(result==SetParamResult::NO_CONNECTION){
        return "Update failed,please try again";
    }
    return "Update failed, unknown error";
}

int MavlinkSettingsModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;

    return m_data.count();
}

QVariant MavlinkSettingsModel::data(const QModelIndex &index, int role) const
{
    if ( !index.isValid() )
        return QVariant();

    const auto& data = m_data.at(index.row());
    if ( role == UniqueIdRole ){
        return data.unique_id;
    }
    else if ( role == ValueRole ){
        if(std::holds_alternative<int32_t>(data.value)){
            return std::get<int32_t>(data.value);
        }
        // We have either string or int, but assert to make it clear to someone reading the code
        assert(std::holds_alternative<std::string>(data.value));
        return QString(std::get<std::string>(data.value).c_str());
   } else if (role==ExtraValueRole){
        if(std::holds_alternative<int>(data.value)){
            auto value=std::get<int>(data.value);
            return int_enum_get_readable(data.unique_id,value);
        }
        // We only support int and string
        assert(std::holds_alternative<std::string>(data.value));
        auto value=std::get<std::string>(data.value);
        return string_enum_get_readable(data.unique_id,value.c_str());
    } else if (role==ValueTypeRole){
        if(std::holds_alternative<int>(data.value)){
            return 0;
        }
        return 1;
    } else if(role == ShortDescriptionRole){
        QString ret=get_short_description(data.unique_id);
        return ret;
    } else if(role ==ReadOnlyRole){
        return is_param_read_only({data.unique_id.toStdString()});
    }
    else
        return QVariant();
}

QHash<int, QByteArray> MavlinkSettingsModel::roleNames() const
{
    static QHash<int, QByteArray> mapping {
        {UniqueIdRole, "unique_id"},
        {ValueRole, "value"},
        {ExtraValueRole, "extraValue"},
        {ValueTypeRole,"valueType"},
        {ShortDescriptionRole,"shortDescription"},
        {ReadOnlyRole,"read_only"}
    };
    return mapping;
}


void MavlinkSettingsModel::removeData(int row)
{
    if (row < 0 || row >= m_data.count())
        return;

    beginRemoveRows(QModelIndex(), row, row);
    m_data.removeAt(row);
    endRemoveRows();
}

// hacky, temporary
static void hacky_set_video_codec_in_qopenhd(const int comp_id,const MavlinkSettingsModel::SettingData& data){
    if(data.unique_id=="VIDEO_CODEC"){
        // Check if the param is still an int (should always be the case, but we don't want to crash in c++)
        if(!std::holds_alternative<int32_t>(data.value)){
            qDebug()<<"ERROR video codec setting messed up, fixme";
            return;
        }
        const int video_codec_in_openhd=std::get<int32_t>(data.value);
        if(comp_id==OHD_COMP_ID_AIR_CAMERA_PRIMARY){
            CameraStreamModel::dirty_set_curr_set_video_codec_for_cam(0,video_codec_in_openhd);
        }else if(comp_id==OHD_COMP_ID_AIR_CAMERA_SECONDARY){
            CameraStreamModel::dirty_set_curr_set_video_codec_for_cam(1,video_codec_in_openhd);
        }
    }
}

static void hacky_set_n_cameras_in_qopenhd(const int comp_id,const MavlinkSettingsModel::SettingData& data){
    if(data.unique_id=="V_N_CAMERAS"){
        if(!std::holds_alternative<int32_t>(data.value)){
            qDebug()<<"ERROR N_CAMERAS messed up, fixme";
            return;
        }
        const int value=std::get<int32_t>(data.value);
        const int value_in_qopenhd=QOpenHDVideoHelper::get_qopenhd_n_cameras();
        if(value!=value_in_qopenhd && value_in_qopenhd==1){
            auto message="QopenHD is not configured for single cam usage, go to QOpenHD settings / General to configure your GCS to show secondary camera screen";
            qDebug()<<message;
            workaround::makePopupMessage(message);
        }
    }
}


void MavlinkSettingsModel::updateData(std::optional<int> row_opt, SettingData new_data)
{
    {
        // temporary, dirty
        hacky_set_n_cameras_in_qopenhd(m_comp_id,new_data);
        hacky_set_video_codec_in_qopenhd(m_comp_id,new_data);
    }
    int row=-1;
    if(row_opt.has_value()){
        row=row_opt.value();
    }else{
        // We need to find the row index for the given string id
        for(int i=0;i<m_data.size();i++){
            if(m_data.at(i).unique_id==new_data.unique_id){
                row=i;
                break;
            }
        }
    }
    if (row < 0 || row >= m_data.count()){
         // Param does not exst
         return;
    }
    if(m_data.at(row).unique_id!=new_data.unique_id){
        qDebug()<<"Argh";
        return;
    }
    m_data[row]=new_data;
    QModelIndex topLeft = createIndex(row,0);
    emit dataChanged(topLeft, topLeft);
}

void MavlinkSettingsModel::addData(MavlinkSettingsModel::SettingData data)
{
    {
        // temporary, dirty
        hacky_set_n_cameras_in_qopenhd(m_comp_id,data);
        hacky_set_video_codec_in_qopenhd(m_comp_id,data);
    }
    if(is_param_whitelisted(data.unique_id.toStdString())){
        // never add whitelisted params to the simple model, they need synchronization
        return;
    }
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    m_data.push_back(data);
    endInsertRows();
}

QString MavlinkSettingsModel::int_enum_get_readable(QString param_id, int value)const
{
    auto as_enum=int_param_to_enum_string_if_known(param_id.toStdString(),value);
    if(as_enum.has_value()){
        return QString(as_enum.value().c_str());
    }
    std::stringstream ss;
    ss<<"{"<<value<<"}";
    return QString(ss.str().c_str());
}

QString MavlinkSettingsModel::string_enum_get_readable(QString param_id,QString value) const
{
    auto as_enum=string_param_to_enum_string_if_known(param_id.toStdString(),value.toStdString());
    if(as_enum.has_value()){
        return QString(as_enum.value().c_str());
    }
    std::stringstream ss;
    ss<<"{"<<value.toStdString()<<"}";
    return QString(ss.str().c_str());
}

bool MavlinkSettingsModel::int_param_has_min_max(QString param_id) const
{
    const auto improved_opt=get_improved_for_int(param_id.toStdString());
    if(improved_opt.has_value()){
        // min max is a requirement for int param
        return true;
    }
    return false;
}

int MavlinkSettingsModel::int_param_get_min_value(QString param_id)const
{
    const auto improved_opt=get_improved_for_int(param_id.toStdString());
    if(improved_opt.has_value()){
        if(improved_opt->has_enum_mapping()){
            return improved_opt->max_value_int;
        }
    }
    return 2147483647;
}

int MavlinkSettingsModel::int_param_get_max_value(QString param_id)const
{
    const auto improved_opt=get_improved_for_int(param_id.toStdString());
    if(improved_opt.has_value()){
        if(improved_opt->has_enum_mapping()){
            return improved_opt->min_value_int;
        }
    }
    return -2147483648;
}

bool MavlinkSettingsModel::int_param_has_enum_keys_values(QString param_id)const
{
    const auto improved_opt=get_improved_for_int(param_id.toStdString());
    if(improved_opt.has_value()){
        if(improved_opt->has_enum_mapping()){
            return true;
        }
    }
    return false;
}

QStringList MavlinkSettingsModel::int_param_get_enum_keys(QString param_id) const
{
    const auto improved_opt=get_improved_for_int(param_id.toStdString());
    if(improved_opt.has_value()){
        const auto improved=improved_opt.value();
        if(improved.has_enum_mapping()){
            return improved.int_enum_keys();
        }
        qDebug()<<"Error no enum mapping for this int param";
    }else{
        qDebug()<<"Error not an int param";
    }
    QStringList ret{"Err(0)"};
    return ret;
}

QList<int> MavlinkSettingsModel::int_param_get_enum_values(QString param_id) const
{
    const auto improved_opt=get_improved_for_int(param_id.toStdString());
    if(improved_opt.has_value()){
        const auto improved=improved_opt.value();
        if(improved.has_enum_mapping()){
            return improved.int_enum_values();
        }
    }
    qDebug()<<"Error no enum mapping for this int param";
    QList<int> ret{0};
    return ret;
}


bool MavlinkSettingsModel::string_param_has_enum(QString param_id) const
{
    const auto improved_opt=get_improved_for_string(param_id.toStdString());
    if(improved_opt.has_value()){
        return true;
    }
    return false;
}

QStringList MavlinkSettingsModel::string_param_get_enum_keys(QString param_id) const
{
    const auto improved_opt=get_improved_for_string(param_id.toStdString());
    if(improved_opt.has_value()){
        return improved_opt->enum_keys();
    }
    qDebug()<<"Error no enum mapping for this int param";
    QStringList ret{"ERROR_KEYS"};
    return ret;
}

QStringList MavlinkSettingsModel::string_param_get_enum_values(QString param_id) const
{
    const auto improved_opt=get_improved_for_string(param_id.toStdString());
    if(improved_opt.has_value()){
        return improved_opt->enum_values();
    }
    qDebug()<<"Error no enum mapping for this int param";
    QStringList ret{"ERROR_VALUES"};
    return ret;
}

QString MavlinkSettingsModel::get_warning_before_safe(const QString param_id)
{
    if(param_id=="V_OS_CAM_CONFIG"){
        return "WARNING: Changing this parameter will perform some special operations and then automatically reboot the air pi after a 3second delay";
    }
    return "";
}

bool MavlinkSettingsModel::get_param_requires_manual_reboot(QString param_id)
{
    if(param_id=="ENABLE_JOY_RC"){
        return true;
    }
    if(param_id=="I_ETH_HOTSPOT_E"){
        return true;
    }
    if(param_id=="V_N_CAMERAS")return true;
    return false;
}

QString MavlinkSettingsModel::get_short_description(const QString param_id)const
{
    if(param_id=="V_BITRATE_MBITS"){
        return "Camera encoder bitrate, does not include FEC overhead. "
               "!! If variable bitrate is enabled (recommended), this value is ignored.!! Otherwise, you can manually set a fixed camera/encoder bitrate here. "
               "NOTE: If you are using a camera not listed on the OpenHD recommended cameras list, the bitrate might be fixed by the vendor and not changeable.";
    }
    if(param_id=="WB_V_FEC_PERC"){
        return "WB Video FEC overhead, in percent. Increases link stability, but also the required link bandwidth (watch out for tx errors). "
               "The best value depends on your rf environment - recommended is about ~20% in low rf enironemnts(e.g. nature), and ~50% in high rf noise environments(populated areas)."
               "Note that your rf interference/ packet loss will increase during flight, it is not recommended to decrase this value below 20%.";
    }
    if(param_id=="WB_V_FEC_BLK_L"){
        return "Default AUTO (Uses biggest block sizes possible while not adding any latency).Otherwise: WB Video FEC block length, previous FEC_K. Increasing this value can improve link stability for free, but can create additional latency.";
    }
    if(param_id=="WB_TX_POWER_MW"){
        return "TX power in mW (milli Watt), changing this value might or might not have any effect, depending on your card & driver. 1000mW=1W";
    }
    if(param_id=="RTL8812AU_PWR_I"){
        return "Unitless power index for RTL8812AU. Leave at 0 to use WB_TX_POWER_MW instead, which doesn't give max power though.[0..58/63] REQUIRES REBOOT TO BE APPLIED";
    }
    if(param_id=="V_OS_CAM_CONFIG"){
        return "If your connected CSI camera is not detected (e.g. you see a dummy camera stream) you need to select the apropriate config here. Air will automatically reboot"
               " when you change this parameter";
    }
    if(param_id=="VARIABLE_BITRATE"){
        return "Recommend a matching bitrate to the encoder depending on the selected link parameters,and reduce bitrate on TX errors (failed injections). On by default, but only works on select cameras. On Cameras that"
               "don't support changing the bitrate / are bad at targeting a given bitrate, you have to adjust your link according to your camera needs.";
    }
    if(param_id=="FC_UART_BAUD"){
        return "RPI HW UART baud rate, needs to match the UART baud rate set on your FC";
    }
    if(param_id=="FC_UART_CONN"){
        return "Enable / disable UART for telemetry from/to your FC. Make sure FC_UART_BAUD matches your FC. See the wiki for more info.";
    }
    if(param_id=="V_FORMAT"){
        return "Video WIDTHxHEIGHT@FPS. You can enter any value you want here, but if you select a video format that is not supported by your camera, the video stream will stop";
    }
    if(param_id=="VIDEO_CODEC"){
        return "Video codec. If your camera/ground station does not support HW accelerated encoding/decoding of the selected codec,it'l default to SW encode/decode. A reboot (air&ground) is recommended after changing this parameter.";
    }
    if(param_id=="V_MJPEG_QUALITY"){
        return "Active if video codec== mjpeg. MJPEG has no encoder bitrate, only an arbitratry quality parameter (0..100)";
    }
    if(param_id=="ENABLE_JOY_RC"){
        return "Only enable joystick rc if you actually use it to save cpu / bandwidth. If enabled, you can connect a joystick to your ground station for RC. REQUIRES REBOOT!";
    }
    if(param_id=="WB_TX_PWR_IDX_O"){
        return "RTL8812AU TX power index (unitless). LOW:default,~25mW, legal in most countries."
               " NOTE: Too high power settings can overload your RF circuits and create packet loss/ destroy your card. Read the Wiki before changing the TX Power";
    }
    if(param_id=="V_AIR_RECORDING"){
        return "Record video data locally on your air unit. You can find the files under /home/openhd/Videos";
    }
    if(param_id=="V_E_STREAMING"){
        return "Enable / disable streaming for this camera. Note that this setting is persistent at run time - once you disable streaming for a camera, you won't have video"
               " until you re-enable streaming or reboot your air unit. On by default";
    }
    if(param_id=="V_KEYFRAME_I"){
        return "Keyframe / instantaneous decode refresh interval, in frames. E.g. if set to 15, every 15th frame will be a key frame. Higher values result in better image compression, but increase the likeliness of microfreezes.";
    }
    if(param_id=="V_VERT_FLIP"){
        return "Flip video vertically";
    }
    if(param_id=="V_HORIZ_FLIP"){
        return "Flip video horizontally";
    }
    if(param_id=="V_CAM_ROT_DEG"){
        return "Rotate video by 90 degree increments";
    }
    if(param_id=="V_AWB_MODE"){
        return "AWB Automatic white balance mode";
    }
    if(param_id=="V_EXP_MODE"){
        return "EXP Exposure mode";
    }
    if(param_id=="V_BRIGHTNESS"){
        return "Image capture brightness, [0..100], default 50, but recommended to tune AWB or EXP instead";
    }
    if(param_id=="V_ISO"){
        return "ISO value to use (0 = Auto)";
    }
    if(param_id=="V_INTRA_REFRESH"){
        return "Experimental,Default NONE, Type of Intra Refresh to use";
    }
    if(param_id=="V_METERING_MODE"){
        return "Camera exposure metering mode to use. Default average.";
    }
    if(param_id=="I_WIFI_HOTSPOT_E"){
        return "Enable/Disable WiFi hotspot such that you can connect to your air/ground unit via normal WiFi. Frequency is always the opposite of your WB link, e.g. "
               "2.4G if your wb link is 5.8G and opposite. However, disable hotspot during flight !";
    }
    if(param_id=="I_ETH_HOTSPOT_E"){
        return "Enable/Disable ethernet hotspot. When enabled, your rpi becomes a DHCPD server and starts forwarding video & telemetry if you connect a device via ethernet."
               "Requires Reboot to be applied !";
    }
    if(param_id=="V_FORCE_SW_ENC"){
        return "Force SW encode for the given USB camera, only enable if your camera supports outputting an appropriate raw format.";
    }
    if(param_id=="V_SWITCH_CAM"){
        return "Requires reboot. Switch primary and secondary camera.";
    }
    if(param_id=="TRACKER_UART_OUT"){
         return "Enable mavlink telemetry out via UART on the ground station for connecting a tracker or even an RC with mavlink lua script.";
    }
    if(param_id=="GPIO_2"){
        return "Experimental, allows manually controlling a rpi gpio for special uses like a LED, landing gear, ...";
    }
    if(param_id=="FC_UART_FLWCTL"){
        return "Leave disabled, for setups with an additional 4th cable for uart flow control";
    }
    if(param_id=="WB_CHANNEL_W" || param_id=="WB_MCS_INDEX" || param_id=="WB_FREQUENCY"){
        // They are whitelisted, but whitelisting can be disabled by enabling developer mode.
        return "!!!Editing this param manually without care will result in a broken link!!!";
    }
    if(param_id=="WB_MAX_D_BZ"){
        return "FEC auto internal.";
    }
    if(param_id=="WIFI_CARD0" || param_id=="WIFI_CARD1" || param_id=="WIFI_CARD2" || param_id=="WIFI_CARD3"){
        return "Detected wifi card type";
    }
    if(param_id=="HOTSPOT_CARD"){
        return "Detected card for wifi hotspot";
    }
    if(param_id=="V_PRIMARY_PERC"){
        return "If Variable bitrate is enabled,your primary camera is given that much percentage of the total available link bandwidth. "
               "The rest is given to the secondary camera. Default to 60% (60:40 split).";
    }
    if(param_id=="V_N_CAMERAS"){
        return "Configure openhd for single / dualcam usage. The air unit will wait for a specific amount of time until it has found that many camera(s),"
               " if it cannot find enough camera(s) it creates as many dummy camera(s) as needec instead.";
    }
    return "TODO";
}
