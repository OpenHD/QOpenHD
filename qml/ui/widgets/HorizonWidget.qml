import QtQuick 2.13
import QtQuick.Window 2.13
import QtQuick.Layouts 1.13

HorizonWidgetForm {

    function configure() {
        console.log("HorizonWidget.configure()");
        settings.sync();
        horizonWidget.visible = settings.value("show_horizon", true);
    }

}
