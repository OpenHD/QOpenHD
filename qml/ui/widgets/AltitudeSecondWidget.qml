import QtQuick 2.13
import QtQuick.Window 2.13
import QtQuick.Layouts 1.13

AltitudeSecondWidgetForm {

    function configure() {
        console.log("AltitudeSecondWidget.configure()");
        settings.sync();
        altitudesecondWidget.visible = settings.value("show_second_alt", true);
    }

}
