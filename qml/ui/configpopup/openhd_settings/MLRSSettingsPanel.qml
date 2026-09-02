import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

ScrollView {
    id: root
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AlwaysOff
    Material.theme: settings_form.darkMode ? Material.Dark : Material.Light
    Material.accent: settings_form.accentColor
    Material.foreground: settings_form.primaryText
    Material.background: settings_form.panelBackgroundRaised

    signal backRequested()
    signal focusItemRequested(var item)

    function reveal(item) {
        if (!item) return
        var flick = root.contentItem
        if (flick && flick.contentItem) {
            var point = item.mapToItem(flick.contentItem, 0, 0)
            var margin = 10
            var top = point.y - margin
            var bottom = point.y + item.height + margin
            if (top < flick.contentY)
                flick.contentY = Math.max(0, top)
            else if (bottom > flick.contentY + flick.height)
                flick.contentY = Math.min(Math.max(0, flick.contentHeight - flick.height), bottom - flick.height)
        }
        focusItemRequested(item)
    }

    function focusAndReveal(item) {
        item.forceActiveFocus()
        Qt.callLater(function() { reveal(item) })
    }

    function gainFocus() { focusAndReveal(refreshButton) }

    function controls() {
        return [refreshButton, txPower, rxPower, mode, rfBand, rfOrtho,
                bindPhrase, applyButton, saveButton]
    }

    function moveFocus(current, step) {
        var list = controls()
        var index = list.indexOf(current)
        var next = index + step
        if (next < 0) {
            backRequested()
            return
        }
        next = Math.min(next, list.length - 1)
        focusAndReveal(list[next])
    }

    function handleKeys(event, control) {
        if (event.key === Qt.Key_Down) {
            moveFocus(control, 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            moveFocus(control, -1)
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            backRequested()
            event.accepted = true
        }
    }

    function syncFromRadio() {
        if (!_mlrsController.parametersLoaded)
            return
        txPower.value = Math.max(0, _mlrsController.txPower)
        rxPower.value = Math.max(0, _mlrsController.rxPower)
        mode.currentIndex = Math.max(0, _mlrsController.mode)
        rfBand.currentIndex = Math.max(0, _mlrsController.rfBand)
        rfOrtho.currentIndex = Math.max(0, _mlrsController.rfOrtho)
        bindPhrase.text = _mlrsController.bindPhrase
    }

    Connections {
        target: _mlrsController
        function onParametersLoadedChanged() { root.syncFromRadio() }
        function onParametersChanged() {
            if (!txPower.activeFocus && !rxPower.activeFocus && !bindPhrase.activeFocus)
                root.syncFromRadio()
        }
    }

    Component.onCompleted: {
        root.syncFromRadio()
        if (_mlrsController.alive && !_mlrsController.parametersLoaded)
            _mlrsController.refresh()
    }

    ColumnLayout {
        width: Math.min(root.availableWidth, 760)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 14

        Item { Layout.preferredHeight: 8 }

        Label {
            Layout.fillWidth: true
            text: qsTr("mLRS TELEMETRY RADIO")
            horizontalAlignment: Text.AlignHCenter
            font.bold: true
            font.pixelSize: 22
        }

        Label {
            Layout.fillWidth: true
            text: _mlrsController.statusText
            horizontalAlignment: Text.AlignHCenter
            color: _mlrsController.alive ? Material.accent : Material.color(Material.Red)
            wrapMode: Text.WordWrap
        }

        Button {
            id: refreshButton
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("REFRESH")
            onClicked: _mlrsController.refresh()
            Keys.onPressed: root.handleKeys(event, refreshButton)
        }

        GridLayout {
            Layout.fillWidth: true
            columns: root.availableWidth > 600 ? 2 : 1
            columnSpacing: 28
            rowSpacing: 12
            enabled: _mlrsController.alive && _mlrsController.parametersLoaded

            GroupBox {
                title: qsTr("POWER")
                Layout.fillWidth: true
                GridLayout {
                    anchors.fill: parent
                    columns: 2
                    Label { text: qsTr("Transmitter step") }
                    SpinBox {
                        id: txPower
                        from: 0
                        to: 15
                        editable: true
                        Keys.onPressed: root.handleKeys(event, txPower)
                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("mLRS power index. The actual mW/dBm depends on the transmitter hardware.")
                    }
                    Label { text: qsTr("Receiver step") }
                    SpinBox {
                        id: rxPower
                        from: 0
                        to: 15
                        editable: true
                        Keys.onPressed: root.handleKeys(event, rxPower)
                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("mLRS power index. The actual mW/dBm depends on the receiver hardware.")
                    }
                }
            }

            GroupBox {
                title: qsTr("RF LINK")
                Layout.fillWidth: true
                GridLayout {
                    anchors.fill: parent
                    columns: 2
                    Label { text: qsTr("Mode") }
                    ComboBox {
                        id: mode
                        model: ["50 Hz", "31 Hz", "19 Hz", "FLRC", "FSK", "19 Hz 7x"]
                        Keys.onPressed: root.handleKeys(event, mode)
                    }
                    Label { text: qsTr("Band") }
                    ComboBox {
                        id: rfBand
                        model: ["2.4 GHz", "915 FCC", "868 MHz", "433 MHz", "70 cm", "866 India", "915 + 2.4", "868 + 2.4"]
                        Keys.onPressed: root.handleKeys(event, rfBand)
                    }
                    Label { text: qsTr("Orthogonality") }
                    ComboBox {
                        id: rfOrtho
                        model: [qsTr("Off"), "1/3", "2/3", "3/3"]
                        Keys.onPressed: root.handleKeys(event, rfOrtho)
                    }
                }
            }
        }

        GroupBox {
            title: qsTr("PAIRING")
            Layout.fillWidth: true
            enabled: _mlrsController.alive && _mlrsController.parametersLoaded
            ColumnLayout {
                anchors.fill: parent
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: qsTr("Bind phrase") }
                    TextField {
                        id: bindPhrase
                        Layout.fillWidth: true
                        maximumLength: 6
                        placeholderText: "xxxxxx"
                        Keys.onPressed: root.handleKeys(event, bindPhrase)
                    }
                }
                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: qsTr("The phrase is written to the connected Tx and, after Save, its linked Rx. Stock mLRS still requires entering bind mode on both devices using their button, CLI, Lua or display; its Tx MAVLink component has no bind command yet.")
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            Button {
                id: applyButton
                text: qsTr("APPLY")
                enabled: _mlrsController.alive && _mlrsController.parametersLoaded
                onClicked: _mlrsController.applySettings(txPower.value, rxPower.value,
                                                          mode.currentIndex, rfBand.currentIndex,
                                                          rfOrtho.currentIndex, bindPhrase.text)
                Keys.onPressed: root.handleKeys(event, applyButton)
            }
            Button {
                id: saveButton
                text: qsTr("SAVE TO RADIO")
                enabled: _mlrsController.alive && _mlrsController.parametersLoaded
                highlighted: true
                onClicked: _mlrsController.save()
                Keys.onPressed: root.handleKeys(event, saveButton)
            }
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Keep Tx Mav Component enabled in mLRS. Apply changes first, verify the returned values, then Save. Unsupported choices are clamped by the radio firmware.")
        }
        Item { Layout.preferredHeight: 16 }
    }
}
