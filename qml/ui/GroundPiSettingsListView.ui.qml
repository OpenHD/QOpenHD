import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

import Qt.labs.settings 1.0

import OpenHD 1.0

ListView {
    clip: true
    enabled: !openHDSettings.busy
    Layout.fillWidth: true


    // this little hack is necessary because inside the delegate's context, "model" means the
    // individual item in the list rather than the entire ListModel, which the delegate needs
    // access to in order to set changed values in reaction to UI events
    property var currentModel: model

    delegate: Loader {
        anchors.left: parent.left
        anchors.right: parent.right

        property var listModel: currentModel
        property var itemModel: model
        //property var choiceValues: model.choiceValues
        //property var value: model.value
        property var index: model.index
        // @disable-check M223
        source: {
            switch (itemType) {
                case "bool":
                    return "delegates/SwitchSettingDelegate.ui.qml"
                case "text":
                    return "delegates/TextSettingDelegate.ui.qml"
                case "range":
                    return "delegates/RangeSettingDelegate.ui.qml"
                case "number":
                    return "delegates/NumberSettingDelegate.ui.qml"
                case "choice":
                    return "delegates/ChoiceSettingDelegate.ui.qml"
                default:
                    return "delegates/TextSettingDelegate.ui.qml"
            }
        }
    }
}
