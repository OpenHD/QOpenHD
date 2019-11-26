import QtQuick 2.12

SlideSwitchForm {
    signal trigger()

    function reset() {
        triggered = false;
    }

    dropArea.onEntered: {
        triggered = true;
        trigger();
    }
}

