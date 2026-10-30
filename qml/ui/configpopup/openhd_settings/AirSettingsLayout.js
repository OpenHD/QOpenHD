.pragma library

var categories = [
 {id:"fc",title:"Flight Controller",icon:"\uf1d8",description:"FC connection and flight telemetry settings."},
 {id:"uart",title:"UART & Telemetry",icon:"\uf120",description:"Serial ports, telemetry and connected peripherals."},
 {id:"peripherals",title:"Peripherals",icon:"\uf2db",description:"GPIO and external devices."},
 {id:"system",title:"System",icon:"\uf013",description:"Wi-Fi, logging and startup settings."},
 {id:"expert",title:"Link recovery",icon:"\uf0ad",description:"Set this unit independently when Air and Ground are out of sync."},
 {id:"developer",title:"Developer settings",icon:"\uf121",description:"Internal controls for development and diagnosis."}
]
var sections = [
 {id:"fcSerial",categories:["fc"],title:"Serial link",description:"",icon:"\uf1d8",ids:["FC_UART_CONN","FC_UART_BAUD","FC_UART_FLWCTL"]},
 {id:"battery",categories:["fc"],title:"Battery settings",description:"",icon:"\uf240",ids:["FC_BATT_N_CELLS"]},
 {id:"fcInfo",categories:["fc"],title:"Identification",description:"",icon:"\uf2db",ids:["FC_FW_INFO","FC_FW_EVID","FC_SYS_ID"]},
 {id:"telemetry",categories:["uart"],title:"Telemetry output",description:"Serial telemetry connection to the ground station.",icon:"\uf519",ids:["OHD_UART_EN","OHD_UART_TLM","OHD_UART_BAUD","OHD_UART_FLW"]},
 {id:"sbus",categories:["uart"],title:"RC Output (SBUS)",description:"Send RC channels to an external SBUS device.",icon:"\uf11b",ids:["SBUS_EN","SBUS_DEV","SBUS_HZ"]},
 {id:"gpio",categories:["peripherals"],title:"Pin outputs (GPIO)",description:"Control external devices using GPIO pins.",icon:"\uf2db",ids:["GPIO_2","GPIO_26"]},
 {id:"logging",categories:["system"],title:"Logging",description:"Save system and telemetry logs.",icon:"\uf15c",ids:["LOG_OPENHD","LOG_MAVLINK"]},
 {id:"hotspot",categories:["system"],title:"Wi-Fi Hotspot",description:"Configure the Air unit's wireless access point.",icon:"\uf1eb",ids:["WIFI_MODE","WIFI_HOTSPOT_E","WIFI_HS_IFACE","WIFI_HS_SSID","WIFI_HS_PW"]},
 {id:"wifiClient",categories:["system"],title:"Wi-Fi Client",description:"Connect the Air unit to a wireless network.",icon:"\uf1eb",ids:["WIFI_CL_IFACE","WIFI_CL_SSID","WIFI_CL_PW","WIFI_IFACES"]},
 {id:"plugins",categories:["system"],title:"Camera control",description:"Status of installed camera-control services.",icon:"\uf1e6",ids:["SIYI_ACTIVE","TOPOTEK_ACTIVE","CAM_CTRL_ACTIVE"]},
 {id:"priority",categories:["uart"],title:"Traffic priorities",description:"Prioritize traffic on the serial telemetry connection.",icon:"\uf120",ids:["UART_PRI_RC","UART_PRI_OHD","UART_PRI_FC"]},
 {id:"role",categories:["system"],title:"Startup role",description:"Configure this unit's role.",icon:"\uf011",ids:["CONFIG_BOOT_AIR"]},
 {id:"links",categories:["expert"],title:"Link operation",description:"Overrides apply only to this unit.",icon:"\uf0c1",ids:["MULTI_LINK_EN","MULTI_LINK_CAP","PRIMARY_LINK","ACTIVE_LINKS"]},
 {id:"datalink",categories:["expert"],title:"Custom datalink",description:"Local UDP transport settings.",icon:"\uf0c1",ids:[]},
 {id:"retransmission",categories:["expert"],title:"Retransmission",description:"Packet recovery and retransmission history.",icon:"\uf2f1",ids:[]},
 {id:"rcRadio",categories:["expert"],title:"Radio Control Channels",description:"Change link settings using RC channels.",icon:"\uf11b",ids:[]},
 {id:"artosyn",categories:["expert"],title:"Artosyn",description:"Artosyn link and radio configuration.",icon:"\uf1eb",ids:[]},
 {id:"radio",categories:["expert"],title:"WiFiBroadcast Radio",description:"Local radio overrides; changes are not synchronized with Ground.",icon:"\uf1eb",ids:[]},
 {id:"diagnostics",categories:["expert"],title:"Hardware Diagnostics",description:"Hardware diagnostics.",icon:"\uf2db",ids:[]},
 {id:"developerControls",categories:["developer"],title:"Developer controls",description:"Internal radio and diagnostic controls.",icon:"\uf121",ids:[]},
 {id:"additional",categories:["system"],title:"Additional Settings",description:"Additional settings reported by this firmware.",icon:"\uf013",ids:[]}
]
var labels = {
 FC_UART_CONN:"Port", FC_UART_BAUD:"Baud rate", FC_UART_FLWCTL:"Flow control", FC_SYS_ID:"MAVLink system ID", FC_BATT_N_CELLS:"Cell count", FC_FW_INFO:"Firmware", FC_FW_EVID:"How it was identified",
 OHD_UART_EN:"Enable serial link",OHD_UART_TLM:"Port",OHD_UART_BAUD:"Baud rate",OHD_UART_FLW:"Flow control",SBUS_EN:"SBUS output",SBUS_DEV:"SBUS port",SBUS_HZ:"Update rate",
 GPIO_2:"GPIO 2 function",GPIO_26:"GPIO 26 function",LOG_OPENHD:"System logging",LOG_MAVLINK:"Telemetry logging",UART_PRI_RC:"RC priority",UART_PRI_OHD:"OpenHD priority",UART_PRI_FC:"FC telemetry priority",
 WIFI_MODE:"Wi-Fi mode",WIFI_HOTSPOT_E:"Hotspot mode",WIFI_HS_IFACE:"Hotspot interface",WIFI_HS_SSID:"Network name",WIFI_HS_PW:"Password",WIFI_CL_IFACE:"Client interface",WIFI_CL_SSID:"Network name",WIFI_CL_PW:"Password",WIFI_IFACES:"Detected interfaces",
 WB_FREQUENCY:"Channel / frequency",WB_CHANNEL_W:"Channel width",WB_MCS_INDEX:"MCS",TX_PWR_LVL:"Transmit power",
 MULTI_LINK_EN:"Multiple links",MULTI_LINK_CAP:"Multiple-link support",PRIMARY_LINK:"Primary link",ACTIVE_LINKS:"Active links",V_SWITCH_CAM:"Swap cameras",V_PRIMARY_PERC:"Camera 1 bandwidth share",V_IP_CAM_MBITS:"IP-camera reservation",
 AUDIO_ENABLE:"Audio capture",AUDIO_GAIN:"Microphone gain",AUDIO_DEVICE:"Capture device",AUDIO_USB_COUNT:"USB devices",AUD_USB_NAMES:"USB device names",AUDIO_DEV_COUNT:"Capture devices",AUDIO_EXAMPLE:"Example audio support",
 ADSB_ENABLE:"ADS-B reception",SIYI_ACTIVE:"SIYI controller",TOPOTEK_ACTIVE:"Topotek controller",CAM_CTRL_ACTIVE:"Camera controller",CONFIG_BOOT_AIR:"Start as an Air unit"
}
var descriptions = {
 FC_UART_CONN:"Select the serial port connected to the controller.",FC_UART_BAUD:"Must match the baud rate configured on the controller.",FC_UART_FLWCTL:"Enable when the RTS and CTS wires are connected.",FC_SYS_ID:"Identifies the controller on the telemetry connection.",FC_BATT_N_CELLS:"Number of cells connected in series.",
 OHD_UART_EN:"Connect Air and Ground using an additional serial link.",OHD_UART_TLM:"Select the serial port used by this link.",OHD_UART_BAUD:"Serial speed for OpenHD telemetry.",OHD_UART_FLW:"Enable when the RTS and CTS wires are connected.",
 SBUS_EN:"Enable SBUS channel output.",SBUS_DEV:"Serial port connected to the SBUS device.",SBUS_HZ:"Number of channel updates per second.",GPIO_2:"Assign a function to GPIO pin 2.",GPIO_26:"Assign a function to GPIO pin 26.",
 LOG_OPENHD:"Save OpenHD system logs to onboard storage.",LOG_MAVLINK:"Record received MAVLink telemetry.",
 FC_FW_INFO:"Firmware reported by the connected controller.",FC_FW_EVID:"Information used to recognize the controller's firmware.",
 UART_PRI_RC:"How much priority RC commands receive on the serial link.",UART_PRI_OHD:"How much priority OpenHD messages receive on the serial link.",UART_PRI_FC:"How much priority controller telemetry receives on the serial link.",
 ADSB_ENABLE:"Show nearby aircraft received through ADS-B.",SIYI_ACTIVE:"Whether the SIYI camera-control service is running.",TOPOTEK_ACTIVE:"Whether the Topotek camera-control service is running.",CAM_CTRL_ACTIVE:"Whether a camera-control service is running.",CONFIG_BOOT_AIR:"Turn off to start this device as a Ground unit."
}
function sectionFor(id) {
 if(isDeveloperParameter(id)) return "developerControls"
 for(var i=0;i<sections.length;i++) if(sections[i].ids.indexOf(id)>=0) return sections[i].id
 if(id.indexOf("WB_RTX_")===0 || id==="WB_ENABLE_RETRA") return "retransmission"
 if(id.indexOf("WB_UDP_")===0) return "datalink"
 if(id.indexOf("RC_")===0 || /_VIA_RC$/.test(id)) return "rcRadio"
 if(id.indexOf("AR_")===0) return "artosyn"
 if(id.indexOf("CARD_TYPE_")===0 || id.indexOf("DEV_")===0 || id.indexOf("MICROHARD_")===0) return "diagnostics"
 if(id.indexOf("WB_")===0 || ["TX_PWR_LVL","VARIABLE_BITRATE","QP_MIN","QP_MAX","ESP_ANALYSE"].indexOf(id)>=0) return "radio"
 if(isLinkRecoveryParameter(id)) return "radio"
 return "additional"
}
function isAirParameter(id) { return knownAirIds.indexOf(id)>=0 || id==="ACTIVE_LINKS" || id.indexOf("CARD_TYPE_")===0 }
var knownAirIds = ["FC_UART_CONN", "FC_UART_BAUD", "FC_UART_FLWCTL", "FC_BATT_N_CELLS", "FC_SYS_ID", "OHD_UART_TLM", "OHD_UART_EN", "OHD_UART_BAUD", "OHD_UART_FLW", "UART_PRI_RC", "UART_PRI_OHD", "UART_PRI_FC", "LOG_MAVLINK", "LOG_OPENHD", "ADSB_ENABLE", "SBUS_EN", "SBUS_DEV", "SBUS_HZ", "SIYI_ACTIVE", "TOPOTEK_ACTIVE", "CAM_CTRL_ACTIVE", "CONFIG_BOOT_AIR", "FC_FW_INFO", "FC_FW_EVID", "MULTI_LINK_CAP", "MULTI_LINK_EN", "WIFI_MODE", "WIFI_IFACES", "PRIMARY_LINK", "WIFI_HOTSPOT_E", "WIFI_HS_IFACE", "WIFI_HS_SSID", "WIFI_HS_PW", "WIFI_CL_IFACE", "WIFI_CL_SSID", "WIFI_CL_PW", "WB_N_CARDS", "WB_FREQUENCY", "WB_CHANNEL_W", "WB_MCS_INDEX", "WB_V_FEC_PERC", "VARIABLE_BITRATE", "QP_MAX", "QP_MIN", "WB_MAX_D_BZ", "WB_V_RATE_PERC", "RC_OHD_CTRL", "RC_SET_BASE", "MCS_VIA_RC", "BW_VIA_RC", "TXMODE_VIA_RC", "FHSS_VIA_RC", "DEV_HIGH_RETR", "ESP_ANALYSE", "WB_ADAPT_CH", "WB_FHSS", "WB_FHSS_SLOT", "WB_ENABLE_RETRA", "WB_RTX_VIDEO", "WB_RTX_TELEM", "WB_RTX_RC", "WB_RTX_V_MAXMS", "WB_RTX_T_MAXMS", "WB_RTX_R_MAXMS", "WB_RTX_REQ_REP", "WB_E_STBC", "WB_E_LDPC", "WB_E_SHORT_GUARD", "TX_PWR_LVL", "WB_PIT_MODE", "WB_DEV_LOGS", "WB_UDP_ENABLE", "WB_UDP_FEC", "WB_UDP_BUDGET", "WB_UDP_MAX_KBPS", "WB_UDP_IN_PORT", "WB_UDP_OUT_PORT", "V_SWITCH_CAM", "V_IP_CAM_MBITS", "V_PRIMARY_PERC", "AUDIO_ENABLE", "AUDIO_EXAMPLE", "AUDIO_GAIN", "AUDIO_USB_COUNT", "AUD_USB_NAMES", "AUDIO_DEV_COUNT", "AUDIO_DEVICE", "GPIO_2", "GPIO_26", "AR_ADDR", "AR_PORT", "AR_SLOT", "AR_VPORT", "AR_TPORT", "AR_DGRAM", "AR_RXBUF", "AR_TXBUF", "AR_RDTMO", "AR_RESET_CMD", "AR_PAIR_CMD", "AR_MCS_MD", "AR_MCS_VAL", "AR_MCS_MIN", "AR_MCS_MAX", "AR_BW_MD", "AR_BW_VAL", "AR_CHN_MD", "AR_CHN_IDX", "AR_PWR_ATO", "AR_PWR_DBM", "AR_BND_MD", "AR_BND_VAL", "AR_CMP_MD", "AR_PWR_MD", "AR_LNA_MD", "AR_LNA_BP", "AR_RF_ATX", "AR_RF_ARX", "AR_RF_BTX", "AR_RF_BRX", "MICROHARD_DUMMY0"]

