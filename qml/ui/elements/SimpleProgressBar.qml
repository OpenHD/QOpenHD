import QtQuick 2.12

Item {

    // Intended to be overridden
    // Progress in [0..100]
    property double impl_curr_progress_perc: 0
    // Color of the bar
    property color impl_curr_color: "#39a2f7"

    property bool impl_show_progress_text: false

    Rectangle{
        id: progress_background
        color: impl_curr_color
        opacity: 0.5
        width: parent.width
        height: parent.height

        anchors.leftMargin: 10
        anchors.rightMargin: 10

    }

    Text{
        width: parent.width
        height: parent.height
        verticalAlignment: Qt.AlignVCenter
        horizontalAlignment: Qt.AlignHCenter
        text: {
            var ret="PROGRESS";
            if(impl_curr_progress_perc>=0 && impl_curr_progress_perc<=100){
                ret += ": "+impl_curr_progress_perc+"%";
            }else{
                ret += "   ";
            }
            return ret;
        }
        color: "white"
        visible: impl_show_progress_text
    }

    Rectangle{
        id: progress_bar
        opacity: impl_show_progress_text ? 0.5 : 1.0
        width: progress_background.width * (impl_curr_progress_perc / 100.0)
        height: parent.height
        anchors.left: parent.left

        color: impl_curr_color
    }


}
