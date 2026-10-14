#include <QtTest>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQuickItem>
#include <QQuickWindow>
#include <QQuickRenderControl>
#include <QDir>
#include <QFontDatabase>
#include <QApplication>
#include "../app/telemetry/settings/pollutionhelper.h"

class ChannelSurveyTest : public QObject {
    Q_OBJECT
private slots:
    void interferenceWithoutPackets() {
        PollutionHelper helper;
        PollutionHelper::PollutionElement noisy{}, quiet{}, missing{};
        noisy.frequency_mhz = 5745;
        quiet.frequency_mhz = 5785;
        missing.frequency_mhz = 5825;
        PollutionHelper::decode_survey_metrics(noisy, 0xc000 | (85 << 7) | 73);
        PollutionHelper::decode_survey_metrics(quiet, 0xc000);
        PollutionHelper::decode_survey_metrics(missing, 0);
        helper.threadsafe_update({noisy, quiet, missing});
        const QList<int> frequencies{5745, 5785, 5825, 5865};
        QCOMPARE(helper.survey_values(frequencies, 0), QVariantList({85, 0, -1, -1}));
        QCOMPARE(helper.survey_values(frequencies, 1), QVariantList({73, 0, -1, -1}));
        QCOMPARE(helper.survey_values(frequencies, 2), QVariantList({0, 0, 0, -1}));
        QVERIFY(helper.survey_labels(frequencies, 0)[2].contains("N/A"));
        QVERIFY(!helper.survey_labels(frequencies, 0)[1].contains("N/A"));
        PollutionHelper::decode_survey_metrics(noisy, 0xc000 | (127 << 7) | 101);
        QCOMPARE(noisy.nhm_env_percent, -1);
        QCOMPARE(noisy.busy_percent, -1);
        PollutionHelper::decode_survey_metrics(noisy, 0x3fff);
        QCOMPARE(noisy.n_foreign_packets, -1);
        QCOMPARE(noisy.n_foreign_packets_normalized, -1);
    }

    void packetCountsStaySeparate() {
        PollutionHelper helper;
        PollutionHelper::PollutionElement a{}, b{};
        a.frequency_mhz = 5745; a.n_foreign_packets = 10;
        b.frequency_mhz = 5785; b.n_foreign_packets = 20;
        PollutionHelper::decode_survey_metrics(a, 0x8000 | (80 << 7));
        PollutionHelper::decode_survey_metrics(b, 0x8000 | (10 << 7));
        helper.threadsafe_update({a, b});
        const QList<int> frequencies{5745, 5785};
        QCOMPARE(helper.survey_values(frequencies, 0), QVariantList({80, 10}));
        QCOMPARE(helper.survey_values(frequencies, 2), QVariantList({10, 20}));
        QCOMPARE(helper.survey_values(frequencies, 3), QVariantList({50, 100}));
    }

    void renderActualPopup() {
        const int fontId = QFontDatabase::addApplicationFont(":/qml/Archivo-Regular.ttf");
        QVERIFY(fontId >= 0);
        QApplication::setFont(QFont(QFontDatabase::applicationFontFamilies(fontId).first()));
        qmlRegisterModule("OpenHD", 1, 0);
        PollutionHelper helper;
        std::vector<PollutionHelper::PollutionElement> samples;
        for (int i = 0; i < 7; ++i) {
            PollutionHelper::PollutionElement sample{};
            sample.frequency_mhz = 5745 + i * 20;
            sample.n_foreign_packets = i * 3;
            PollutionHelper::decode_survey_metrics(sample,
                i == 5 ? 0 : 0xc000 | ((i * 15) << 7) | (i * 11));
            samples.push_back(sample);
        }
        helper.threadsafe_update(samples);
        QQmlEngine engine;
        engine.rootContext()->setContextProperty("_pollutionHelper", &helper);
        const QString panelDir = "qrc:/qml/ui/configpopup/openhd_settings";
        const QByteArray harness = (
            "import QtQuick 2.12\nimport '" + panelDir + "' as Panels\n"
            "Item { width: 1004; height: 620; "
            "property var settings_form: QtObject { property bool darkMode: true; "
            "property color accentColor: '#278cff'; property color primaryText: '#f2f6fb'; "
            "property color secondaryText: '#aebdcb'; property color panelBackground: '#102235'; "
            "property color panelBackgroundRaised: '#15283b'; property color lineColor: '#33485d'; "
            "property color errorColor: '#e75f68' } "
            "property var _ohdSystemGround: QtObject { property bool is_alive: true; property int wb_gnd_operating_mode: 0 } "
            "property var _wbLinkSettingsHelper: QtObject { property int analyze_progress_perc: 100; "
            "property int current_analyze_frequency: -1; function start_analyze_channels(i) { return false; } } "
            "property var _frequencyHelper: QtObject { function get_frequencies(i) { return [5745,5765,5785,5805,5825,5845,5865]; } } "
            "property var _qopenhd: QtObject { function show_toast(s) {} } "
            "Panels.PopupAnalyzeChannels { objectName: 'surveyPopup' } }").toUtf8();
        QQmlComponent component(&engine);
        component.setData(harness, QUrl());
        QVERIFY2(component.isReady(), qPrintable(component.errorString()));
        std::unique_ptr<QObject> object(component.create());
        QVERIFY2(object != nullptr, qPrintable(component.errorString()));
        auto* item = qobject_cast<QQuickItem*>(object.get());
        QVERIFY(item);
        auto* popup = object->findChild<QObject*>("surveyPopup");
        QVERIFY(popup);
        QVERIFY(QMetaObject::invokeMethod(popup, "open"));
        QQuickRenderControl renderer;
        QQuickWindow window(&renderer);
        item->setParentItem(window.contentItem());
        for (const QSize size : {QSize(1004, 620), QSize(430, 728)}) {
            window.setGeometry(0, 0, size.width(), size.height());
            item->setWidth(size.width()); item->setHeight(size.height());
            renderer.initialize(nullptr);
            QTest::qWait(250);
            renderer.polishItems(); renderer.sync(); renderer.render();
            const auto image = renderer.grab();
            QVERIFY(!image.isNull());
            QVERIFY(image.save(QCoreApplication::applicationDirPath() +
                QString("/survey-%1.png").arg(size.width())));
        }
    }
};
QTEST_MAIN(ChannelSurveyTest)
#include "channel_survey_test.moc"
