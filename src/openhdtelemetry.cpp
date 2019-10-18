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

OpenHDTelemetry::OpenHDTelemetry(QObject *parent): QObject(parent) {
    qDebug() << "OpenHDTelemetry::OpenHDTelemetry()";
    init();
}

void OpenHDTelemetry::init() {
    qDebug() << "OpenHDTelemetry::init()";
#if defined(__rasp_pi__)
    rx_status = telemetry_wbc_status_memory_open();
    rx_status_uplink = telemetry_wbc_status_memory_open_uplink();
    rx_status_rc = telemetry_wbc_status_memory_open_rc();
    rx_status_osd = telemetry_wbc_status_memory_open_osd();
    rx_status_sysair = telemetry_wbc_status_memory_open_sysair();
    restartSHM();
#else
    telemetrySocket = new QUdpSocket(this);
    telemetrySocket->bind(QHostAddress::Any, 5154);
    connect(telemetrySocket, &QUdpSocket::readyRead, this, &OpenHDTelemetry::processDatagrams);
#endif
}

#if defined(__rasp_pi__)
void OpenHDTelemetry::restartSHM() {
    qDebug() << "OpenHDTelemetry::restartSHM()";
    shmFuture = QtConcurrent::run(this, &OpenHDTelemetry::processSHM);
    watcher.cancel();
    disconnect(&watcher, &QFutureWatcherBase::finished, this, &OpenHDTelemetry::restartSHM);
    connect(&watcher, &QFutureWatcherBase::finished, this, &OpenHDTelemetry::restartSHM);
    watcher.setFuture(shmFuture);
}

void OpenHDTelemetry::processSHM() {
    OpenHDPi p;

    while (true) {
        p.update_ground();

        wifibroadcast_rx_status_forward_t telemetry;

        telemetry.wifi_adapter_cnt = rx_status_osd->wifi_adapter_cnt; // number of wifi adapters

        //wifi_adapter_rx_status_t adapter
        for (uint wifi_adapter = 0; wifi_adapter < rx_status_osd->wifi_adapter_cnt; wifi_adapter++) {
            wifi_adapter_rx_status_t adapter = rx_status_osd->adapter[wifi_adapter];
            wifi_adapter_rx_status_forward_t _adapter;
            _adapter.type = adapter.type;
            _adapter.signal_good = (int8_t)adapter.signal_good;
            _adapter.current_signal_dbm = adapter.current_signal_dbm;
            _adapter.received_packet_cnt = adapter.received_packet_cnt;
            telemetry.adapter[wifi_adapter] = _adapter;
        }

        OpenHD::instance()->set_air_undervolt(rx_status_sysair->undervolt);

        telemetry.current_signal_telemetry_uplink = rx_status_uplink->adapter[0].current_signal_dbm;
        telemetry.lost_packet_cnt_telemetry_up = rx_status_uplink->lost_packet_cnt;


        telemetry.current_signal_joystick_uplink = rx_status_rc->adapter[0].current_signal_dbm;
        telemetry.lost_packet_cnt_rc = rx_status_rc->lost_packet_cnt;

        // todo: this is the wrong rvalue, find the right one
        telemetry.lost_packet_cnt_telemetry_down = rx_status_rc->tx_restart_cnt;

        // this has no equivalent coming through UDP so we set it directly here
        OpenHD::instance()->set_cts(rx_status_sysair->cts);

        telemetry.kbitrate = rx_status->kbitrate;
        telemetry.kbitrate_measured = rx_status_sysair->bitrate_measured_kbit;
        telemetry.kbitrate_set = rx_status_sysair->bitrate_kbit;
        telemetry.skipped_packet_cnt = rx_status_sysair->skipped_fec_cnt;
        telemetry.injection_fail_cnt = rx_status_sysair->injection_fail_cnt;

        // not used and not provided over UDP either
        //rx_status_sysair->injection_time_block;
        telemetry.damaged_block_cnt = rx_status_osd->damaged_block_cnt;
        telemetry.lost_packet_cnt = rx_status_osd->lost_packet_cnt;
        telemetry.received_packet_cnt = rx_status_osd->received_packet_cnt;

        telemetry.cpuload_air = rx_status_sysair->cpuload;
        telemetry.temp_air = rx_status_sysair->temp;
        telemetry.cpuload_gnd = p.ground_load;
        telemetry.temp_gnd = p.ground_temp;
        telemetry.HomeLat = 0.0;
        telemetry.HomeLon = 0.0;

        processOpenHDTelemetry(telemetry);
        QThread::msleep(1000);
    }
}
#else
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
#endif

