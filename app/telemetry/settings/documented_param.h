#ifndef DOCUMENTED_PARAM_H
#define DOCUMENTED_PARAM_H

#include "improvedintsetting.h"
#include "improvedstringsetting.h"
#include "param_names.h"

#include <map>
#include <string>


//
// Here we have the mapping (if available) and documentation for all parameters
//
// WAY BIGGER file than one would like, but there is no easy alternative

struct XParam{
    // each param has a unique name / ID.
    // must be valid string
    std::string param_name;
    // if param is of type int, it can have a mapping with verbose user choices
    std::optional<ImprovedIntSetting> improved_int;
    // if param is of type string, it can have a mapping with verbose user choices
    std::optional<ImprovedStringSetting> improved_string;
    // it has a short description
    std::string description;
    // and this flag (if set) says changing the parameter requires a (manual) reboot
    bool requires_reboot=false;
    // and this flag (if set) says the parameter is read-only (cannot be changed)
    bool is_read_only=false;
};

// These are util methods for the most common cases for adding parameters to the stored parameters set
static void append_int(std::vector<XParam>& list,std::string param_name,std::optional<ImprovedIntSetting> improved_int,std::string description,bool requires_reboot=false){
    list.push_back(XParam{param_name,improved_int,std::nullopt,description,requires_reboot});
}
static void append_string(std::vector<XParam>& list,std::string param_name,std::optional<ImprovedStringSetting> improved_string,std::string description,bool requires_reboot=false){
    list.push_back(XParam{param_name,std::nullopt,improved_string,description,requires_reboot});
}
static void append_only_documented(std::vector<XParam>& list,std::string param_name,std::string description,bool requires_reboot=false){
    list.push_back(XParam{param_name,std::nullopt,std::nullopt,description,requires_reboot});
}
static void append_documented_read_only(std::vector<XParam>& list,std::string param_name,std::string description){
    list.push_back(XParam{param_name,std::nullopt,std::nullopt,description,false,true});
}


