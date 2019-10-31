import QtQuick 2.13
import QtQuick.Window 2.13
import QtQuick.Layouts 1.13

ArrowWidgetForm {

    function configure() {
        console.log("ArrowWidget.configure()");
        settings.sync();
        arrowWidget.visible = settings.value("show_arrow", true);
    }

}
