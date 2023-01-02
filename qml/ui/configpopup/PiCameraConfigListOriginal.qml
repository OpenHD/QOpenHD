import QtQuick 2.15

ListModel {
    id:piCameraModel

    ListElement {
        name: "Camera V1"
        portrait: "../../resources/cameras/portrait.png"
        raspOverlay:"test0"

    }
    ListElement {
        name: "Camera V2"
        portrait: "../../resources/cameras/portrait.png"
        raspOverlay:"test1"

    }
    ListElement {
        name: "HQ Camera"
        portrait: "../../resources/cameras/portrait.png"
        raspOverlay:"test2"

    }
    ListElement {
        name: "other"
        portrait: "../../resources/cameras/portrait.png"
        raspOverlay:"test3"

    }

}