static std::vector<XParam> get_parameters_list(){
    std::vector<XParam> ret;
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

    {
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
        append_int(ret,openhd::WB_RTL8812AU_TX_PWR_IDX_OVERRIDE,
                   ImprovedIntSetting(0,63,values_WB_TX_PWR_LEVEL),
                   "NEW: Recommended to change TX_POWER_I_ARMED instead ! RTL8812AU TX power index (unitless). LOW:default,~25mW, legal in most countries."
                   " NOTE: Too high power settings can overload your RF circuits and create packet loss/ destroy your card. Read the Wiki before changing the TX Power."
                   " NOTE2: For high power cards, it is recommended to leave this param default and change TX_POWER_ARMED instead to avoid overheating on the bench."
        );
    }
    {
        auto values_WB_TX_PWR_LEVEL_ARMED=std::vector<ImprovedIntSetting::Item>{
                {"Disabled[0]",0},
                {"LOW(~25mW)[22]",22},
                {"MEDIUM [37]",37},
                {"HIGH [53]",53},
                {"MAX1(!DANGER!)[58]",58},
                // Intentionally disabled, since it creates unusably high packet loss
                // (e.g. the rf circuit is over-amplified)
                //{"MAX2(!DANGER!)[63]",63},
        };
        append_int(ret,openhd::WB_RTL8812AU_TX_PWR_IDX_ARMED,
                   ImprovedIntSetting(0,63,values_WB_TX_PWR_LEVEL_ARMED),
                   "TX Power (in override indices units) that is applied when the FC is armed. When the FC is not armed, TX_POWER_I is applied."
                   "When this param is disabled, TX_POWER_I is applied regardless if armed or not (default)."
                   " This helps to avoid overheating of the WIFI card while openhd is powered on the bench / without airflow on the cards."
        );
    }
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
        std::pair<std::string,int> val1{"20Mhz",20};
        std::pair<std::string,int> val2{"40Mhz",40};
        append_int(ret,openhd::WB_CHANNEL_WIDTH,
                   ImprovedIntSetting::createEnumSimple({val1,val2}),
                   "!!!Editing this param manually without care will result in a broken link!!!"
        );
    }
    append_int(ret,openhd::WB_MCS_INDEX,
               ImprovedIntSetting::createEnum({"MCS0","MCS1","MCS2","MCS3","MCS4","MCS5","MCS6","MCS7"}),
               "!!!Editing this param manually without care will result in a broken link!!!"
    );
    append_int(ret,openhd::WB_MCS_INDEX_VIA_RC_CHANNEL,
               ImprovedIntSetting::createEnum({"Disable","Channel 1","CHannel 2","Channel 3","Channel 4","Channel 5",
                                               "Channel 6","Channel 7","Channel 8","Channel 9","Channel 10"}),
               "Dynamically change the MCS Index (Trade range <-> image quality (bitrate)) during flight using your RC and a specific channel "
               "(similar to how flight modes work)."
               );
    append_only_documented(ret,openhd::WB_FREQUENCY,"!!!Editing this param manually without care will result in a broken link!!!");
    append_only_documented(ret,openhd::WB_MAX_FEC_BLOCK_SIZE_FOR_PLATFORM,"Developer only, FEC auto internal.");
    append_only_documented(ret,openhd::WB_TX_POWER_MILLI_WATT,
                           "TX power in mW (milli Watt), changing this value might or might not have any effect, depending on your card & driver. 1000mW=1W");
    const auto descr_wifi_card="Detected wifi card type used for wifibroadcast.";
    append_documented_read_only(ret,"WIFI_CARD0",descr_wifi_card);
    append_documented_read_only(ret,"WIFI_CARD1",descr_wifi_card);
    append_documented_read_only(ret,"WIFI_CARD2",descr_wifi_card);
    append_documented_read_only(ret,"WIFI_CARD3",descr_wifi_card);
    append_documented_read_only(ret,"HOTSPOT_CARD","Detected card for wifi hotspot");
    append_documented_read_only(ret,"WB_N_RX_CARDS","TODO");
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
            append_string(ret,"V_FORMAT",ImprovedStringSetting::create_from_keys_only(choices_video_res_framerate),
                          "Video WIDTHxHEIGHT@FPS. You can enter any value you want here, but if you select a video format that is not supported by your camera, the video stream will stop");
        }
        {
            // Needs to match OpenHD
            //   MMAL = 0, // raspivid / gst-rpicamsrc
            //   IMX462 Low Light Mini, // "normal" libcamera, explicitly set to Arducam_piviarity detection only NEEDS CUSTOM LIBCAMERA
            //   SkyMaster HDR, // "normal" libcamera, explicitly set to imx708 detection only
            //   SkyVision Pro, // "normal" libcamera, explicitly set to imx519 detection only NEEDS CUSTOM LIBCAMERA
            //   LIBCAMERA_IMX477M, // "normal" libcamera, explicitly set to imx477 detection only NEEDS CUSTOM TUNING FILE
            //   LIBCAMERA_IMX477, // "normal" libcamera, explicitly set to imx477 detection only 
            //   LIBCAMERA_IMX462, // "normal" libcamera, explicitly set to imx462 detection only 
            //   LIBCAMERA_IMX327, // "normal" libcamera, explicitly set to imx327 detection only 
            //   LIBCAMERA_IMX290, // "normal" libcamera, explicitly set to imx290 detection only 
            //   LIBCAMERA_AUTO, // standart libcamera with autodetect
            //   LIBCAMERA_ARDUCAM_AUTO, // pivariety libcamera (arducam special)NEEDS CUSTOM LIBCAMERA
            //   VEYE_327, // Veye IMX290/IMX327 (older versions)
            //   VEYE_CSIMX307, // Veye IMX307
            //   VEYE_CSSC132, //Veye SC132
            //   VEYE_MVCAM, // Veye MV Cameras
            //   VEYE_CAM2M // Veye IMX327 (never versions), VEYE series with 200W resolution
            auto cam_config_items=std::vector<std::string>{
                    "Legacy(MMAL)",
                    "IMX462 Low Light Mini",
                    "SkyMaster HDR",
                    "SkyVision Pro",
                    "LIBCAMERA_IMX477M",
                    "LIBCAMERA_IMX477",
                    "LIBCAMERA_IMX462",
                    "LIBCAMERA_IMX327",
                    "LIBCAMERA_IMX290",
                    "LIBCAMERA_AUTO",
                    "LIBCAMERA_ARDUCAM_AUTO",
                    "VEYE_327",
                    "VEYE_CSIMX307",
                    "VEYE_CSSC132",
                    "VEYE_MVCAM",
                    "VEYE_CAM2M"
            };
            append_int(ret,"V_OS_CAM_CONFIG",
                       ImprovedIntSetting::createEnum(cam_config_items),
                       "If your connected CSI camera is not detected (e.g. you see a dummy camera stream) you need to select the apropriate config here. "
                       "Air will automatically reboot when you change this parameter"
            );
        }
        append_int(ret,"VIDEO_CODEC",
                   ImprovedIntSetting::createEnum( std::vector<std::string>{"h264","h265","mjpeg"}),
                   "Video codec. If your camera/ground station does not support HW accelerated encoding/decoding of the selected codec,it'l default to SW encode/decode. "
                   "A reboot (air&ground) is recommended after changing this parameter."
        );
        append_int(ret,"V_AIR_RECORDING",
                   ImprovedIntSetting::createEnum( std::vector<std::string>{"DISABLE","ENABLE","AUTO(armed)"}),
                   "Record video data locally on your air unit. You can find the files under /home/openhd/Videos on the SD card and/or download them via the web ui."
                   "When AUTO is set, air recording automatically starts (and stops) when you arm/disarm your drone (requires inav / ardupilot FC)."
        );
        append_int(ret,"V_E_STREAMING",
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
            append_int(ret,"V_BITRATE_MBITS",
                       ImprovedIntSetting(1,100,default_values),
                       "Camera encoder bitrate, does not include FEC overhead. "
                       "!! If variable bitrate is enabled (recommended), this value is ignored.!! Otherwise, you can manually set a fixed camera/encoder bitrate here. "
                       "NOTE: If you are using a camera not listed on the OpenHD recommended cameras list, the bitrate might be fixed by the vendor and not changeable."
            );
            append_only_documented(ret,"V_MJPEG_QUALITY",
                                   "Active if video codec== mjpeg. MJPEG has no encoder bitrate, only an arbitratry quality parameter (0..100)");
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
            append_int(ret,"V_KEYFRAME_I",
                       ImprovedIntSetting(0,100,default_values),
                       "Keyframe / instantaneous decode refresh interval, in frames. E.g. if set to 15, every 15th frame will be a key frame. Higher values result in better image compression, but increase the likeliness of microfreezes."
            );
        }
        append_int(ret,"V_FORCE_SW_ENC",
                   ImprovedIntSetting::createEnumEnableDisable(),
                   "Force SW encode for the given camera, only enable if your camera supports outputting an appropriate raw format."
        );
        append_int(ret,"V_SWITCH_CAM",
                   ImprovedIntSetting::createEnumEnableDisable(),
                   "Requires reboot. Switch primary and secondary camera.");
        append_only_documented(ret,"V_PRIMARY_PERC",
                               "If Variable bitrate is enabled,your primary camera is given that much percentage of the total available link bandwidth. "
                               "The rest is given to the secondary camera. Default to 60% (60:40 split).");
        append_int(ret,"V_HORIZ_FLIP",
                   ImprovedIntSetting::createEnumEnableDisable(),
                   "Flip video horizontally"
        );
        append_int(ret,"V_VERT_FLIP",
                   ImprovedIntSetting::createEnumEnableDisable(),
                   "Flip video vertically"
        );

        append_int(ret,"V_CAM_ROT_DEG",
                   ImprovedIntSetting(0,270,{
                           ImprovedIntSetting::Item{"0°(disable)",0},
                           ImprovedIntSetting::Item{"90 (mmal only)°",90},
                           ImprovedIntSetting::Item{"180°",180},
                           ImprovedIntSetting::Item{"270°(mmal only)",270}}),
                   "Rotate video by 90 degree increments"
        );
        append_int(ret,"V_INTRA_REFRESH",
                   ImprovedIntSetting(-1,2130706433,{
                           ImprovedIntSetting::Item{"NONE",-1},
                           ImprovedIntSetting::Item{"CYCLIC",0},
                           ImprovedIntSetting::Item{"ADAPTIVE",1},
                           ImprovedIntSetting::Item{"BOTH",2},
                           ImprovedIntSetting::Item{"CYCLIC_ROWS",2130706433}
                   }),
                   "Experimental,Default NONE, Type of Intra Refresh to use"
        );
        append_int(ret,"V_N_CAMERAS",
                   ImprovedIntSetting(1,2,{ImprovedIntSetting::Item{"SINGLE (default)",1},ImprovedIntSetting::Item{"DUALCAM",2}}),
                   "Configure openhd for single / dualcam usage. The air unit will wait for a specific amount of time until it has found that many camera(s),"
                   " if it cannot find enough camera(s) it creates as many dummy camera(s) as needec instead.",
                   true
        );
        append_only_documented(ret,"V_BRIGHTNESS","Image capture brightness, [0..100], default 50. Increase for a brighter Image. However, if available, it is recommended to tune AWB or EXP instead.");
        append_only_documented(ret,"V_ISO","ISO value to use (0 = Auto)");

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
            append_int(ret,"V_AWB_MODE",
                       ImprovedIntSetting::createEnum(gst_awb_modes),
                       "AWB Automatic white balance mode"
            );
            append_int(ret,"V_EXP_MODE",
                       ImprovedIntSetting::createEnum(gst_exposure_modes),
                       "EXP Exposure mode"
            );
            append_int(ret,"V_METERING_MODE",
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
        append_documented_read_only(ret,"V_CAM_TYPE","Detected camera type");
        append_documented_read_only(ret,"V_CAM_SENSOR","Detected camera sensor (might not work)");
        append_documented_read_only(ret,"V_CAM_NAME","Detected camera name (might not work)");
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

        {
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
        }
        append_int(ret,"CONFIG_BOOT_AIR",ImprovedIntSetting::createEnumEnableDisable(),"DEV, change boot as air / ground",true);
        append_int(ret,"WIFI_HOTSPOT_E",ImprovedIntSetting::createEnumEnableDisable(),
                   "Enable/Disable WiFi hotspot such that you can connect to your air/ground unit via normal WiFi. Frequency is always the opposite of your WB link, e.g. "
                   "2.4G if your wb link is 5.8G and opposite. Wifi hotspot is automatically disabled when you arm your FC (to avoid interference) !");

        append_int(ret,"ETH_HOTSPOT_E",ImprovedIntSetting::createEnumEnableDisable(),
                   "Enable/Disable ethernet hotspot. When enabled, your rpi becomes a DHCPD server and starts forwarding video & telemetry if you connect a device via ethernet."
                   "However, this doesn't allow you to share your other device(s) internet with the RPI (e.g android) and in general, it is recommended to use ETH_PASSIVE_F instead."
                   "Cannot be used simultanoeusly with ETH_PASSIVE_F. Requires reboot.",true);
        append_int(ret,"ETH_PASSIVE_F",ImprovedIntSetting::createEnumEnableDisable(),
                   "Enable automatic video & telemetry forwarding via ethernet if EITH_HOTSPOT_E is false (Recommended)."
                   "Cannot be used simultaneously with ETH_HOTSPOT_E. Doesn't require reboot.",false);
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
                    {"disable",""},
                    {"serial0","/dev/serial0"},
                    {"serial1","/dev/serial1"},
                    {"ttyUSB0","/dev/ttyUSB0"},
                    {"ttyACM0","/dev/ttyACM0"},
                    {"ttyACM1","/dev/ttyACM1"},
                    {"ttyS7","/dev/ttyS7"}
            };
            append_string(ret,"FC_UART_CONN",ImprovedStringSetting{fc_uart_conn_values},
                          "Telemetry FC<->Air unit. Make sure FC_UART_BAUD matches your FC. For rpi users, select serial0 for GPIO serial. "
                          "See the wiki for more info.");
            //same for ground uart out
            append_string(ret,"TRACKER_UART_OUT",ImprovedStringSetting{fc_uart_conn_values},
                          "Enable mavlink telemetry out via UART on the ground station for connecting a tracker or even an RC with mavlink lua script.");
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
        append_only_documented(ret,"RC_UPDATE_HZ",
                               "Specify the update rate of RC over wifibroadcast. A higher update rate gives lower RC latency, but takes more bandwidth away from the downlink."
                               "No effect if joy rc is disabled.");

    }
    return ret;
}


static std::map<std::string,XParam> create_param_map(){
   auto tmp=get_parameters_list();
   std::map<std::string,XParam> ret;
   for(const auto& param:tmp){
        if(ret.find(param.param_name)!=ret.end()){
            qWarning("Param %s already exists !",param.param_name.c_str());
        }
        ret[param.param_name]=param;
        //qDebug()<<"YY"<<param.param_name.c_str();
   }
   //qDebug()<<"create_param_map()"<<tmp.size()<<", "<<tmp.size();
   return ret;
}

static std::optional<XParam> find_param(const std::string& param_name){
   //qDebug()<<"find_param"<<param_name.c_str();
   // we use static to create a cache - we only read from the map anyways
   static std::map<std::string,XParam> cached=create_param_map();
   if(cached.find(param_name)!=cached.end()){
        XParam ret=cached.at(param_name);
        //qDebug()<<"XXX Found "<<param_name.c_str()<<" "<<ret.param_name.c_str();
        return ret;
   }else{
        //qDebug()<<"XXX Didn't find "<<param_name.c_str();
   }
   return std::nullopt;
}



#endif // DOCUMENTED_PARAM_H
