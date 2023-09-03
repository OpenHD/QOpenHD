import QtQuick 2.12

Item {

    // Intended to be overridden
    // Progress in [0..100]
    property double impl_curr_progress_perc: 0
    // Color of the bar
    property color impl_curr_color: "blue"

    Rectangle{
        id: progress_background
        color: impl_curr_color
        opacity: 0.5
        width: parent.width
        height: parent.height

        anchors.leftMargin: 10
        anchors.rightMargin: 10

    }

    Rectangle{
        id: progress_bar
        opacity: 1.0
        width: progress_background.width * (impl_curr_progress_perc / 100.0)
        height: parent.height
        anchors.left: parent.left

        color: impl_curr_color

    }
}
