import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12
import Qt.labs.settings 1.0

import OpenHD 1.0

import "connect"
import "credits"
import "dev"
import "log"
import "qopenhd_settings"
import "openhd_settings"
import "rc"
import "status"

// Contains the selector on the left and a stack view for the panels on the right
Rectangle {
    id: settings_form

    // The connect is only needed when qopenhd is not running on the ground system itself (e.g. android)
    property bool m_show_connect_option: true // _qopenhd.is_android()

    // size of the elements in the left bar - e.g. what allows switching between all the tabs
    property int left_sidebar_elements_height: 46

    function openSettings() {
        settings_form.visible=true
        settings_form.focus=true;
        sidebar.focus=true
    }

    function close_all(){
        visible = false;
        focus=false;
        hudOverlayGrid.regain_focus();
    }

    function showAppSettings(i) {
        console.log("TEST show app settings:"+i);
    }

    function side_bar_regain_focus(){
        sidebar.focus = true;
    }

    /*Keys.onPressed: (event)=> {
        console.log("ConfigPopup Key was pressed:"+event);
        if (event.key == Qt.Key_Return) {
            console.log("enter was pressed");
            event.accepted = true;
            close_all()
            //hudOverlayGrid.settingsButtonClicked();
            //settingsButton.focus=false;
        }
    }*/

    //anchors.fill: parent
    width: parent.width * settings.screen_settings_overlay_size_percent / 100;
    height: parent.height * settings.screen_settings_overlay_size_percent / 100;

    z: 4.0

    color: "transparent"

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
                        close_all();
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

        Keys.onPressed: (event)=> {
                console.log("Sidebar Key was pressed:"+event);
                var tmp_index=mainStackLayout.currentIndex;
                if(event.key==Qt.Key_Up){
                    tmp_index--;
                    if(tmp_index<0)tmp_index=0;
                    mainStackLayout.currentIndex=tmp_index;
                }else if (event.key == Qt.Key_Down) {
                    console.log("Down arrow");
                    tmp_index++;
                    if(tmp_index>=mainStackLayout.count)tmp_index=0;
                    mainStackLayout.currentIndex=tmp_index;
                }else if(event.key == Qt.Key_Left){
                    close_all()
                }else if(event.key == Qt.Key_Right){
                    //mainStackLayout.childAt(mainStackLayout.currentIndex).focus=true
                    _qopenhd.show_toast("No joystick navigation for this panel");
                }
            }

        Column {
            width: parent.width

            anchors.top: parent.top

            // Status
            ConfigPopupSidebarButton{
                id:  power
                m_icon_text: "\uf21e" //"\uf011"
                m_description_text: "Status"
                m_selection_index: 0
            }

            // QOpenHD Settings - AppSettingsPanel
            ConfigPopupSidebarButton{
                id:  qopenhd_button
                m_icon_text: "\uf013"
                m_description_text: "QOpenHD"
                m_selection_index: 1
            }

            // OpenHD Settings - MavlinkAllSettingsPanel
            ConfigPopupSidebarButton{
                id:  openhd_button
                m_icon_text: "\uf085"
                m_description_text: "OpenHD"
                m_selection_index: 2
            }

            // Log
            ConfigPopupSidebarButton{
                id:  log_button
                m_icon_text: "\uf0c9"
                m_description_text: "Log"
                m_selection_index: 3
            }

            // RC
            ConfigPopupSidebarButton{
                id:  rc
                m_icon_text: "\uf11b"
                m_description_text: "RC"
                m_selection_index: 4
            }


            // Credits and copyright
            ConfigPopupSidebarButton{
                id:  credits
                m_icon_text: "\uf005"
                m_description_text: "Credits"
                m_selection_index: 5
            }

            // Developer stats
            ConfigPopupSidebarButton{
                id:  developerstats
                m_icon_text: "\uf0ad"
                m_description_text: "DEV"
                m_selection_index: 6
            }

            // We only need the connect panel on android (external device)
            // On localhost, QOpenHD "automatically" connects due to udp localhost method
            ConfigPopupSidebarButton{
                visible: m_show_connect_option
                id:  connect_button
                m_icon_text: "\uf6ff"
                m_description_text: "Connect"
                m_selection_index: 7
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

        // default index
        currentIndex: 0

        PanelStatus {
            id: statusPanel
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

        RcInfoPanel {
            id: rcInfoPanel
        }

        Credits {
            id: creditspanel
        }

        AppDeveloperStatsPanel {
            id: appDeveloperStatsPanel
        }
        ConnectPanel{
            id: connectPanel
        }
    }
}

