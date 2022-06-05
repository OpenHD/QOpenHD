import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

Item {
    Layout.fillHeight: true
    Layout.fillWidth: true

    Loader {
        z: 1.0
        anchors {
            top: parent.top
            topMargin: 0
            left: parent.left
            leftMargin: 0
            right: parent.right
            rightMargin: 0
            bottom: parent.bottom
            bottomMargin: 12
        }

        //source: EnableCharts ? "./elements/StatusChart.qml" : ""
        source: "./elements/StatusChart.qml";
    }
}
