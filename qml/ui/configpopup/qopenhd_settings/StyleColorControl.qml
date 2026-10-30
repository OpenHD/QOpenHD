import "../MenuTypography.js" as Typography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."

Rectangle {
    id: root
    property string label: ""
    property string hint: ""
    property color selectedColor: "white"
    signal colorSelected(string value)
    implicitHeight: 112
    radius: 8
    color: settings_form.panelBackgroundRaised
    border.color: settings_form.lineColor
    ColumnLayout {
        anchors.fill:parent;anchors.margins:10;spacing:8
        RowLayout {
            Layout.fillWidth:true;spacing:9
            AdvancedActionButton {
                objectName:"customColorButton"
                topInset:0;bottomInset:0;leftInset:0;rightInset:0
                Layout.preferredWidth:34;Layout.preferredHeight: Typography.controlHeight
                Accessible.name:qsTr("Choose %1").arg(root.label)
                onClicked:root.openPicker()
                background:Rectangle {radius:17;color:root.selectedColor;border.color:parent.activeFocus?settings_form.accentColor:settings_form.secondaryText;border.width:2}
            }
            ColumnLayout {
                Layout.fillWidth:true;spacing:2
                Text {Layout.fillWidth:true;text:root.label;color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;font.bold:true;wrapMode:Text.WordWrap}

            }
        }
        Row {
            Layout.fillWidth:true;spacing:5
            Repeater {
                model:["#ffffff","#ec71bf","#ff4035","#ffff00","#14ff00","#249fff","#a16bff","#000000"]
                delegate:AdvancedActionButton {
                    width:17;height:Typography.controlHeight
                    topInset:0;bottomInset:0;leftInset:0;rightInset:0
                    Accessible.name:modelData
                    onClicked:root.colorSelected(modelData)
                    background:Rectangle {radius:9;color:modelData;border.color:Qt.colorEqual(root.selectedColor,modelData)?settings_form.primaryText:"#40576a";border.width:Qt.colorEqual(root.selectedColor,modelData)?2:1}
                }
            }
        }
    }
    function openPicker() {
        pickerLoader.active=true
        if(pickerLoader.item)pickerLoader.item.openColor(root.selectedColor.toString())
    }
    Loader {
        id:pickerLoader
        active:false
        sourceComponent:pickerComponent
        onLoaded:item.openColor(root.selectedColor.toString())
    }
    Component {
        id:pickerComponent
    AdvancedDialog {
        id:picker
        function openColor(value){hexInput.text=value;open()}
        parent:Overlay.overlay
        anchors.centerIn:parent
        width:Math.min(370,parent.width-24)
        height:250
        title:qsTr("%1 colour").arg(root.label)
        contentItem:ColumnLayout {
            spacing:12

            TextField { verticalAlignment: TextInput.AlignVCenter; leftPadding: 12; rightPadding: 12; topPadding: 6; bottomPadding: 6;id:hexInput;Layout.fillWidth:true;selectByMouse:true;color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body}
        }
        footer:Item {
            implicitHeight:64
            RowLayout {
                anchors.fill:parent;anchors.margins:12
                Item {Layout.fillWidth:true}
                AdvancedDialogButton {text:qsTr("Cancel");onClicked:picker.reject()}
                AdvancedDialogButton {text:qsTr("Use colour");enabled:/^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(hexInput.text);onClicked:{root.colorSelected(hexInput.text);picker.accept()}}
            }
        }
    }
    }
}
