import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Popup {
    id: popup
    objectName: "linkAllocationPopup"
    property var usage: null
    readonly property var allocation: usage && usage.allocation ? usage.allocation : null
    readonly property var streams: allocation && allocation.streams ? allocation.streams : []
    readonly property var parameterModel: _ohdSystemAirSettingsModel
    readonly property bool canWrite: !_qopenhd.debugMenuPreview && _ohdSystemAir.is_alive && parameterModel.has_params_fetched && !parameterModel.ui_is_busy
    readonly property int revision: parameterModel.update_count
    readonly property bool hasPercent: { revision; return parameterModel.param_int_exists("V_PRIMARY_PERC") }
    readonly property int primaryPercent: { revision; return hasPercent ? parameterModel.get_cached_int("V_PRIMARY_PERC") : streams.length > 0 ? Number(streams[0].percent) : 0 }
    readonly property bool sharesAvailable: hasPercent || dynamicCount() === 1 || (streams.length === 2 && Number(streams[0].percent) + Number(streams[1].percent) === 100)
    property int draftPercent: primaryPercent
    onPrimaryPercentChanged: draftPercent = primaryPercent
    onOpened: { draftPercent = primaryPercent; Qt.callLater(resizeToContent) }
    readonly property bool budgetsAvailable: allocation && allocation.available && allocation.enabled
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(parent.width - 24, 680)
    height: Math.min(parent.height - 24, 480)
    function resizeToContent() { if (parent) height = Math.min(parent.height - 24, body.implicitHeight + 32) }
    Connections { target: popup.parent; function onHeightChanged() { Qt.callLater(popup.resizeToContent) } }
    modal: true; dim: true; focus: true; padding: 16
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    background: Rectangle { color: settings_form.panelBackground; radius: 14; border.color: settings_form.accentColor }
    function rate(kbits) { return Number(kbits) >= 1000 ? (kbits/1000).toFixed(2) + " Mbit/s" : Math.round(kbits) + " kbit/s" }
    function measured(id) {
        if (!usage || !usage.categories) return qsTr("Unavailable")
        for (var i=0;i<usage.categories.length;i++) if (usage.categories[i].id === id) return rate(Number(usage.categories[i].bps)/1000)
        return qsTr("Unavailable")
    }
    function dynamicCount() { var count=0; for(var i=0;i<streams.length;i++) if(streams[i].active && streams[i].controllable) count++; return count }
    function dynamicStreams() {
        var result=[]
        for(var i=0;i<streams.length;i++) if(streams[i].active && streams[i].controllable) result.push(streams[i])
        return result
    }
    function share(stream) { return dynamicCount() === 1 ? 100 : stream.id === 0 ? draftPercent : 100-draftPercent }
    function commitShare() { if (canWrite && hasPercent && dynamicCount()>1) parameterModel.try_set_param_int_async("V_PRIMARY_PERC", draftPercent, true) }
    contentItem: Flickable {
        contentWidth: width; contentHeight: body.implicitHeight; clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        ColumnLayout {
            id: body
            onImplicitHeightChanged: Qt.callLater(popup.resizeToContent)
            width: parent.width; spacing: 10
            RowLayout {
                Layout.fillWidth: true
                Text { text: qsTr("Link Allocation"); color: settings_form.primaryText; font.pixelSize: 19; font.bold: true; Layout.fillWidth: true }
                Button {
                    text: qsTr("Close"); implicitHeight: 28; onClicked: popup.close()
                    contentItem: Text { text: parent.text; color: settings_form.primaryText; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 12 }
                    background: Rectangle { radius: 6; color: settings_form.panelBackgroundRaised; border.color: settings_form.lineColor }
                }
            }
            Text {
                Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 11
                text: !popup.allocation ? qsTr("Allocation telemetry unavailable. Connect an updated Air unit.")
                      : !popup.allocation.enabled ? qsTr("Dynamic Link Bitrate is off. Manual bitrate settings apply.")
                      : popup.allocation.waiting ? qsTr("Waiting for link and stream measurements.")
                      : popup.allocation.overcommitted ? qsTr("Overcommitted: fixed traffic or encoder minimums exceed capacity.") : qsTr("WiFiBroadcast • estimates account for telemetry, fixed traffic and encoder limits")
                color: popup.allocation && popup.allocation.enabled && popup.allocation.overcommitted ? settings_form.errorColor : settings_form.secondaryText
            }
            GridLayout {
                Layout.fillWidth: true; columns: popup.width < 440 ? 1 : 3; columnSpacing: 8; rowSpacing: 6
                Repeater {
                    model: [
                        {label: qsTr("Usable capacity • estimate"), value: popup.budgetsAvailable ? popup.rate(popup.allocation.capacity_kbits) : qsTr("Unavailable"), detail: ""},
                        {label: qsTr("Priority + buffer • reserved estimate"), value: popup.budgetsAvailable ? popup.rate(Number(popup.allocation.priority_kbits)+Number(popup.allocation.safety_kbits)) : qsTr("Unavailable"), detail: qsTr("Automatically reserved")},
                        {label: qsTr("Fixed traffic • measured"), value: popup.budgetsAvailable ? popup.rate(popup.allocation.fixed_measured_kbits) : qsTr("Unavailable"), detail: popup.budgetsAvailable ? qsTr("Reserved estimate: %1").arg(popup.rate(popup.allocation.fixed_kbits)) : ""}
                    ]
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 62
                        radius: 8; color: settings_form.panelBackgroundRaised; border.color: settings_form.lineColor
                        Column {
                            anchors.fill: parent; anchors.margins: 7; spacing: 4
                            Text { width: parent.width; text: modelData.label; color: settings_form.secondaryText; font.pixelSize: 10; elide: Text.ElideRight }
                            Text { text: modelData.value; color: settings_form.primaryText; font.pixelSize: 14; font.bold: true }
                            Text { width: parent.width; text: modelData.detail; color: settings_form.secondaryText; font.pixelSize: 9; elide: Text.ElideRight }
                        }
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: poolContent.implicitHeight + 24
                radius: 14; color: settings_form.panelBackgroundRaised; border.color: settings_form.lineColor
                ColumnLayout {
                    id: poolContent
                    anchors.fill: parent; anchors.margins: 12; spacing: 10
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 3
                            Text { text: qsTr("Dynamic Pool"); color: settings_form.primaryText; font.pixelSize: 16; font.bold: true }
                            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: popup.budgetsAvailable ? qsTr("%1 link, %2 reserved").arg(popup.rate(popup.allocation.capacity_kbits)).arg(popup.rate(Number(popup.allocation.priority_kbits)+Number(popup.allocation.fixed_kbits)+Number(popup.allocation.safety_kbits))) : qsTr("No active allocation estimate"); color: settings_form.secondaryText; font.pixelSize: 11 }
                        }
                        Text { text: popup.budgetsAvailable ? popup.rate(popup.allocation.pool_kbits) : "—"; color: settings_form.primaryText; font.pixelSize: popup.width < 440 ? 18 : 25; font.bold: true }
                    }
                    LinkSegmentsBar {
                        Layout.fillWidth: true; Layout.preferredHeight: 20
                        denominator: 100
                        segments: (popup.sharesAvailable ? popup.dynamicStreams() : []).map(function(stream) {return {value: popup.share(stream), color: stream.id === 0 ? "#347ff0" : "#a58bf5"}})
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: !popup.sharesAvailable ? qsTr("Shares unavailable") : popup.dynamicCount()>0 ? qsTr("Video %1: %2%").arg(popup.dynamicStreams()[0].id+1).arg(popup.share(popup.dynamicStreams()[0])) : qsTr("No active controllable encoders"); color: settings_form.primaryText; font.pixelSize: 13; font.bold: true; Layout.fillWidth: true }
                        Text { visible: popup.dynamicCount()>1 && popup.sharesAvailable; text: popup.dynamicCount()>1 ? qsTr("Video %1: %2%").arg(popup.dynamicStreams()[1].id+1).arg(popup.share(popup.dynamicStreams()[1])) : ""; color: settings_form.primaryText; font.pixelSize: 13; font.bold: true }
                    }
                    Slider {
                        id: slider
                        objectName: "allocationSlider0"
                        Layout.fillWidth: true; implicitHeight: 26
                        from: popup.dynamicCount() === 1 ? 0 : 10; to: popup.dynamicCount() === 1 ? 100 : 90; stepSize: 1
                        enabled: popup.dynamicCount()>1 && popup.canWrite && popup.hasPercent && popup.sharesAvailable
                        value: popup.dynamicCount() === 1 ? 100 : popup.draftPercent
                        onMoved: popup.draftPercent = Math.round(value)
                        onPressedChanged: if (!pressed && enabled) popup.commitShare()
                        Keys.onReleased: function(event) { if (enabled && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) popup.commitShare() }
                        background: Rectangle { x: slider.leftPadding; y: slider.topPadding + (slider.availableHeight-height)/2; width: slider.availableWidth; height: 18; radius: 9; color: "#263d50" }
                        handle: Rectangle { x: slider.leftPadding + slider.visualPosition * (slider.availableWidth-width); y: slider.topPadding + (slider.availableHeight-height)/2; width: 19; height: 19; radius: 10; color: slider.enabled ? "#edf4fa" : "#6f879d" }
                    }
                    GridLayout {
                        Layout.fillWidth: true; columns: 2; columnSpacing: 8
                        Repeater {
                            model: popup.dynamicStreams()
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 78
                                radius: 10; color: settings_form.panelBackground
                                Column {
                                    anchors.fill: parent; anchors.margins: 9; spacing: 5
                                    Text { text: qsTr("Video %1 budget • estimate").arg(modelData.id+1); color: settings_form.secondaryText; font.pixelSize: 11 }
                                    Text { text: popup.budgetsAvailable && popup.sharesAvailable ? popup.rate(Number(popup.allocation.pool_kbits) * popup.share(modelData) / 100) : "—"; color: settings_form.primaryText; font.pixelSize: popup.width < 440 ? 18 : 24; font.bold: true }
                                    Text { text: popup.budgetsAvailable ? qsTr("Applied %1 • measured %2").arg(popup.rate(modelData.budget_kbits)).arg(popup.measured(modelData.id+1)) : qsTr("Measured: %1").arg(popup.measured(modelData.id+1)); color: settings_form.secondaryText; font.pixelSize: 10 }
                                }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: qsTr("Total dynamic allocation"); color: settings_form.secondaryText; font.pixelSize: 11; Layout.fillWidth: true }
                        Text { text: popup.dynamicCount()>0 && popup.sharesAvailable ? "100%" : qsTr("Unavailable"); color: popup.dynamicCount()>0 ? "#35dc72" : settings_form.secondaryText; font.pixelSize: 13; font.bold: true }
                    }
                }
            }
            Repeater {
                model: popup.streams.filter(function(stream) {return stream.active && !stream.controllable})
                Text { Layout.fillWidth: true; text: qsTr("Video %1 • fixed stream • measured %2").arg(modelData.id+1).arg(popup.measured(modelData.id+1)); color: settings_form.secondaryText; font.pixelSize: 11 }
            }
            Text { Layout.fillWidth: true; text: qsTr("Shares divide only the dynamic pool. Encoder limits can leave unused capacity; minimum rates can cause overcommitment. Fixed streams are measured, not controlled."); color: settings_form.secondaryText; font.pixelSize: 10; wrapMode: Text.WordWrap }
        }
    }
}