// User-reviewed Air tab visibility; unreviewed parameters keep their existing behavior.
var reviewDecisions = {
 "FC_UART_CONN": "KEEP",
 "FC_UART_BAUD": "KEEP",
 "FC_UART_FLWCTL": "KEEP",
 "FC_BATT_N_CELLS": "KEEP",
 "FC_SYS_ID": "ADVANCED",
 "OHD_UART_TLM": "ADVANCED",
 "OHD_UART_EN": "ADVANCED",
 "OHD_UART_BAUD": "ADVANCED",
 "OHD_UART_FLW": "ADVANCED",
 "UART_PRI_RC": "ADVANCED",
 "UART_PRI_OHD": "ADVANCED",
 "UART_PRI_FC": "ADVANCED",
 "LOG_MAVLINK": "ADVANCED",
 "LOG_OPENHD": "ADVANCED",
 "ADSB_ENABLE": "KEEP",
 "SBUS_EN": "ADVANCED",
 "SBUS_DEV": "ADVANCED",
 "SBUS_HZ": "ADVANCED",
 "SIYI_ACTIVE": "ADVANCED",
 "TOPOTEK_ACTIVE": "ADVANCED",
 "CAM_CTRL_ACTIVE": "ADVANCED",
 "CONFIG_BOOT_AIR": "ADVANCED",
 "FC_FW_INFO": "KEEP",
 "FC_FW_EVID": "KEEP"
}
var developerParameters = ["DEV_HIGH_RETR", "WB_MAX_D_BZ", "WB_DEV_LOGS", "WFB_LINK_EN", "WIFI_CARD0", "WIFI_CARD1", "WIFI_CARD2", "WIFI_CARD3"]
function isDeveloperParameter(id) { return id.indexOf("AR1_") === 0 || /^WIFI_CARD[0-9]+$/.test(id) || reviewDecisions[id] === "DEVELOPER" || (!reviewDecisions[id] && developerParameters.indexOf(id)>=0) }
function visibleInMode(id, advanced, developer) {
 if(reviewDecisions[id] === "REMOVE") return false
 if(isDeveloperParameter(id)) return developer
 return reviewDecisions[id] !== "ADVANCED" || advanced
}

