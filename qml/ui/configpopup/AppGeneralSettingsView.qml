import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"


Flickable {
    id: appManageSettingsView
    width: parent.width
    height: parent.height
    contentHeight: generalColumn.height
    boundsBehavior: Flickable.StopAtBounds

    visible: appSettingsBar.currentIndex == 0

    clip: true

    onActiveFocusChanged: {console.log("FOCUS CHANGED");}

    property bool controlSelected: false

    function focusAppGeneralView(){
        console.log("appGeneralSettingsView reached");
        mavlinkSysIDSpinBox.forceActiveFocus()
        controlSelected=false
    }

    function closeAppGeneralView(){
        console.log("closeAppGeneralView reached");
    }

    function scrollToY(y) {
        //So we can control scrolling when focus shift down view
        console.log("scroll :" +y);
        //1.0 is bottom
        //appManageSettingsView.ScrollBar.vertical.position= .5 - appManageSettingsView.ScrollBar.vertical.size

        //added 48px for the content above the column
        var columnH=generalColumn.childrenRect.height+48
        var viewH= applicationWindow.height
        console.log("height: " + viewH + " column: " + columnH)
        if (columnH > viewH){
            // 8 is total children
        var ratio = columnH/8
            //now find where you are in the column ( "1" ) and move there
        var position = ratio * 1
            appManageSettingsView.flick(0,-position);
        }
    }

    Item {
        anchors.fill: parent       

        FocusScope {
            id: scope
            anchors.fill: parent

            Keys.onPressed: (event)=> {
                                if (event.key === Qt.Key_Escape)
                                closeAppGeneralView()
                            }

        Column {
            id: generalColumn
            spacing: 0
            anchors.left: parent.left
            anchors.right: parent.right

            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("Mavlink SysID")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }

                GgSpinBox {
                    id: mavlinkSysIDSpinBox
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    from: 1
                    to: 255
                    stepSize: 1
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18
                    value: settings.qopenhd_mavlink_sysid
                    onValueChanged: settings.qopenhd_mavlink_sysid = value
                }
                Keys.onPressed: (event)=> {
                                    if (event.key === Qt.Key_Minus && controlSelected == false){
                                    ggSwitch.forceActiveFocus()
                                    appGeneralSettingsView.scrollToY(Positioner.index);
                                    }
                                    else if (event.key === Qt.Key_S){
                                    controlSelected=true
                                    }
                                    else if (event.key === Qt.Key_Escape)
                                    controlSelected=false
                                }
            }

            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("Enable Goggle Layout")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }

                GgSwitch {
                    id:ggSwitch
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.goggle_layout

                    onCheckedChanged: {
                        closeSettings()
                        settings.goggle_layout = checked
                    }
                }
                Keys.onPressed: (event)=> {
                                    if (event.key === Qt.Key_Equal)
                                    mavlinkSysIDSpinBox.forceActiveFocus()
                                    else if (event.key === Qt.Key_Minus)
                                    speechSwitch.forceActiveFocus()
                                }
            }

            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                //color: "#8cbfd7f3"
                Text {
                    text: qsTr("Enable Speech")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }

                GgSwitch {
                    id:speechSwitch
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.enable_speech
                    onCheckedChanged: settings.enable_speech = checked
                }
                Keys.onPressed: (event)=> {
                                    if (event.key === Qt.Key_Equal)
                                    ggSwitch.forceActiveFocus()
                                    else if (event.key === Qt.Key_Minus)
                                    logLevelspinBox.forceActiveFocus()
                                }
            }

            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("Log Level")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }

                GgSpinBox {
                    id: logLevelspinBox
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    from: 0
                    to: 7
                    stepSize: 1
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                    value: settings.log_level
                    onValueChanged: settings.log_level = value
                }
                Keys.onPressed: (event)=> {
                                    if (event.key === Qt.Key_Equal && controlSelected == false){
                                        speechSwitch.forceActiveFocus()
                                        appGeneralSettingsView.scrollToY(Positioner.index);
                                    }
                                    else if (event.key === Qt.Key_Minus && controlSelected == false){
                                        unitsSwitch.forceActiveFocus()
                                        appGeneralSettingsView.scrollToY(Positioner.index);
                                    }
                                    else if (event.key === Qt.Key_S){
                                        controlSelected=true
                                    }
                                    else if (event.key === Qt.Key_Escape)
                                    controlSelected=false
                                }
            }

            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("Imperial units")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }

                GgSwitch {
                    id: unitsSwitch
                    width: 32
                    height: elementHeight
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: settings.enable_imperial
                    onCheckedChanged: settings.enable_imperial = checked
                }
                Keys.onPressed: (event)=> {
                                    if (event.key === Qt.Key_Equal)
                                    logLevelspinBox.forceActiveFocus()
                                    else if (event.key === Qt.Key_Minus)
                                    gndBatteryCellspinBox.forceActiveFocus()
                                }
            }

            Rectangle {

                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                visible: true

                Text {
                    text: qsTr("Ground Battery Cells")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }

                GgSpinBox {
                    id: gndBatteryCellspinBox
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    from: 1
                    to: 6
                    stepSize: 1
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                    value: settings.ground_battery_cells
                    onValueChanged: settings.ground_battery_cells = value
                }
                Keys.onPressed: (event)=> {
                                    if (event.key === Qt.Key_Equal && controlSelected == false){
                                        unitsSwitch.forceActiveFocus()
                                        appGeneralSettingsView.scrollToY(Positioner.index);
                                    }
                                    else if (event.key === Qt.Key_Minus && controlSelected == false){
                                        languageSelectBox.forceActiveFocus()
                                        appGeneralSettingsView.scrollToY(Positioner.index);
                                    }
                                    else if (event.key === Qt.Key_S){
                                        controlSelected=true
                                    }
                                    else if (event.key === Qt.Key_Escape)
                                    controlSelected=false
                                }
            }

            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"

                Text {
                    text: qsTr("Language / Locale")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }

     /*           LanguageSelect {
                    id: languageSelectBox
                    height: elementHeight
                    width: 210
                    anchors.right: parent.right
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizonatalCenter
                }
   */

                ListModel {
                    id: locales
                        ListElement { text: "German"; locale: "de" }
                        ListElement { text: "Russian"; locale: "ru" }
                        ListElement { text: "English"; locale: "en" }
                        ListElement { text: "French"; locale: "fr" }
                        ListElement { text: "Spanish"; locale: "es" }
                        ListElement { text: "Dutch"; locale: "nl" }
                        ListElement { text: "Romanian"; locale: "ro" }
                        ListElement { text: "Chinese"; locale: "zh" }
                        ListElement { text: "Italian"; locale: "it" }
                }

                GgComboBox {
                    id: languageSelectBox
                    model: locales
                    height: elementHeight
                    width: 210
                    anchors.right: parent.right
                    anchors.rightMargin: Qt.inputMethod.visible ? 96 : 36
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizonatalCenter

                    Component.onCompleted: {
                        for (var i = 0; i < model.count; i++) {
                            var choice = model.get(i);
                            if (choice.locale == settings.locale) {
                                languageSelectBox.currentIndex = i;
                            }
                        }
                      //  _qopenhd.switchToLanguage(settings.locale);
                        console.log("Current language:"+settings.locale);
                    }

                    onActivated: {
                        settings.locale = locales.get(languageSelectBox.currentIndex).locale

                    //    _qopenhd.switchToLanguage(settings.locale);
                        console.log("New language:"+settings.locale);
                    }
                }
                Keys.onPressed: (event)=> {
                                    if (event.key === Qt.Key_Equal && controlSelected == false){
                                        gndBatteryCellspinBox.forceActiveFocus()
                                        appGeneralSettingsView.scrollToY(Positioner.index);
                                    }
                                    else if (event.key === Qt.Key_Minus && controlSelected == false){
                                        dev_qopenhd_n_cameras_spinbox.forceActiveFocus()
                                        appGeneralSettingsView.scrollToY(Positioner.index);
                                    }
                                    else if (event.key === Qt.Key_S){
                                        controlSelected=true
                                    }
                                    else if (event.key === Qt.Key_Escape)
                                    controlSelected=false

                                }

            }

            // exp
            Rectangle {
                width: parent.width
                height: rowHeight
                color: (Positioner.index % 2 == 0) ? "#8cbfd7f3" : "#00000000"
                visible: true
                Text {
                    text: qsTr("N Cameras to controll")
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 224
                    height: elementHeight
                    anchors.left: parent.left
                }

                GgSpinBox {
                    id: dev_qopenhd_n_cameras_spinbox
                    height: elementHeight
                    width: 210
                    font.pixelSize: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    from: 1
                    to: 2
                    stepSize: 1
                    anchors.rightMargin: Qt.inputMethod.visible ? 78 : 18

                    value: settings.dev_qopenhd_n_cameras
                    onValueChanged: settings.dev_qopenhd_n_cameras = value
                }
                Keys.onPressed: (event)=> {
                                    if (event.key === Qt.Key_Equal && controlSelected == false){
                                        languageSelectBox.forceActiveFocus()
                                        appGeneralSettingsView.scrollToY(Positioner.index);
                                    }
                            /*        else if (event.key === Qt.Key_Minus && controlSelected == false){
                                        languageSelectBox.forceActiveFocus()
                                        appGeneralSettingsView.scrollToY(Positioner.index);
                                    }
                            */
                                    else if (event.key === Qt.Key_S){
                                        controlSelected=true
                                    }
                                    else if (event.key === Qt.Key_Escape)
                                    controlSelected=false
                                }
            }

        }
    }
}
}
