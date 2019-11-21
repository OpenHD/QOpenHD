import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12

HorizonWidgetForm {

    function configure() {
        horizonWidget.visible = settings.value("show_horizon", true);
    }

}
