import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."
import "../openhd_settings"

AdvancedDialog {
    id: dialog
    objectName: "simulationPopup"
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(680, parent.width - 24)
    height: Math.min(640, parent.height - 24)
    title: qsTr("Simulate Air / Ground")
    readonly property var simulator: typeof _uiSimulator !== "undefined" ? _uiSimulator : null
    property var draft: ({ground:21, air:11, camera1:32, camera2:3, radio:17, link:1, secondLink:0, state:1, fc:true, groundRadios:1, airRadios:1, accessMode:0})
    readonly property var linkChoices: [{label:"WiFiBroadcast",value:1},{label:"Ethernet",value:2},{label:"UART",value:3},
        {label:"Microhard",value:4},{label:"Artosyn",value:5},{label:"FleetControl",value:6},{label:"mLRS",value:7}]
    function setChoice(key,value) { var copy=Object.assign({},draft);copy[key]=value;draft=copy }
    function indexOfValue(choices,value) { for(var i=0;i<choices.length;i++) if(choices[i].value===value)return i;return 0 }
    onOpened: if(simulator) draft=Object.assign({},simulator.profile)
    contentItem: ColumnLayout {
        spacing: 12
        Text {
            Layout.fillWidth: true
            text: qsTr("Offline UI simulation. Telemetry and device settings stay separate from live devices. No video is transmitted or decoded.")
            color: "#aebdcb"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.body; wrapMode: Text.WordWrap
        }
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 80
            clip: true
            contentWidth: availableWidth
            ColumnLayout {
                id: form
                width: parent.width
                spacing: 8
                Repeater {
                    model: [
                        {key:"accessMode",label:qsTr("Settings mode"),choices:[{label:qsTr("Normal"),value:0},{label:qsTr("Advanced"),value:1},{label:qsTr("Developer"),value:2}]},
                        {key:"ground",label:qsTr("Ground hardware"),choices:dialog.simulator ? dialog.simulator.platforms():[]},
                        {key:"air",label:qsTr("Air hardware"),choices:dialog.simulator ? dialog.simulator.platforms():[]},
                        {key:"camera1",label:qsTr("Camera 1"),choices:dialog.simulator ? dialog.simulator.cameras(dialog.draft.air):[]},
                        {key:"camera2",label:qsTr("Camera 2"),choices:dialog.simulator ? dialog.simulator.cameras(dialog.draft.air):[]},
                        {key:"radio",label:qsTr("Wi-Fi chipset"),choices:dialog.simulator ? dialog.simulator.radios():[]},
                        {key:"groundRadios",label:qsTr("Ground radios"),choices:[{label:"1",value:1},{label:"2",value:2},{label:"3",value:3},{label:"4",value:4}]},
                        {key:"airRadios",label:qsTr("Air radios"),choices:[{label:"1",value:1},{label:"2",value:2}]},
                        {key:"link",label:qsTr("Primary link"),choices:dialog.linkChoices},
                        {key:"secondLink",label:qsTr("Second link"),choices:[{label:qsTr("None"),value:0}].concat(dialog.linkChoices)},
                        {key:"state",label:qsTr("Connection state"),choices:[{label:qsTr("Online / streaming"),value:1},{label:qsTr("Camera restarting"),value:2},{label:qsTr("Disconnected"),value:0}]}
                    ]
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumHeight: 40
                        spacing: 12
                        Text { Layout.preferredWidth: dialog.width < 500 ? 118 : 160; text:modelData.label; color:"#edf4fa";font.family: MenuTypography.family;font.pixelSize: MenuTypography.body;wrapMode:Text.WordWrap }
                        CompactLinkComboBox {
                            objectName: "simulationChoice_"+modelData.key
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.preferredHeight: MenuTypography.controlHeight
                            Layout.minimumHeight: 36
                            readonly property var entry: modelData
                            model:entry.choices; textRole:"label"
                            currentIndex:dialog.indexOfValue(entry.choices,dialog.draft[entry.key])
                            onActivated: {
                                dialog.setChoice(entry.key,entry.choices[currentIndex].value)
                                if(entry.key==="air") {
                                    var cameras=dialog.simulator.cameras(dialog.draft.air)
                                    for(var n=1;n<=2;n++) {
                                        var key="camera"+n,found=false
                                        for(var i=0;i<cameras.length;i++)if(cameras[i].value===dialog.draft[key])found=true
                                        if(!found)dialog.setChoice(key,-1)
                                    }
                                }
                            }
                        }
                    }
                }
                CheckBox {
                    objectName:"simulationFc"
                    text:qsTr("Flight controller connected")
                    checked:dialog.draft.fc
                    onToggled:dialog.setChoice("fc",checked)
                }
            }
        }
        Text { Layout.fillWidth:true; visible:dialog.simulator && dialog.simulator.active; text:dialog.simulator?dialog.simulator.lastAction:"";color:"#70c8ff";font.pixelSize: MenuTypography.helper;wrapMode:Text.WordWrap }
    }
    footer: Item {
        implicitHeight: 68
        RowLayout {
            anchors.fill:parent;anchors.margins:14;spacing:10
            AdvancedDialogButton { text:qsTr("Stop simulation");visible:dialog.simulator && dialog.simulator.active;onClicked:{dialog.simulator.stop();dialog.close()} }
            Item { Layout.fillWidth:true }
            AdvancedDialogButton { text:qsTr("Cancel");onClicked:dialog.reject() }
            AdvancedDialogButton {
                objectName:"simulationStart"
                text:qsTr("Start simulation")
                enabled:!!dialog.simulator
                onClicked:if(dialog.simulator.start(dialog.draft))dialog.accept()
            }
        }
    }
}
