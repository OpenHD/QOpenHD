import QtQuick 2.15

ListModel {

    ListElement {
        name: "CSI HDMI"
        portrait: "../../resources/cameras/otherHDMI.png"
        raspOverlay: "notImplementedYet"
    }
    ListElement {
        name: "Debug Camera"
        portrait: "../../resources/cameras/otherTest.png"
        raspOverlay: "notNeeded"
    }
    ListElement {
        name: "IP Camera"
        portrait: "../../resources/cameras/otherIP.png"
        raspOverlay: "notNeeded"
    }

}
