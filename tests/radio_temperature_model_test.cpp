#include <QApplication>
#include <QEventLoop>
#include <QTimer>
#include <iostream>
#include <stdexcept>

#include "telemetry/models/aohdsystem.h"
#include "telemetry/models/openhd_core/wifi_card_type.h"

#define CHECK(value) do { if (!(value)) throw std::runtime_error(#value); } while (0)

static void card(AOHDSystem& system, bool air, int index, int type,
                 int temperature, bool valid = false, int delta = 0) {
    mavlink_openhd_stats_monitor_mode_wifi_card_t value{};
    value.card_index = index;
    value.card_type = type;
    value.card_temperature = temperature;
    value.dummy1 = 20 | ((delta & 0xff) << 8);
    value.dummy2 = valid ? (1u << 21) : 0;
    mavlink_message_t msg{};
    mavlink_msg_openhd_stats_monitor_mode_wifi_card_encode(air ? 101 : 100,191,&msg,&value);
    CHECK(system.process_message(msg));
}
static void core(AOHDSystem& system, bool air, int first, int second) {
    mavlink_openhd_core_status_t value{};
    value.wifi0_temp = first; value.wifi1_temp = second;
    mavlink_message_t msg{};
    mavlink_msg_openhd_core_status_encode(air ? 101 : 100,191,&msg,&value);
    CHECK(system.process_message(msg));
}

int main(int argc, char** argv) {
    QApplication app(argc,argv);
    app.setOrganizationName("OpenHDModelRegression");
    app.setApplicationName("RadioTemperatureTest");
    try {
        AOHDSystem air(true), ground(false);
        core(ground,false,72,83);
        CHECK(ground.radio_temperature_warnings().size() == 2);
        CHECK(ground.radio_temperature_display_text() == QString::fromUtf8("83°C"));
        const int legacy = openhd::wifi_card_type_to_int(openhd::WiFiCardType::OPENHD_RTL_88X2AU);
        const int devourer = openhd::wifi_card_type_to_int(openhd::WiFiCardType::DEVOURER_RTL8812A);
        card(ground,false,3,legacy,69);
        CHECK(ground.radio_temperature_warnings().isEmpty());
        card(ground,false,3,legacy,70);
        CHECK(ground.radio_temperature_warnings().size() == 1);
        CHECK(ground.radio_temperature_warnings().front().toMap().value("index").toInt() == 3);
        CHECK(ground.radio_temperature_state() == 2);
        card(ground,false,3,legacy,85);
        CHECK(ground.radio_temperature_state() == 3);
        card(ground,false,3,legacy,0);
        CHECK(ground.radio_temperature_warnings().isEmpty());
        CHECK(ground.radio_temperature_state() == -1);

        card(air,true,0,devourer,45,true,25);
        card(air,true,1,devourer,35,true,15);
        card(air,true,3,devourer,28,true,8);
        CHECK(air.radio_temperature_warnings().size() == 2);
        CHECK(air.radio_temperature_state() == 3);
        CHECK(air.radio_temperature_display_text() == "Overheating");
        CHECK(air.radio_temperature_warnings()[1].toMap().value("index").toInt() == 1);
        card(air,true,0,devourer,100,false,25);
        CHECK(air.radio_temperature_warnings().size() == 1);
        CHECK(air.radio_temperature_state() == 2);
        core(air,true,120,120); // Relative raw readings must never become Celsius.
        CHECK(air.radio_temperature_warnings().size() == 1);
        CHECK(air.radio_temperature_state() == 2);
        card(ground,false,3,legacy,90);

        // Keep the units alive while card telemetry stops: stale hot readings
        // must expire independently of the Air/Ground connection heartbeat.
        QTimer heartbeats;
        QObject::connect(&heartbeats,&QTimer::timeout,[&] {
            for (bool isAir : {false,true}) {
                mavlink_message_t msg{};
                mavlink_msg_heartbeat_pack(isAir ? 101 : 100,191,&msg,
                    MAV_TYPE_ONBOARD_CONTROLLER,MAV_AUTOPILOT_INVALID,0,0,MAV_STATE_ACTIVE);
                (isAir ? air : ground).process_message(msg);
            }
        });
        heartbeats.start(200);
        QEventLoop loop;
        QTimer::singleShot(7000,&loop,&QEventLoop::quit);
        loop.exec();
        CHECK(air.is_alive() && ground.is_alive());
        CHECK(air.radio_temperature_warnings().isEmpty());
        CHECK(ground.radio_temperature_warnings().isEmpty());
        CHECK(air.radio_temperature_state() == -1);
        CHECK(ground.radio_temperature_state() == -1);
        std::cout << "Radio telemetry thresholds, secondary Air, invalid data and expiry passed\n";
    } catch (const std::exception& ex) {
        std::cerr << ex.what() << '\n';
        return 1;
    }
}
