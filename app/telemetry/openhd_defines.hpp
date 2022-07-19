#ifndef OPENHD_DEFINES_H
#define OPENHD_DEFINES_H

// Needs to be kept in sync with openhd

//namespace OHDDefines{
// OpenHD mavlink sys IDs
static constexpr auto OHD_SYS_ID_GROUND = 100;
static constexpr auto OHD_SYS_ID_AIR = 101;
static_assert(OHD_SYS_ID_GROUND != OHD_SYS_ID_AIR);
// other
//static constexpr auto OHD_GROUND_CLIENT_TCP_PORT=14445;
static constexpr auto OHD_GROUND_CLIENT_TCP_PORT = 1234;

static constexpr auto OHD_GROUND_CLIENT_UDP_PORT_OUT = 14550;
static constexpr auto OHD_GROUND_CLIENT_UDP_PORT_IN = 14551;
//static constexpr auto OHD_GROUND_CLIENT_UDP_PORT_IN=58302;
//}

static constexpr auto OHD_COMP_ID_AIR_CAMERA=192;
static constexpr auto OHD_COMP_ID_LINK_PARAM=100;


#endif // OPENHD_DEFINES_H
