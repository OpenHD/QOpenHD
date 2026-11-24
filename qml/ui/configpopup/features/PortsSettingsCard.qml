import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../qopenhd_settings"
import "../openhd_settings"
import "../MenuTypography.js" as Typography

MapSettingsCard {
    id: card

    property var section
    property bool air
    property var params
    property bool connected
    property var validateChange
    signal validationFailed(string reason)
    signal settingFocused(Item row)
    signal backRequested()

    readonly property bool link: section.id === "link"
    readonly property string reportedIds: {
        params.update_count
        return section.groups.reduce(function(ids, group) {
            return ids.concat(group.rows.map(function(entry) { return entry[0] }).filter(function(id) {
                return params.param_int_exists(id) || params.param_string_exists(id)
            }))
        }, []).join(",")
    }
    readonly property var groups: {
        var ids = reportedIds.split(",")
        return section.groups.map(function(group) {
            return {columns: group.columns === true, rows: group.rows.filter(function(entry) {
                return ids.indexOf(entry[0]) >= 0
            })}
        }).filter(function(group) { return group.rows.length > 0 })
    }

    objectName: "portsSection_" + section.id
    compact: true
    title: section.title
    subtitle: link ? qsTr("Use the same baud rate on Air and Ground.") : ""
    headerNote: air ? qsTr("Air") : qsTr("Ground")
    icon: section.icon

    Text {
        Layout.fillWidth: true
        visible: (!card.connected && !_qopenhd.debugMenuPreview) || !card.groups.length
        text: !card.connected && !_qopenhd.debugMenuPreview ? qsTr("Unit offline") :
              card.params.ui_is_busy ? qsTr("Loading settings…") : qsTr("No settings reported")
        color: settings_form.secondaryText
        font.family: Typography.family
        font.pixelSize: Typography.helper
        wrapMode: Text.Wrap
    }

    Column {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: card.groups
            delegate: Column {
                id: groupLayout
                readonly property var group: modelData
                width: card.contentWidth
                spacing: 4

                Rectangle {
                    width: parent.width
                    height: 1
                    visible: index > 0
                    color: settings_form.lineColor
                }

                Grid {
                    id: fields
                    width: groupLayout.width
                    columns: groupLayout.group.columns && width >= 620 ? 3 : 1
                    columnSpacing: 20

                    Repeater {
                        model: groupLayout.group.rows
                        delegate: AirSettingRow {
                            id: settingRow
                            objectName: "portSetting_" + (card.link ? (card.air ? "airLink" : "groundLink") : card.section.id) + "_" + paramId
                            width: (fields.width - fields.columnSpacing * (fields.columns - 1)) / fields.columns
                            compact: true
                            stacked: width < 245 || fields.columns > 1
                            showSeparator: !card.link && index + 1 < groupLayout.group.rows.length
                            settingsModel: card.params
                            connectionAlive: card.connected
                            paramId: modelData[0]
                            labelOverride: modelData[1]
                            labelIcon: modelData[2] || ""
                            validateChange: card.validateChange
                            onValidationFailed: function(reason) { card.validationFailed(reason) }
                            onBackRequested: card.backRequested()
                            onActiveFocusChanged: if (activeFocus) card.settingFocused(settingRow)
                        }
                    }
                }
            }
        }
    }
}
