import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12

FpvWidgetForm {

    function configure() {
        fpvWidget.visible = settings.value("show_fpv", true);
    }

}
