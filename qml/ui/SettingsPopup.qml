import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12
import Qt.labs.settings 1.0
import QtQuick.Dialogs 1.1

import OpenHD 1.0


SettingsPopupForm {
    id: settings_form
    signal localMessage(var message, var level)

    /*
     * These are models for the settings visible in each tab. They are dynamically generated at runtime
     * to allow different settings to be visible as needed, and to allow for dynamic row types.
     *
     */

    ListModel {
        dynamicRoles: true
        id: generalSettingsModel
    }

    ListModel {
        dynamicRoles: true
        id: radioSettingsModel
    }

    ListModel {
        dynamicRoles: true
        id: videoSettingsModel
    }

    ListModel {
        dynamicRoles: true
        id: rcSettingsModel
    }

    ListModel {
        dynamicRoles: true
        id: hotspotSettingsModel
    }

    ListModel {
        dynamicRoles: true
        id: smartSyncSettingsModel
    }

    ListModel {
        dynamicRoles: true
        id: otherSettingsModel
    }

    SettingsMap {
        id: settingsMap
    }

    /*Connections {
        target: OpenHDRC
        onSelectedGamepadChanged: {
            console.log("onSelectedGamepadChanged %1".arg(selectedGamepad));
        }
        onSelectedGamepadNameChanged: {
            console.log("onSelectedGamepadNameChanged %1".arg(selectedGamepadName));
        }
    }*/

    /*
     * Remote OpenHD settings on the ground station
     *
     */
    OpenHDSettings {
        id: openHDSettings

        onAllSettingsChanged: {
            /*
             * Clear the local ListModels for each tab, the ListView in each tab uses these to decide
             * what to draw.
             *
             */
            generalSettingsModel.clear();
            radioSettingsModel.clear();
            videoSettingsModel.clear();
            hotspotSettingsModel.clear();
            smartSyncSettingsModel.clear();
            otherSettingsModel.clear();

            /*
             * Helper to retrieve and map settings values to a normal representation for display.
             *
             *
             * When the remote settings are saved again, we map these values back to the representation
             * expected by the ground station. This should avoid introducing subtle bugs on the ground station
             * side of things.
             *
             */
            function _process(setting, initialValue, model, mapping, disabled) {
                var itemTitle = mapping[setting]["title"];
                var itemInfo = mapping[setting]["info"];
                if (itemInfo === undefined) {
                    itemInfo = "N/A";
                }
                var itemType  = mapping[setting]["itemType"];

                // not all of these are used for each setting, they don't need to be defined in the
                // mapping if they aren't needed as the QML component will simply not attempt to use them
                var trueValue    = mapping[setting]["trueValue"];
                var falseValue   = mapping[setting]["falseValue"];
                var choiceValues = mapping[setting]["choiceValues"];
                var lowerLimit   = mapping[setting]["lowerLimit"];
                var upperLimit   = mapping[setting]["upperLimit"];
                var interval     = mapping[setting]["interval"];
                var unit         = mapping[setting]["unit"];

                var finalValue;

                // these all need to be mapped because the values coming from the C++ side
                // are of type 'QVariant', not actual types that can be worked with
                if (itemType === "bool") {
                    finalValue = (initialValue == trueValue) ? true : false;
                } else if (itemType === "choice") {
                    finalValue = String(initialValue);
                } else if (itemType === "range") {
                    finalValue = Number(initialValue);
                } else if (itemType === "number") {
                    finalValue = Number(initialValue);
                } else if (itemType === "string") {
                    finalValue = String(initialValue);
                } else {
                    finalValue = initialValue;
                }
                model.append({"title": itemTitle,
                              "setting": setting,
                              "choiceValues": choiceValues,
                              "lowerLimit": lowerLimit,
                              "upperLimit": upperLimit,
                              "interval": interval,
                              "itemType": itemType,
                              "value": finalValue,
                              "unit": unit,
                              "modified": false,
                              "disabled": disabled,
                              "info": itemInfo});
            }

            /*
             * Process all of the ground station settings received over UDP, which happens on the C++
             * side (in openhdsettings.cpp)
             *
             */
            for (var setting in openHDSettings.allSettings) {
                /*
                 * Here we distribute the incoming settings key/value pairs to the ListModel for each tab.
                 *
                 * If a particular setting is found in one of the mappings, we give it special treatment
                 * by adding a nicer title, handling any value mapping that may be required, and place it
                 * in a particular tab on the settings panel for organization and ease of use.
                 *
                 */

                if (settingsMap.blacklistMap[setting] !== undefined) {
                    continue;
                }

                var disabled = false;
                if (settingsMap.disabledMap[setting] !== undefined) {
                    disabled = true;
                }

                var initialValue = openHDSettings.allSettings[setting];
                if (settingsMap.generalSettingsMap[setting] !== undefined) {
                    _process(setting, initialValue, generalSettingsModel, settingsMap.generalSettingsMap, disabled);
                } else if (settingsMap.radioSettingsMap[setting] !== undefined) {
                    _process(setting, initialValue, radioSettingsModel, settingsMap.radioSettingsMap, disabled);
                } else if (settingsMap.videoSettingsMap[setting] !== undefined) {
                    _process(setting, initialValue, videoSettingsModel, settingsMap.videoSettingsMap, disabled);
                } else if (settingsMap.rcSettingsMap[setting] !== undefined) {
                    _process(setting, initialValue, rcSettingsModel, settingsMap.rcSettingsMap, disabled);
                } else if (settingsMap.hotspotSettingsMap[setting] !== undefined) {
                    _process(setting, initialValue, hotspotSettingsModel, settingsMap.hotspotSettingsMap, disabled);
                } else if (settingsMap.smartSyncSettingsMap[setting] !== undefined) {
                    _process(setting, initialValue, smartSyncSettingsModel, settingsMap.smartSyncSettingsMap, disabled);
                } else {
                    // setting not found in any mapping so add it to the "other" tab as-is, no processing
                    // of any kind. This guarantees that newly added settings are never missing from the app.
                    otherSettingsModel.append({"title": setting,
                                               "setting": setting,
                                               "itemType": "string",
                                               "value": String(openHDSettings.allSettings[setting]),
                                               "disabled": disabled,
                                               "info": "No additional information available, check the Open.HD wiki"});
                }
            }
        }
    }

    function writeRemoteSettings() {
        var remoteSettings = {};

        function _process(model, mapping) {
            for(var index = 0; index < model.count; index++) {
                var setting = model.get(index);
                var modified = setting["modified"];
                // skip saving any settings the user hasn't actually changed
                if (!modified) {
                    continue;
                }
                var key = setting["setting"];
                var initialValue = setting["value"];
                // by default we pass through the value as-is, only map to another type if needed
                var finalValue = initialValue;

                // map bool values back to their expected representation for each setting, because
                // it's not the same for all of them
                if (mapping !== undefined && mapping[setting.setting] !== undefined) {
                    var itemType   = mapping[setting.setting]["itemType"];
                    var trueValue  = mapping[setting.setting]["trueValue"];
                    var falseValue = mapping[setting.setting]["falseValue"];

                    if (itemType === "bool") {
                        if (initialValue) {
                            finalValue = trueValue;
                        } else {
                            finalValue = falseValue;
                        }
                    }
                }
                remoteSettings[key] = finalValue;
            }
        }
        _process(generalSettingsModel,   settingsMap.generalSettingsMap);
        _process(radioSettingsModel,     settingsMap.radioSettingsMap);
        _process(videoSettingsModel,     settingsMap.videoSettingsMap);
        _process(rcSettingsModel,        settingsMap.rcSettingsMap);
        _process(hotspotSettingsModel,   settingsMap.hotspotSettingsMap);
        _process(smartSyncSettingsModel, settingsMap.smartSyncSettingsMap);

        _process(otherSettingsModel, {});

        // don't save back settings until the values and mappings are all tested properly
        openHDSettings.saveSettings(remoteSettings);
    }

    function openSettings() {
        openHDSettings.fetchSettings();
        settings_panel.settings_popup.open();
    }

    rebootButton.onClicked: {
        settings_popup.close();
        rebootDialog.open()
    }

    closeButton.onClicked: {
        settings_popup.close();
    }

    save.onClicked: {
        writeRemoteSettings();
    }


    MessageDialog {
        id: rebootDialog
        title: qsTr("Reboot ground station?")
        text: qsTr("This will immediately reboot the ground station!\n\nIf your drone is armed it may crash or enter failsafe mode.\n\nYou have been warned.")
        icon: StandardIcon.Warning
        standardButtons: StandardButton.Yes | StandardButton.Cancel
        onYes: {
            openHDSettings.reboot();
            localMessage("Rebooting...", 3);
            rebootDialog.close()
        }
        onRejected: {
             rebootDialog.close()
        }

        Component.onCompleted: visible = false
    }
}

