import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12
import Qt.labs.settings 1.0

import OpenHD 1.0

// Contains the selector on the left and a stack view for the panels on the right
Rectangle {
    id: settings_form

    property int eeInt : 0

    function openSettings() {
        visible = true
        focus = true        
        sidebar.x = -1 //animation for sidebar
        if (settings.goggle_layout==true){
            mainStackLayout.visible=false
            mainStackLayout.currentIndex=1
        }
        else {
            mainStackLayout.visible=true
            mainStackLayout.currentIndex=0
        }
    }

    function closeSettings() {                       settings_form.visible=false
        sidebar.x = -300 //animation for sidebar
        if (settings.goggle_layout==true){ //reset stuff
            mainStackLayout.visible=false
            mainStackLayout.currentIndex=1
            sidebar.opacity=1
        }
        else {
            mainStackLayout.visible=true
            mainStackLayout.currentIndex=0
        }
    }

    function showAppSettings(i) {
        console.log("TEST show app settings:"+i);
    }

    anchors.fill: parent

    z: 4.0

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: false
    }
    Rectangle {
        id: spacerTopSpacer
        width: 132
        visible: true
        anchors.left: parent.left
        anchors.leftMargin: -1
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -1
        anchors.top: parent.top
        anchors.topMargin: -1
        color: "#fafafa"

        clip: true

        Column {
            width: parent.width
            anchors.top: parent.top
            // Close Button
            Item {
                height: 48
                width: parent.width

                Button{
                    id: closeButton
                    text: "\uf060"
                    font.family: "Font Awesome 5 Free"
                    font.pixelSize: 22
                    height: 35
                    width: 35
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    background: Rectangle {
                        opacity: .3
                        radius: 5
                        //later this can be changed to focus
                        color: closeButton.hovered ? "grey" : "white" // I update background color by this
                    }
                    onClicked: {
                        closeSettings();
                    }
                }
            }
        }
    }

    // This is the settings row on the left. When an item is clicked, the stack layout index is changed which
    // means a different category is displayed.
    // NOTE: when changing the n of elements in the panel, remember to change the indices
    Rectangle {
        id: sidebar
        width: 132
        visible: true
        //x:-300 //for animation
        //anchors.left: parent.left
        //anchors.leftMargin: -1
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -1
        anchors.top: parent.top
        anchors.topMargin: 48
        color: "#333c4c"
        border.width: 1
        border.color: "#4c000000"

        clip: true

        Behavior on x { //when settings are opened animation
            NumberAnimation {
                duration: 600
                easing.type: Easing.OutBack
            }
        }

        Behavior on opacity { //fade when menu is selected
            NumberAnimation {
                duration: 700
                easing.type: Easing.OutBack
            }
        }

        Column {
            width: parent.width
            anchors.top: parent.top

            // QOpenHD Settings - AppSettingsPanel
            Item {
                height: 48
                width: parent.width

                Button{
                    id: appSettingsBtn
                    height: parent.height
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        id: appIcon
                        text: "\uf013"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: "Font Awesome 5 Free"
                        font.pixelSize: 18
                        height: parent.height
                        width: 24
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        color: "#dde4ed"
                    }
                    Text {
                        id: appButton
                        text: qsTr("QOpenHD")
                        height: parent.height
                        anchors.left: appIcon.right
                        anchors.leftMargin: 6
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        color: mainStackLayout.currentIndex == 0 ? "#33aaff" :
                            mainStackLayout.currentIndex == 1 ? "#33aaff" : "#dde4ed"
                    }
                    background: Rectangle {
                        opacity: .3
                        radius: 5
                        color: appSettingsBtn.hovered ? "grey" : "transparent" // I update background color by this
                    }
                    onClicked: {
                        if (settings.goggle_layout==true){
                            mainStackLayout.currentIndex = 1
                            mainStackLayout.visible=true
                            sidebar.opacity = .5 //animation for sidebar fade
                            mainStackLayout.activeFocus
                            ggAppSettingsPanel.openAppMenu()
                        }
                        else{
                            mainStackLayout.currentIndex = 0
                       }
                    }
                }
            }

            // OpenHD Settings - MavlinkAllSettingsPanel
            Item {
                height: 48
                width: parent.width
                Button{
                    id: openhdSettingsBtn
                    height: parent.height
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        id: groundIcon
                        text: "\uf085"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: "Font Awesome 5 Free"
                        font.pixelSize: 18
                        height: parent.height
                        width: 24
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        color: "#dde4ed"
                    }
                    Text {
                        id: groundButton
                        text: qsTr("OpenHD")
                        height: parent.height
                        anchors.left: groundIcon.right
                        anchors.leftMargin: 6
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        color: mainStackLayout.currentIndex == 2 ? "#33aaff" : "#dde4ed"
                    }
                    background: Rectangle {
                        opacity: .3
                        radius: 5
                        color: openhdSettingsBtn.hovered ? "grey" : "transparent" // I update background color by this
                    }
                    onClicked: {
                        mainStackLayout.currentIndex = 2
                    }
                }
            }

            // Log
            Item {
                height: 48
                width: parent.width
                visible: true
                Button{
                    id: logBtn
                    height: parent.height
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        id: logIcon
                        text: "\uf0c9"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: "Font Awesome 5 Free"
                        font.pixelSize: 18
                        height: parent.height
                        width: 24
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        color: "#dde4ed"
                    }

                    Text {
                        id: logButton
                        text: qsTr("Log")
                        height: parent.height
                        anchors.left: logIcon.right
                        anchors.leftMargin: 6
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        color: mainStackLayout.currentIndex == 3 ? "#33aaff" : "#dde4ed"
                    }
                    background: Rectangle {
                        opacity: .3
                        radius: 5
                        color: logBtn.hovered ? "grey" : "transparent" // I update background color by this
                    }
                    onClicked: {
                        mainStackLayout.currentIndex = 3
                    }
                }
            }

            // Power
            Item {
                height: 48
                width: parent.width
                Button{
                    id: powerSettingsBtn
                    height: parent.height
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        id: powerIcon
                        text: "\uf011"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: "Font Awesome 5 Free"
                        font.pixelSize: 18
                        height: parent.height
                        width: 24
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        color: "#dde4ed"
                    }

                    Text {
                        id: powerButton
                        text: qsTr("Power")
                        height: parent.height
                        anchors.left: powerIcon.right
                        anchors.leftMargin: 6
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        color: mainStackLayout.currentIndex == 4 ? "#33aaff" : "#dde4ed"
                    }
                    background: Rectangle {
                        opacity: .3
                        radius: 5
                        color: powerSettingsBtn.hovered ? "grey" : "transparent" // I update background color by this
                    }
                    onClicked: {
                        mainStackLayout.currentIndex = 4
                    }
                }
            }

            // About
            Item {
                height: 48
                width: parent.width
                Button{
                    id: aboutBtn
                    height: parent.height
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        id: aboutIcon
                        text: "\uf05a"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: "Font Awesome 5 Free"
                        font.pixelSize: 18
                        height: parent.height
                        width: 24
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        color: "#dde4ed"
                    }

                    Text {
                        id: aboutButton
                        text: qsTr("About")
                        height: parent.height
                        anchors.left: aboutIcon.right
                        anchors.leftMargin: 6
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        color: mainStackLayout.currentIndex == 5 ? "#33aaff" : "#dde4ed"
                    }
                    background: Rectangle {
                        opacity: .3
                        radius: 5
                        color: aboutBtn.hovered ? "grey" : "transparent" // I update background color by this
                    }
                    onClicked: {
                        mainStackLayout.currentIndex = 5
                        if (eeInt > 8){
                            eeItem.visible = true
                            eeInt = 0
                        }else{
                            eeItem.visible = false
                            eeInt = eeInt+1
                        }
                    }
                }
            }

            // Developer stats
            Item {
                height: 48
                width: parent.width
                Button{
                    id: devStatsBtn
                    height: parent.height
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        id: developerStatsIcon
                        text: "\uf05a"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: "Font Awesome 5 Free"
                        font.pixelSize: 18
                        height: parent.height
                        width: 24
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        color: "#dde4ed"
                    }

                    Text {
                        id: developerStatsButton
                        text: qsTr("DEV")
                        height: parent.height
                        anchors.left: developerStatsIcon.right
                        anchors.leftMargin: 6
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        color: mainStackLayout.currentIndex == 5 ? "#33aaff" : "#dde4ed"
                    }
                    background: Rectangle {
                        opacity: .3
                        radius: 5
                        color: devStatsBtn.hovered ? "grey" : "transparent" // I update background color by this
                    }
                    onClicked: {
                        mainStackLayout.currentIndex = 5
                    }
                }
            }

            // RC
            Item {
                height: 48
                width: parent.width
                Button{
                    id: rcSettingsBtn
                    height: parent.height
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        id: rcIcon
                        text: "\uf05a"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: "Font Awesome 5 Free"
                        font.pixelSize: 18
                        height: parent.height
                        width: 24
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        color: "#dde4ed"
                    }

                    Text {
                        id: rcButton
                        text: qsTr("RC")
                        height: parent.height
                        anchors.left: rcIcon.right
                        anchors.leftMargin: 6
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        color: mainStackLayout.currentIndex == 6 ? "#33aaff" : "#dde4ed"
                    }
                    background: Rectangle {
                        opacity: .3
                        radius: 5
                        color: rcSettingsBtn.hovered ? "grey" : "transparent" // I update background color by this
                    }
                    onClicked: {
                        mainStackLayout.currentIndex = 7
                    }
                }
            }

            Item {
                id: eeItem
                visible: false
                height: 48
                width: parent.width
                Button{
                    id: eeBtn

                    height: parent.height
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        id: eeIcon
                        text: "\uf05a"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: "Font Awesome 5 Free"
                        font.pixelSize: 18
                        height: parent.height
                        width: 24
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        color: "#dde4ed"
                    }

                    Text {
                        id: eeButton
                        height: parent.height
                        anchors.left: eeIcon.right
                        anchors.leftMargin: 6

                        text: qsTr("EasterEgg")
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        color: mainStackLayout.currentIndex == 7 ? "#33aaff" : "#dde4ed"
                    }
                    background: Rectangle {
                        opacity: .3
                        radius: 5
                        //later this can be changed to focus
                        color: eeBtn.hovered ? "grey" : "transparent" // I update background color by this
                    }
                    onClicked: {
                        mainStackLayout.currentIndex = 7
                    }
                }
            }
        }
    }


    StackLayout {
        id: mainStackLayout
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: settings.goggle_layout ? sidebar.left : sidebar.right
        anchors.leftMargin: settings.goggle_layout ? 50 : -1
        anchors.topMargin: settings.goggle_layout ? 48 : 0
        anchors.top: parent.top

        AppSettingsPanel {
            id: appSettingsPanel
        }

        GgAppSettingsPanel {
            id: ggAppSettingsPanel
        }

        MavlinkAllSettingsPanel {
            id:  mavlinkAllSettingsPanel //this is "openhd" menu
        }

        LogMessagesStatusView{
            id: logMessagesStatusView
        }

        PowerPanel {
            id: powerPanel
        }

        AboutPanel {
            id: aboutPanel
        }

        AppDeveloperStatsPanel {
            id: appDeveloperStatsPanel
        }

        RcInfoPanel {
            id: rcInfoPanel
        }

        EasterEggPanel {
            id: eePanel
        }
    }
}

