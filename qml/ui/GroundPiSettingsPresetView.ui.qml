import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

ScrollView {
    id: presetScrollView
    contentHeight: presetColumn.height
    enabled: !openHDSettings.busy
    clip: true

    property int currentSelectedPreset: 0

    PresetMap {
        id: presetMap
    }

    function loadPresetDetails() {
        console.log("loadPresetDetails");
        pendingPreset = ({})
        var selected = presetMap.presetSettingsMap[currentSelectedPreset];
        presetDescription.text = selected.info;

        var settingList = "";

        for (var setting in selected.settings) {
            var settingKey = selected.settings[setting].setting
            var value = selected.settings[setting].value;

            pendingPreset[settingKey] = value;

            settingList = settingList + settingKey + " = " + value + '\n';
        }
        changesText.text = settingList;
    }

    Column {
        id: presetColumn
        spacing: 24
        width: parent.width
        leftPadding: 24
        rightPadding: 24
        topPadding: 48
        bottomPadding: 12

        Text {
            text: qsTr("Presets are groups of settings that must be configured together for some OpenHD features and to make common configurations easier to use. Once you apply a preset, the ground station will reboot and enter SmartSync mode automatically, then power on your drone to let it sync the new settings.");
            wrapMode: Text.WordWrap
            width: parent.width - 48
            font.pixelSize: 14
        }

        Text {
            text: qsTr("Note: you can apply more than one preset, but any settings that are mutually exclusive (band switcher + 2nd camera at the same time), the last preset to be configured \"wins\"");
            wrapMode: Text.WordWrap
            width: parent.width - 48
            font.pixelSize: 14
        }

        Row {

            spacing: 24

            ComboBox {
                id: presetBox
                textRole: "title"
                model: presetMap.presetSettingsMap
                width: presetColumn.width - 48
                height: 40
                font.pixelSize: 14

                // @disable-check M223
                Component.onCompleted: {
                    currentSelectedPreset = currentIndex;
                    // @disable-check M222
                    loadPresetDetails();
                }

                // @disable-check M223
                onActivated: {
                    currentSelectedPreset = currentIndex;
                    // @disable-check M222
                    loadPresetDetails();
                }
            }
        }


        Text {
            id: presetDescription
            wrapMode: Text.WordWrap
            width: parent.width - 48
            font.pixelSize: 14
        }

        Text {
            id: changesTitle
            text: qsTr("Changes that will be applied:")
            font.pixelSize: 14
        }

        Rectangle {
            id: changes
            width: parent.width - 48
            height: 160
            border.color: "black"
            border.width: 1
            clip: true

            ScrollView {
                id: changesView
                width: changes.width
                height: changes.height
                clip: true

                Text {
                    id: changesText
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    padding: 12
                    font.pixelSize: 12
                }
            }
        }
    }
}
