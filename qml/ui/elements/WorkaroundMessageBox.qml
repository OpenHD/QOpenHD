import QtQuick 2.12

MessagePopup {
    title: qsTr("QOpenHD") + (_messageBoxInstance.remaining_time_seconds < 0 ? "" : "   " + _messageBoxInstance.remaining_time_seconds + "s")
    message: _messageBoxInstance.text
    visible: _messageBoxInstance.visible
    showOkayButton: _messageBoxInstance.remaining_time_seconds < 0 || _messageBoxInstance.remaining_time_seconds > 1
    function acknowledge() {
        _messageBoxInstance.okay_button_clicked()
        if (typeof hudOverlayGrid !== "undefined") hudOverlayGrid.regain_focus()
    }
    onAccepted: acknowledge()
    onRejected: acknowledge()
}
