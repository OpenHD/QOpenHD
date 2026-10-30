import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Column {
    id: section
    objectName: "linkAllocationSection" + linkId
    spacing: 12
    readonly property int linkId: usage ? Number(usage.id) : 1
    readonly property string linkName: ["", "WiFiBroadcast", "Ethernet", "UART", "Microhard", "Artosyn", "FleetControl", "mLRS"][linkId] || qsTr("Link %1").arg(linkId)
    readonly property string linkIcon: linkId === 1 ? "\uf519" : linkId === 2 ? "\uf6ff" : linkId === 3 ? "\uf1e6" : "\uf0c1"
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
    readonly property bool dynamicEnabled: {
        revision
        return parameterModel && parameterModel.param_int_exists("VARIABLE_BITRATE")
            ? parameterModel.get_cached_int("VARIABLE_BITRATE") === 1 : !!allocation && !!allocation.enabled
    }
    readonly property bool customDataEnabled: {
        revision
        return linkId === 1 && parameterModel && parameterModel.param_int_exists("WB_UDP_ENABLE") && parameterModel.get_cached_int("WB_UDP_ENABLE") !== 0
    }
    readonly property bool budgetsAvailable: allocation && allocation.available && allocation.enabled
    readonly property bool connected: !!usage && _ohdSystemAir.is_alive && (linkId !== 2 ||
        Number(usage.rx_bps) > 0 || (usage.rtt_us !== undefined && usage.rtt_us !== null && Number(usage.rtt_us) >= 0))
    // The table displays measured transport traffic, so prefer its wire capacity.
    readonly property real capacityBps: usage && Number(usage.capacity_bps) > 0 ? Number(usage.capacity_bps)
        : budgetsAvailable && Number(allocation.capacity_kbits) > 0 ? Number(allocation.capacity_kbits) * 1000 : 0
    readonly property bool compact: width < 540
    readonly property real labelWidth: compact ? 116 : 222
    readonly property real totalWidth: compact ? 92 : 126
    function rateBps(value) {
        if (!isFinite(value) || value < 0) return qsTr("Not reported")
        if (value > 0 && value < 100000) return (value / 1000).toFixed(0) + " kbit/s"
        return (value / 1000000).toFixed(value === 0 ? 0 : 1) + " Mbit/s"
    }
    function categoryBps(id) {
        if (!usage || !usage.categories) return -1
        for (var i=0; i<usage.categories.length; i++)
            if (Number(usage.categories[i].id) === id) return Number(usage.categories[i].bps)
        return -1
    }
    function datalinkBps() {
        return categoryBps(7)
    }
    function cameraActive(id) {
        if (categoryBps(id + 1) > 0) return true
        for (var i=0; i<streams.length; i++) if (streams[i].id === id) return !!streams[i].active
        return false
    }
    readonly property var trafficRows: [
        {name: qsTr("Video 1"), icon: "\uf03d", color: "#198eff", tint: "#073e5a", bps: categoryBps(1), active: cameraActive(0), empty: qsTr("Not available")},
        {name: qsTr("Video 2"), icon: "\uf03d", color: "#23c3eb", tint: "#073e5a", bps: categoryBps(2), active: cameraActive(1), empty: qsTr("Not available")},
        {name: qsTr("Telemetry"), icon: "\uf121", color: "#ac58ee", tint: "#302450", bps: categoryBps(4), active: true, empty: qsTr("Not used")},
        // Wire-rate remainder: FEC, packet framing and retransmission overhead.
        {name: linkId === 1 ? qsTr("FEC") : qsTr("Transport overhead"), icon: "\uf3ed", color: "#35dc72", tint: "#0d403b", bps: categoryBps(5), active: true, empty: qsTr("Not used")},
        {name: qsTr("Audio"), icon: "\uf001", color: "#55c8dd", tint: "#193749", bps: categoryBps(3), active: true, empty: qsTr("Not used")},
        {name: qsTr("RC control"), icon: "\uf11b", color: "#ed72c6", tint: "#402440", bps: categoryBps(6), active: true, empty: qsTr("Not used")},
        {name: qsTr("Custom datalink"), icon: "\uf121", color: "#f4bb47", tint: "#40351d", bps: categoryBps(7), active: true, empty: qsTr("Not used")}
    ]
    function dynamicCount() { var count=0; for(var i=0;i<streams.length;i++) if(streams[i].active && streams[i].controllable) count++; return count }
    function dynamicStreams() {
        var result=[]
        for(var i=0;i<streams.length;i++) if(streams[i].active && streams[i].controllable) result.push(streams[i])
        return result
    }
    function share(stream) { return dynamicCount() === 1 ? 100 : stream.id === 0 ? draftPercent : 100-draftPercent }
    function controllableCamera(id) {
        for (var i=0; i<streams.length; i++)
            if (Number(streams[i].id) === id) return !!streams[i].active && !!streams[i].controllable
        var camera = id === 0 ? (typeof _cameraStreamModelPrimary !== "undefined" ? _cameraStreamModelPrimary : null)
                              : (typeof _cameraStreamModelSecondary !== "undefined" ? _cameraStreamModelSecondary : null)
        return !!camera && camera.supports_variable_bitrate
    }
    function cameraModel(id) {
        return id === 0 ? (typeof _airCameraSettingsModel !== "undefined" ? _airCameraSettingsModel : null)
                        : (typeof _airCameraSettingsModel2 !== "undefined" ? _airCameraSettingsModel2 : null)
    }
    function manualBitrateAvailable(id) {
        if (id > 1 || dynamicEnabled || !cameraActive(id) || !controllableCamera(id)) return false
        var model = cameraModel(id)
        if (!model) return false
        var unusedRevision = model.update_count
        if (!model.has_params_fetched || !model.param_int_exists("BITRATE_MBITS")) return false
        var metadata = model.get_ui_metadata("BITRATE_MBITS")
        return !metadata.readOnly && metadata.control !== "readonly" && metadata.control !== "unsupported"
    }
    function commitShare() {
        if (canWrite && dynamicEnabled && budgetsAvailable && hasPercent && sharesAvailable && dynamicCount()>1)
            parameterModel.try_set_param_int_async("V_PRIMARY_PERC", draftPercent, true)
    }
    function setCameraShare(id, value, commit) {
        if (!canWrite || !dynamicEnabled || !budgetsAvailable || !hasPercent || !sharesAvailable || dynamicCount()<2 || !controllableCamera(id)) return
        var percent = Math.max(10, Math.min(90, Math.round(value)))
        draftPercent = id === 0 ? percent : 100-percent
        if (commit) commitShare()
    }
            Rectangle {
                width: parent.width; height: 84; radius: 14; color: "#052334"; border.color: "#075477"
                RowLayout {
                    anchors.fill: parent; anchors.margins: 12; spacing: section.compact ? 12 : 18
                    Rectangle {
                        Layout.preferredWidth: 62; Layout.preferredHeight: 60; radius: 12; color: "#063c59"
                        Text { anchors.centerIn: parent; text: section.linkIcon; color: "#00b9ed"; font.family: "Font Awesome 5 Free"; font.pixelSize: MenuTypography.sectionIcon }
                    }
                    Column {
                        Layout.fillWidth: section.compact; Layout.preferredWidth: section.compact ? 100 : 148; spacing: 6
                        Text { text: section.linkName; color: "#edf4fa"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.body; font.bold: true }
                        Row {
                            spacing: 8
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 10; height: 10; radius: 5; color: section.connected ? "#35dc72" : "#7c98aa" }
                            Text { text: section.connected ? qsTr("Connected") : section.usage && _ohdSystemAir.is_alive ? qsTr("Reported") : qsTr("Disconnected"); color: "#adc8da"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.helper }
                        }
                    }
                    Rectangle { visible: !section.compact; Layout.preferredWidth: 1; Layout.preferredHeight: MenuTypography.controlHeight; color: "#123c52" }
                    Column {
                        Layout.fillWidth: !section.compact; spacing: 3
                        Text { objectName: "allocationCapacity"; text: section.capacityBps > 0 ? section.rateBps(section.capacityBps) : qsTr("Not reported"); color: "#edf4fa"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.sectionTitle; font.bold: true }
                        Text { text: qsTr("Available"); color: "#adc8da"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.helper }
                    }
                }
            }
            Rectangle {
                width: parent.width; height: tableContent.implicitHeight; radius: 14; color: "#031e2c"; border.color: "#10384c"; clip: true
                Column {
                    id: tableContent; width: parent.width; spacing: 0
                    RowLayout {
                        width: parent.width - 24; x: 12; height: 40; spacing: 12
                        Text { Layout.preferredWidth: section.labelWidth; text: qsTr("Stream"); color: "#adc8da"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.body }
                        Text { Layout.fillWidth: true; text: section.linkName; color: "#adc8da"; font.family: MenuTypography.family; font.pixelSize: section.compact ? MenuTypography.helper : MenuTypography.body }
                        Text { Layout.preferredWidth: section.totalWidth; text: qsTr("Total"); color: "#adc8da"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.body; horizontalAlignment: Text.AlignRight }
                    }
                    Repeater {
                        model: 7
                        delegate: Rectangle {
                            id: trafficRow
                            objectName: "allocationTrafficRow" + index
                            property var entry: section.trafficRows[index]
                            visible: index < 5 || entry.bps > 0 || (index === 6 && section.customDataEnabled)
                            readonly property bool shareControl: index < 2 && section.controllableCamera(index) && section.dynamicEnabled && section.budgetsAvailable && section.dynamicCount() > 1 && section.hasPercent && section.sharesAvailable
                            readonly property bool singleShare: index < 2 && section.controllableCamera(index) && section.dynamicEnabled && section.budgetsAvailable && section.dynamicCount() === 1
                            readonly property bool manualControl: index < 2 && section.manualBitrateAvailable(index)
                            width: tableContent.width; height: shareControl ? 89 : manualControl ? 113 : singleShare ? 76 : 53
                            color: index % 2 ? "#062535" : "transparent"
                            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: "#103347" }
                            RowLayout {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: 53; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 12
                                Row {
                                    Layout.preferredWidth: section.labelWidth; spacing: section.compact ? 8 : 16
                                    Rectangle {
                                        width: section.compact ? 30 : 44; height: 40; radius: 9
                                        color: trafficRow.entry.bps > 0 ? trafficRow.entry.tint : "#173343"
                                        Text { anchors.centerIn: parent; text: trafficRow.entry.icon; color: trafficRow.entry.bps > 0 ? trafficRow.entry.color : "#7799af"; font.family: "Font Awesome 5 Free"; font.pixelSize: section.compact ? MenuTypography.rowIcon : MenuTypography.sectionIcon }
                                    }
                                    Text { anchors.verticalCenter: parent.verticalCenter; width: section.labelWidth - (section.compact ? 38 : 60); wrapMode: Text.WordWrap; text: trafficRow.entry.name; color: trafficRow.entry.bps > 0 ? "#edf4fa" : "#adc8da"; font.family: MenuTypography.family; font.pixelSize: section.compact ? MenuTypography.helper : MenuTypography.body }
                                }
                                Rectangle {
                                    id: track; Layout.fillWidth: true; Layout.preferredHeight: 30; radius: 10; color: trafficRow.entry.bps > 0 ? "#113448" : "#072737"; clip: true
                                    Rectangle {
                                        objectName: "allocationTrafficFill" + index
                                        height: parent.height; radius: 9; color: trafficRow.entry.color
                                        width: trafficRow.entry.bps > 0 && section.capacityBps > 0 ? Math.min(parent.width, Math.max(3, parent.width * trafficRow.entry.bps / section.capacityBps)) : 0
                                    }
                                    Text {
                                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 6; verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: trafficRow.entry.bps > 0 ? Text.AlignHCenter : Text.AlignLeft
                                        text: trafficRow.entry.bps < 0 ? qsTr("Not reported") : !trafficRow.entry.active ? trafficRow.entry.empty : trafficRow.entry.bps === 0 ? trafficRow.entry.empty : section.rateBps(trafficRow.entry.bps)
                                        visible: !section.compact || trafficRow.entry.bps <= 0
                                        elide: Text.ElideRight; color: trafficRow.entry.bps > 0 ? "#edf4fa" : "#91b2c9"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.helper
                                    }
                                }
                                Text { objectName: "allocationTrafficTotal" + index; Layout.preferredWidth: section.totalWidth; text: section.rateBps(trafficRow.entry.bps); color: trafficRow.entry.bps > 0 ? "#edf4fa" : "#adc8da"; font.family: MenuTypography.family; font.pixelSize: section.compact ? MenuTypography.helper : MenuTypography.body; font.bold: trafficRow.entry.bps > 0; horizontalAlignment: Text.AlignRight }
                            }
                            RowLayout {
                                x: section.compact ? 12 : section.labelWidth + 24; y: 51
                                width: parent.width - x - 12; height: 30; spacing: 12
                                visible: trafficRow.shareControl
                                Slider {
                                    id: cameraShare
                                    objectName: "allocationSlider" + index
                                    Layout.fillWidth: true; implicitHeight: 28
                                    Accessible.name: qsTr("%1 dynamic share").arg(trafficRow.entry.name)
                                    from: section.dynamicCount() === 1 ? 0 : 10; to: section.dynamicCount() === 1 ? 100 : 90; stepSize: 1
                                    enabled: trafficRow.shareControl && section.canWrite
                                    value: section.dynamicCount() === 1 ? 100 : index === 0 ? section.draftPercent : 100-section.draftPercent
                                    onMoved: section.setCameraShare(index, value, false)
                                    onPressedChanged: if (!pressed && enabled) section.commitShare()
                                    Keys.onReleased: function(event) { if (enabled && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) section.commitShare() }
                                    background: Rectangle { x: cameraShare.leftPadding; y: cameraShare.topPadding + (cameraShare.availableHeight-height)/2; width: cameraShare.availableWidth; height: 6; radius: 3; color: "#143b50"; Rectangle { width: cameraShare.visualPosition*parent.width; height: parent.height; radius: 3; color: trafficRow.entry.color } }
                                    handle: Rectangle { x: cameraShare.leftPadding + cameraShare.visualPosition * (cameraShare.availableWidth-width); y: cameraShare.topPadding + (cameraShare.availableHeight-height)/2; width: 17; height: 17; radius: 9; color: cameraShare.enabled ? "#edf4fa" : "#6f879d" }
                                }
                                Text { Layout.preferredWidth: section.totalWidth; text: qsTr("Share: %1%").arg(index === 0 ? section.draftPercent : 100-section.draftPercent); color: "#adc8da"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.helper; horizontalAlignment: Text.AlignRight }
                            }
                            Text {
                                visible: trafficRow.singleShare
                                x: 12; y: 53; width: parent.width - 24
                                text: qsTr("Dynamic share: 100% (single camera)")
                                color: "#91b2c9"; font.family: MenuTypography.family; font.pixelSize: MenuTypography.helper
                            }
                            Loader {
                                active: trafficRow.manualControl; visible: active
                                x: 12; y: 53; width: parent.width - 24; height: 52
                                sourceComponent: Component {
                                    DynamicLinkSetting {
                                        objectName: "allocationBitrate" + index
                                        settingsModel: section.cameraModel(index); paramId: "BITRATE_MBITS"
                                        label: qsTr("Encoder bitrate"); valueSuffix: " Mbit/s"
                                        editorEnabled: section.canWrite && !settingsModel.ui_is_busy
                                        commitHandler: function(value) {
                                            var model = section.cameraModel(index)
                                            if (section.canWrite && section.manualBitrateAvailable(index) && !model.ui_is_busy)
                                                model.try_set_param_int_async("BITRATE_MBITS", value, true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
}
