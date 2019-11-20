import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import Qt.labs.settings 1.0

MessageHUDForm {
    /*
     *
     * List of messages that should be on screen right now, periodically maintained by a timer
     *
     */
    ListModel {
        id: messageModel
    }

    /*
     *
     * Maximum number of messages that can be on screen at once. If another message comes in
     * while the list is full, the oldest will disapper regardless of how old it is.
     *
     */
    property var maxMessageCount: 3

    function pushMessage(message, level, timeout) {
        // pop extra messages off at the zero index to cause the others to shift upward on-screen
        while (messageModel.count >= maxMessageCount) {
            messageModel.remove(0);
        }
        // add to the end of the list so this message appears at the bottom on-screen
        messageModel.append({text: message, level: level, timeout: 1.0})

        /*
         * Resize the list view to fit the number of messages on-screen, this ensures that
         * if there is only one message it will appear to "hug" the bottom bar rather than float
         * in the middle of the screen
         */
        messageListView.contentHeight = 24 * messageModel.count;
        messageListView.height = 24 * messageModel.count;
        messageWidget.height = 24 * messageModel.count;
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            for (var i = 0; i < messageModel.count; i++) {
                var message = messageModel.get(i);
                /*
                 * Remove expired messages, currently a 10 second limit because we start at
                 * 1.0 and subtract 0.1 every second (a few lines down from here)
                 *
                 */
                if (message.timeout <= 0.0) {
                    messageModel.remove(i);
                    continue;
                }
                /*
                 * This might be a race condition, pushMessage() can be triggered by a background
                 * thread at any time
                 *
                 */
                messageModel.set(i, {text: message.text, level: message.level, timeout: message.timeout - 0.1});
            }
            messageListView.contentHeight = 24 * messageModel.count;
            messageListView.height = 24 * messageModel.count;
            messageWidget.height = 24 * messageModel.count;
        }
    }

    function configure() {
        console.log("MessageHUD.configure()");
        messageHUD.visible = settings.value("show_log_onscreen", true);
    }
}
