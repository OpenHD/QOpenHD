import QtQuick 2.13
import QtQuick.Window 2.13
import QtQuick.Layouts 1.13

AltitudeWidgetForm {

    function configure() {
        console.log("AltitudeWidget.configure()");
        settings.sync();
        altitudeWidget.visible = settings.value("show_altitude", true);
    }

}
