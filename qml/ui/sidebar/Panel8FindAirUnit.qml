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
        startButtonNextLeftExits=false;
    }

    // Tracks whether the next left key from startButton should exit back to the sidebar
    property bool startButtonNextLeftExits: false

    ColumnLayout{
        anchors.top: parent.top
        anchors.topMargin: secondaryUiHeight/8
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 5

        RowLayout{
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Button{
                id: startButton
                text: "START"
                enabled: _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode==0
                onClicked: {
                    var how_many_freq_bands = comboBoxWhichFrequencyToScan.currentIndex;
                    var how_many_bandwidths = 2;
                    var result = _wbLinkSettingsHelper.start_scan_channels(how_many_freq_bands, how_many_bandwidths);
                    if(result){
                        _qopenhd.show_toast("Channel scan started, please wait", true);
                    }else{
                        _qopenhd.show_toast("Busy,please try again later", true);
                    }
                }
                Keys.onPressed: (event)=> {
                    if(event.key===Qt.Key_Left){
                        if(startButtonNextLeftExits){
                            sidebar.regain_control_on_sidebar_stack();
                        }else{
                            comboBoxWhichFrequencyToScan.focus=true;
                        }
                        event.accepted=true;
                    }
                }
            }

            ComboBox{
                id: comboBoxWhichFrequencyToScan
                Layout.preferredWidth: 200
                model: ListModel {
                    ListElement { title: "OpenHD [1-7] only" }
                    ListElement { title: "All 2.4G channels" }
                    ListElement { title: "All 5.8G channels" }
                }
                textRole: "title"
                enabled: _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode==0
                Keys.onPressed: (event)=> {
                    if(event.key===Qt.Key_Left){
                        startButton.focus=true;
                        startButtonNextLeftExits=true;
                        event.accepted=true;
                    }else if(event.key===Qt.Key_Up){
                        if(!comboBoxWhichFrequencyToScan.popup.visible)
                            comboBoxWhichFrequencyToScan.popup.open();
                        comboBoxWhichFrequencyToScan.currentIndex = Math.max(
                                    0, comboBoxWhichFrequencyToScan.currentIndex - 1);
        
                        event.accepted=true;
                    }else if(event.key===Qt.Key_Down){
                        if(!comboBoxWhichFrequencyToScan.popup.visible)
                            comboBoxWhichFrequencyToScan.popup.open();
                        comboBoxWhichFrequencyToScan.currentIndex = Math.min(
                                    comboBoxWhichFrequencyToScan.count - 1,
                                    comboBoxWhichFrequencyToScan.currentIndex + 1);

                        event.accepted=true;
                    }else if(event.key===Qt.Key_Enter || event.key===Qt.Key_Return){
                        comboBoxWhichFrequencyToScan.popup.open();
                        event.accepted=true;
                    }
                }
            }
        }

        SimpleProgressBar{
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.preferredWidth: 250
            Layout.preferredHeight: 40
            impl_curr_progress_perc: _wbLinkSettingsHelper.scan_progress_perc
            impl_show_progress_text: true
        }

        Text{
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            text: _wbLinkSettingsHelper.scanning_text_for_ui
            font.pixelSize: 21
            color: "#fff"
        }

        Item{
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
