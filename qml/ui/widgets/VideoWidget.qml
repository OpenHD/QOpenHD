import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12

Loader {
    source: (EnableVideo && EnablePiP) ? "VideoWidgetForm.ui.qml" : ""
}
