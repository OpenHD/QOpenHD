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
#include <QJsonObject>
#include <QJsonArray>
#include <QtCharts/QChart>
#include "../app/telemetry/settings/frequencyhelper.h"
#include "../app/telemetry/settings/pollutionhelper.h"

// Standalone metadata fixture: the normal selector may intersect Air/Ground;
// a receiver survey must use the Ground list alone.
static QJsonObject groundFrequencyMetadata, airFrequencyMetadata;
namespace DocumentedParam {
bool has_device_metadata(int sys, int) {
    return !(sys == 100 ? groundFrequencyMetadata : airFrequencyMetadata).isEmpty();
}
QJsonObject metadata(const std::string&, int sys, int) {
    return sys == 100 ? groundFrequencyMetadata : airFrequencyMetadata;
}
}

class ChannelSurveyTest : public QObject {
    Q_OBJECT
private slots:
    void analysisFollowsGroundCapabilities() {
        FrequencyHelper helper;
        const std::vector<uint16_t> supported{2412,5080,5180,5200,5745,5885,6085};
        helper.set_hw_supported_frequencies_threadsafe(supported);
        QJsonArray choices;
        for (const auto frequency : supported) choices.append(QJsonObject{{"value",frequency}});
        groundFrequencyMetadata = QJsonObject{{"choices",choices}};
        airFrequencyMetadata = QJsonObject{{"choices",QJsonArray{QJsonObject{{"value",5180}}}}};
        const QList<int> all5g{5080,5180,5200,5745,5885,6085};
        QCOMPARE(helper.get_analyze_frequencies(2), all5g);
        QCOMPARE(helper.get_analyze_frequencies(1), QList<int>({2412}));
        QCOMPARE(helper.get_frequencies(2), QList<int>({5180}));
        groundFrequencyMetadata = {}; airFrequencyMetadata = {};
        QCOMPARE(helper.get_analyze_frequencies(2), all5g);
    }
    void selectableChannelsIncludeAll2gPrimaries() {
        FrequencyHelper helper;
        QJsonArray choices;
        QList<int> expected;
        for (int i = 0; i < 13; ++i) expected.append(2412 + i * 5);
        expected.append(2484);
        for (const auto frequency : expected) choices.append(QJsonObject{{"value",frequency}});
        choices.append(QJsonObject{{"value",5080}});
        choices.append(QJsonObject{{"value",6085}});
        groundFrequencyMetadata = QJsonObject{{"choices",choices}};
        airFrequencyMetadata = groundFrequencyMetadata;
        QCOMPARE(helper.get_analyze_frequencies(1), expected);
        QCOMPARE(helper.get_frequencies(1), expected);
        QCOMPARE(helper.get_frequencies(2), QList<int>({5080,6085}));
        QVERIFY(helper.get_frequency_description(2417).contains("2417"));
        groundFrequencyMetadata = {}; airFrequencyMetadata = {};
    }
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
        QVERIFY(helper.survey_labels(frequencies, 0)[2].contains("Unavailable"));
        QCOMPARE(helper.survey_labels(frequencies, 0)[1], QString("5785 MHz"));
        QVERIFY(helper.survey_labels(frequencies, 0)[3].contains("Not scanned"));
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

