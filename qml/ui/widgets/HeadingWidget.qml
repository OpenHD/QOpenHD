import QtQuick 2.13
import QtQuick.Window 2.13
import QtQuick.Layouts 1.13

HeadingWidgetForm {

    function configure() {
        console.log("HeadingWidget.configure()");
        settings.sync();
        headingWidget.visible = settings.value("show_heading", true);
    }

}
