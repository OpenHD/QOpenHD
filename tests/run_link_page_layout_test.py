"""Check the production Link page scroll geometry with deterministic transport cards."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

TEST = '''import QtQuick 2.12
import QtTest 1.2
Item {
    id: scene; width: 850; height: 300
    QtObject { id: _qopenhd; property bool debugMenuPreview: false }
    QtObject {
        id: settings_form
        property bool darkMode: true
        property bool showDeveloperSettings: true
        property color accentColor: "#278cff"
        property color primaryText: "white"
        property color secondaryText: "#aebdcb"
        property color panelBackgroundRaised: "#15283b"
        property color panelBackground: "#102235"
        property color lineColor: "#26394c"
        property color errorColor: "red"
        function side_bar_regain_focus() {}
    }
    QtObject {
        id: settings
        property bool dev_show_link_routing: false
        property bool dev_show_link_usage: true
        property bool dev_simulate_wifibroadcast_link: false
        property bool dev_simulate_ethernet_link: false
        property bool dev_simulate_uart_link: false
        property int qopenhd_frequency_filter_selection: 0
    }
    QtObject {
        id: _ohdSystemAir
        property bool is_alive: false
        property int primary_link_type: 0
        property int microhard_enabled: 0
        property bool artosyn_link_detected: false
        property int curr_channel_mhz: 5805
        property var link_usage: []
        property bool fleetcontrol_lte_active: false
        property int fleetcontrol_lte_max_kbit: 0
    }
    property var _ohdSystemGround: _ohdSystemAir
    QtObject { id: _wifi_card_air; property bool alive: true; property string card_type_as_string: "RTL" }
    property var _wifi_card_gnd0: _wifi_card_air
    QtObject { id: _mlrsController; property bool alive: false }
    QtObject {
        id: _ohdSystemAirSettingsModel
        property int update_count: 0
        property bool has_params_fetched: false
        property bool ui_is_busy: false
        function param_int_exists(id) { return id === "WFB_LINK_EN" }
        function get_cached_int(id) { return 0 }
    }
    property var _ohdSystemGroundSettings: _ohdSystemAirSettingsModel
    QtObject { id: _wbLinkSettingsHelper; property int ui_rebuild_models: 0; property int curr_channel_mhz: 5805 }
    QtObject { id: _frequencyHelper; function get_frequencies(filter) { return [5805] } function get_frequency_description(value) { return String(value) } }
    LinkQuickPanel { id: page; anchors.fill: parent }
    TestCase {
        name: "LinkPageLayout"; when: windowShown
        function test_developer_link_visibility() {
            settings_form.showDeveloperSettings=false
            _qopenhd.debugMenuPreview=true
            settings.dev_show_link_routing=true
            wait(30)
            compare(page.linkVisible("ethernet"),true)
            compare(page.linkVisible("wifi"),true)
            var kinds=["uart","microhard","artosyn","mlrs","fleetcontrol"]
            for(var i=0;i<kinds.length;i++) compare(page.linkVisible(kinds[i]),false,kinds[i])
            compare(findChild(page,"linkRoutingSection").visible,false)
            var cards=findChild(page,"linkTransportCards")
            compare(cards.children[0].loadedCard.objectName,"testWifiBroadcastLinkCard")
            settings_form.showDeveloperSettings=true
            wait(30)
            compare(findChild(page,"linkRoutingSection").visible,true)
            for(var j=0;j<kinds.length;j++) compare(page.linkVisible(kinds[j]),true,kinds[j])
            _qopenhd.debugMenuPreview=false
            settings.dev_show_link_routing=false
        }
        function test_normal_wifibroadcast_usage() {
            settings_form.showDeveloperSettings=false
            _qopenhd.debugMenuPreview=false
            _ohdSystemAir.link_usage=[{id:1,total_bps:1000000,capacity_bps:40000000,categories:[]}]
            wait(60)
            var cards=findChild(page,"linkTransportCards")
            compare(cards.children[0].loadedCard.objectName,"testWifiBroadcastLinkCard")
            compare(findChild(page,"totalLinkUsageSection").visible,true)
            compare(page.visibleReportedUsage.length,1)
            compare(page.visibleReportedUsage[0].id,1)
            settings_form.showDeveloperSettings=true
        }
        function test_scroll_geometry_data() {
            return [{tag:"normal-offline",w:750,h:300,live:false},
                    {tag:"normal-live",w:750,h:300,live:true},
                    {tag:"wide",w:1024,h:480,live:true},
                    {tag:"narrow",w:420,h:500,live:false}]
        }
        function test_scroll_geometry(data) {
            scene.width=data.w; scene.height=data.h
            _ohdSystemAir.link_usage=data.live ? [{id:1,total_bps:1000000,capacity_bps:40000000,categories:[]}] : []
            wait(220)
            var scroll=findChild(page,"linkPageScroll")
            var cards=findChild(page,"linkTransportCards")
            var usage=findChild(page,"totalLinkUsageSection")
            verify(scroll !== null && cards !== null && usage !== null)
            verify(scroll.height >= scene.height-20, "Usage must not consume a separate fixed viewport")
            verify(cards.height >= 650, "Transport controls must retain their full height")
            verify(usage.y >= cards.y+cards.height, "Usage must follow, never cover, transport controls")
            verify(scroll.contentHeight >= usage.y+usage.height, "Usage must be reachable by scrolling")
            verify(usage.height < 260, "Offline and live summaries must remain compact")
            scroll.contentY=scroll.contentHeight-scroll.height
            wait(220)
            var bottom=usage.mapToItem(scroll,0,usage.height).y
            verify(bottom <= scroll.height+1 && bottom > 0, "Allocation controls must be visible at scroll end")
        }
    }
}
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--qt-bin", type=Path, required=True)
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="qopenhd-link-layout-") as temp:
        folder = Path(temp)
        source = ROOT / "qml/ui/configpopup/openhd_settings"
        for name in ("LinkQuickPanel", "LinkUsageMeter", "LinkSegmentsBar", "LinkAllocationPopup", "LinkAllocationSection"):
            content = (source / (name + ".qml")).read_text(encoding="utf-8")
            (folder / (name + ".qml")).write_text(content.replace('../MenuTypography.js', 'MenuTypography.js'), encoding="utf-8")
        shutil.copy(source.parent / "MenuTypography.js", folder)
        shutil.copy(source.parent / "AdvancedActionButton.qml", folder)
        (folder / "DynamicLinkSetting.qml").write_text("import QtQuick 2.12\nItem {property var settingsModel;property string paramId;property string label;property string valueSuffix;property bool editorEnabled;property var commitHandler}\n", encoding="utf-8")
        # Keep the real scrolling/Flow/Loader hierarchy; replace backend-heavy
        # card contents with a tall deterministic card that reproduces clipping.
        stub = '''import QtQuick 2.12
Item {
    implicitHeight: 650
    property var host
    property int cardIndex: 0
    property bool keyboardSelected: false
    property string linkKind
    function gainFocus() {}
    function animateScan() {}
}
'''
        for name in ("WifiBroadcastLinkCard", "SimulatedLinkCard", "MicrohardLinkCard", "ArtosynLinkCard", "MLRSLinkCard", "FleetControlLinkCard"):
            (folder / (name + ".qml")).write_text(stub.replace("implicitHeight: 650", 'objectName: "test' + name + '"; implicitHeight: 650'), encoding="utf-8")
        for name in ("PopupScanChannels", "PopupAnalyzeChannels", "DialoqueFreqChangeGndOnly", "DialoqueFreqChangeAirGnd"):
            (folder / (name + ".qml")).write_text("import QtQuick.Controls 2.12\nPopup {}\n", encoding="utf-8")
        module = folder / "OpenHD"
        module.mkdir()
        (module / "qmldir").write_text("module OpenHD\nDummy 1.0 Dummy.qml\n")
        (module / "Dummy.qml").write_text("import QtQuick 2.12\nQtObject {}\n")
        (folder / "tst_layout.qml").write_text(TEST, encoding="utf-8")
        env = os.environ.copy()
        env.update(QT_QUICK_BACKEND="software", QT_QUICK_CONTROLS_STYLE="Basic",
                   QT_FORCE_STDERR_LOGGING="1",
                   QML_DISABLE_DISK_CACHE="1",
                   QML2_IMPORT_PATH=str(args.qt_bin.parent / "qml"),
                   QT_QPA_PLATFORM_PLUGIN_PATH=str(args.qt_bin.parent / "plugins/platforms"))
        return subprocess.run([str(args.qt_bin / "qmltestrunner.exe"), "-input", str(folder), "-import", str(folder)], env=env).returncode


if __name__ == "__main__":
    raise SystemExit(main())
