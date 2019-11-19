import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12

ArrowWidgetForm {

    function configure() {
        console.log("ArrowWidget.configure()");
        settings.sync();
        arrowWidget.visible = settings.value("show_arrow", true);
    }

}
