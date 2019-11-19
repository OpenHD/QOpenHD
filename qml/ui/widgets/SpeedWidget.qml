import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12

SpeedWidgetForm {

    function configure() {
        console.log("SpeedWidget.configure()");
        settings.sync();
        speedWidget.visible = settings.value("show_speed", true);
    }

}
