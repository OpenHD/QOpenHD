import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12
import Qt.labs.settings 1.0
import OpenHD 1.0
import "../elements"

SideBarBasePanel{
    override_title: "Find Air Unit"

    function takeover_control(){
        bandSelection.takeover_control();
    }

    ColumnLayout{
        anchors.top: parent.top
        anchors.topMargin: secondaryUiHeight/8
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 5

        ListModel{
            id: scanBandModel
            ListElement { title: "OpenHD [1-7] only" }
            ListElement { title: "All 2.4G channels" }
            ListElement { title: "All 5.8G channels" }
        }

        BaseJoyEditElement{
            id: bandSelection
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            m_title: "Channels"

            property int currentIndex: 0

            m_button_left_activated: currentIndex>0 && _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode==0
            m_button_right_activated: currentIndex<scanBandModel.count-1 && _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode==0

            m_displayed_value: scanBandModel.get(currentIndex).title

            onChoice_left: {
                if(currentIndex>0) currentIndex--;
            }
            onChoice_right: {
                if(currentIndex+1<scanBandModel.count) currentIndex++;
            }
            onGoto_previous: {
                sidebar.regain_control_on_sidebar_stack();
            }
            onGoto_next: {
                startButton.focus=true;
            }
        }

        Button{
            id: startButton
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.preferredWidth: 250
            text: "START SCAN"
            enabled: _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode==0
            hoverEnabled: true
            background: Rectangle {
                color: "#2196F3"
                border.color: "white"
                border.width: startButton.focus ? 3 : 0
                opacity: startButton.focus ? 1.0 : 0.8
            }
            function startScan(){
                var how_many_freq_bands = bandSelection.currentIndex;
                var how_many_bandwidths = 2;
                var result = _wbLinkSettingsHelper.start_scan_channels(how_many_freq_bands, how_many_bandwidths);
                if(result){
                    _qopenhd.show_toast("Channel scan started, please wait", true);
                }else{
                    _qopenhd.show_toast("Busy,please try again later", true);
                }
            }
            onClicked: startScan()
            Keys.onPressed: (event)=> {
                if(event.key===Qt.Key_Up){
                    bandSelection.takeover_control();
                    event.accepted=true;
                }else if(event.key===Qt.Key_Left){
                    sidebar.regain_control_on_sidebar_stack();
                    event.accepted=true;
                }else if(event.key===Qt.Key_Enter || event.key===Qt.Key_Return){
                    startScan();
                    event.accepted=true;
                }
            }
        }

        RowLayout{
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            spacing: 10
            ProgressBar{
                Layout.preferredWidth: 150
                value: _wbLinkSettingsHelper.scan_progress_perc/100.0
            }
            Text{
                text: "Progress: " + _wbLinkSettingsHelper.scan_progress_perc + "%"
                font.pixelSize: 21
                color: "#fff"
            }
        }

        Item{
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
