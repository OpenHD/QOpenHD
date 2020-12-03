import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

ListView {
    id: groundListView
    clip: true
    enabled: !openHDSettings.busy

    /* this little hack is necessary because inside the delegate's context, "model" means the
       individual item in the list rather than the entire ListModel, which the delegate needs
       access to in order to set changed values in reaction to UI events */
    property var currentModel: model

    delegate: Loader {
        width: groundListView.width
        property var listModel: currentModel
        property var itemModel: model
        /*property var choiceValues: model.choiceValues
          property var value: model.value*/
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

    property int tempContentY: 0
    property int ySizeFactor: 18

    onAtYBeginningChanged: {
        if (atYBeginning) {
            tempContentY = contentY
        }
    }

    // if tempContentY - contentY > 10*ySizeFactor refresh news
    onContentYChanged: {
        if (atYBeginning) {
            if (Math.abs(tempContentY - contentY) > 10 * ySizeFactor) {
                if (busyIndicator.running) {
                    return;
                } else {
                    openHDSettings.fetchSettings();
                }
            }
        }
    }

}
