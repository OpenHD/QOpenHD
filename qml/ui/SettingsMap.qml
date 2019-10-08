import QtQuick 2.13

/*
 * These are mappings for the raw settings key/value pairs provided by the ground station. We
 * give certain settings full readable titles, type information, and limits or ranges in order
 * to make them more visible and easier to deal with.
 *
 * Any settings not listed in these mappings will still end up in the "other" tab, allowing graceful
 * fallback if new settings are added on the ground station. Any settings that are *removed* will
 * simply not show up anymore, preventing the app from being fragile and dependent on specific
 * versions of the ground station.
 *
 */
Item {
    id: settingsMap
    property var generalSettingsMap: ({
        "DEBUG": {title: "Enable debug mode", itemType: "bool", trueValue: "Y", falseValue: "N"},
        "QUIET": {title: "Enable quiet mode", itemType: "bool", trueValue: "Y", falseValue: "N"},
        "ENABLE_SCREENSHOTS": {title: "Enable OSD screenshots", itemType: "bool", trueValue: "Y", falseValue: "N"},
        "DISPLAY_OSD": {title: "Display OSD", itemType: "bool", trueValue: "Y", falseValue: "N"},
    })

    property var videoSettingsMap: ({
        "BITRATE_PERCENT": {title: "Bitrate percent",
                            itemType: "number",
                            lowerLimit: 0,
                            upperLimit: 100,
                            interval: 1,
                            unit: "%"},
        "VIDEO_BITRATE": {title: "Video bitrate", itemType: "string"},
        "VIDEO_BLOCKLENGTH": {title: "Block length", itemType: "string"},
        "VIDEO_BLOCKS": {title: "Blocks",
                         itemType: "number",
                         lowerLimit: 1,
                         upperLimit: 20,
                         interval: 1,
                         unit: ""},
        "VIDEO_FECS": {title: "FECs",
                       itemType: "number",
                       lowerLimit: 1,
                       upperLimit: 20,
                       interval: 1,
                       unit: ""},
        "WIDTH": {title: "Width", itemType: "string"},
        "HEIGHT": {title: "Height", itemType: "string"},
        "FPS": {title: "Frames per second",
                itemType: "choice",
                choiceValues: [{title: "30 FPS", value: 30},
                               {title: "48 FPS", value: 48},
                               {title: "59.9 FPS", value: 59.9}]},
        "KEYFRAMERATE": {title: "Keyframe interval",
                         itemType: "number",
                         lowerLimit: 1,
                         upperLimit: 60,
                         interval: 1,
                         unit: ""},
        "EXTRAPARAMS": {title: "Extra parameters", itemType: "string"},
    })

    property var radioSettingsMap: ({
        "Bandwidth": {title: "Radio bandwidth",
                      itemType: "choice",
                      "choiceValues": [{title: "5MHz", value: 5},
                                       {title: "10MHz", value: 10},
                                       {title: "20MHz", value: 20}]},
        "EncryptionOrRange": {title: "Encryption/range mode",
                              itemType: "choice",
                              choiceValues: [{title: "Encryption", value: "Encryption"},
                                             {title: "Range", value: "Range"}]},
        "FREQ": {title: "Frequency", itemType: "string"},
        "CTS_PROTECTION": {title: "CTS", itemType: "bool", trueValue: "Y", falseValue: "N"},
        "DATARATE": {title: "Data rate",
                     itemType: "choice",
                     choiceValues: [{title: "5.5Mbps/6.5Mbps (MCS)", value: 1},
                                    {title: "11Mbps/13Mbps (MCS)", value: 2},
                                    {title: "12Mbps/13Mbps (MCS)", value: 3},
                                    {title: "19.5Mbps", value: 4},
                                    {title: "24Mbps/26Mbps (MCS)", value: 5},
                                    {title: "36Mbps/39Mbps (MCS)", value: 6}]},
        "TxPowerAir": {title: "TX power (air)", itemType: "string"},
        "TxPowerGround": {title: "TX power (ground)", itemType: "string"},
        "UseLDPC": {title: "Use LDPC", itemType: "bool", trueValue: "Y", falseValue: "N"},
        "UseMCS": {title: "Use MCS", itemType: "bool", trueValue: "Y", falseValue: "N"},
        "UseSTBC": {title: "Use STBC", itemType: "bool", trueValue: "Y", falseValue: "N"},
    })

    property var rcSettingsMap: ({

    })


    property var smartSyncSettingsMap: ({
        "SmartSync_StartupMode": {title: "SmartSync Startup Mode",
                                  itemType: "choice",
                                  choiceValues: [{title: "Quick", value: "0"},
                                                 {title: "Wait for air at boot", value: "1"}]},

        "SmartSyncRC_Channel": {title: "SmartSync RC Channel",
                                itemType: "number",
                                lowerLimit: 1,
                                upperLimit: 10,
                                interval: 1,
                                unit: ""},
    })

    property var hotspotSettingsMap: ({
        "ETHERNET_HOTSPOT": {title: "Enable ethernet hotspot",
                             itemType: "bool",
                             trueValue: "Y",
                             falseValue: "N"},
        "WIFI_HOTSPOT": {title: "Enable WiFi hotspot",
                         itemType: "choice",
                         choiceValues: [{title: "Automatic", value: "auto"},
                                        {title: "Yes", value: "yes"},
                                        {title: "No", value: "no"}]},
        "HOTSPOT_BAND": {title: "WiFi hotspot band",
                         itemType: "choice",
                         choiceValues: [{title: "5GHz", value: "a"},
                                        {title: "2.4GHz", value: "g"}]},
        "HOTSPOT_CHANNEL": {title: "Hotspot WiFi channel", itemType: "string"},
    })
}
