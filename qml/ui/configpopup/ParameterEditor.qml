import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

// Dirty. This is opened up every time the user wants to change a parameter.
// R.n it supports int and string parameters.
// TODO: int enum(s), proper int ranges, string enum(s)

Rectangle{

    property int total_width: 300

    width: total_width
    height: parent.height
    border.color: "black"
    border.width: 5

    anchors.right: parent.right;
    anchors.top: parent.top
    //Layout.alignment: Qt.AlignRight || Qt.AlignTop
    // by default, invisble. Element becomes visible when user clicks on edit for a specific param
    visible: false

    property var instanceMavlinkSettingsModel: _groundPiSettingsModel

    property int customHeight: 50

    property string parameterId: "PARAM_ID"

    property int paramValueType: 0 // 0==int, 1==string

    // These are only for int params, and also parially optional (e.g not every in param is range checked usw)
    // int param begin -----------------------------
    property int paramValueInt: 0
    property string paramExtraValueInt: "0"
    // int param end   -----------------------------

    // only for string params begin
    property string paramValueString: "ValueString"
    // only for string params end

    property string shortParamDescription: "?"

    // disable some checking we do for the user, should be used only in really rare cases
    property bool enableAdvanced: false


    function holds_int_value(){
        return paramValueType==0;
    }

    function holds_string_value(){
        return paramValueType==1;
    }

    function get_param_type_readable(){
        if(holds_int_value())return "(int)"
        return "(string)"
    }

    function param_int_min_value(){
        // Advanced passes all restrictions
        if(enableAdvanced){
            return -2147483648;
        }
        if(instanceMavlinkSettingsModel.has_int_enum_mapping(parameterId)){
            return instanceMavlinkSettingsModel.int_enum_get_min(parameterId);
        }
        return 0;
    }
    function param_int_max_value(){
        // Advanced passes all restrictions
        if(enableAdvanced){
            return 2147483647;
        }
        if(instanceMavlinkSettingsModel.has_int_enum_mapping(parameterId)){
            return instanceMavlinkSettingsModel.int_enum_get_max(parameterId);
        }
        return 100000;
    }

    function setup_for_parameter(param_id,model){
        console.log("setup_for_parameter"+param_id);
        if(model.unique_id !== param_id){
            console.log("Error wrong usage, pass in the right model");
            return;
        }
        // Every time the user wants to enable the "advanced", he needs to re-do it for every param,
        // since advanced only makes sense in the rarest case(s), e.g. when QOpenHD and OpenHD are out of sync.
        checkBoxEnableAdvanced.checked=false
        enableAdvanced=false;
        // set param id and the value type this param holds
        parameterId=param_id;
        paramValueType=model.valueType
        shortParamDescription=model.shortDescription
        if(paramValueType==0){
            // This is an int param
            paramValueInt=model.value
            paramExtraValueInt= model.extraValue
            paramValueString="Do not use me !!!"
        }else{
            // This is a string param
            paramValueString=model.value
            paramExtraValueInt= "Do not use me !!!!"
        }
        setup_spin_box()
        setup_text_input()
        parameterEditor.visible=true
    }

    // For int params we use the spin box
    function setup_spin_box(){
        if(holds_int_value()){
            spinBoxInputParamtypeInt.visible=true
            spinBoxInputParamtypeInt.from=param_int_min_value()
            spinBoxInputParamtypeInt.to=param_int_max_value()
            spinBoxInputParamtypeInt.value=paramValueInt
        }else{
            spinBoxInputParamtypeInt.visible=false
        }
    }
    // for string params we use the text input
    function setup_text_input(){
        if(holds_string_value()){
            textInputParamtypeString.visible=true
            textInputParamtypeString.text= paramValueString
        }else{
            textInputParamtypeString.visible=false
        }
    }


    ColumnLayout{
        width: parent.width
        height:parent.height

        spacing: 10

        Label{
            width: total_width
            height: customHeight
            text: "Parameter editor"
            horizontalAlignment: Qt.AlignCenter
            font.bold: true
        }

        Label{
            //width: total_width
            height:customHeight
            text: qsTr(parameterId+" "+get_param_type_readable())
            horizontalAlignment: Qt.AlignCenter
            // dafuq https://stackoverflow.com/questions/35799944/text-type-alignment
            Layout.alignment: Qt.AlignCenter
        }
        Text {
            width: total_width
            height:customHeight
            id: textDescription
            //horizontalAlignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Description: "+shortParamDescription)
            Layout.alignment: Qt.AlignCenter
        }

        // Value edit part begin
        // if holds int
        /*TextInput {
            id: textInputParamtypeInt
            horizontalAlignment: Qt.AlignCenter
            height: customHeight
            text: paramValueInt
            cursorVisible: false
            visible: holds_int_value()
            validator: IntValidator {bottom: 0; top: 2147483647} //2,147,483,647==int32 max
            Layout.alignment: Qt.AlignCenter
        }*/

        SpinBox {
            id: spinBoxInputParamtypeInt
            height: customHeight
            font.pixelSize: 14
            Layout.alignment: Qt.AlignCenter
            from: param_int_min_value()
            to: param_int_max_value()
            stepSize: 1
            value: paramValueInt
            visible: holds_int_value()

            editable: true
            onValueChanged: {

            }
        }


        // if holds string
        TextInput{
            id: textInputParamtypeString
            horizontalAlignment: Qt.AlignCenter
            height: customHeight
            text: paramValueString
            cursorVisible: false
            visible: holds_string_value()
            Layout.alignment: Qt.AlignCenter
        }
        //Value edit part end

        RowLayout{
            width:parent.width
            height: 50
            spacing: 10
            Layout.alignment: Qt.AlignHCenter

            Button{
                text: "Cancel"
                Layout.alignment: Qt.AlignLeft
                onClicked: {
                    parameterEditor.visible=false
                }
            }
            Button{
                text: "Save"
                Layout.alignment: Qt.AlignRight
                onClicked: {
                    var res=false;
                    if(paramValueType==0){
                        //var value_int_as_string=spinBoxInputParamtypeInt.text
                        //var value_int = parseInt(value_int_as_string)
                        //console.log("UI set int:{"+value_int_as_string+"}={"+value_int+"}")
                        var value_int=spinBoxInputParamtypeInt.value
                        console.log("UI set int:{"+value_int+"}")
                        res=instanceMavlinkSettingsModel.try_update_parameter_int(parameterId,value_int)
                    }else{
                        var value_string=textInputParamtypeString.text
                        console.log("UI set string:{"+value_string+"}")
                        res=instanceMavlinkSettingsModel.try_update_parameter_string(parameterId,value_string);
                    }
                    if(!res){
                        console.log("Update failed")
                        _messageBoxInstance.set_text_and_show("Update failed")
                    }else{
                        parameterEditor.visible=false
                    }
                }
            }
        }
        CheckBox{
            width: total_width
            height:customHeight
            id: checkBoxEnableAdvanced
            //horizontalAlignment: Qt.AlignCenter
            text: qsTr("Advanced")
            Layout.alignment: Qt.AlignHCenter
            onCheckStateChanged: {
                enableAdvanced=checkBoxEnableAdvanced.checked
                // We need to refresh the input field, since aparently qt rejects values out of range
                if(holds_int_value() && enableAdvanced){
                    //console.log("Test:"+paramValueInt)
                    spinBoxInputParamtypeInt.from=param_int_min_value()
                    spinBoxInputParamtypeInt.to=param_int_max_value()
                    spinBoxInputParamtypeInt.value=paramValueInt
                }
            }
        }
    }
}

