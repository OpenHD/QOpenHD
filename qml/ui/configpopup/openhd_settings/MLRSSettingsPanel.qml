import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

ScrollView {
    id: root
    clip: true

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
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("REFRESH")
            onClicked: _mlrsController.refresh()
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
                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("mLRS power index. The actual mW/dBm depends on the transmitter hardware.")
                    }
                    Label { text: qsTr("Receiver step") }
                    SpinBox {
                        id: rxPower
                        from: 0
                        to: 15
                        editable: true
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
                    }
                    Label { text: qsTr("Band") }
                    ComboBox {
                        id: rfBand
                        model: ["2.4 GHz", "915 FCC", "868 MHz", "433 MHz", "70 cm", "866 India", "915 + 2.4", "868 + 2.4"]
                    }
                    Label { text: qsTr("Orthogonality") }
                    ComboBox {
                        id: rfOrtho
                        model: [qsTr("Off"), "1/3", "2/3", "3/3"]
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
                text: qsTr("APPLY")
                enabled: _mlrsController.alive && _mlrsController.parametersLoaded
                onClicked: _mlrsController.applySettings(txPower.value, rxPower.value,
                                                          mode.currentIndex, rfBand.currentIndex,
                                                          rfOrtho.currentIndex, bindPhrase.text)
            }
            Button {
                text: qsTr("SAVE TO RADIO")
                enabled: _mlrsController.alive && _mlrsController.parametersLoaded
                highlighted: true
                onClicked: _mlrsController.save()
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
