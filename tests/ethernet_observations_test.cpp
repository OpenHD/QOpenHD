#include <QApplication>
#include <QEventLoop>
#include <QTimer>
#include <cstring>
#include <iostream>
#include <stdexcept>
#include "telemetry/models/aohdsystem.h"
#define CHECK(v) do { if (!(v)) throw std::runtime_error(#v); } while(0)
static void put(uint8_t* data, int offset, uint32_t value) {
    for(int i=0;i<4;++i) data[offset+i]=value>>(i*8);
}
int main(int argc,char** argv) {
    QApplication app(argc,argv);
    app.setOrganizationName("OpenHDModelRegression");app.setApplicationName("EthernetObservationsTest");
    try {
        AOHDSystem air(true);
        AOHDSystem ground(false);
        mavlink_data96_t details{}; details.type=0x47;details.len=76;
        std::memcpy(details.data,"OHDG",4);details.data[4]=1;details.data[5]=31;
        put(details.data,8,3);put(details.data,12,1073741824);put(details.data,20,2147483648u);
        std::memcpy(details.data+44,"192.168.3.1",12);std::memcpy(details.data+60,"8.8.8.8",8);
        mavlink_message_t detailsMessage{};
        mavlink_msg_data96_encode(100,191,&detailsMessage,&details);
        ground.process_message(detailsMessage);
        CHECK(ground.ground_details().value("hotspot_clients").toInt()==3);
        CHECK(ground.ground_details().value("hotspot_ip").toString()=="192.168.3.1");
        CHECK(ground.ground_details().value("system_total_bytes").toDouble()==2147483648.0);
        details.data[5]=0;mavlink_msg_data96_encode(100,191,&detailsMessage,&details);
        ground.process_message(detailsMessage);CHECK(ground.ground_details().isEmpty());

        mavlink_data96_t payload{};payload.type=0x4f;payload.len=82;
        std::memcpy(payload.data,"OHLU",4);payload.data[4]=1;payload.data[5]=2;payload.data[6]=6;
        put(payload.data,8,12300000);put(payload.data,12,1000000000);
        for(int i=0;i<6;++i) payload.data[16+i*5]=i+1;
        std::memcpy(payload.data+46,"ETH1",4);
        const uint32_t fields[]={12300000,64000,1400,55,2200,300,5,2};
        for(int i=0;i<8;++i) put(payload.data,50+i*4,fields[i]);
        auto receive=[&] { mavlink_message_t msg{};mavlink_msg_data96_encode(101,191,&msg,&payload);CHECK(air.process_message(msg)); };
        receive();CHECK(air.link_usage().size()==1);
        auto usage=air.link_usage()[0].toMap();
        CHECK(usage.value("tx_bps").toULongLong()==12300000);
        CHECK(usage.value("rtt_us").toInt()==2200);
        CHECK(usage.value("probe_loss_permille").toInt()==5);
        CHECK(usage.value("send_errors").toInt()==2);
        CHECK(usage.value("categories").toList().size()==6);
        put(payload.data,66,UINT32_MAX);receive();
        CHECK(!air.link_usage()[0].toMap().value("rtt_us").isValid());
        // Short/old trailers must not retain stale metrics or read zero padding.
        payload.len=81;receive();CHECK(!air.link_usage()[0].toMap().contains("tx_bps"));
        payload.len=46;receive();CHECK(air.link_usage()[0].toMap().value("capacity_bps").toULongLong()==1000000000);
        CHECK(!air.link_usage()[0].toMap().contains("tx_bps"));
        payload.len=16;payload.data[6]=255;receive();CHECK(air.link_usage().size()==1);
        // Allocation snapshots use a separate, backwards-compatible WiFi trailer.
        payload.data[5]=1;payload.data[6]=6;payload.len=90;
        std::memcpy(payload.data+46,"BWA1",4);
        const uint32_t allocationFields[]={11000,250,2000,330,8420,1700,9};
        for(int i=0;i<7;++i) put(payload.data,50+i*4,allocationFields[i]);
        payload.data[78]=3;payload.data[79]=70;put(payload.data,80,5894);
        payload.data[84]=3;payload.data[85]=30;put(payload.data,86,2526);
        receive();CHECK(air.link_usage().size()==2);
        auto allocation=air.link_usage()[1].toMap().value("allocation").toMap();
        CHECK(allocation.value("available").toBool());CHECK(allocation.value("enabled").toBool());
        CHECK(allocation.value("pool_kbits").toInt()==8420);
        const auto streams=allocation.value("streams").toList();
        CHECK(streams[0].toMap().value("percent").toInt()+streams[1].toMap().value("percent").toInt()==100);
        CHECK(streams[1].toMap().value("budget_kbits").toInt()==2526);
        payload.len=89;receive();CHECK(!air.link_usage()[1].toMap().contains("allocation"));
        QEventLoop loop;QTimer::singleShot(4200,&loop,&QEventLoop::quit);loop.exec();
        CHECK(air.link_usage().empty());
        std::cout<<"Ethernet and bandwidth allocation decoding, legacy packets, unknowns, truncation and expiry passed\n";
    } catch(const std::exception& error) {std::cerr<<error.what()<<"\n";return 1;}
}