void OpenHDTelemetry::processOpenHDTelemetry(wifibroadcast_rx_status_forward_t telemetry) {
    // find adapter with best signal. right now just uses the signal level, but should
    // also store the index in a property so it can be highlighted in the adapter list popup
    int current_best = 0;
    for (uint wifi_adapter = 0; wifi_adapter < telemetry.wifi_adapter_cnt; wifi_adapter++) {
        wifi_adapter_rx_status_forward_t adapter = telemetry.adapter[wifi_adapter];
        if (adapter.current_signal_dbm < current_best) {
            current_best = adapter.current_signal_dbm;
        }
    }
    QLocale l = QLocale::system();

    OpenHD::instance()->set_downlink_rssi(tr("%1").arg(current_best));

    auto damaged_percent = (double)telemetry.damaged_block_cnt / (double)telemetry.received_packet_cnt * 100.0;
    auto damaged_percent_visible = std::isnan(damaged_percent) ? 0.0 : damaged_percent;
    OpenHD::instance()->set_damaged_block_cnt(tr("%1 (%2%)").arg(l.toString(telemetry.damaged_block_cnt)).arg((int)damaged_percent_visible));

    auto lost_percent = (double)telemetry.lost_packet_cnt / (double)telemetry.received_packet_cnt * 100.0;
    auto lost_percent_visible = std::isnan(lost_percent) ? 0.0 : lost_percent;
    OpenHD::instance()->set_lost_packet_cnt(tr("%1 (%2%)").arg(l.toString(telemetry.lost_packet_cnt)).arg((int)lost_percent_visible));

    //ui.skipped_packet_cnt->setText(tr("%1").arg(rssi.skipped_zxpacket_cnt));
    //ui.injection_fail_cnt->setText(tr("%1").arg(rssi.injection_fail_cnt));
    ////ui.received_packet_cnt->setText(tr("%1").arg(rssi.received_packet_cnt));
    OpenHD::instance()->set_kbitrate(tr("%1 Mbit").arg(telemetry.kbitrate/1024.0,  3, 'f', 1, '0'));
    OpenHD::instance()->set_kbitrate_measured(tr("%1 Mbit").arg(telemetry.kbitrate_measured/1024.0,  3, 'f', 1, '0'));
    OpenHD::instance()->set_kbitrate_set(tr("%1 Mbit").arg(telemetry.kbitrate_set/1024.0,  3, 'f', 1, '0'));
    ////ui.lost_packet_cnt_telemetry_up->setText(tr("%1").arg(rssi.lost_packet_cnt_telemetry_up));
    ////ui.lost_packet_cnt_telemetry_down->setText(tr("%1").arg(rssi.lost_packet_cnt_telemetry_down));
    ////ui.lost_packet_cnt_msp_up->setText(tr("%1").arg(rssi.lost_packet_cnt_msp_up));
    ////ui.lost_packet_cnt_msp_down->setText(tr("%1").arg(rssi.lost_packet_cnt_msp_down));
    ////ui.lost_packet_cnt_rc->setText(tr("%1").arg(telemetry.lost_packet_cnt_rc));
    OpenHD::instance()->set_current_signal_joystick_uplink(tr("%1").arg(telemetry.current_signal_joystick_uplink));
    //set_homelat(tr("%1").arg((double)rssi.HomeLat));
    //set_homelon(tr("%1").arg((double)rssi.HomeLon));
    OpenHD::instance()->set_cpuload_gnd(tr("%1%").arg(telemetry.cpuload_gnd));
    OpenHD::instance()->set_temp_gnd(tr("%1°").arg(telemetry.temp_gnd));
    OpenHD::instance()->set_cpuload_air(tr("%1%").arg(telemetry.cpuload_air));
    OpenHD::instance()->set_temp_air(tr("%1°").arg(telemetry.temp_air));

    qint64 current_timestamp = QDateTime::currentMSecsSinceEpoch();
    set_last_heartbeat(QString(tr("%1s").arg(current_timestamp - last_heartbeat_timestamp)));
}


void OpenHDTelemetry::set_last_heartbeat(QString last_heartbeat) {
    m_last_heartbeat = last_heartbeat;
    emit last_heartbeat_changed(m_last_heartbeat);
}
