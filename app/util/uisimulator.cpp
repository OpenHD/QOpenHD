#include <QScopedValueRollback>
#include "telemetry/action/ohdaction.h"
#include "telemetry/models/rcchannelsmodel.h"
#include "telemetry/settings/pollutionhelper.h"
#include "uisimulator.h"
#include "qopenhd.h"
#include "telemetry/models/aohdsystem.h"
#include "telemetry/models/camerastreammodel.h"
#include "telemetry/models/fcmavlinksystem.h"
#include "telemetry/models/wificard.h"
#include "telemetry/models/openhd_core/platform.hpp"
#include "telemetry/settings/mavlinksettingsmodel.h"
#include "telemetry/settings/documentedparam.h"
#include "telemetry/settings/wblinksettingshelper.h"
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QCoreApplication>
#include <QThread>

std::atomic_bool UiSimulator::s_active{false};
UiSimulator& UiSimulator::instance() { static auto* s=new UiSimulator(QCoreApplication::instance()); return *s; }
bool UiSimulator::isActive() { return s_active.load(); }
UiSimulator::UiSimulator(QObject* parent):QObject(parent) {
    m_tick.setInterval(1000);
    connect(&m_tick,&QTimer::timeout,this,[this]{++m_seconds;refresh();});
    m_profile={{"ground",21},{"air",11},{"camera1",32},{"camera2",3},{"radio",17},
               {"link",1},{"secondLink",0},{"state",1},{"fc",true},{"groundRadios",1},{"airRadios",1},{"accessMode",0}};
}
void UiSimulator::install(QQmlContext* context) {
    m_context=context;
    for(const auto& key:{"_ohdSystemAir","_ohdSystemGround","_cameraStreamModelPrimary","_cameraStreamModelSecondary",
           "_ohdSystemAirSettingsModel","_ohdSystemGroundSettings","_airCameraSettingsModel","_airCameraSettingsModel2",
           "_wifi_card_air","_wifi_card_gnd0","_wifi_card_gnd1","_wifi_card_gnd2","_wifi_card_gnd3",
           "_fcMavlinkSystem","_wbLinkSettingsHelper","_pollutionHelper","_ohdAction","_rcchannelsmodelfc","_rcchannelsmodelground"})
        m_live.insert(key,context->contextProperty(key).value<QObject*>());
    context->setContextProperty("_uiSimulator",this);
}
QVariantList UiSimulator::platforms() const {
    QVariantList out;
    const QMap<int,QString> friendly{{11,"Raspberry Pi 4"},{12,"Raspberry Pi CM4"},{13,"Raspberry Pi 5"},
        {20,"Radxa Zero 3W"},{21,"Radxa ROCK 5A"},{22,"Radxa ROCK 5B"},{51,"ORQA"}};
    for(int id:{1,10,11,12,13,20,21,22,24,25,27,28,30,31,32,36,40,46,47,51,52,61})
        out.append(QVariantMap{{"value",id},{"label",friendly.value(id,QString::fromStdString(x_platform_type_to_string(id)))}});
    return out;
}
QVariantList UiSimulator::cameras(int platform) const {
    CameraStreamModel model(0);
    QVariantList out{QVariantMap{{"value",-1},{"label",tr("Not connected")}}};
    const auto types=model.get_supported_camera_types(platform);
    const auto names=model.get_supported_camera_names(platform);
    for(int i=0;i<types.size();++i) out.append(QVariantMap{{"value",types[i]},{"label",names.value(i)}});
    return out;
}
QVariantList UiSimulator::radios() const {
    WiFiCard model(false,0);
    for(auto* timer:model.findChildren<QTimer*>()) timer->stop();
    QVariantList out;
    for(int id:{17,22,23,25,0,1,2,3,7,10})
        out.append(QVariantMap{{"value",id},{"label",model.cardTypeName(id)}});
    return out;
}
void UiSimulator::createModels() {
    if(m_air) return;
    m_air=new AOHDSystem(true,this);m_ground=new AOHDSystem(false,this);
    m_fc=new FCMavlinkSystem(this);m_linkHelper=new WBLinkSettingsHelper(this);m_pollution=new PollutionHelper(this);m_actions=new OHDAction(this);m_rc=new RCChannelsModel(this);
    m_airParams=new MavlinkSettingsModel(101,191,this);m_groundParams=new MavlinkSettingsModel(100,191,this);
    m_simulated={{"_ohdSystemAir",m_air},{"_ohdSystemGround",m_ground},{"_fcMavlinkSystem",m_fc},
        {"_wbLinkSettingsHelper",m_linkHelper},{"_pollutionHelper",m_pollution},{"_ohdAction",m_actions},{"_rcchannelsmodelfc",m_rc},{"_rcchannelsmodelground",m_rc},{"_ohdSystemAirSettingsModel",m_airParams},{"_ohdSystemGroundSettings",m_groundParams}};
    for(int i=0;i<2;++i) {
        m_cameras[i]=new CameraStreamModel(i,this);
        m_cameraParams[i]=new MavlinkSettingsModel(101,100+i,this);
        m_simulated.insert(i?"_cameraStreamModelSecondary":"_cameraStreamModelPrimary",m_cameras[i]);
        m_simulated.insert(i?"_airCameraSettingsModel2":"_airCameraSettingsModel",m_cameraParams[i]);
    }
    for(int i=0;i<5;++i) {
        m_radios[i]=new WiFiCard(i==0,i==0?0:i-1,this);
        m_simulated.insert(i==0?QString("_wifi_card_air"):QString("_wifi_card_gnd%1").arg(i-1),m_radios[i]);
    }
    // The cloned models receive no network packets and must not expire their
    // synthetic state or trigger native discovery/flight timers.
    for(auto* timer:findChildren<QTimer*>()) timer->stop();
    for(auto* model:{m_airParams,m_groundParams,m_cameraParams[0],m_cameraParams[1]})
        connect(model,&MavlinkSettingsModel::update_countChanged,this,[this]{if(active())refresh();});
}
void UiSimulator::seedParameters(MavlinkSettingsModel* model,int system,int component,int platform,int camera) {
    QFile file(":/settings/catalog.json");file.open(QIODevice::ReadOnly);
    const auto catalog=QJsonDocument::fromJson(file.readAll()).object()["settings"].toArray();
    QJsonArray metadata;QVariantMap values;
    const bool cam=component==100||component==101;
    for(auto entry:catalog) {
        auto e=entry.toObject();const QString id=e["id"].toString();
        const bool cameraSetting=DocumentedParam::is_camera_setting(id);
        if(cam!=cameraSetting) continue;
        if(cam && !DocumentedParam::camera_setting_supported(id,camera,platform)) continue;
        if(!cam && (id.startsWith("RPI_") || id.startsWith("MICROHARD_"))) continue;
        if(id.startsWith("AR_") && m_profile["link"].toInt()!=5 && m_profile["secondLink"].toInt()!=5)continue;
        if(platform<10||platform>13) {if(id.startsWith("RPI_")||id.startsWith("LIBCAMERA_"))continue;}
        if(platform<20||platform>28) {if(id.startsWith("ROCKCHIP_"))continue;}
        if(system==100 && (id.startsWith("FC_")||id.startsWith("GPIO_")||id.startsWith("SBUS_")))continue;
        auto choices=e["choices"].toArray();
        QVariant value=e["type"]=="string"?QVariant(QString()):QVariant(e["minimum"].toInt(0));
        if(!choices.isEmpty()) value=choices.first().toObject()["value"].toVariant();
        if(e["type"]=="runtime") {e["type"]="int32";e["minimum"]=0;e["maximum"]=100000;}
        values[id]=value;metadata.append(e);
    }
    auto put=[&](QString id,QVariant value,QJsonArray choices=QJsonArray{},bool readOnly=false) {
        values[id]=value;QJsonObject e{{"id",id},{"label",id},{"type",value.userType()==QMetaType::QString?"string":"int32"},
            {"minimum",0},{"maximum",10000000},{"readOnly",readOnly},{"writable",!readOnly},{"choices",choices}};
        for(int i=0;i<metadata.size();++i)if(metadata[i].toObject()["id"]==id){auto previous=metadata[i].toObject();previous["type"]=e["type"];if(!choices.isEmpty())previous["choices"]=choices;metadata[i]=previous;return;}
        metadata.append(e);
    };
    auto choice=[](QString label,QVariant value){return QJsonObject{{"label",label},{"value",QJsonValue::fromVariant(value)}};};
    if(cam && camera>=0) {
        QJsonArray camerasJson;for(auto c:cameras(platform)) {auto m=c.toMap();if(m["value"].toInt()>=0)camerasJson.append(choice(m["label"].toString(),m["value"]));}
        put("CAMERA_TYPE",camera,camerasJson);put("STREAMING_E",1,QJsonArray{choice("Disabled",0),choice("Enabled",1)});
        put("RESOLUTION_FPS",QString("1920x1080@30"));put("BITRATE_MBITS",camera==3?3:8);put("VIDEO_CODEC",1);put("KEYFRAME_I",5);
        put("AIR_RECORDING_E",0);
        if(camera==3){put("IP_CAM_ADDRESS",QString("192.168.1.90"));put("IP_CAM_PIPELINE",QString("rtspsrc location=rtsp://192.168.1.90:554/stream"));}
    }
    if(!cam) {
        put("WB_FREQUENCY",5745,QJsonArray{choice("[36] 5180 MHz",5180),choice("[149] 5745 MHz",5745),choice("[165] 5825 MHz",5825)});
        put("WB_CHANNEL_W",20,QJsonArray{choice("20 MHz",20),choice("40 MHz",40)});
        QJsonArray mcs;for(int i=0;i<8;++i)mcs.append(choice(QString("MCS %1").arg(i),i));put("WB_MCS_INDEX",2,mcs);
        put("WB_V_FEC_PERC",20);put("TX_PWR_LVL",20);put("WB_PIT_MODE",1);
        put("WFB_LINK_EN",m_profile["link"].toInt()==1||m_profile["secondLink"].toInt()==1?1:0);
        put("ETH_LINK_EN",m_profile["link"].toInt()==2||m_profile["secondLink"].toInt()==2?1:0);
        put("MULTI_LINK_EN",m_profile["secondLink"].toInt()>0?1:0);put("MULTI_LINK_CAP",1,{},true);
        put("VARIABLE_BITRATE",1);put("V_PRIMARY_PERC",70);put("V_IP_CAM_MBITS",3);put("AUDIO_ENABLE",1);put("AUDIO_GAIN",100);put("AUDIO_DEV_COUNT",2,{},true);put("AUDIO_USB_COUNT",1,{},true);
        put("AUD_USB_NAMES",QString("Simulated USB microphone"),{},true);
        put("AUDIO_DEVICE",QString("hw:1,0"),QJsonArray{choice("USB microphone",QString("hw:1,0")),choice("Onboard microphone",QString("hw:0,0"))});
        const int radios=qBound(1,m_profile[system==100?"groundRadios":"airRadios"].toInt(),4);
        put("WB_N_CARDS",radios,{},true);for(int i=0;i<4;++i)put(QString("CARD_TYPE_%1").arg(i),i<radios?m_profile["radio"].toInt():15,{},true);
        put("WIFI_MODE",1);put("WIFI_HOTSPOT_E",0);put("WIFI_HS_SSID",system==100?QString("OpenHD-Ground"):QString("OpenHD-Air"));
        put("WIFI_HS_PW",QString("simulation"));put("WIFI_HS_IFACE",QString());
        put("WIFI_CL_IFACE",QString());put("WIFI_CL_SSID",QString("Workshop"));put("WIFI_CL_PW",QString("simulation"));
        put("WIFI_IFACES",QString("wlan0(BROADCOM,hotspot)"),{},true);
        if(system==101){put("FC_UART_CONN",QString("/dev/ttyAMA0"));put("FC_UART_BAUD",115200);put("FC_BATT_N_CELLS",4);put("FC_SYS_ID",1);
            put("FC_FW_INFO",QString("INAV"),{},true);put("FC_FW_EVID",QString("{\"evidence\":\"Simulated firmware reply\"}"),{},true);}
        put("PRIMARY_LINK",QString(m_profile["link"].toInt()==2?"Ethernet":"WiFiBroadcast"),{},true);
    }
    // No process-wide metadata or live device metadata is replaced.
    const bool metadataOk=DocumentedParam::install_metadata(-system,component,QJsonDocument(QJsonObject{{"version",1},{"systemId",-system},{"componentId",component},{"settings",metadata}}).toJson());
    Q_ASSERT(metadataOk);
    if(!metadataOk) qWarning("Simulator metadata rejected for system %d component %d",system,component);
    model->initializeSimulation(values);
}
bool UiSimulator::start(const QVariantMap& config) {
    if(!m_unlocked || !m_context)return false;
    QVariantMap proposed=m_profile;
    for(auto it=config.begin();it!=config.end();++it)proposed[it.key()]=it.value();
    auto hasValue=[](const QVariantList& list,int value){for(auto e:list)if(e.toMap().value("value").toInt()==value)return true;return false;};
    if(!hasValue(platforms(),proposed["air"].toInt())||!hasValue(platforms(),proposed["ground"].toInt())||
       !hasValue(cameras(proposed["air"].toInt()),proposed["camera1"].toInt())||!hasValue(cameras(proposed["air"].toInt()),proposed["camera2"].toInt())||
       !hasValue(radios(),proposed["radio"].toInt())||proposed["link"].toInt()<1||proposed["link"].toInt()>7||
       proposed["secondLink"].toInt()<0||proposed["secondLink"].toInt()>7||proposed["accessMode"].toInt()<0||proposed["accessMode"].toInt()>2)return false;
    if(active())stop();
    for(const auto& key:{"ground","air","camera1","camera2","radio","link","secondLink","state","fc","groundRadios","airRadios","accessMode"})
        if(config.contains(key))m_profile[key]=config[key];
    if(m_profile["link"]==m_profile["secondLink"])m_profile["secondLink"]=0;
    createModels();m_seconds=0;m_radioProgress=-1;
    const QVariantMap localDefaults{{"ground_battery_type",0},{"ground_battery_capacity_mah",5200},{"ground_battery_cells",4},
          {"ground_battery_low",35},{"ground_battery_mid",37},{"ground_battery_full",42}};
    for(auto it=localDefaults.begin();it!=localDefaults.end();++it)m_localSettings.insert(it.key(),it.value());
    QOpenHD::instance().setDebugMenuPreviewLevel(0);
    seedParameters(m_airParams,101,191,m_profile["air"].toInt(),-1);
    seedParameters(m_groundParams,100,191,m_profile["ground"].toInt(),-1);
    for(int i=0;i<2;++i)seedParameters(m_cameraParams[i],101,100+i,m_profile["air"].toInt(),m_profile[i?"camera2":"camera1"].toInt());
    m_storage={QVariantMap{{"id",1},{"storageId",1},{"kind","disk"},{"device","/dev/simulated"},{"internal",false},{"totalMiB",32768},{"freeMiB",24576},{"canRepartition",true},{"canCreatePartition",true}},
        QVariantMap{{"id",2},{"storageId",2},{"kind","partition"},{"device","/dev/simulated1"},{"internal",false},{"totalMiB",32768},{"freeMiB",24576},{"mountedAtVideo",true},{"formatted",true},{"canMount",true},{"canFormat",true},{"canResize",true}}};
    m_actions->setSimulationStorage(m_storage);
    m_active=true;s_active=true;refresh();
    for(auto it=m_simulated.begin();it!=m_simulated.end();++it)m_context->setContextProperty(it.key(),it.value());
    m_tick.start();emit profileChanged();emit activeChanged();recordAction(tr("Simulation started - device changes stay in memory"));return true;
}
void UiSimulator::stop() {
    if(!active())return;
    m_tick.stop();
    // Restore live bindings while the outbound guard is still active.
    for(auto it=m_live.begin();it!=m_live.end();++it)m_context->setContextProperty(it.key(),it.value());
    m_active=false;s_active=false;emit activeChanged();recordAction(tr("Live device view restored"));
}
void UiSimulator::recordAction(const QString& action) {m_lastAction=action;emit lastActionChanged();}
bool UiSimulator::setParameter(int system,int component,const QString& id,const QVariant& value) {
    if(!active() || (system!=100 && system!=101) ||
       (component!=191 && !(system==101 && (component==100 || component==101))))return false;
    bool ok=false;
    auto apply=[&]{auto* model=system==100?m_groundParams:component==100?m_cameraParams[0]:component==101?m_cameraParams[1]:m_airParams;ok=model->setSimulationValue(id,value);};
    if(QThread::currentThread()==thread())apply();else QMetaObject::invokeMethod(this,apply,Qt::BlockingQueuedConnection);
    return ok;
}
bool UiSimulator::storageAction(int action,int id) {
    if(!active())return false;
    for(int i=0;i<m_storage.size();++i){auto item=m_storage[i].toMap();if(item["id"].toInt()!=id)continue;
        if(action==3)item["mountedAtVideo"]=true;
        if(action==4){item["freeMiB"]=item["totalMiB"];item["formatted"]=true;}
        m_storage[i]=item;
    }
    m_actions->setSimulationStorage(m_storage);
    recordAction(tr("Simulated storage operation %1 - no disk changed").arg(action));return true;
}
void UiSimulator::startRadioOperation(bool analysis) {
    if(!active())return;
    m_analyzing=analysis;m_radioProgress=0;
    if(analysis){m_linkHelper->set_analyze_progress_perc(0);m_linkHelper->set_analyzed_channel_count(0);}
    else {m_linkHelper->set_scan_progress_perc(0);m_linkHelper->set_scanning_text_for_ui("Simulated scan");}
    recordAction(analysis?tr("Simulated RF analysis - synthetic measurements"):tr("Simulated channel scan"));
}
void UiSimulator::refresh() {
    if(m_refreshing)return;
    QScopedValueRollback<bool> refreshing(m_refreshing,true);
    for(int i=0;i<2;++i){
        const QString key=i?"camera2":"camera1";
        if(m_cameraParams[i]->param_int_exists("CAMERA_TYPE")){
            const int type=m_cameraParams[i]->get_cached_int("CAMERA_TYPE");
            if(type!=m_profile[key].toInt()){
                m_profile[key]=type;seedParameters(m_cameraParams[i],101,100+i,m_profile["air"].toInt(),type);emit profileChanged();
            }
        }
    }
    if(m_radioProgress>=0) {
        m_radioProgress=qMin(100,m_radioProgress+20);
        if(m_analyzing) {
            std::vector<PollutionHelper::PollutionElement> samples;
            for(int f:{5180,5200,5220,5240,5745,5785,5825}) {
                PollutionHelper::PollutionElement p;p.frequency_mhz=f;p.nhm_env_percent=5+(f%17);p.busy_percent=10+(f%23);
                p.n_foreign_packets=f%40;p.n_foreign_packets_normalized=f%40;p.rf_sampled_busy=true;p.devourer_survey=true;samples.push_back(p);
            }
            m_pollution->threadsafe_update(samples);
            m_linkHelper->set_analyze_progress_perc(m_radioProgress);m_linkHelper->set_analyzed_channel_count(int(samples.size()));
            m_linkHelper->set_analyze_results_revision(m_linkHelper->analyze_results_revision()+1);
        } else {m_linkHelper->set_scan_progress_perc(m_radioProgress);if(m_radioProgress==100)m_linkHelper->set_scanning_text_for_ui("Simulated Air unit found");}
        if(m_radioProgress==100)m_radioProgress=-1;
    }
    const bool connected=m_profile["state"].toInt()!=0;
    int dynamicCameras=0;
    for(auto* p:m_cameraParams)if(p->param_int_exists("STREAMING_E")&&p->get_cached_int("STREAMING_E")&&p->get_cached_int("CAMERA_TYPE")!=3)++dynamicCameras;
    int enabled=0;
    for(int i=0;i<2;++i){
        const int type=m_cameraParams[i]->param_int_exists("CAMERA_TYPE")?m_cameraParams[i]->get_cached_int("CAMERA_TYPE"):-1;
        auto* cam=m_cameras[i];auto* params=m_cameraParams[i];
        const bool on=type>=0&&params->param_int_exists("STREAMING_E")&&params->get_cached_int("STREAMING_E")!=0;
        if(on)++enabled;
        cam->set_camera_type(type);cam->set_camera_status(!connected?-1:!on?0:m_profile["state"].toInt()==2?2:1);
        cam->set_encoding_codec(params->param_int_exists("VIDEO_CODEC")?params->get_cached_int("VIDEO_CODEC"):1);
        const auto format=params->param_string_exists("RESOLUTION_FPS")?params->get_cached_string("RESOLUTION_FPS"):QString();
        cam->set_curr_set_video_format(format);cam->set_curr_set_video_format_and_codec(format+(cam->encoding_codec()==1?" H.265":" H.264"));
        const int fps=format.section('@',1).toInt();cam->set_curr_set_video_fps_int(fps);cam->set_curr_video_measured_encoder_fps_int(fps);
        int bitrate=params->param_int_exists("BITRATE_MBITS")?params->get_cached_int("BITRATE_MBITS")*1000000:0;
        if(type!=3 && m_airParams->get_cached_int("VARIABLE_BITRATE")==1)
            bitrate=dynamicCameras==1?16600000:16600000*(i?100-m_airParams->get_cached_int("V_PRIMARY_PERC"):m_airParams->get_cached_int("V_PRIMARY_PERC"))/100;
        cam->set_curr_video_measured_encoder_bitrate_bps(on&&connected?bitrate:0);
        cam->set_curr_video_measured_encoder_bitrate(QString::number(cam->curr_video_measured_encoder_bitrate_bps()/1000000.0,'f',1)+" Mbit/s");
        cam->set_curr_video_injected_bitrate_bps(qint64(cam->curr_video_measured_encoder_bitrate_bps())*(100+m_airParams->get_cached_int("WB_V_FEC_PERC"))/100);
    }
    for(int i=0;i<2;++i){auto* unit=i?m_air:m_ground;const int platform=m_profile[i?"air":"ground"].toInt();
        unit->set_is_alive(connected);unit->set_ohd_platform(platform);unit->set_ohd_platform_type_as_string(QString::fromStdString(x_platform_type_to_string(platform)));
        unit->set_openhd_version("3.0.0 SIMULATION");unit->set_curr_cpuload_perc((i?28:12)+m_seconds%5);unit->set_curr_soc_temp_degree(i?48:42);
        unit->set_onboard_uptime_ms((300+m_seconds)*1000);unit->set_onboard_ram_usage_mib(i?24:12);unit->set_onboard_ram_total_mib((platform==21?8192:4096)*1024);
        unit->set_curr_space_left_mb(24576);unit->set_wifi_hotspot_state((i?m_airParams:m_groundParams)->get_cached_int("WIFI_HOTSPOT_E")==1?1:2);
        unit->set_wifi_hotspot_frequency(2412);unit->set_n_openhd_cameras(enabled);unit->set_dirty_air_has_secondary_cam(enabled>1);
        unit->set_wb_gnd_operating_mode(0);unit->set_primary_link_type(m_profile["link"].toInt()==4?3:m_profile["link"].toInt()==5?4:m_profile["link"].toInt()<=2?m_profile["link"].toInt():0);unit->set_current_rx_rssi(-48);unit->set_current_rx_signal_quality(98);
        unit->set_curr_channel_mhz((i?m_airParams:m_groundParams)->get_cached_int("WB_FREQUENCY"));unit->set_curr_channel_width_mhz((i?m_airParams:m_groundParams)->get_cached_int("WB_CHANNEL_W"));
        unit->set_curr_mcs_index(m_airParams->get_cached_int("WB_MCS_INDEX"));unit->set_last_ping_result_openhd("4 ms");unit->set_wb_link_pollution_perc(2);unit->set_wb_link_curr_foreign_pps(12);
        unit->set_ina219_voltage_millivolt(15800);unit->set_battery_percent(72);
        unit->set_ground_details({{"hotspot_clients",2},{"hotspot_ip","192.168.3.1"},{"public_ip","203.0.113.10"},
             {"system_used_bytes",QVariant::fromValue<qulonglong>(8ULL<<30)},{"system_total_bytes",QVariant::fromValue<qulonglong>(32ULL<<30)}});
    }
    for(int i=0;i<5;++i){auto* card=m_radios[i];card->set_alive(connected&&(i==0||i<=m_profile["groundRadios"].toInt()));card->set_card_type(m_profile["radio"].toInt());card->set_card_type_as_string(card->cardTypeName(m_profile["radio"].toInt()));card->set_card_type_supported(true);card->set_curr_rx_rssi_dbm(-48);}
    QVariantList usage;
    for(int id:{m_profile["link"].toInt(),m_profile["secondLink"].toInt()}){
        if(id<1||!connected)continue;
        QVariantList categories; qint64 total=18000;
        for(int i=0;i<2;++i){auto bps=m_cameras[i]->curr_video_measured_encoder_bitrate_bps();total+=bps;categories.append(QVariantMap{{"id",i+1},{"bps",bps}});}
        categories.append(QVariantMap{{"id",4},{"bps",18000}});
        int fec=id==1?int((total-18000)*m_airParams->get_cached_int("WB_V_FEC_PERC")/100):0;
        categories.append(QVariantMap{{"id",5},{"bps",fec}});total+=fec;
        QVariantList streams;
        for(int i=0;i<2;++i)streams.append(QVariantMap{{"id",i},{"active",m_cameras[i]->camera_status()==1},{"controllable",m_cameraParams[i]->param_int_exists("CAMERA_TYPE")&&m_cameraParams[i]->get_cached_int("CAMERA_TYPE")!=3},
            {"percent",i?100-m_airParams->get_cached_int("V_PRIMARY_PERC"):m_airParams->get_cached_int("V_PRIMARY_PERC")},
            {"budget_kbits",m_cameras[i]->curr_video_measured_encoder_bitrate_bps()/1000}});
        QVariantMap allocation{{"available",true},{"enabled",m_airParams->get_cached_int("VARIABLE_BITRATE")==1},{"capacity_kbits",20000},{"priority_kbits",200},
            {"safety_kbits",200},{"fixed_kbits",3000},{"pool_kbits",16600},{"streams",streams}};
        usage.append(QVariantMap{{"id",id},{"total_bps",total},{"capacity_bps",id==2?1000000000:20000000},{"categories",categories},{"allocation",allocation},
            {"tx_bps",total},{"rx_bps",64000},{"rtt_us",2200},{"jitter_us",100},{"probe_loss_permille",0},{"send_errors",0}});
    }
    m_air->setSimulationLinkUsage(usage);m_ground->set_received_link_bitrate_bps(connected?m_cameras[0]->curr_video_injected_bitrate_bps()+m_cameras[1]->curr_video_injected_bitrate_bps()+18000:-1);
    m_air->set_received_link_bitrate_bps(m_ground->received_link_bitrate_bps());
    m_linkHelper->set_curr_channel_mhz(m_ground->curr_channel_mhz());m_linkHelper->set_curr_channel_width_mhz(m_ground->curr_channel_width_mhz());
    m_linkHelper->set_curr_air_channel_width_mhz(m_air->curr_channel_width_mhz());
    RCChannelsModel::RC_CHANNELS channels{};for(int i=0;i<18;++i)channels[i]=i==2?1000:1500+(i%3-1)*100;
    m_rc->update_all_channels(channels);m_rc->set_is_alive(connected&&m_profile["fc"].toBool());
    m_fc->set_is_alive(connected&&m_profile["fc"].toBool());m_fc->set_telemetry_active(m_fc->is_alive());
    m_fc->set_mav_type_str("QUADROTOR");m_fc->set_battery_voltage_volt(15.8);m_fc->set_battery_percent(72);m_fc->set_battery_voltage_single_cell(3.95);
    m_fc->set_firmware_identity({{"name","INAV"},{"sys",1},{"comp",1}});
    m_fc->set_craft_diagnostics({{"heartbeatAge",0.2},{"statusAge",0.1},{"present",3},{"enabled",3},{"healthy",3}});
}
