import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12

MapWidgetForm {

    function configure() {
        console.log("MapWidget.configure()");
        settings.sync();
        mapWidget.visible = settings.value("show_map", true);
    }

}
