import QtQuick 2.12
import QtQuick.Layouts 1.12

Item {
    id: root
    property var usage: null
    property string title: qsTr("Link Usage")
    readonly property real total: usage ? Number(usage.total_bps) : 0
    readonly property real capacity: usage ? Number(usage.capacity_bps) : 0
    readonly property real barDenominator: Math.max(1, capacity, total)

    function labelFor(id) {
        if (id === 1) return qsTr("Cam 1")
        if (id === 2) return qsTr("Cam 2")
        if (id === 3) return qsTr("Audio")
        if (id === 4) return qsTr("Telemetry")
        if (id === 5) return qsTr("Other")
        if (id === 6) return qsTr("Control")
        return qsTr("Type %1").arg(id)
    }
    function iconFor(id) {
        if (id === 1 || id === 2) return "\uf030"
        if (id === 3) return "\uf028"
        if (id === 4) return "\uf1eb"
        if (id === 6) return "\uf11b"
        return "\uf141"
    }
    function colorFor(id) {
        if (id === 1) return "#299fff"
        if (id === 2) return "#34dba0"
        if (id === 3) return "#ffad32"
        if (id === 4) return "#a967e8"
        if (id === 6) return "#d08cff"
        return "#91aac5"
    }
    function rate(value) {
        if (value >= 1000000) return (value / 1000000).toFixed(1) + " Mbit/s"
        if (value >= 1000) return (value / 1000).toFixed(1) + " kbit/s"
        return Number(value).toFixed(0) + " bit/s"
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

    Column {
        anchors.fill: parent
        spacing: 6
        RowLayout {
            width: parent.width
            height: 18
            Text { text: root.title; color: settings_form.primaryText; font.pixelSize: 10; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
            Text {
                text: root.usage ? root.rate(root.total) + (root.capacity > 0 ? " / " + root.rate(root.capacity) : "") : qsTr("Waiting for telemetry")
                color: settings_form.secondaryText; font.pixelSize: 9; font.bold: true
            }
            Rectangle {
                Layout.preferredWidth: 42; Layout.preferredHeight: 22; radius: 6
                color: "#163955"; border.color: "#31516c"
                Text { anchors.centerIn: parent; text: root.usage && root.capacity > 0 ? Math.round(root.total * 100 / root.capacity) + "%" : "N/A"; color: "#e7f2ff"; font.pixelSize: 10; font.bold: true }
            }
        }
        Rectangle {
            id: track
            width: parent.width; height: 13; radius: 6
            color: "#294761"; border.color: "#45627b"; border.width: 1
            clip: true
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
                    Text { text: root.labelFor(Number(modelData.id)) + " " + root.rate(Number(modelData.bps)); color: settings_form.secondaryText; font.pixelSize: 8 }
                }
            }
        }
    }
}
