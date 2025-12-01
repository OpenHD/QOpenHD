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
            ListElement { value: 0; verbose: "OpenHD [1-7]" }
            ListElement { value: 1; verbose: "2.4G " }
            ListElement { value: 2; verbose: "5.8G " }
        }

        BaseJoyEditElement2{
            id: bandSelection
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            m_title: "Channels"

            property int currentIndex: 0

            m_displayed_value: scanBandModel.get(currentIndex).verbose

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
                choiceSelector.open_choices(scanBandModel, scanBandModel.get(currentIndex).value, bandSelection);
                choiceSelector.set_clickable(clickable);
            }

            function user_selected_value(value_new){
                currentIndex=parseInt(value_new);
            }
        }

Button {
    id: startButton
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    Layout.preferredWidth: 250
    text: "START SCAN"
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
        border.width: startButton.focus ? 3 : 0
        opacity: startButton.focus ? 1.0 : 0.8
    }

    function startScan(){
        var how_many_freq_bands = bandSelection.currentIndex;
        var how_many_bandwidths = 2;
        var result = _wbLinkSettingsHelper.start_scan_channels(how_many_freq_bands, how_many_bandwidths);
        if(result){
            _qopenhd.show_toast("Channel scan started, please wait", true);
        } else {
            _qopenhd.show_toast("Busy, please try again later", true);
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
