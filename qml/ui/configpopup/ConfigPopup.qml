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
    // size of the elements in the left bar - e.g. what allows switching between all the tabs
    property int left_sidebar_elements_height: 46

    function openSettings() {
        visible = true
        focus = true
    }

    function close_all(){
        visible = false;
        focus=false;
    }

    function showAppSettings(i) {
        console.log("TEST show app settings:"+i);
    }

    //anchors.fill: parent
    width: parent.width * settings.screen_settings_overlay_size_percent / 100;
    height: parent.height * settings.screen_settings_overlay_size_percent / 100;

    z: 4.0

    color: "transparent"


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

            // Close
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
                        opacity: .5
                        radius: 5
                        //later this can be changed to focus
                        color: closeButton.hovered ? "grey" : "white" // I update background color by this
                    }
                    onClicked: {
                        settings_form.visible=false
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
        anchors.left: parent.left
        anchors.leftMargin: -1
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -1
        anchors.top: parent.top
        anchors.topMargin: 48
        color: "#333c4c"
        radius: 0
        border.width: 1
        border.color: "#4c000000"

        clip: true

        Column {
            width: parent.width
            anchors.top: parent.top

            // We only need the connect panel on android (external device)
            // On localhost, QOpenHD "automatically" connects due to udp localhost method
            Item {
                height: left_sidebar_elements_height
                width: parent.width
                // only show on android to not confuse users
                visible: _qopenhd.is_android() || true
                Button{
                    id: connectB
                    height: parent.height
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        id: connectIcon
                        text: "\uf6ff"
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
                        id: connectBX
                        text: qsTr("Connect")
                        height: parent.height
                        anchors.left: connectIcon.right
                        anchors.leftMargin: 6
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        color: mainStackLayout.currentIndex == 7 ? "#33aaff" : "#dde4ed"
                    }
                    background: Rectangle {
                        opacity: .5
                        radius: 5
                        //later this can be changed to focus
                        color: connectB.hovered ? "grey" : "transparent" // I update background color by this
                    }
                    onClicked: {
                        mainStackLayout.currentIndex = 0
                    }
                }
            }

            // QOpenHD Settings - AppSettingsPanel
            Item {
                height: left_sidebar_elements_height
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
                        color: mainStackLayout.currentIndex == 0 ? "#33aaff" : "#dde4ed"
                    }
                    background: Rectangle {
                        opacity: .5
                        radius: 5
                        //later this can be changed to focus
                        color: appSettingsBtn.hovered ? "grey" : "transparent" // I update background color by this
                    }
                    onClicked: {
                        mainStackLayout.currentIndex = 1
                    }
                }
            }

            // OpenHD Settings - MavlinkAllSettingsPanel
            Item {
                height: left_sidebar_elements_height
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
                        color: mainStackLayout.currentIndex == 1 ? "#33aaff" : "#dde4ed"
                    }
                    background: Rectangle {
                        opacity: .5
                        radius: 5
                        //later this can be changed to focus
                        color: openhdSettingsBtn.hovered ? "grey" : "transparent" // I update background color by this
                    }
                    onClicked: {
                        mainStackLayout.currentIndex = 2
                    }
                }
            }

            // Log
            Item {
                height: left_sidebar_elements_height
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
                        color: mainStackLayout.currentIndex == 2 ? "#33aaff" : "#dde4ed"
                    }
                    background: Rectangle {
                        opacity: .5
                        radius: 5
                        //later this can be changed to focus
                        color: logBtn.hovered ? "grey" : "transparent" // I update background color by this
                    }
                    onClicked: {
                        mainStackLayout.currentIndex = 3
                    }
                }
            }

            // Power
            Item {
                height: left_sidebar_elements_height
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
                        color: mainStackLayout.currentIndex == 3 ? "#33aaff" : "#dde4ed"
                    }
                    background: Rectangle {
                        opacity: .5
                        radius: 5
                        //later this can be changed to focus
                        color: powerSettingsBtn.hovered ? "grey" : "transparent" // I update background color by this
                    }
                    onClicked: {
                        mainStackLayout.currentIndex = 4
                    }
                }
            }

            // About
            Item {
                height: left_sidebar_elements_height
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
                        color: mainStackLayout.currentIndex == 4 ? "#33aaff" : "#dde4ed"
                    }
                    background: Rectangle {
                        opacity: .5
                        radius: 5
                        //later this can be changed to focus
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

            // RC
            Item {
                height: left_sidebar_elements_height
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
                        color: mainStackLayout.currentIndex == 5 ? "#33aaff" : "#dde4ed"
                    }
                    background: Rectangle {
                        opacity: .5
                        radius: 5
                        //later this can be changed to focus
                        color: rcSettingsBtn.hovered ? "grey" : "transparent" // I update background color by this
                    }
                    onClicked: {
                        mainStackLayout.currentIndex = 6
                    }
                }
            }

            // FC Setup
            /*Item {
                id: fcSetup
                height: left_sidebar_elements_height
                width: parent.width
                Button{
                    id: fcSetupButton
                    height: parent.height
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        id: fcSetupIcon
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
                        id: fcSetupButtonText
                        text: qsTr("FC Setup")
                        height: parent.height
                        anchors.left: fcSetupIcon.right
                        anchors.leftMargin: 6
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        color: mainStackLayout.currentIndex == 6 ? "#33aaff" : "#dde4ed"
                    }
                    background: Rectangle {
                        opacity: .5
                        radius: 5
                        //later this can be changed to focus
                        color: fcSetupButton.hovered ? "grey" : "transparent" // I update background color by this
                    }
                    onClicked: {
                        mainStackLayout.currentIndex = 6
                    }
                }
            }*/



            // Developer stats
            Item {
                height: left_sidebar_elements_height
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
                        color: mainStackLayout.currentIndex == 6 ? "#33aaff" : "#dde4ed"
                    }
                    background: Rectangle {
                        opacity: .5
                        radius: 5
                        //later this can be changed to focus
                        color: devStatsBtn.hovered ? "grey" : "transparent" // I update background color by this
                    }
                    onClicked: {
                        mainStackLayout.currentIndex = 7
                    }
                }
            }


            Item {
                id: eeItem
                visible: false
                height: left_sidebar_elements_height
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
                        color: mainStackLayout.currentIndex == 8 ? "#33aaff" : "#dde4ed"
                    }
                    background: Rectangle {
                        opacity: .5
                        radius: 5
                        //later this can be changed to focus
                        color: eeBtn.hovered ? "grey" : "transparent" // I update background color by this
                    }
                    onClicked: {
                        mainStackLayout.currentIndex = 8
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
        anchors.left: sidebar.right
        anchors.leftMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0


        ConnectPanel{
            id: connectPanel
        }

        AppSettingsPanel {
            id: appSettingsPanel
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

        RcInfoPanel {
            id: rcInfoPanel
        }

        AppDeveloperStatsPanel {
            id: appDeveloperStatsPanel
        }

        EasterEggPanel {
            id: easterEgPanel
        }
    }
}

