import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12

AltitudeWidgetForm {

    function configure() {
        console.log("AltitudeWidget.configure()");
        altitudeWidget.visible = settings.value("show_altitude", true);
    }

}
