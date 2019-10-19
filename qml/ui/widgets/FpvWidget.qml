import QtQuick 2.13
import QtQuick.Window 2.13
import QtQuick.Layouts 1.13

FpvWidgetForm {

    function configure() {
        console.log("FpvWidget.configure()");
        settings.sync();
        fpvWidget.visible = settings.value("show_fpv", true);
    }

}
