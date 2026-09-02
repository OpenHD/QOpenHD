import QtQuick 2.12
import QtQuick.Controls 2.12

FocusScope {
    id: root
    property var settingsModel
    property string paramId: ""
    property int valueType: 0
    property var paramValue
    property string displayValue: ""
    property bool readOnly: false
    property bool busy: false

    readonly property bool isInteger: valueType === 0
    readonly property bool hasEnum: isInteger
                                    ? settingsModel.int_param_has_enum_keys_values(paramId)
                                    : settingsModel.string_param_has_enum(paramId)
    readonly property var enumKeys: hasEnum
                                    ? (isInteger ? settingsModel.int_param_get_enum_keys(paramId)
                                                 : settingsModel.string_param_get_enum_keys(paramId))
                                    : []
    readonly property var enumValues: hasEnum
                                      ? (isInteger ? settingsModel.int_param_get_enum_values(paramId)
                                                   : settingsModel.string_param_get_enum_values(paramId))
                                      : []

    function valueIndex() {
        for (var i = 0; i < enumValues.length; ++i) {
            if (String(enumValues[i]) === String(paramValue))
                return i
        }
        return -1
    }
    function warnIfNeeded() {
        var warning = settingsModel.get_warning_before_safe(paramId)
        if (warning !== "")
            _messageBoxInstance.set_text_and_show(warning)
    }
    function commitInt(value) {
        warnIfNeeded()
        settingsModel.try_set_param_int_async(paramId, Number(value), true)
    }
    function commitString(value) {
        warnIfNeeded()
        settingsModel.try_set_param_string_async(paramId, String(value), true)
    }
    function gainFocus() {
        if (editorLoader.item)
            editorLoader.item.forceActiveFocus()
    }

    Loader {
        id: editorLoader
        anchors.fill: parent
        sourceComponent: root.readOnly ? readOnlyEditor
                                      : (root.hasEnum ? enumEditor
                                                      : (root.isInteger ? integerEditor : stringEditor))
    }

    Component {
        id: enumEditor
        CompactLinkComboBox {
            model: root.enumKeys
            currentIndex: root.valueIndex()
            displayText: currentIndex >= 0 ? String(root.enumKeys[currentIndex]) : root.displayValue
            enabled: !root.busy
            popupWidth: Math.max(width, 260)
            onActivated: {
                if (currentIndex < 0 || currentIndex >= root.enumValues.length)
                    return
                if (root.isInteger)
                    root.commitInt(root.enumValues[currentIndex])
                else
                    root.commitString(root.enumValues[currentIndex])
            }
        }
    }

    Component {
        id: integerEditor
        SpinBox {
            id: spin
            from: root.settingsModel.int_param_has_min_max(root.paramId)
                  ? root.settingsModel.int_param_get_min_value(root.paramId) : 0
            to: root.settingsModel.int_param_has_min_max(root.paramId)
                ? root.settingsModel.int_param_get_max_value(root.paramId) : 2147483647
            value: Number(root.paramValue)
            editable: true
            enabled: !root.busy
            font.pixelSize: 12
            onValueModified: root.commitInt(value)
        }
    }

    Component {
        id: stringEditor
        TextField {
            id: field
            text: String(root.paramValue)
            enabled: !root.busy
            selectByMouse: true
            font.pixelSize: 12
            color: settings_form.primaryText
            onEditingFinished: {
                if (text !== String(root.paramValue))
                    root.commitString(text)
            }
            background: Rectangle {
                radius: 7
                color: settings_form.panelBackgroundRaised
                border.color: field.activeFocus ? settings_form.accentColor : settings_form.lineColor
                border.width: field.activeFocus ? 2 : 1
            }
        }
    }

    Component {
        id: readOnlyEditor
        Rectangle {
            color: settings_form.panelBackgroundRaised
            radius: 7
            border.color: settings_form.lineColor
            Text {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                text: root.displayValue
                color: settings_form.secondaryText
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideLeft
            }
        }
    }
}
