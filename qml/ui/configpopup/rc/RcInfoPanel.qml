import QtQuick 2.12
import ".."

AdvancedPage {
    pageIcon: "\uf11b"
    pageTitle: qsTr("RC CONTROL")
    function gainFocus() { channels.gainFocus() }
    onBackRequested: settings_form.side_bar_regain_focus()

    RcDebugScreenFC {
        id: channels
        anchors.fill: parent
        onBackRequested: settings_form.side_bar_regain_focus()
    }
}
