import QtQuick 2.13
import Qt.labs.settings 1.0

import OpenHD 1.0


UpperOverlayBarForm {
    id: upperOverlayBar
    signal settingsButtonClicked();

    settingsButtonMouseArea.onClicked: {
        upperOverlayBar.settingsButtonClicked();
    }

    function configure() {
        console.log("UpperOverlayBar.configure()");
        settings.sync();
        downlink.visible = settings.value("show_downlink_rssi", true);
        uplink.visible = settings.value("show_uplink_rssi", true);
        bitrate.visible = settings.value("show_bitrate", true);
        ground_status.visible = settings.value("show_ground_status", true);
        air_status.visible = settings.value("show_air_status", true);
    }
}
