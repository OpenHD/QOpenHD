import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12

SpeedWidgetForm {

    function configure() {
        speedWidget.visible = settings.value("show_speed", true);
    }

}
