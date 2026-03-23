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
        id: panelColumn
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 5

        ListModel{
            id: scanBandModel
        }
        ListModel{
            id: scanBandwidthModel
        }

        function rebuildBandModel(){
            scanBandModel.clear();
            scanBandModel.append({value: 0, verbose: "OpenHD [1-7]"});
            scanBandModel.append({value: 1, verbose: "2.4G"});
            scanBandModel.append({value: 2, verbose: "5.8G"});
        }

        function rebuildBandwidthModel(){
            scanBandwidthModel.clear();
            scanBandwidthModel.append({value: 10, verbose: "10 MHz"});
            scanBandwidthModel.append({value: 20, verbose: "20 MHz"});
            if(settings.dev_allow_40mhz){
                scanBandwidthModel.append({value: 40, verbose: "40 MHz"});
            }
        }

        function syncBandwidthIndex(){
            for(var i=0;i<scanBandwidthModel.count;i++){
                if(scanBandwidthModel.get(i).value===settings.scan_channel_width_mhz){
                    bandwidthSelection.currentIndex=i;
                    return;
                }
            }
            if(scanBandwidthModel.count>0){
                var defaultIndex=bandwidth_index_for_value(20);
                if(defaultIndex<0){
                    defaultIndex=0;
                }
                bandwidthSelection.currentIndex=defaultIndex;
                settings.scan_channel_width_mhz=scanBandwidthModel.get(defaultIndex).value;
            }
        }

        function bandwidth_index_for_value(value){
            for(var i=0;i<scanBandwidthModel.count;i++){
                if(scanBandwidthModel.get(i).value===value){
                    return i;
                }
            }
            return -1;
        }

        function syncBandIndex(){
            if(scanBandModel.count<=0){
                bandSelection.currentIndex=0;
                return;
            }
            if(bandSelection.currentIndex<0 || bandSelection.currentIndex>=scanBandModel.count){
                bandSelection.currentIndex=0;
            }
        }

        Component.onCompleted: {
            rebuildBandModel();
            rebuildBandwidthModel();
            syncBandIndex();
            syncBandwidthIndex();
        }

        BaseJoyEditElement2{
            id: bandSelection
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            m_title: "Channels"

            property int currentIndex: -1

            m_displayed_value: (scanBandModel.count>0 && currentIndex>=0 && currentIndex<scanBandModel.count)
                ? scanBandModel.get(currentIndex).verbose
                : "OpenHD [1-7]"

            Keys.onPressed: (event)=> {
                if(event.key===Qt.Key_Left){
                    sidebar.regain_control_on_sidebar_stack();
                    event.accepted=true;
                }else if(event.key===Qt.Key_Right || event.key===Qt.Key_Enter || event.key===Qt.Key_Return){
                    open_choices_menu(false);
                    event.accepted=true;
                }else if(event.key===Qt.Key_Up){
                    choiceSelector.discard_and_close();
                    sidebar.regain_control_on_sidebar_stack();
                    event.accepted=true;
                }else if(event.key===Qt.Key_Down){
                    choiceSelector.discard_and_close();
                    bandwidthSelection.takeover_control();
                    event.accepted=true;
                }
            }

            onBase_joy_edit_element_clicked: {
                if(choiceSelector.visible){
                    choiceSelector.close_choices();
                }else{
                    open_choices_menu(true);
                }
            }

            function open_choices_menu(clickable){
                var idx=currentIndex;
                if(idx<0 || idx>=scanBandModel.count){
                    idx=0;
                }
                choiceSelector.open_choices(scanBandModel, scanBandModel.get(idx).value, bandSelection);
                choiceSelector.set_clickable(clickable);
            }

            function user_selected_value(value_new){
                currentIndex=parseInt(value_new);
            }
        }

        BaseJoyEditElement2{
            id: bandwidthSelection
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            m_title: "Bandwidth"

            property int currentIndex: 0

            m_displayed_value: (scanBandwidthModel.count>0 && currentIndex>=0 && currentIndex<scanBandwidthModel.count)
                ? scanBandwidthModel.get(currentIndex).verbose
                : "20 MHz"

            Keys.onPressed: (event)=> {
                if(event.key===Qt.Key_Left){
                    sidebar.regain_control_on_sidebar_stack();
                    event.accepted=true;
                }else if(event.key===Qt.Key_Right || event.key===Qt.Key_Enter || event.key===Qt.Key_Return){
                    open_choices_menu(false);
                    event.accepted=true;
                }else if(event.key===Qt.Key_Up){
                    choiceSelector.discard_and_close();
                    bandSelection.takeover_control();
                    event.accepted=true;
                }else if(event.key===Qt.Key_Down){
                    choiceSelector.discard_and_close();
                    startButton.focus=true;
                    event.accepted=true;
                }
            }

            onBase_joy_edit_element_clicked: {
                if(choiceSelector.visible){
                    choiceSelector.close_choices();
                }else{
                    open_choices_menu(true);
                }
            }

            function open_choices_menu(clickable){
                var idx=currentIndex;
                if(idx<0 || idx>=scanBandwidthModel.count){
                    idx=panelColumn.bandwidth_index_for_value(settings.scan_channel_width_mhz);
                    if(idx<0){
                        idx=0;
                    }
                }
                choiceSelector.open_choices(scanBandwidthModel, scanBandwidthModel.get(idx).value, bandwidthSelection);
                choiceSelector.set_clickable(clickable);
            }

            function user_selected_value(value_new){
                var value=parseInt(value_new);
                var idx=panelColumn.bandwidth_index_for_value(value);
                if(idx>=0){
                    currentIndex=idx;
                    settings.scan_channel_width_mhz = scanBandwidthModel.get(idx).value;
                }
            }
        }

Button {
    id: startButton
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    Layout.preferredWidth: 250
            text: qsTr("START SCAN")
    enabled: _ohdSystemGround.is_alive && _ohdSystemGround.wb_gnd_operating_mode==0
    hoverEnabled: true

    contentItem: Text {
        text: startButton.text
        color: "white"
        font: startButton.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        anchors.fill: parent
    }

    background: Rectangle {
        color: "#171d25"
        border.color: "white"
        border.width: startButton.activeFocus ? 3 : 0
        opacity: startButton.activeFocus ? 1.0 : 0.8
    }

    function startScan(){
        var how_many_freq_bands = bandSelection.currentIndex;
        var channel_width_mhz = settings.scan_channel_width_mhz;
        var result = _wbLinkSettingsHelper.start_scan_channels(how_many_freq_bands, channel_width_mhz);
        if(result){
            _qopenhd.show_toast(qsTr("Channel scan started, please wait"), true);
        } else {
            _qopenhd.show_toast(qsTr("Busy, please try again later"), true);
        }
    }

    onClicked: startScan()

    Keys.onPressed: (event) => {
        if(event.key === Qt.Key_Up){
            bandSelection.takeover_control();
            event.accepted = true;
        } else if(event.key === Qt.Key_Left){
            sidebar.regain_control_on_sidebar_stack();
            event.accepted = true;
        } else if(event.key === Qt.Key_Enter || event.key === Qt.Key_Return){
            startScan();
            event.accepted = true;
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
                text: _wbLinkSettingsHelper.scan_progress_perc + "%"
                font.pixelSize: 18
                color: "#fff"
            }
        }

        Item{
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
