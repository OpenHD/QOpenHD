import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12

Loader {
    property string elementName
    source: (EnableVideo && EnablePiP) ? "VideoWidgetForm.ui.qml" : ""
}
