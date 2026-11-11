import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12
import ".."
import "../openhd_settings"
import "../MenuTypography.js" as Typography
import "RcRanges.js" as Ranges

Column {
    id: root
    objectName: "channelRangeEditor" + actionIndex
    Material.theme: settings_form.darkMode ? Material.Dark : Material.Light
    Material.accent: settings_form.accentColor
    Material.foreground: settings_form.primaryText
    property var ranges: []
    property var options: []
    property bool editable: false
    property int live: -1
    property int actionIndex: 0
    property int selectedArea: 0
    signal edited(var next)
    signal resetRequested()
    spacing: 12
    onRangesChanged: selectedArea = Math.min(selectedArea, Math.max(0, ranges.length-1))
    function label(value) {
        for (var i=0; i<options.length; ++i) if (options[i].value === value) return options[i].text
        return "—"
    }
    function optionIndex(value) {
        for (var i=0; i<options.length; ++i) if (options[i].value === value) return i
        return -1
    }
    readonly property bool liveValid: live >= 800 && live <= 2200
    readonly property int liveArea: live >= 900 && live <= 2100
        ? ranges.findIndex(function(range) { return live <= range.upper }) : -1

    RowLayout {
        width: parent.width
        Label {
            Layout.fillWidth: true
            text: qsTr("PWM ranges")
            color: settings_form.secondaryText
            font.pixelSize: Typography.helper
        }
        Label {
            objectName: "channelLiveRange" + root.actionIndex
            text: !root.liveValid ? qsTr("No RC signal")
                : root.liveArea < 0 ? qsTr("%1 µs · Outside range").arg(root.live)
                : qsTr("%1 µs · %2").arg(root.live).arg(root.label(root.ranges[root.liveArea].value))
            color: root.liveValid ? settings_form.accentColor : settings_form.secondaryText
            font.pixelSize: Typography.helper
            font.bold: root.liveValid
        }
    }
    Column {
        width: parent.width
        spacing: 4
        Item {
            id: track
            objectName: "channelRangeTrack" + root.actionIndex
            width: parent.width
            height: 72

            function xForPwm(pwm) {
                return width * Math.max(0, Math.min(1, (pwm - 900) / 1200))
            }

            function splitX(index) {
                return index >= root.ranges.length - 1 ? width : xForPwm(root.ranges[index].upper + 0.5)
            }

            Repeater {
                model: root.ranges.length
                Rectangle {
                    id: area
                    objectName: "channelRange" + root.actionIndex + "_" + index
                    readonly property var range: root.ranges[index] || { upper: 2100, value: -1 }
                    readonly property int low: root.ranges[index-1] ? root.ranges[index-1].upper + 1 : 900
                    readonly property int high: range.upper
                    readonly property bool activeRange: root.liveArea === index
                    readonly property bool selected: root.editable && root.selectedArea === index
                    x: index === 0 ? 0 : track.splitX(index - 1)
                    width: Math.max(0, track.splitX(index) - x)
                    height: parent.height
                    radius: Math.min(6, width / 2)
                    clip: true
                    color: activeRange ? (settings_form.darkMode ? "#006da6" : "#d2f0ff")
                        : selected ? settings_form.panelBackgroundRaised : settings_form.panelBackground
                    border.width: activeRange || selected ? 2 : 1
                    border.color: activeRange ? "#16b9ef" : selected ? settings_form.accentColor : settings_form.lineColor
                    Column {
                        anchors.centerIn: parent
                        width: Math.max(0, parent.width - 16)
                        spacing: 4
                        Label {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: root.label(area.range.value)
                            color: settings_form.primaryText
                            font.family: Typography.family
                            font.pixelSize: Typography.helper
                            font.bold: area.activeRange || area.selected
                        }
                        Label {
                            width: parent.width
                            visible: width >= implicitWidth
                            horizontalAlignment: Text.AlignHCenter
                            text: area.low + "–" + area.high
                            color: settings_form.primaryText
                            font.pixelSize: 11
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: root.editable
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedArea = index
                    }
                    Accessible.role: Accessible.Button
                    Accessible.name: root.label(area.range.value) + ", " + area.low + "–" + area.high + " µs"
                    Accessible.onPressAction: if (root.editable) root.selectedArea = index
                    activeFocusOnTab: root.editable
                    Keys.onSpacePressed: root.selectedArea = index
                    Keys.onReturnPressed: root.selectedArea = index
                }
            }
            Rectangle {
                objectName: "channelLiveMarker" + root.actionIndex
                visible: root.liveValid
                z: 1
                width: 3
                height: parent.height
                x: Math.max(0, Math.min(parent.width - width, track.xForPwm(root.live) - width / 2))
                radius: 1
                color: settings_form.darkMode ? "#effaff" : "#134568"
            }
            Repeater {
                model: Math.max(0, root.ranges.length - 1)
                MouseArea {
                    id: handle
                    objectName: "channelRangeHandle" + root.actionIndex + "_" + index
                    property real pressOffset: 0
                    visible: root.editable
                    enabled: root.editable
                    x: track.splitX(index) - width / 2
                    width: 24
                    height: track.height
                    z: pressed ? 3 : 2
                    preventStealing: true
                    hoverEnabled: true
                    cursorShape: Qt.SizeHorCursor
                    onPressed: function(mouse) {
                        pressOffset = mapToItem(track, mouse.x, mouse.y).x - track.splitX(index)
                        root.selectedArea = index
                    }
                    onPositionChanged: function(mouse) {
                        if (!pressed || track.width <= 0) return
                        var position = mapToItem(track, mouse.x, mouse.y).x - pressOffset
                        var next = Ranges.setBoundary(root.ranges, index, 900 + 1200 * position / track.width - 0.5)
                        if (next[index].upper !== root.ranges[index].upper) root.edited(next)
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 8
                        height: 30
                        radius: 4
                        color: handle.pressed || handle.containsMouse ? settings_form.accentColor
                            : settings_form.darkMode ? "#d9ebf7" : "#52728a"
                        border.color: settings_form.panelBackground
                    }
                }
            }
        }
        RowLayout {
            width: parent.width
            Label { text: "900 µs"; color: settings_form.secondaryText; font.pixelSize: Typography.helper }
            Item { Layout.fillWidth: true }
            Label { text: "1500"; color: settings_form.secondaryText; font.pixelSize: Typography.helper }
            Item { Layout.fillWidth: true }
            Label { text: "2100 µs"; color: settings_form.secondaryText; font.pixelSize: Typography.helper }
        }
    }
    Column {
        visible: root.editable; width: parent.width; spacing: 10
        Label { text: qsTr("Area %1 · %2–%3 µs").arg(root.selectedArea + 1)
            .arg(root.selectedArea === 0 ? 900 : root.ranges[root.selectedArea - 1].upper + 1)
            .arg(root.ranges.length ? root.ranges[root.selectedArea].upper : 2100); color: settings_form.secondaryText; font.pixelSize: Typography.helper }
        RowLayout {
            width: parent.width; spacing: 10
            CompactLinkComboBox {
                objectName: "rangeValue" + root.actionIndex
                Layout.fillWidth: true; Layout.minimumWidth: 0; popupWidth: width
                model: root.options; textRole: "text"
                currentIndex: root.ranges.length ? root.optionIndex(root.ranges[root.selectedArea].value) : -1
                onActivated: root.edited(Ranges.setValue(root.ranges, root.selectedArea, root.options[currentIndex].value))
            }
            Label { text: qsTr("Ends at"); color: settings_form.secondaryText; font.pixelSize: Typography.helper }
            SpinBox {
                objectName: "rangeBoundary" + root.actionIndex
                Layout.preferredWidth: 120; implicitHeight: 34
                from: root.selectedArea === 0 ? 900 : root.ranges[root.selectedArea-1].upper+1
                to: root.selectedArea < root.ranges.length-1 ? root.ranges[root.selectedArea+1].upper-1 : 2100
                value: root.ranges.length ? root.ranges[root.selectedArea].upper : 2100
                enabled: root.selectedArea < root.ranges.length-1
                editable: true
                textFromValue: function(value) { return value.toString() }
                valueFromText: function(text) { return Number(text) }
                onValueModified: root.edited(Ranges.setBoundary(root.ranges, root.selectedArea, value))
                Accessible.name: qsTr("Inclusive upper PWM boundary in µs")
            }
        }
        Flow {
            width: parent.width; spacing: 8
            AdvancedActionButton {
                objectName: "rangeAdd" + root.actionIndex; text: qsTr("+ Area")
                enabled: root.ranges.length < 5 && root.ranges.length > 0 && root.ranges[root.selectedArea].upper > (root.selectedArea === 0 ? 900 : root.ranges[root.selectedArea-1].upper+1)
                onClicked: {
                    var current = root.ranges[root.selectedArea].value
                    var next = root.options[(root.optionIndex(current)+1)%root.options.length].value
                    root.edited(Ranges.split(root.ranges, root.selectedArea, next))
                    root.selectedArea++
                }
            }
            AdvancedActionButton { objectName: "rangeRemove" + root.actionIndex; text: qsTr("Remove area"); enabled: root.ranges.length > 1; onClicked: root.edited(Ranges.remove(root.ranges, root.selectedArea)) }
            AdvancedActionButton { objectName: "rangeReset" + root.actionIndex; text: qsTr("Defaults"); onClicked: root.resetRequested() }
        }
    }
}
