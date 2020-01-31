#include "openhdtelemetry.h"

#include <QtNetwork>
#include <QThread>
#include <QtConcurrent>
#include <QFutureWatcher>
#include <QFuture>

#include "wifibroadcast.h"

#include "constants.h"

#include "openhdpi.h"
#include "openhd.h"


static OpenHDTelemetry* _instance = new OpenHDTelemetry();

OpenHDTelemetry* OpenHDTelemetry::instance() {
    return _instance;
}

OpenHDTelemetry::OpenHDTelemetry(QObject *parent): QObject(parent) {
    qDebug() << "OpenHDTelemetry::OpenHDTelemetry()";
}

void OpenHDTelemetry::onStarted() {
    qDebug() << "OpenHDTelemetry::onStarted()";
    telemetrySocket = new QUdpSocket(this);

#if defined(__rasp_pi__)
    telemetrySocket->bind(QHostAddress::Any, 5155);
#else
    telemetrySocket->bind(QHostAddress::Any, 5154);
#endif
    connect(telemetrySocket, &QUdpSocket::readyRead, this, &OpenHDTelemetry::processDatagrams);

    timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &OpenHDTelemetry::stateLoop);
    timer->start(200);
}


void OpenHDTelemetry::processDatagrams() {
    QByteArray datagram;
    wifibroadcast_rx_status_forward_t telemetry;

    while (telemetrySocket->hasPendingDatagrams()) {
        datagram.resize(int(telemetrySocket->pendingDatagramSize()));
        telemetrySocket->readDatagram(datagram.data(), datagram.size());

        if (datagram.size() == 113) {
            memcpy(&telemetry, datagram.constData(), datagram.size());
            processOpenHDTelemetry(telemetry);
        }
    }
}



void OpenHDTelemetry::stateLoop() {
    qint64 current_timestamp = QDateTime::currentMSecsSinceEpoch();
    set_last_heartbeat(current_timestamp - last_heartbeat_timestamp);
}



void OpenHDTelemetry::processOpenHDTelemetry(wifibroadcast_rx_status_forward_t telemetry) {
    // find adapter with best signal. right now just uses the signal level, but should
    // also store the index in a property so it can be highlighted in the adapter list popup
    int current_best = -127;

    QList<QVariantMap> wifiAdapters;

    for (uint wifi_adapter = 0; wifi_adapter < telemetry.wifi_adapter_cnt; wifi_adapter++) {
        wifi_adapter_rx_status_forward_t adapter = telemetry.adapter[wifi_adapter];
        QVariantMap wifiAdapter;
        wifiAdapter.insert("received_packet_cnt", QVariant(adapter.received_packet_cnt));
        wifiAdapter.insert("current_signal_dbm", QVariant(adapter.current_signal_dbm));
        wifiAdapter.insert("type", QVariant(adapter.type));
        wifiAdapter.insert("signal_good", QVariant(adapter.signal_good));
        wifiAdapters.append(wifiAdapter);

        if (adapter.current_signal_dbm > current_best) {
            current_best = adapter.current_signal_dbm;
        }
    }

    OpenHD::instance()->setWifiAdapters(wifiAdapters);

    QLocale l = QLocale::system();

    OpenHD::instance()->set_downlink_rssi(current_best);

    auto damaged_percent = (double)telemetry.damaged_block_cnt / (double)telemetry.received_packet_cnt * 100.0;
    auto damaged_percent_visible = std::isnan(damaged_percent) ? 0.0 : damaged_percent;
    OpenHD::instance()->set_damaged_block_cnt(telemetry.damaged_block_cnt);
    OpenHD::instance()->set_damaged_block_percent((int)damaged_percent_visible);

    auto lost_percent = (double)telemetry.lost_packet_cnt / (double)telemetry.received_packet_cnt * 100.0;
    auto lost_percent_visible = std::isnan(lost_percent) ? 0.0 : lost_percent;
    OpenHD::instance()->set_lost_packet_cnt(telemetry.lost_packet_cnt);
    OpenHD::instance()->set_lost_packet_percent((int)lost_percent_visible);

    OpenHD::instance()->set_skipped_packet_cnt(telemetry.skipped_packet_cnt);
    OpenHD::instance()->set_injection_fail_cnt(telemetry.injection_fail_cnt);

    ////ui.received_packet_cnt->setText(tr("%1").arg(rssi.received_packet_cnt));
    OpenHD::instance()->set_kbitrate(telemetry.kbitrate);
    OpenHD::instance()->set_kbitrate_measured(telemetry.kbitrate_measured);
    OpenHD::instance()->set_kbitrate_set(telemetry.kbitrate_set);
    ////ui.lost_packet_cnt_telemetry_up->setText(tr("%1").arg(rssi.lost_packet_cnt_telemetry_up));
    ////ui.lost_packet_cnt_telemetry_down->setText(tr("%1").arg(rssi.lost_packet_cnt_telemetry_down));
    ////ui.lost_packet_cnt_msp_up->setText(tr("%1").arg(rssi.lost_packet_cnt_msp_up));
    ////ui.lost_packet_cnt_msp_down->setText(tr("%1").arg(rssi.lost_packet_cnt_msp_down));
    ////ui.lost_packet_cnt_rc->setText(tr("%1").arg(telemetry.lost_packet_cnt_rc));
    OpenHD::instance()->set_current_signal_joystick_uplink(telemetry.current_signal_joystick_uplink);
    //set_homelat(tr("%1").arg((double)rssi.HomeLat));
    //set_homelon(tr("%1").arg((double)rssi.HomeLon));
    OpenHD::instance()->set_cpuload_gnd(telemetry.cpuload_gnd);

    OpenHD::instance()->set_temp_gnd(telemetry.temp_gnd);
    OpenHD::instance()->set_cpuload_air(telemetry.cpuload_air);

    OpenHD::instance()->set_temp_air(telemetry.temp_air);

    qint64 current_timestamp = QDateTime::currentMSecsSinceEpoch();

    last_heartbeat_timestamp = current_timestamp;
}


void OpenHDTelemetry::set_last_heartbeat(qint64 last_heartbeat) {
    m_last_heartbeat = last_heartbeat;
    emit last_heartbeat_changed(m_last_heartbeat);
}
