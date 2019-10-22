import QtQuick 2.13
import QtQuick.Window 2.13
import QtQuick.Layouts 1.13

SpeedWidgetForm {

    function configure() {
        console.log("SpeedWidget.configure()");
        settings.sync();
        speedWidget.visible = settings.value("show_speed", true);
    }

}
