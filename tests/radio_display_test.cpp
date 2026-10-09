#include <QtTest>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQuickRenderControl>
#include <QQuickWindow>
#include <QFontDatabase>
#include <QQuickItem>
#include <QFile>
#include "../app/telemetry/models/temperaturestate.h"

// Exercise the actual widget bindings with fresh/stale telemetry, and render
// its temperature/loss rows without requiring radio hardware or a video feed.
class RadioDisplayTest : public QObject {
    Q_OBJECT
    QByteArray widget;
    QByteArray function(const QByteArray& name) {
        const int start = widget.indexOf("    function " + name + "(");
        const int end = widget.indexOf("\n    }", start);
        return start < 0 || end < 0 ? QByteArray() : widget.mid(start, end + 6 - start);
    }
    QByteArray row(const QByteArray& marker) {
        const int pos = widget.indexOf(marker);
        const int start = widget.lastIndexOf("            Item {", pos);
        const int end = widget.indexOf("            Item {", pos);
        return pos < 0 || start < 0 || end < 0 ? QByteArray() : widget.mid(start, end - start);
    }
private slots:
    void audioControls() {
        QFile source(QFINDTESTDATA("../qml/ui/configpopup/features/FeatureSettingsPanel.qml"));
        QVERIFY(source.open(QIODevice::ReadOnly));
        QByteArray panel = source.readAll();
        const int props = panel.indexOf("    property bool audioAvailable:");
        const int propsEnd = panel.indexOf("    property bool devourerLoggingAvailable:", props);
        const int setter = panel.indexOf("    function setAirInt(");
        const int setterEnd = panel.indexOf("    function setAirString(", setter);
        const int controls = panel.lastIndexOf("                            RowLayout {", panel.indexOf("Stream audio from air unit"));
        const int controlsEnd = panel.indexOf("                            Label {", panel.indexOf("id: audioMode", controls));
        QVERIFY(props >= 0 && setter >= 0 && controls >= 0 && controlsEnd > controls);
        QByteArray rows = panel.mid(controls, controlsEnd - controls);
        rows.replace("CompactLinkComboBox", "ComboBox");
        QQmlEngine engine;
        QQmlComponent component(&engine);
        component.setData("import QtQuick 2.12\nimport QtQuick.Controls 2.12\nimport QtQuick.Layouts 1.12\n"
            "Item { id: root; width: 700; height: 160; property int airRevision: _ohdSystemAirSettingsModel.update_count; "
            "property var settings_form: ({primaryText: 'white'}); "
            "property var _hudLogMessagesModel: QtObject { function signalAddLogMessage(level, text) {} } "
            "property var _ohdSystemAirSettingsModel: QtObject { property int update_count: 0; property int mode: 101; "
            "property bool available: true; property bool example: true; property int usbCount: -1; property int captureCount: 0; "
            "function param_int_exists(id) { return available && (id === 'AUDIO_ENABLE' || (id === 'AUDIO_EXAMPLE' && example) || id === 'AUDIO_USB_COUNT' || id === 'AUDIO_DEV_COUNT'); } "
            "function get_cached_int(id) { return id === 'AUDIO_ENABLE' ? mode : (id === 'AUDIO_USB_COUNT' ? usbCount : (id === 'AUDIO_DEV_COUNT' ? captureCount : 1)); } "
            "function param_string_exists(id) { return id === 'AUD_USB_NAMES'; } function get_cached_string(id) { return 'USB Headset'; } "
            "function try_update_parameter_int(id, value) { mode = value; update_count++; return ''; } } "
            + panel.mid(props, propsEnd - props) + panel.mid(setter, setterEnd - setter)
            + "ColumnLayout { anchors.fill: parent; " + rows + "} }", QUrl());
        QVERIFY2(component.isReady(), qPrintable(component.errorString()));
        QScopedPointer<QObject> root(component.create());
        QVERIFY(root);
        auto* toggle = root->findChild<QObject*>("audioStreamingSwitch");
        auto* selector = root->findChild<QObject*>("audioSourceSelector");
        auto* model = root->property("_ohdSystemAirSettingsModel").value<QObject*>();
        QVERIFY(toggle && selector && model);
        QVERIFY(root->property("usbAudioStatus").toString().contains("unavailable"));
        model->setProperty("usbCount", 0);
        model->setProperty("update_count", 1);
        QVERIFY(root->property("usbAudioStatus").toString().contains("No USB audio device"));
        QVERIFY(root->property("captureAudioStatus").toString().contains("No microphone input"));
        model->setProperty("usbCount", 1);
        model->setProperty("captureCount", 2);
        model->setProperty("update_count", 2);
        QCOMPARE(root->property("usbAudioStatus").toString(), QString("USB audio detected: USB Headset"));
        QCOMPARE(root->property("captureAudioStatus").toString(), QString("Microphone inputs detected: 2"));
        QCOMPARE(toggle->property("checked").toBool(), true);
        QCOMPARE(selector->property("currentIndex").toInt(), 1);
        toggle->setProperty("checked", false);
        QVERIFY(QMetaObject::invokeMethod(toggle, "toggled"));
        QCOMPARE(model->property("mode").toInt(), 1);
        toggle->setProperty("checked", true);
        QVERIFY(QMetaObject::invokeMethod(toggle, "toggled"));
        QCOMPARE(model->property("mode").toInt(), 101);
        toggle->setProperty("checked", false);
        QVERIFY(QMetaObject::invokeMethod(toggle, "toggled"));
        QVERIFY(QMetaObject::invokeMethod(selector, "activated", Q_ARG(int, 0)));
        QCOMPARE(model->property("mode").toInt(), 1); // Choosing a source while off stays off.
        toggle->setProperty("checked", true);
        QVERIFY(QMetaObject::invokeMethod(toggle, "toggled"));
        QCOMPARE(model->property("mode").toInt(), 0);
        QVERIFY(QMetaObject::invokeMethod(selector, "activated", Q_ARG(int, 1)));
        QCOMPARE(model->property("mode").toInt(), 101);
        QVERIFY(QMetaObject::invokeMethod(selector, "activated", Q_ARG(int, 2)));
        QCOMPARE(model->property("mode").toInt(), 100);
        model->setProperty("example", false);
        model->setProperty("update_count", 20);
        QCOMPARE(selector->property("count").toInt(), 2);
        model->setProperty("available", false);
        model->setProperty("update_count", 21);
        QCOMPARE(toggle->property("enabled").toBool(), false);
    }
    void microphoneDevices() {
        QFile source(QFINDTESTDATA("../qml/ui/configpopup/features/FeatureSettingsPanel.qml"));
        QVERIFY(source.open(QIODevice::ReadOnly));
        const auto panel = source.readAll();
        const int start = panel.indexOf("                                CompactLinkComboBox {", panel.indexOf("Label { text: qsTr(\"Microphone\")"));
        const int end = panel.indexOf("                                Button {", start);
        QVERIFY(start >= 0 && end > start);
        QByteArray control = panel.mid(start, end - start);
        control.replace("CompactLinkComboBox", "ComboBox");
        QQmlEngine engine;
        QQmlComponent component(&engine);
        component.setData("import QtQuick 2.12\nimport QtQuick.Controls 2.12\nimport QtQuick.Layouts 1.12\n"
            "Item { id: root; width: 700; property bool audioAvailable: true; "
            "property var audioMode: ({currentIndex: 0}); "
            "property var _ohdSystemAirSettingsModel: QtObject { property int update_count: 0; "
            "property string selected: ''; property var devices: []; "
            "function param_string_exists(id) { return id === 'AUDIO_DEVICE' || devices[Number(id.substring(8))] !== undefined; } "
            "function get_cached_string(id) { return id === 'AUDIO_DEVICE' ? selected : devices[Number(id.substring(8))]; } } "
            "function setAirString(id, value) { _ohdSystemAirSettingsModel.selected = value; _ohdSystemAirSettingsModel.update_count++; } "
            + control + "}", QUrl());
        QVERIFY2(component.isReady(), qPrintable(component.errorString()));
        QScopedPointer<QObject> root(component.create());
        QVERIFY(root);
        auto* selector = root->findChild<QObject*>("audioMicrophoneSelector");
        auto* model = root->property("_ohdSystemAirSettingsModel").value<QObject*>();
        QVERIFY(selector && model);
        QCOMPARE(selector->property("count").toInt(), 1);
        model->setProperty("devices", QStringList{"alsasrc:plughw:2,0|USB microphone", "alsasrc:plughw:3,1|Headset"});
        model->setProperty("update_count", 1);
        QCOMPARE(selector->property("count").toInt(), 3);
        QCOMPARE(selector->property("model").toStringList().at(1), QString("USB microphone"));
        QVERIFY(QMetaObject::invokeMethod(selector, "activated", Q_ARG(int, 2)));
        QCOMPARE(model->property("selected").toString(), QString("alsasrc:plughw:3,1"));
        QCOMPARE(selector->property("currentIndex").toInt(), 2);
        QVERIFY(QMetaObject::invokeMethod(selector, "activated", Q_ARG(int, 0)));
        QCOMPARE(model->property("selected").toString(), QString());
        model->setProperty("devices", QStringList{});
        model->setProperty("update_count", 4);
        QCOMPARE(selector->property("count").toInt(), 1);
        QCOMPARE(selector->property("currentIndex").toInt(), 0);
    }
    void initTestCase() {
        QFile source(QFINDTESTDATA("../qml/ui/widgets/LinkOverviewWidget.qml"));
        QVERIFY(source.open(QIODevice::ReadOnly));
        widget = source.readAll();
        QVERIFY(QFontDatabase::addApplicationFont(QFINDTESTDATA("../qml/osdfonts/Quicksand-Regular.ttf")) >= 0);
        QVERIFY(QFontDatabase::addApplicationFont(QFINDTESTDATA("../qml/osdfonts/Quicksand-Bold.ttf")) >= 0);
    }
    void temperature() {
        using namespace TemperatureTelemetry;
        QCOMPARE(displayCelsius(0), QString("N/A"));
        QCOMPARE(displayCelsius(-128), QString("N/A"));
        QCOMPARE(displayCelsius(38), QString::fromUtf8("38\u00b0C"));
        QCOMPARE(displayDevourer(false, 8), QString("N/A"));
        QCOMPARE(displayDevourer(true, -8), QString("Normal"));
        QCOMPARE(displayDevourer(true, 7), QString("Normal"));
        QCOMPARE(displayDevourer(true, 8), QString("Warm"));
        QCOMPARE(displayDevourer(true, 14), QString("Warm"));
        QCOMPARE(displayDevourer(true, 15), QString("Hot"));
        QCOMPARE(displayDevourer(true, 24), QString("Hot"));
        QCOMPARE(displayDevourer(true, 25), QString("Overheating"));
    }
    void lossAndRender() {
        QQmlEngine engine;
        QQmlComponent component(&engine);
        const QByteArray qml = "import QtQuick 2.12\nRectangle { width: 320; height: 110; color: \"black\"; "
            "property var _ohdSystemGround: QtObject { property bool is_alive: true; property int current_rx_rssi: -55 }\n"
            "property int m_packet_loss_perc: 7; property string m_rx_temperature_text: \"38\u00b0C\"; "
            "property string m_tx_temperature_text: \"Normal\"; "
            "property string linkFont: \"Quicksand\"; property int detailPanelFontPixels: 20; "
            + function("clamp") + function("get_rx_loss_text") + function("get_dbm_text") + function("get_primary_link_text")
            + "Column { anchors.fill: parent; spacing: 6; "
            + row("text: qsTr(\"RX temperature:") + row("text: qsTr(\"TX temperature:")
            + row("text: qsTr(\"RX packet loss:") + "} }";
        component.setData(qml, QUrl());
        QVERIFY2(component.isReady(), qPrintable(component.errorString()));
        auto* item = qobject_cast<QQuickItem*>(component.create());
        QVERIFY(item);
        const auto loss = [item]() {
            QVariant result;
            QMetaObject::invokeMethod(item, "get_rx_loss_text", Q_RETURN_ARG(QVariant, result));
            return result.toString();
        };
        QCOMPARE(loss(), QString("7%"));
        QVariant compactText;
        QVERIFY(QMetaObject::invokeMethod(item, "get_primary_link_text", Q_RETURN_ARG(QVariant, compactText)));
        QVERIFY(compactText.toString().contains("7%"));
        QVERIFY(!compactText.toString().contains("COLD"));
        item->setProperty("m_packet_loss_perc", -1);
        QCOMPARE(loss(), QString("N/A"));
        item->setProperty("m_packet_loss_perc", 125);
        QCOMPARE(loss(), QString("100%"));
        auto* ground = item->property("_ohdSystemGround").value<QObject*>();
        QVERIFY(ground);
        ground->setProperty("is_alive", false);
        QCOMPARE(loss(), QString("N/A"));
        ground->setProperty("is_alive", true);
        item->setProperty("m_packet_loss_perc", 7);
        QQuickRenderControl renderer;
        QQuickWindow window(&renderer);
        window.setGeometry(0, 0, 320, 110);
        item->setParentItem(window.contentItem());
        renderer.initialize(nullptr);
        QTest::qWait(100);
        renderer.polishItems();
        renderer.sync();
        renderer.render();
        QCoreApplication::processEvents();
        renderer.polishItems();
        renderer.sync();
        renderer.render();
        const QImage image = renderer.grab();
        QVERIFY(!image.isNull());
        QVERIFY(image.save(QCoreApplication::applicationDirPath() + "/radio-display-preview.png"));
    }
};
QTEST_MAIN(RadioDisplayTest)
#include "radio_display_test.moc"