// These Air-provided parameters are presented by their dedicated Extras pages.
function isUartParameter(id) {
 return ["FC_UART_CONN","FC_UART_BAUD","FC_UART_FLWCTL","TRACKER_UART_OUT","TRACK_UART_BAUD","TRACK_UART_FLOW",
         "OHD_UART_EN","OHD_UART_TLM","OHD_UART_BAUD","OHD_UART_FLW","UART_PRI_RC","UART_PRI_OHD","UART_PRI_FC"].indexOf(id)>=0
}
function belongsToExtras(id) { return isUartParameter(id) || id === "ADSB_ENABLE" || id.indexOf("AUDIO_") === 0 || id.indexOf("AUD_") === 0 }

// UI ownership is separate from the Air component that supplies the parameters.
// Dedicated controls stay deduplicated, except explicit local link recovery in Advanced settings.
var dedicatedPages = {
 "V_SWITCH_CAM":"Camera", "V_IP_CAM_MBITS":"Camera",
 "V_PRIMARY_PERC":"Link allocation", "VARIABLE_BITRATE":"Link allocation",
 "MULTI_LINK_EN":"Link", "MULTI_LINK_CAP":"Link", "PRIMARY_LINK":"Link", "ACTIVE_LINKS":"Link",
 "WB_FREQUENCY":"Link", "WB_CHANNEL_W":"Link", "WB_MCS_INDEX":"Link",
 "TX_PWR_LVL":"Link", "WB_PIT_MODE":"Link", "WB_ADAPT_CH":"Link",
 "WB_FHSS":"Link", "WB_FHSS_SLOT":"Link", "ESP_ANALYSE":"Link",
 "AR_MCS_MD":"Link", "AR_MCS_VAL":"Link", "AR_BW_MD":"Link", "AR_BW_VAL":"Link",
 "AR_CHN_MD":"Link", "AR_CHN_IDX":"Link", "AR_PWR_ATO":"Link", "AR_PWR_DBM":"Link",
 "RC_OHD_CTRL":"Extras", "RC_SET_BASE":"Extras", "WB_DEV_LOGS":"Extras"
}
function dedicatedPage(id) {
 if(belongsToExtras(id) || id.indexOf("WB_UDP_") === 0) return "Extras"
 return dedicatedPages[id] || ""
}
function isLinkRecoveryParameter(id) {
 return id.indexOf("WB_") === 0 || id.indexOf("AR_") === 0 ||
        id.indexOf("TX_POWER_") === 0 || id.indexOf("CARD_TYPE_") === 0 ||
        ["TX_PWR_LVL","ESP_ANALYSE","MULTI_LINK_EN","MULTI_LINK_CAP","PRIMARY_LINK","ACTIVE_LINKS",
         "MCS_VIA_RC","BW_VIA_RC","TXMODE_VIA_RC","FHSS_VIA_RC"].indexOf(id) >= 0
}
function belongsInAir(id, advanced) {
 return isLinkRecoveryParameter(id) ? !!advanced : dedicatedPage(id).length === 0
}

// The parent tab uses the same content test without instantiating its page.
function availableParameterIds(model, advanced, developer, preview) {
 var ids = model.param_ids().slice()
 var reviewed = Object.keys(reviewDecisions).concat(advanced ? knownAirIds : []).concat(developer ? developerParameters : [])
 for(var i=0;i<reviewed.length;i++) {
  var id=reviewed[i]
  if(ids.indexOf(id)<0 && (model.param_int_exists(id) || model.param_string_exists(id))) ids.push(id)
 }
 return ids.filter(function(id) {
  if (!belongsInAir(id, advanced) || (preview && !isAirParameter(id)) || !visibleInMode(id, advanced, developer)) return false
  var section = sectionFor(id)
  return sections.some(function(s) {
   return s.id === section && s.categories.some(function(c) {
    return (c !== "expert" || advanced) && (c !== "developer" || developer)
   })
  })
 })
}
