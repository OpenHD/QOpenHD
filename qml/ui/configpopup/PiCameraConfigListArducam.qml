import QtQuick 2.15

ListModel {

    ListElement {
        name: "IMX477(und mini)"
        portrait: "../../resources/cameras/ArduIMX477.png"
        raspOverlay: "libcamera_imx477"
    }
    ListElement {
        name: "LowLight"
        portrait: "../../resources/cameras/ArduIMX462.png"
        raspOverlay: "libcamera_arducam"
    }
    ListElement {
        name: "IMX519"
        portrait: "../../resources/cameras/ArduIMX519.png"
        raspOverlay: "libcamera_imx519"
    }

}