    void failedAndQuietPacketBins() {
        PollutionHelper helper;
        PollutionHelper::PollutionElement quiet{}, failed{};
        quiet.frequency_mhz = 5745;
        failed.frequency_mhz = 5785;
        PollutionHelper::decode_survey_metrics(failed, 0x3fff);
        helper.threadsafe_update({quiet, failed});
        QCOMPARE(helper.survey_values({5745,5785,5825}, 3), QVariantList({0,-1,-1}));
        QVERIFY(helper.survey_labels({5745,5785}, 3)[1].contains("Unavailable"));
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
            "property bool analyze_request_pending: false; property int analyze_results_revision: 0; property int analyzed_channel_count: 7; property int current_analyze_frequency: -1; property int requestedProfile: -1; function start_analyze_channels(i, profile) { requestedProfile = profile; return true; } } "
            "property var _frequencyHelper: QtObject { function get_analyze_frequencies(i) { return [5745,5765,5785,5805,5825,5845,5865]; } } "
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
        auto* metric = object->findChild<QObject*>("surveyMetric");
        auto* chart = object->findChild<QObject*>("surveyChart");
        QVERIFY(metric); QVERIFY(chart);
        QCOMPARE(chart->property("animationOptions").toInt(), int(QtCharts::QChart::NoAnimation));
        QCOMPARE(metric->property("currentIndex").toInt(), 0);
        QCOMPARE(chart->property("measuredChannels").toInt(), 6);
        // A new result must refresh an already open popup, without reopening
        // it or changing the selected metric.
        helper.threadsafe_update({samples.front()});
        auto* link = qvariant_cast<QObject*>(object->property("_wbLinkSettingsHelper"));
        QVERIFY(link);
        auto* duration = object->findChild<QObject*>("surveyDuration");
        QVERIFY(duration);
        QCOMPARE(duration->property("count").toInt(), 3);
        QCOMPARE(duration->property("currentIndex").toInt(), 1);
        for (int profile = 0; profile < 3; ++profile) {
            duration->setProperty("currentIndex", profile);
            QVERIFY(QMetaObject::invokeMethod(popup, "startAnalysis"));
            QCOMPARE(link->property("requestedProfile").toInt(), profile);
        }
        duration->setProperty("currentIndex", 1);
        auto* ground = qvariant_cast<QObject*>(object->property("_ohdSystemGround"));
        auto* status = object->findChild<QObject*>("surveyStatus");
        QVERIFY(ground); QVERIFY(status);
        link->setProperty("analyze_request_pending", true);
        QCOMPARE(popup->property("analyzing").toBool(), true);
        QVERIFY(QMetaObject::invokeMethod(popup, "requestClose"));
        QCOMPARE(popup->property("visible").toBool(), true);
        link->setProperty("analyze_request_pending", false);
        link->setProperty("analyze_progress_perc", 14);
        link->setProperty("analyzed_channel_count", 1);
        ground->setProperty("wb_gnd_operating_mode", 2);
        QTRY_VERIFY(status->property("text").toString().contains("1 channels"));
        link->setProperty("analyze_results_revision", 1);
        QTRY_COMPARE(chart->property("measuredChannels").toInt(), 1);
        helper.threadsafe_update(samples);
        link->setProperty("analyze_results_revision", 2);
        QTRY_COMPARE(chart->property("measuredChannels").toInt(), 6);
        link->setProperty("analyzed_channel_count", 7);
        QTRY_VERIFY(status->property("text").toString().contains("7 channels"));
        duration->setProperty("currentIndex", 2);
        link->setProperty("analyze_progress_perc", 50);
        auto* sweepStatus = object->findChild<QObject*>("surveySweepStatus");
        QVERIFY(sweepStatus);
        QTRY_VERIFY(sweepStatus->property("text").toString().contains("Second sweep"));
        QVERIFY(status->property("text").toString().contains("Analyzing"));
        duration->setProperty("currentIndex", 1);
        ground->setProperty("wb_gnd_operating_mode", 0);
        link->setProperty("analyze_progress_perc", 100);
        for (int index = 0; index < 4; ++index) {
            metric->setProperty("currentIndex", index);
            QTRY_COMPARE(chart->property("measuredChannels").toInt(), index < 2 ? 6 : 7);
        }
        helper.threadsafe_update({});
        link->setProperty("analyze_results_revision", 3);
        QTRY_COMPARE(chart->property("measuredChannels").toInt(), 0);
        auto* explanation = object->findChild<QObject*>("surveyExplanation");
        QVERIFY(explanation);
        QVERIFY(explanation->property("text").toString().contains("no values"));
        helper.threadsafe_update(samples);
        link->setProperty("analyze_results_revision", 4);
        QTRY_COMPARE(chart->property("measuredChannels").toInt(), 7);
        QQuickRenderControl renderer;
        QQuickWindow window(&renderer);
        item->setParentItem(window.contentItem());
        for (const QSize size : {QSize(1004, 620), QSize(430, 728)}) {
            window.setGeometry(0, 0, size.width(), size.height());
            item->setWidth(size.width()); item->setHeight(size.height());
            renderer.initialize(nullptr);
            QTest::qWait(250);
            renderer.polishItems(); renderer.sync(); renderer.render();
            // Qt Charts completes its initial axis layout after the first frame.
            QTest::qWait(40);
            renderer.polishItems(); renderer.sync(); renderer.render();
            const auto image = renderer.grab();
            QVERIFY(!image.isNull());
            // Retransmitted pages must leave the rendered graph unchanged.
            const auto chartHeight = chart->property("height");
            link->setProperty("analyze_results_revision", 5 + size.width());
            QTest::qWait(40);
            renderer.polishItems(); renderer.sync(); renderer.render();
            QCOMPARE(renderer.grab(), image);
            QCOMPARE(chart->property("height"), chartHeight);
            QVERIFY(image.save(QCoreApplication::applicationDirPath() +
                QString("/survey-%1.png").arg(size.width())));
            for (int index = 0; index < 4; ++index) {
                metric->setProperty("currentIndex", index);
                QTest::qWait(220);
                renderer.polishItems(); renderer.sync(); renderer.render();
                QVERIFY(renderer.grab().save(QCoreApplication::applicationDirPath() +
                    QString("/survey-%1-metric-%2.png").arg(size.width()).arg(index)));
            }
        }
    }
};
QTEST_MAIN(ChannelSurveyTest)
#include "channel_survey_test.moc"
