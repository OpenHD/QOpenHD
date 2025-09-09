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
        startButton.focus=true;
    }

    ColumnLayout{
        anchors.top: parent.top
        anchors.topMargin: secondaryUiHeight/8
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10

        ComboBox{
            id: comboBoxWhichFrequencyToScan
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.preferredWidth: 250
            model: ListModel {
                ListElement { title: "OpenHD [1-7] only" }
                ListElement { title: "All 2.4G channels" }
                ListElement { title: "All 5.8G channels" }
            }
            textRole: "title"
            enabled: _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode==0
            hoverEnabled: true
            background: Rectangle {
                color: comboBoxWhichFrequencyToScan.focus ? highlightColor : "#333c4c"
                border.color: "white"
                border.width: comboBoxWhichFrequencyToScan.focus ? 3 : 0
                opacity: comboBoxWhichFrequencyToScan.focus ? 1.0 : 0.3
            }
            Keys.onPressed: (event)=> {
                if(event.key===Qt.Key_Left){
                    sidebar.regain_control_on_sidebar_stack();
                    event.accepted=true;
                }else if(event.key===Qt.Key_Down){
                    if(!comboBoxWhichFrequencyToScan.popup.visible){
                        startButton.focus=true;
                    }else{
                        comboBoxWhichFrequencyToScan.currentIndex = Math.min(
                                    comboBoxWhichFrequencyToScan.count - 1,
                                    comboBoxWhichFrequencyToScan.currentIndex + 1);
                    }
                    event.accepted=true;
                }else if(event.key===Qt.Key_Up){
                    if(!comboBoxWhichFrequencyToScan.popup.visible)
                        comboBoxWhichFrequencyToScan.popup.open();
                    comboBoxWhichFrequencyToScan.currentIndex = Math.max(
                                0, comboBoxWhichFrequencyToScan.currentIndex - 1);
                    event.accepted=true;
                }else if(event.key===Qt.Key_Enter || event.key===Qt.Key_Return){
                    if(comboBoxWhichFrequencyToScan.popup.visible){
                        comboBoxWhichFrequencyToScan.popup.close();
                    }else{
                        comboBoxWhichFrequencyToScan.popup.open();
                    }
                    event.accepted=true;
                }
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
                color: startButton.focus ? highlightColor : "#333c4c"
                border.color: "white"
                border.width: startButton.focus ? 3 : 0
                opacity: startButton.focus ? 1.0 : 0.3
            }
            function startScan(){
                var how_many_freq_bands = comboBoxWhichFrequencyToScan.currentIndex;
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
                if(event.key===Qt.Key_Left){
                    sidebar.regain_control_on_sidebar_stack();
                    event.accepted=true;
                }else if(event.key===Qt.Key_Up){
                    comboBoxWhichFrequencyToScan.focus=true;
                    event.accepted=true;
                }else if(event.key===Qt.Key_Enter || event.key===Qt.Key_Return){
                    startScan();
                    event.accepted=true;
                }
            }
        }

        SimpleProgressBar{
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.preferredWidth: 250
            Layout.preferredHeight: 30
            impl_curr_progress_perc: _wbLinkSettingsHelper.scan_progress_perc
            impl_show_progress_text: true
        }

        Item{
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
