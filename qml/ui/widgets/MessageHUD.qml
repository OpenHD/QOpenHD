import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import Qt.labs.settings 1.0

MessageHUDForm {


    /*Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            // Something something stephen legacy UI
            // console.log("Timer message hud")
            // DIRTY
            //
            //Resize the list view to fit the number of messages on-screen, this ensures that
            //if there is only one message it will appear to "hug" the bottom bar rather than float
            //in the middle of the screen
            //
            var n_elements=_hudLogMessagesModel.rowCount();
            messageListView.contentHeight = 24 * n_elements;
            messageListView.height = 24 * n_elements;
            messageWidget.height = 24 * n_elements;

        }
    }*/
}
