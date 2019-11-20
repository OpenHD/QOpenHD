import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12

HeadingWidgetForm {

    function configure() {
        console.log("HeadingWidget.configure()");
        headingWidget.visible = settings.value("show_heading", true);
    }

}
