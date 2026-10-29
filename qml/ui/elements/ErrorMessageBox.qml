import QtQuick 2.12

MessagePopup {
    title: qsTr("Error")
    message: _qopenhd.error_message_text
    visible: message !== ""
    function acknowledge() {
        _qopenhd.show_error_message("")
        if (typeof hudOverlayGrid !== "undefined") hudOverlayGrid.regain_focus()
    }
    onAccepted: acknowledge()
    onRejected: acknowledge()
}
