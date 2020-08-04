import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12

RcRSSIWidgetForm {


    property double lastData: 0
    property int rssiValue: 0

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var currentTime = (new Date).getTime();
            if (currentTime - lastData > 3000) {
                rssiValue = 0
            }
        }
    }

    Connections {
        target: OpenHD
        function onRcRssiChanged() {
            lastData = (new Date).getTime();
            rssiValue = OpenHD.rcRssi
        }
    }
}
