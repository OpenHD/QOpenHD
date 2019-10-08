import QtQuick 2.13
import QtQuick.Window 2.13
import QtQuick.Layouts 1.13
import Qt.labs.settings 1.0

LowerOverlayBarForm {
    id: lowerOverlayBar

    function configure() {
        console.log("LowerOverlayBar.configure()");
        home_distance.visible = settings.value("show_home_distance", true);
        flight_timer.visible = settings.value("show_flight_timer", true)
        flight_mode.visible = settings.value("show_flight_mode", true)
        air_battery.visible = settings.value("show_air_battery", true)
        gps.visible = settings.value("show_gps", true)
    }

}
