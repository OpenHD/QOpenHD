import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12

Item {
    id: root
    implicitHeight: allocationControls ? allocationContent.implicitHeight : usageContent.implicitHeight
    property var usage: null
    property bool allocationControls: false
    signal allocationRequested()
    readonly property var allocationSettings: typeof _ohdSystemAirSettingsModel !== "undefined" ? _ohdSystemAirSettingsModel : null
    readonly property int allocationRevision: allocationSettings ? allocationSettings.update_count : 0
    readonly property bool dynamicEnabled: { allocationRevision; return allocationSettings && allocationSettings.param_int_exists("VARIABLE_BITRATE") && allocationSettings.get_cached_int("VARIABLE_BITRATE") === 1 }
    property string title: qsTr("Link Usage")
    readonly property real total: usage ? Number(usage.total_bps) : 0
    readonly property real capacity: usage ? Number(usage.capacity_bps) : 0
    // Never rescale an overloaded link to make it appear below capacity.
    readonly property real barDenominator: capacity > 0 ? capacity : Math.max(1, total)
    readonly property var allocation: usage && usage.allocation ? usage.allocation : null
    readonly property bool allocationAvailable: allocation && allocation.available && allocation.enabled
    readonly property real allocationCapacity: allocationAvailable ? Number(allocation.capacity_kbits) : 0
    readonly property real priorityReservation: allocationAvailable ? Number(allocation.priority_kbits) + Number(allocation.safety_kbits) : 0
    readonly property real fixedReservation: allocationAvailable ? Number(allocation.fixed_kbits) : 0
    readonly property real dynamicPool: allocationAvailable ? Number(allocation.pool_kbits) : 0
    readonly property int fixedPercent: allocationCapacity > 0 ? Math.min(100, Math.max(0, Math.round((priorityReservation + fixedReservation) * 100 / allocationCapacity))) : 0
    readonly property int dynamicPercent: allocationCapacity > 0 ? 100 - fixedPercent : 0

    function labelFor(id) {
        if (id === 1) return qsTr("Cam 1")
        if (id === 2) return qsTr("Cam 2")
        if (id === 3) return qsTr("Audio")
        if (id === 4) return qsTr("Telemetry")
        if (id === 5) return usage && Number(usage.id) === 1 ? qsTr("FEC") : qsTr("Overhead")
        if (id === 7) return qsTr("Custom data")
        if (id === 6) return qsTr("RC control")
        return qsTr("Type %1").arg(id)
    }
    function iconFor(id) {
        if (id === 1 || id === 2) return "\uf030"
        if (id === 3) return "\uf028"
        if (id === 4) return "\uf1eb"
        if (id === 6) return "\uf11b"
        if (id === 7) return "\uf121"
        return "\uf141"
    }
    function colorFor(id) {
        if (id === 1) return "#198eff"
        if (id === 2) return "#23c3eb"
        if (id === 3) return "#55c8dd"
        if (id === 4) return "#ac58ee"
        if (id === 6) return "#ed72c6"
        if (id === 5) return "#35dc72"
        if (id === 7) return "#f4bb47"
        return "#91aac5"
    }
    function rate(value) {
        if (value >= 1000000) return (value / 1000000).toFixed(1) + " Mbit/s"
        if (value >= 1000) return (value / 1000).toFixed(1) + " kbit/s"
        return Number(value).toFixed(0) + " bit/s"
    }
    function compactUsage(value) {
        if (capacity <= 0) return rate(value)
        var percent = Math.max(0, Math.min(100, Number(value) * 100 / capacity))
        if (percent > 0 && percent < 0.1) return "<0.1%"
        return percent.toFixed(1).replace(/\.0$/, "") + "%"
    }
    function segments() {
        if (!usage || !usage.categories) return []
        var result = []
        for (var i = 0; i < usage.categories.length; ++i) {
            var item = usage.categories[i]
            if (Number(item.bps) > 0) result.push(item)
        }
        return result
    }

    ColumnLayout {
        id: allocationContent
        visible: root.allocationControls
        width: parent.width
        spacing: 8
        RowLayout {
            Layout.fillWidth: true
            Text { text: qsTr("Link Usage"); color: settings_form.primaryText; font.pixelSize: MenuTypography.sectionTitle; font.family: MenuTypography.family; font.bold: true; Layout.fillWidth: true }
            Switch {
                id: allocationSwitch
                objectName: "dynamicLinkBitrateSwitch"
                text: qsTr("Dynamic Link Bitrate")
                enabled: root.allocationSettings && _ohdSystemAir.is_alive && !_qopenhd.debugMenuPreview && root.allocationSettings.has_params_fetched && !root.allocationSettings.ui_is_busy && root.allocationSettings.param_int_exists("VARIABLE_BITRATE")
                onClicked: root.allocationSettings.try_set_param_int_async("VARIABLE_BITRATE", checked ? 1 : 0, true)
                font.pixelSize: MenuTypography.body
                contentItem: Text { text: parent.text; font: parent.font; color: settings_form.primaryText; leftPadding: parent.indicator.width + parent.spacing; verticalAlignment: Text.AlignVCenter }
            }
            Binding { target: allocationSwitch; property: "checked"; value: root.dynamicEnabled }
        }
        Rectangle {
            id: allocationTrack
            objectName: "linkAllocationTrack"
            Layout.fillWidth: true; Layout.preferredHeight: root.usage ? 24 : 10
            radius: 8; color: "#294154"; clip: true
            LinkSegmentsBar {
                anchors.fill: parent
                objectName: "linkUsageSegments"
                denominator: root.barDenominator
                segments: root.segments().map(function(item) {return {value: Number(item.bps), color: root.colorFor(Number(item.id))}})
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.allocationRequested() }
        }
        Flow {
            Layout.fillWidth: true
            spacing: 14
            Repeater {
                model: root.segments().filter(function(item) {
                    return Number(item.id) !== 6 || root.capacity <= 0 || Number(item.bps) * 100 / root.capacity >= 0.1
                })
                delegate: Row {
                    spacing: 6
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 9; height: 9; radius: 3; color: root.colorFor(Number(modelData.id)) }
                    Text {
                        objectName: "linkUsagePercent" + modelData.id
                        text: root.labelFor(Number(modelData.id)) + " " + root.compactUsage(Number(modelData.bps))
                        color: settings_form.secondaryText; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
                    }
                }
            }
        }
        Text {
            visible: !root.usage || root.capacity <= 0
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: root.usage ? qsTr("Link capacity not reported.") : qsTr("Waiting for link telemetry.")
            color: settings_form.secondaryText
            font.pixelSize: MenuTypography.helper; font.family: MenuTypography.family
        }
        Text {
            visible: !!root.allocation && !!root.allocation.enabled && !!root.allocation.overcommitted
            Layout.fillWidth: true; wrapMode: Text.WordWrap
            text: qsTr("Overcommitted — display capped at 100%. Encoder minimums or fixed traffic exceed capacity.")
            color: settings_form.errorColor; font.pixelSize: MenuTypography.body; font.family: MenuTypography.family
        }

    }

    Column {
        id: usageContent
        visible: !root.allocationControls
        width: parent.width
        spacing: 6
        RowLayout {
            width: parent.width
            height: root.allocationControls ? 34 : 18
            Text { text: root.title; color: settings_form.primaryText; font.pixelSize: MenuTypography.sectionTitle; font.family: MenuTypography.family; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
            Text {
                visible: !root.allocationControls
                text: root.usage ? root.rate(root.total) + (root.capacity > 0 ? " / " + root.rate(root.capacity) : "") : qsTr("Waiting for telemetry")
                color: settings_form.secondaryText; font.pixelSize: MenuTypography.helper; font.family: MenuTypography.family; font.bold: true
            }
            Rectangle {
                visible: !root.allocationControls
                Layout.preferredWidth: 42; Layout.preferredHeight: 22; radius: 6
                color: "#163955"; border.color: "#31516c"
                Text { anchors.centerIn: parent; text: root.usage && root.capacity > 0 ? Math.min(100, Math.max(0, Math.round(root.total * 100 / root.capacity))) + "%" : "N/A"; color: "#e7f2ff"; font.pixelSize: MenuTypography.helper; font.family: MenuTypography.family; font.bold: true }
            }
        }
        Text {
            visible: root.allocationControls
            text: root.usage ? root.rate(root.total) + (root.capacity > 0 ? " / " + root.rate(root.capacity) : "") + " " + qsTr("measured traffic / radio estimate") : qsTr("Waiting for telemetry")
            color: settings_form.secondaryText; font.pixelSize: MenuTypography.helper; font.family: MenuTypography.family
            width: parent.width; elide: Text.ElideRight
        }
        Rectangle {
            id: track
            width: parent.width; height: 13; radius: 6
            color: "#294761"; border.color: "#45627b"; border.width: 1
            clip: true
            MouseArea { anchors.fill: parent; enabled: root.allocationControls; cursorShape: Qt.PointingHandCursor; onClicked: root.allocationRequested() }
            Row {
                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                Repeater {
                    model: root.segments()
                    delegate: Rectangle {
                        width: Math.max(0, (track.width - 2) * Number(modelData.bps) / root.barDenominator)
                        height: track.height
                        color: root.colorFor(Number(modelData.id))
                    }
                }
            }
        }
        Flow {
            id: legend
            width: parent.width
            height: childrenRect.height
            spacing: 7
            Repeater {
                model: root.segments()
                delegate: Row {
                    spacing: 3
                    Text { text: root.iconFor(Number(modelData.id)); color: root.colorFor(Number(modelData.id)); font.family: "Font Awesome 5 Free"; font.pixelSize: 9 }
                    Text { text: root.labelFor(Number(modelData.id)) + " " + root.rate(Number(modelData.bps)); color: settings_form.secondaryText; font.pixelSize: MenuTypography.helper; font.family: MenuTypography.family }
                }
            }
        }

    }
}
