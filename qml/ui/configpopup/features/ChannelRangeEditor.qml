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
    Label { text: qsTr("Range behavior (µs)"); color: settings_form.secondaryText; font.pixelSize: Typography.helper }
    Row {
        width: parent.width; spacing: 0
        Repeater {
            model: root.ranges
            Rectangle {
                id: area
                objectName: "channelRange" + root.actionIndex + "_" + index
                readonly property int low: index === 0 ? 900 : root.ranges[index-1].upper+1
                readonly property int high: modelData.upper
                readonly property bool activeRange: root.live >= low && root.live <= high
                width: parent.width / root.ranges.length; height: 76; radius: 7
                color: activeRange ? (settings_form.darkMode ? "#006da6" : "#d2f0ff") : settings_form.panelBackground
                border.width: activeRange || (root.editable && root.selectedArea === index) ? 2 : 1
                border.color: activeRange ? "#16b9ef" : root.editable && root.selectedArea === index ? settings_form.accentColor : settings_form.lineColor
                Behavior on color { ColorAnimation { duration: 140 } }
                Column {
                    anchors.centerIn: parent; width: parent.width - 6; spacing: 7
                    Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: area.low + "–" + area.high; color: settings_form.primaryText; font.family: Typography.family; font.pixelSize: root.width < 400 && root.ranges.length > 3 ? 9 : 12 }
                    Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: root.label(modelData.value); color: settings_form.primaryText; font.family: Typography.family; font.pixelSize: root.width < 400 ? 11 : Typography.helper; font.bold: area.activeRange }
                }
                MouseArea { anchors.fill: parent; enabled: root.editable; cursorShape: Qt.PointingHandCursor; onClicked: root.selectedArea = index }
                Rectangle { visible: index > 0; z: 2; x: -4; anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: settings_form.darkMode ? "#e9f8ff" : settings_form.accentColor }
                Accessible.role: Accessible.Button
                Accessible.name: root.label(modelData.value) + ", " + area.low + "–" + area.high + " µs"
                Accessible.onPressAction: if (root.editable) root.selectedArea = index
                activeFocusOnTab: root.editable
                Keys.onSpacePressed: root.selectedArea = index
                Keys.onReturnPressed: root.selectedArea = index
            }
        }
    }
    Column {
        visible: root.editable; width: parent.width; spacing: 10
        Label { text: qsTr("Area %1").arg(root.selectedArea+1); color: settings_form.secondaryText; font.pixelSize: Typography.helper }
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
