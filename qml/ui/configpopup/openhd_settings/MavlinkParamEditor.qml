import QtQuick 2.12
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12
import QtQuick.Controls.Styles 1.4

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

// Dirty. This is opened up every time the user wants to change a parameter.
// R.n it supports int and string parameters.
// int parameters can have sequential (0,1,2,..) or custom (1000Mhz,2000Mhz,3000Mhz) enums,
// which is much more verbose to the user.
//
// Aligned to the right, and width can be set by total_width property manually
Rectangle{

    property int total_width: 400

    width: total_width
    height: parent.height
    anchors.right: parent.right;
    //anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    //anchors.centerIn: parent
    //anchors.topMargin: -15
    color: "#333c4c"

    //Layout.alignment: Qt.AlignRight || Qt.AlignTop
    // by default, invisble. Element becomes visible when user clicks on edit for a specific param
    visible: false
    // We set a the ground pi instance as default (such that the qt editor code completion helps us a bit),
    // but this can be replaced by the proper instance for air or camera
    property var instanceMavlinkSettingsModel: _ohdSystemGroundSettings

    property int customHeight: 50

    property string parameterId: "PARAM_ID_UNSET"

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
    property bool m_has_param_description: false

    // disable some checking we do for the user, should be used only in really rare cases
    property bool enableAdvanced: false

    // For getting the result of a update operation
    property int m_update_count: instanceMavlinkSettingsModel.update_count

    onM_update_countChanged: {
        console.log("Update count changed, "+instanceMavlinkSettingsModel.last_updated_param_id+" "+instanceMavlinkSettingsModel.last_updated_param_success);
        if(instanceMavlinkSettingsModel.last_updated_param_id==parameterId && instanceMavlinkSettingsModel.last_updated_param_success && parameterEditor.visible){
            // Success updating, close the editor
            parameterEditor.visible=false
            _qopenhd.show_toast("Set "+parameterId+" success");
        }
    }


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
        if(instanceMavlinkSettingsModel.int_param_has_min_max(parameterId)){
            return instanceMavlinkSettingsModel.int_param_get_min_value(parameterId);
        }
        // r.n all int params are unsigend
        return 0;
    }
    function param_int_max_value(){
        // Advanced passes all restrictions
        if(enableAdvanced){
            return 2147483647;
        }
        if(instanceMavlinkSettingsModel.int_param_has_min_max(parameterId)){
            return instanceMavlinkSettingsModel.int_param_get_max_value(parameterId);
        }
        return 2147483647;
    }

    function setup_for_parameter(param_id,model){
        console.log("setup_for_parameter"+param_id);
        if(model.unique_id !== param_id){
            console.log("Error wrong usage, pass in the right model");
            return;
        }
        // Every time the user wants to enable the "advanced", he needs to re-do it for every param,
        // since advanced only makes sense in the rarest case(s), e.g. when QOpenHD and OpenHD are out of sync.
        enableAdvanced=false;
        // disable by default, enable only in case it is needed
        stringEnumDynamicComboBox.visible=false
        // set param id and the value type this param holds
        parameterId=param_id;
        paramValueType=model.valueType
        shortParamDescription=model.shortDescription
        if(shortParamDescription==="TODO"){
            m_has_param_description=false;
        }else{
            m_has_param_description=true;
        }
        var warning_string=instanceMavlinkSettingsModel.get_warning_before_safe(parameterId);
        if(warning_string!==""){
            console.log("Show extra dialog before actually saving:"+warning_string);
            _messageBoxInstance.set_text_and_show(warning_string);
        }
        if(paramValueType==0){
            // This is an int param
            paramValueInt=model.value
            paramExtraValueInt= model.extraValue
            paramValueString="Do not use me !!!"
        }else{
            // This is a string param
            paramValueString=model.value
            paramValueInt=-1
            paramExtraValueInt= "Do not use me !!!!"
        }
        setup_spin_box_int_param()
        setup_text_input_string_param()
        parameterEditor.visible=true
    }


    // For int params we use the spin box
    function setup_spin_box_int_param(){
        if(holds_int_value()){
            // If we can treat this int value as an enum, this is the most verbose for the user
            // unless the user explicitly wants raw access to the param (enable advanced)
            if(instanceMavlinkSettingsModel.int_param_has_enum_keys_values(parameterId) && !enableAdvanced){
                console.log(parameterId+" has int enum mapping")
                spinBoxInputParamtypeInt.visible=false
                intEnumDynamicComboBox.visible=true
                // Populate the model with the key,value pairs for this enum
                const keys=instanceMavlinkSettingsModel.int_param_get_enum_keys(parameterId)
                const values=instanceMavlinkSettingsModel.int_param_get_enum_values(parameterId);
                intEnumDynamicListModel.clear()
                var currently_selected_index=-1;
                for (var i = 0; i < keys.length; i++) {
                    var key=keys[i];
                    var value=values[i];
                    //console.log(key,value);
                    intEnumDynamicListModel.append({title: key, value: value})
                    if(value===paramValueInt){
                        currently_selected_index=i;
                    }
                }
                if(currently_selected_index==-1){
                    // We are missing a description for this int value, add row
                    var new_key="Unknown ("+paramValueInt+")"
                    console.log("Adding missing dummy description :"+new_key+" "+paramValueInt)
                    intEnumDynamicListModel.append({title: new_key, value: paramValueInt})
                    currently_selected_index=intEnumDynamicListModel.count-1
                }
                intEnumDynamicComboBox.currentIndex=currently_selected_index
                console.log("Curr index:",currently_selected_index);
            }else{
                // Less verbose
                console.log("Int parameter has no int enum mapping")
                intEnumDynamicComboBox.visible=false
                spinBoxInputParamtypeInt.visible=true
                spinBoxInputParamtypeInt.from=param_int_min_value()
                spinBoxInputParamtypeInt.to=param_int_max_value()
                spinBoxInputParamtypeInt.value=paramValueInt
            }
        }else{
            spinBoxInputParamtypeInt.visible=false
            intEnumDynamicComboBox.visible=false;
        }
    }

    // for string params we use the text input
    function setup_text_input_string_param(){
        if(holds_string_value()){
            if(instanceMavlinkSettingsModel.string_param_has_enum(parameterId)){
                console.log(parameterId+" has string enum mapping")
                // Populate the model with the key,value pairs for this enum
                //const enum_mapping_string=instanceMavlinkSettingsModel.string_param_get_enum(parameterId);
                //const keys=enum_mapping_string.keys;
                //const values=enum_mapping_string.values;
                const keys=instanceMavlinkSettingsModel.string_param_get_enum_keys(parameterId)
                const values=instanceMavlinkSettingsModel.string_param_get_enum_values(parameterId);
                stringEnumDynamicListModel.clear();
                var currently_selected_index=-1;
                for (var i = 0; i < keys.length; i++) {
                    var key=keys[i];
                    var value=values[i];
                    console.log(key,value);
                    stringEnumDynamicListModel.append({title: key, value: value})
                    if(value===paramValueString){
                        currently_selected_index=i;
                    }
                }
                console.log("currently_selected_index:"+currently_selected_index);
                if(currently_selected_index==-1){
                    var new_key="{"+paramValueString+"}"
                    console.log("Adding missing dummy description :"+new_key+" "+paramValueString)
                    stringEnumDynamicListModel.append({title: new_key, value: paramValueString})
                    currently_selected_index=stringEnumDynamicListModel.count-1
                }
                stringEnumDynamicComboBox.currentIndex=currently_selected_index
                console.log("Curr index:",currently_selected_index);
                stringEnumDynamicComboBox.visible=true;
            }
            textInputParamtypeString.visible=true
            textInputParamtypeString.text= paramValueString
        }else{
            textInputParamtypeString.visible=false
            stringEnumDynamicComboBox.visible=false
        }
    }

    // This button closes the param editor
    Button{
        id:exit_button
        text: "x"
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.rightMargin: 25
        width: 30
        height: 30
        contentItem: Text {
            text: exit_button.text
            font: exit_button.font
            opacity: enabled ? 1.0 : 0.3
            color: exit_button.down ? "#222425" : "#fff"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            implicitWidth: 100
            implicitHeight: 100
            opacity: enabled ? 0.1 : 1
            color: exit_button.down ? "#14181f" : "#333c4c"
        }
        onClicked: {
            console.log("Closing param editor")
            parameterEditor.visible=false
        }
    }


    ColumnLayout{
        width: parent.width
        height:parent.height
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 15
        spacing: 10

        Label{
            height: customHeight
            text: "Parameter editor"
            color: "white"
            font.bold: true
            font.pixelSize: 18
            horizontalAlignment: Qt.AlignHCenter
            Layout.alignment: Qt.AlignCenter
        }

        Label{
            height:customHeight
            anchors.topMargin: 30
            font.pixelSize: 12
            text: qsTr(parameterId+" "+get_param_type_readable())
            color: "white"
            // dafuq https://stackoverflow.com/questions/35799944/text-type-alignment
            horizontalAlignment: Qt.AlignHCenter
            Layout.alignment: Qt.AlignCenter
        }
        Text{
            width: 300
            height:customHeight
            Layout.alignment: Qt.AlignCenter
            color: "white"
            text: "Description not availble"
            visible: !m_has_param_description
        }

        // Value edit part begin

        // Type int only begin --------------------------
        // For int values that do not have an enum mapping, we use a SpinBox such that the user can either
        // use the +/- to edit the value (for touch screen users) but also allows the user to
        // type in an int value directly with the keyboard.
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
            // Not the best design style wise, but since the param editor is dark blue, otherwise the spin
            background: Rectangle {
                implicitWidth: 200
                implicitHeight: 20
                border.color: "gray"
                radius: 2
            }
        }
        // And for int values that do have an enum mapping we use a more verbose combo box and a dynamically updated model
        // The best example is the typical yes/no, or uart1,uart2,uart3,...
        ListModel{
            id: intEnumDynamicListModel
            ListElement {title: "I SHOULD NEVER APPEAR"; value: 0}
        }
        ComboBox {
            id: intEnumDynamicComboBox
            height: customHeight
            font.pixelSize: 14
            Layout.alignment: Qt.AlignCenter
            model: intEnumDynamicListModel
            textRole: "title"
            Layout.minimumWidth : total_width*0.8
            onCurrentIndexChanged: {
            }
            visible:false
        }
        // Type int only end --------------------------

        // Type string only begin --------------------------
        // if we have a mapping / pre-selected recommended choices
        ListModel{
            id: stringEnumDynamicListModel
            ListElement {title: "I SHOULD NEVER APPEAR"; value:"ERROR"}
        }

        ComboBox {
            id: stringEnumDynamicComboBox
            height: customHeight
            font.pixelSize: 14
            Layout.alignment: Qt.AlignCenter
            model: stringEnumDynamicListModel
            textRole: "title"
            Layout.minimumWidth : total_width*0.8
            onCurrentIndexChanged: {
                console.debug("currentIndex:"+currentIndex)
                if(currentIndex>=0){
                    // no idea why this is needed
                    const new_param_value=stringEnumDynamicListModel.get(currentIndex).value
                    console.debug("new_param_value:"+new_param_value)
                    textInputParamtypeString.text=new_param_value
                }
            }
            visible:false
        }

        // for strings, we always show the text input
        TextInput{
            id: textInputParamtypeString
            horizontalAlignment: Qt.AlignCenter
            height: customHeight
            text: paramValueString
            cursorVisible: false
            visible: false
            Layout.alignment: Qt.AlignCenter
            // Not the best design style wise, but since the param editor is dark blue, otherwise the spin
            color: "white"
        }
        // Type string only end --------------------------
        /*CheckBox{
            id: advanced_checkbox
            text: "experiment"
            Layout.alignment: Qt.AlignHCenter
            onClicked: {
                enableAdvanced= !enableAdvanced
                // Completely re-fresh the UI - the user has now more direct access to the parameter(s)
                setup_spin_box_int_param()
                setup_text_input_string_param()
            }
        }*/
        //Value edit part end

        RowLayout{
            width:parent.width
            height: 50
            spacing: 10
            Layout.alignment: Qt.AlignHCenter

            Button{
                text: "Advanced"
                visible: settings.dev_show_advanced_button
                Layout.alignment: Qt.AlignLeft
                onClicked: {
                    enableAdvanced= !enableAdvanced
                    // Completely re-fresh the UI - the user has now more direct access to the parameter(s)
                    setup_spin_box_int_param()
                    setup_text_input_string_param()
                }
                enabled: !instanceMavlinkSettingsModel.ui_is_busy
            }
            Button{
                text: "Save"
                Layout.alignment: Qt.AlignRight
                onClicked: {
                    var res="";
                    if(paramValueType==0){
                        var value_int;
                        if(intEnumDynamicComboBox.visible){
                            value_int=intEnumDynamicListModel.get(intEnumDynamicComboBox.currentIndex).value
                        }else{
                            value_int=spinBoxInputParamtypeInt.value
                        }
                        //var value_int_as_string=spinBoxInputParamtypeInt.text
                        //var value_int = parseInt(value_int_as_string)
                        //console.log("UI set int:{"+value_int_as_string+"}={"+value_int+"}")
                        console.log("UI set int:{"+value_int+"}")
                        //res=instanceMavlinkSettingsModel.try_update_parameter_int(parameterId,value_int)
                        instanceMavlinkSettingsModel.try_set_param_int_async(parameterId,value_int);
                    }else{
                        var value_string=textInputParamtypeString.text
                        console.log("UI set string:{"+value_string+"}")
                        instanceMavlinkSettingsModel.try_set_param_string_async(parameterId,value_string);
                    }
                    /*if(res===""){
                        // Update success (no error code)
                        if(instanceMavlinkSettingsModel.get_param_requires_manual_reboot(parameterId)){
                            _messageBoxInstance.set_text_and_show("Please reboot to apply")
                        }
                        var argh=paramValueType==0 ? (""+value_int) : (""+value_string);
                        parameterEditor.visible=false
                        _qopenhd.show_toast("Set "+parameterId+" to ["+argh+"]");
                    }else{
                        console.log("Update failed")
                        _qopenhd.show_toast(res,true);
                    }*/
                }
                enabled: !instanceMavlinkSettingsModel.ui_is_busy
            }
        }
    }
}

