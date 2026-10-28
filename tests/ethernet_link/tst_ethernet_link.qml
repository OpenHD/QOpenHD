import QtQuick 2.12
import QtQuick.Controls 2.12
import QtTest 1.2
import "../../qml/ui/configpopup/openhd_settings" as Cards
Item {
    id: scene
    width: 720; height: 420
    property bool captureImages: false
    FontLoader { source: "../../qml/resources/Font Awesome 5 Free-Solid-900.otf" }
    FontLoader { source: "../../qml/osdfonts/Archivo-Regular.ttf" }
    Component.onCompleted: Qt.application.font = Qt.font({family:"Archivo",pixelSize:13})
    QtObject { id: settings; property bool dev_simulate_ethernet_link: false; property bool dev_simulate_uart_link: false; property bool dev_show_advanced_button: true }
    QtObject { id: settings_form; property color panelBackgroundRaised:"#15283b";property color panelBackground:"#102235";property color lineColor:"#26394c";property color accentColor:"#278cff";property color primaryText:"#f2f6fb";property color secondaryText:"#aebdcb";property color goodColor:"#35dc72" }
    QtObject { id: _ohdSystemGround; property bool is_alive:true }
    QtObject { id: _ohdSystemGroundSettings;property int update_count:0;property bool ui_is_busy:false;function param_int_exists(id) {return false} function get_cached_int(id) {return 1} }
    QtObject {
        id: fakeHost
        property bool bothMultiEnabled:false;property bool bothSingleEnabled:false
        property var usage: ({id:2,total_bps:12300000,capacity_bps:1000000000,tx_bps:12300000,rx_bps:64000,tx_pps:1400,rx_pps:55,rtt_us:2200,jitter_us:300,probe_loss_permille:5,send_errors:2,categories:[]})
        function usageFor(kind) {return usage} function wifiActive() {return false} function collapseCard(index) {}
    }
    Cards.SimulatedLinkCard { id: card; width: parent.width; height: implicitHeight; host: fakeHost }
    TestCase {
        name:"EthernetLinkCard";when:windowShown
        function test_metrics_and_unavailable_values() {
            compare(card.bitrate("tx_bps"),"12.30 Mbit/s")
            verify(card.implicitHeight < scene.height)
            if (scene.captureImages) { wait(100);grabImage(scene).save("build/status-layout-full/ethernet-card.png") }
            compare(card.metric("rtt_us",1000," ms",1),"2.2 ms")
            compare(card.metric("probe_loss_permille",10," %",1),"0.5 %")
            fakeHost.usage={id:2,total_bps:0,capacity_bps:0,categories:[]}
            compare(card.bitrate("tx_bps"),"N/A")
            fakeHost.usage={id:2,tx_bps:0,rtt_us:null,categories:[]}
            compare(card.bitrate("tx_bps"),"0.00 Mbit/s")
            compare(card.metric("rtt_us",1000," ms",1),"N/A")
            fakeHost.usage=null;compare(card.bitrate("rx_bps"),"N/A")
            card.gainFocus();verify(card.activeFocus)
        }
    }
}
