#include <QApplication>
#include <QRegularExpression>
#include <chrono>
#include <iostream>
#include <stdexcept>
#include <thread>

#include "telemetry/MavlinkTelemetry.h"
#include "telemetry/tutil/qopenhdmavlinkhelper.hpp"

// Compile this harness with -fno-access-control to exercise the real receive
// callback without adding a production test API or opening network sockets.
static QString timing;
static void logMessage(QtMsgType, const QMessageLogContext&, const QString& text) {
    if (text.startsWith("telemetry-ping-v1")) timing = text;
}

int main(int argc, char** argv) {
    QApplication app(argc, argv);
    app.setOrganizationName("OpenHDModelRegression");
    app.setApplicationName("TelemetryPingTimingTest");
    try {
        MavlinkTelemetry telemetry;
        qInstallMessageHandler(logMessage);
        telemetry.m_last_timesync_out_us = QOpenHDMavlinkHelper::getTimeMicroseconds() - 8000;
        mavlink_timesync_t reply{};
        reply.tc1 = 1;
        reply.ts1 = telemetry.m_last_timesync_out_us;
        mavlink_message_t msg{};
        mavlink_msg_timesync_encode(101, 191, &msg, &reply);
        std::thread receiver([&] { telemetry.process_mavlink_message(msg, 0); });
        receiver.join();
        // Deliberately block the GUI after endpoint delivery, just as a busy
        // render/model event loop can. RTT diagnostics must retain that boundary.
        std::this_thread::sleep_for(std::chrono::milliseconds(70));
        app.processEvents();
        const auto match = QRegularExpression(
            "endpoint_rtt_us= (\\d+) gui_delay_us= (\\d+) displayed_rtt_us= (\\d+)").match(timing);
        if (!match.hasMatch()) throw std::runtime_error("missing ping breakdown");
        const auto endpoint = match.captured(1).toLongLong();
        const auto gui = match.captured(2).toLongLong();
        const auto displayed = match.captured(3).toLongLong();
        if (endpoint < 8000 || gui < 60000 || displayed != endpoint + gui)
            throw std::runtime_error("receive timestamp lost across GUI delivery");
        timing.clear();
        telemetry.process_mavlink_message(msg, 1); // Superseded connection.
        if (!timing.isEmpty()) throw std::runtime_error("stale generation accepted");
        reply.ts1--;
        mavlink_msg_timesync_encode(101, 191, &msg, &reply);
        telemetry.process_mavlink_message(msg, 0);
        if (!timing.isEmpty()) throw std::runtime_error("unmatched ping accepted");
        qInstallMessageHandler(nullptr);
        std::cout << "PASS: endpoint RTT preserved across delayed GUI delivery; stale replies ignored\n";
    } catch (const std::exception& ex) {
        qInstallMessageHandler(nullptr);
        std::cerr << ex.what() << '\n';
        return 1;
    }
}
