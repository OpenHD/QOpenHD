import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12

AltitudeSecondWidgetForm {

    function configure() {
        altitudesecondWidget.visible = settings.value("show_second_alt", true);
    }

}
