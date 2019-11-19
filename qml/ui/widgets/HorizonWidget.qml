import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12

HorizonWidgetForm {

    function configure() {
        console.log("HorizonWidget.configure()");
        settings.sync();
        horizonWidget.visible = settings.value("show_horizon", true);
    }

}
