import QtQuick 2.12
import QtQuick.Window 2.12
import com.luke 1.0

Window {
    property int enumValue: MySharedEnum.Value6

    visible: true
    x: settings.appX
    y: settings.appY
    width: settings.appWidth
    height: settings.appHeight
    title: qsTr("Hello World")

    Component.onCompleted: {
        console.log("Enum value:", enumValue)
    }

    Connections {
        target: settings
        onAppWidthChanged:
            console.log("App width saved:", settings.appWidth)
        onAppHeightChanged:
            console.log("App width saved:", settings.appHeight)
    }

    Binding { target: settings; property: "appWidth"; value: width }
    Binding { target: settings; property: "appHeight"; value: height }
    Binding { target: settings; property: "appX"; value: x }
    Binding { target: settings; property: "appY"; value: y }
}
