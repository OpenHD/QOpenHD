import QtQuick 2.13
import QtQuick.Window 2.13
import QtQuick.Layouts 1.13

MapWidgetForm {

    function configure() {
        console.log("MapWidget.configure()");
        settings.sync();
        mapWidget.visible = settings.value("show_map", true);
    }

}
