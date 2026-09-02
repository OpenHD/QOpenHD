import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Rectangle {
    id: root
    property var host
    property int cardIndex: -1
    property bool keyboardSelected: false
    radius: 10; color: settings_form.panelBackgroundRaised
    border.color: keyboardSelected ? settings_form.accentColor : settings_form.lineColor
    border.width: keyboardSelected ? 2 : 1
    function controls() { var list=[]; for(var i=0;i<settingRepeater.count;++i){var v=settingRepeater.itemAt(i);if(v&&v.visible&&v.focusControl)list.push(v.focusControl)} return list }
    function focusAndReveal(item) { if(!item)return; item.forceActiveFocus(); if(host)Qt.callLater(function(){host.ensureItemVisible(item)}) }
    function gainFocus() { var list=controls(); if(list.length) focusAndReveal(list[0]); else parent.parent.forceActiveFocus() }
    function moveFocus(step) { var list=controls(), current=-1; for(var i=0;i<list.length;++i)if(list[i].activeFocus)current=i; if(list.length)focusAndReveal(list[(current+step+list.length)%list.length]) }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 8; spacing: 7
        RowLayout { Layout.fillWidth: true; Layout.preferredHeight: 36; spacing: 8
            Text { text: "A"; color: "#9a76ff"; font.pixelSize: 18; font.bold: true }
            Text { text: qsTr("ArtoSyn Link 1"); color: settings_form.primaryText; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true }
            Rectangle { width: activeText.implicitWidth + 14; height: 21; radius: 7; color: Qt.rgba(0.1, 0.8, 0.35, 0.12)
                Text { id: activeText; anchors.centerIn: parent; text: qsTr("ACTIVE"); color: settings_form.goodColor; font.pixelSize: 8; font.bold: true }
            }
        }
        GridLayout { Layout.fillWidth: true; Layout.preferredHeight: 55; columns: 3; columnSpacing: 0
            Repeater { model: [
                {label: "MCS", value: String(_ohdSystemGround.artosyn_rx_mcs)},
                {label: qsTr("PHY RATE"), value: _ohdSystemGround.artosyn_tx_phy_rate_mbps + " Mbps"},
                {label: qsTr("RX RATE"), value: Math.round(_ohdSystemGround.artosyn_rx_rate_kbits / 100) / 10 + " Mbps"}]
                delegate: Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: settings_form.panelBackground; border.color: settings_form.lineColor
                    Column { anchors.centerIn: parent; spacing: 2
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: settings_form.secondaryText; font.pixelSize: 7; font.bold: true }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.value; color: settings_form.primaryText; font.pixelSize: 10; font.bold: true }
                    }
                }
            }
        }
        Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; radius: 7; color: settings_form.panelBackground; border.color: settings_form.lineColor
            Flickable { anchors.fill: parent; anchors.margins: 8; contentWidth: width; contentHeight: settingsGrid.implicitHeight; clip: true; ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }
                GridLayout { id: settingsGrid; width: parent.width; columns: 1; rowSpacing: 2
                    Repeater { id: settingRepeater
                        model: [{id:"AR_MCS_MD",label:qsTr("MCS mode")},{id:"AR_MCS_VAL",label:qsTr("Manual MCS")},{id:"AR_BW_MD",label:qsTr("Bandwidth mode")},{id:"AR_BW_VAL",label:qsTr("Manual bandwidth")},{id:"AR_CHN_MD",label:qsTr("Channel mode")},{id:"AR_CHN_IDX",label:qsTr("Manual channel")},{id:"AR_PWR_ATO",label:qsTr("Power control")},{id:"AR_PWR_DBM",label:qsTr("TX power"),suffix:" dBm"}]
                        delegate: DynamicLinkSetting { property var sourceModel: _ohdSystemAirSettingsModel.param_int_exists(modelData.id) ? _ohdSystemAirSettingsModel : _ohdSystemGroundSettings; Layout.fillWidth: true; visible: sourceModel.param_int_exists(modelData.id); settingsModel: sourceModel; paramId: modelData.id; label: modelData.label; valueSuffix: modelData.suffix||""; onMoveRequested: root.moveFocus(step); onBackRequested: if (root.host) root.host.collapseCard(root.cardIndex) }
                    }
                }
            }
        }
        RowLayout { Layout.fillWidth: true; Layout.preferredHeight: 25
            Text { Layout.fillWidth: true; text: qsTr("ArtoSyn parameters exposed by the active system"); color: settings_form.secondaryText; font.pixelSize: 7 }
            Rectangle { width: 7; height: 7; radius: 4; color: settings_form.goodColor }
        }
    }
}
