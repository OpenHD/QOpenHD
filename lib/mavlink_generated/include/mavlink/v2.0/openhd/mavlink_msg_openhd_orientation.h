#pragma once
// MESSAGE OPENHD_ORIENTATION PACKING

#define MAVLINK_MSG_ID_OPENHD_ORIENTATION 1251

MAVPACKED(
typedef struct __mavlink_openhd_orientation_t {
 int16_t heading; /*<  heading*/
 int16_t elevation; /*<  elevation*/
 uint8_t target_system; /*<  system id of the requesting system*/
 uint8_t target_component; /*<  component id of the requesting component*/
}) mavlink_openhd_orientation_t;

#define MAVLINK_MSG_ID_OPENHD_ORIENTATION_LEN 6
#define MAVLINK_MSG_ID_OPENHD_ORIENTATION_MIN_LEN 6
#define MAVLINK_MSG_ID_1251_LEN 6
#define MAVLINK_MSG_ID_1251_MIN_LEN 6

#define MAVLINK_MSG_ID_OPENHD_ORIENTATION_CRC 193
#define MAVLINK_MSG_ID_1251_CRC 193



#if MAVLINK_COMMAND_24BIT
#define MAVLINK_MESSAGE_INFO_OPENHD_ORIENTATION { \
    1251, \
    "OPENHD_ORIENTATION", \
    4, \
    {  { "target_system", NULL, MAVLINK_TYPE_UINT8_T, 0, 4, offsetof(mavlink_openhd_orientation_t, target_system) }, \
         { "target_component", NULL, MAVLINK_TYPE_UINT8_T, 0, 5, offsetof(mavlink_openhd_orientation_t, target_component) }, \
         { "heading", NULL, MAVLINK_TYPE_INT16_T, 0, 0, offsetof(mavlink_openhd_orientation_t, heading) }, \
         { "elevation", NULL, MAVLINK_TYPE_INT16_T, 0, 2, offsetof(mavlink_openhd_orientation_t, elevation) }, \
         } \
}
#else
#define MAVLINK_MESSAGE_INFO_OPENHD_ORIENTATION { \
    "OPENHD_ORIENTATION", \
    4, \
    {  { "target_system", NULL, MAVLINK_TYPE_UINT8_T, 0, 4, offsetof(mavlink_openhd_orientation_t, target_system) }, \
         { "target_component", NULL, MAVLINK_TYPE_UINT8_T, 0, 5, offsetof(mavlink_openhd_orientation_t, target_component) }, \
         { "heading", NULL, MAVLINK_TYPE_INT16_T, 0, 0, offsetof(mavlink_openhd_orientation_t, heading) }, \
         { "elevation", NULL, MAVLINK_TYPE_INT16_T, 0, 2, offsetof(mavlink_openhd_orientation_t, elevation) }, \
         } \
}
#endif

/**
 * @brief Pack a openhd_orientation message
 * @param system_id ID of this system
 * @param component_id ID of this component (e.g. 200 for IMU)
 * @param msg The MAVLink message to compress the data into
 *
 * @param target_system  system id of the requesting system
 * @param target_component  component id of the requesting component
 * @param heading  heading
 * @param elevation  elevation
 * @return length of the message in bytes (excluding serial stream start sign)
 */
static inline uint16_t mavlink_msg_openhd_orientation_pack(uint8_t system_id, uint8_t component_id, mavlink_message_t* msg,
                               uint8_t target_system, uint8_t target_component, int16_t heading, int16_t elevation)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    char buf[MAVLINK_MSG_ID_OPENHD_ORIENTATION_LEN];
    _mav_put_int16_t(buf, 0, heading);
    _mav_put_int16_t(buf, 2, elevation);
    _mav_put_uint8_t(buf, 4, target_system);
    _mav_put_uint8_t(buf, 5, target_component);

        memcpy(_MAV_PAYLOAD_NON_CONST(msg), buf, MAVLINK_MSG_ID_OPENHD_ORIENTATION_LEN);
#else
    mavlink_openhd_orientation_t packet;
    packet.heading = heading;
    packet.elevation = elevation;
    packet.target_system = target_system;
    packet.target_component = target_component;

        memcpy(_MAV_PAYLOAD_NON_CONST(msg), &packet, MAVLINK_MSG_ID_OPENHD_ORIENTATION_LEN);
#endif

    msg->msgid = MAVLINK_MSG_ID_OPENHD_ORIENTATION;
    return mavlink_finalize_message(msg, system_id, component_id, MAVLINK_MSG_ID_OPENHD_ORIENTATION_MIN_LEN, MAVLINK_MSG_ID_OPENHD_ORIENTATION_LEN, MAVLINK_MSG_ID_OPENHD_ORIENTATION_CRC);
}

/**
 * @brief Pack a openhd_orientation message on a channel
 * @param system_id ID of this system
 * @param component_id ID of this component (e.g. 200 for IMU)
 * @param chan The MAVLink channel this message will be sent over
 * @param msg The MAVLink message to compress the data into
 * @param target_system  system id of the requesting system
 * @param target_component  component id of the requesting component
 * @param heading  heading
 * @param elevation  elevation
 * @return length of the message in bytes (excluding serial stream start sign)
 */
static inline uint16_t mavlink_msg_openhd_orientation_pack_chan(uint8_t system_id, uint8_t component_id, uint8_t chan,
                               mavlink_message_t* msg,
                                   uint8_t target_system,uint8_t target_component,int16_t heading,int16_t elevation)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    char buf[MAVLINK_MSG_ID_OPENHD_ORIENTATION_LEN];
    _mav_put_int16_t(buf, 0, heading);
    _mav_put_int16_t(buf, 2, elevation);
    _mav_put_uint8_t(buf, 4, target_system);
    _mav_put_uint8_t(buf, 5, target_component);

        memcpy(_MAV_PAYLOAD_NON_CONST(msg), buf, MAVLINK_MSG_ID_OPENHD_ORIENTATION_LEN);
#else
    mavlink_openhd_orientation_t packet;
    packet.heading = heading;
    packet.elevation = elevation;
    packet.target_system = target_system;
    packet.target_component = target_component;

        memcpy(_MAV_PAYLOAD_NON_CONST(msg), &packet, MAVLINK_MSG_ID_OPENHD_ORIENTATION_LEN);
#endif

    msg->msgid = MAVLINK_MSG_ID_OPENHD_ORIENTATION;
    return mavlink_finalize_message_chan(msg, system_id, component_id, chan, MAVLINK_MSG_ID_OPENHD_ORIENTATION_MIN_LEN, MAVLINK_MSG_ID_OPENHD_ORIENTATION_LEN, MAVLINK_MSG_ID_OPENHD_ORIENTATION_CRC);
}

/**
 * @brief Encode a openhd_orientation struct
 *
 * @param system_id ID of this system
 * @param component_id ID of this component (e.g. 200 for IMU)
 * @param msg The MAVLink message to compress the data into
 * @param openhd_orientation C-struct to read the message contents from
 */
static inline uint16_t mavlink_msg_openhd_orientation_encode(uint8_t system_id, uint8_t component_id, mavlink_message_t* msg, const mavlink_openhd_orientation_t* openhd_orientation)
{
    return mavlink_msg_openhd_orientation_pack(system_id, component_id, msg, openhd_orientation->target_system, openhd_orientation->target_component, openhd_orientation->heading, openhd_orientation->elevation);
}

/**
 * @brief Encode a openhd_orientation struct on a channel
 *
 * @param system_id ID of this system
 * @param component_id ID of this component (e.g. 200 for IMU)
 * @param chan The MAVLink channel this message will be sent over
 * @param msg The MAVLink message to compress the data into
 * @param openhd_orientation C-struct to read the message contents from
 */
static inline uint16_t mavlink_msg_openhd_orientation_encode_chan(uint8_t system_id, uint8_t component_id, uint8_t chan, mavlink_message_t* msg, const mavlink_openhd_orientation_t* openhd_orientation)
{
    return mavlink_msg_openhd_orientation_pack_chan(system_id, component_id, chan, msg, openhd_orientation->target_system, openhd_orientation->target_component, openhd_orientation->heading, openhd_orientation->elevation);
}

/**
 * @brief Send a openhd_orientation message
 * @param chan MAVLink channel to send the message
 *
 * @param target_system  system id of the requesting system
 * @param target_component  component id of the requesting component
 * @param heading  heading
 * @param elevation  elevation
 */
#ifdef MAVLINK_USE_CONVENIENCE_FUNCTIONS

static inline void mavlink_msg_openhd_orientation_send(mavlink_channel_t chan, uint8_t target_system, uint8_t target_component, int16_t heading, int16_t elevation)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    char buf[MAVLINK_MSG_ID_OPENHD_ORIENTATION_LEN];
    _mav_put_int16_t(buf, 0, heading);
    _mav_put_int16_t(buf, 2, elevation);
    _mav_put_uint8_t(buf, 4, target_system);
    _mav_put_uint8_t(buf, 5, target_component);

    _mav_finalize_message_chan_send(chan, MAVLINK_MSG_ID_OPENHD_ORIENTATION, buf, MAVLINK_MSG_ID_OPENHD_ORIENTATION_MIN_LEN, MAVLINK_MSG_ID_OPENHD_ORIENTATION_LEN, MAVLINK_MSG_ID_OPENHD_ORIENTATION_CRC);
#else
    mavlink_openhd_orientation_t packet;
    packet.heading = heading;
    packet.elevation = elevation;
    packet.target_system = target_system;
    packet.target_component = target_component;

    _mav_finalize_message_chan_send(chan, MAVLINK_MSG_ID_OPENHD_ORIENTATION, (const char *)&packet, MAVLINK_MSG_ID_OPENHD_ORIENTATION_MIN_LEN, MAVLINK_MSG_ID_OPENHD_ORIENTATION_LEN, MAVLINK_MSG_ID_OPENHD_ORIENTATION_CRC);
#endif
}

/**
 * @brief Send a openhd_orientation message
 * @param chan MAVLink channel to send the message
 * @param struct The MAVLink struct to serialize
 */
static inline void mavlink_msg_openhd_orientation_send_struct(mavlink_channel_t chan, const mavlink_openhd_orientation_t* openhd_orientation)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    mavlink_msg_openhd_orientation_send(chan, openhd_orientation->target_system, openhd_orientation->target_component, openhd_orientation->heading, openhd_orientation->elevation);
#else
    _mav_finalize_message_chan_send(chan, MAVLINK_MSG_ID_OPENHD_ORIENTATION, (const char *)openhd_orientation, MAVLINK_MSG_ID_OPENHD_ORIENTATION_MIN_LEN, MAVLINK_MSG_ID_OPENHD_ORIENTATION_LEN, MAVLINK_MSG_ID_OPENHD_ORIENTATION_CRC);
#endif
}

#if MAVLINK_MSG_ID_OPENHD_ORIENTATION_LEN <= MAVLINK_MAX_PAYLOAD_LEN
/*
  This varient of _send() can be used to save stack space by re-using
  memory from the receive buffer.  The caller provides a
  mavlink_message_t which is the size of a full mavlink message. This
  is usually the receive buffer for the channel, and allows a reply to an
  incoming message with minimum stack space usage.
 */
static inline void mavlink_msg_openhd_orientation_send_buf(mavlink_message_t *msgbuf, mavlink_channel_t chan,  uint8_t target_system, uint8_t target_component, int16_t heading, int16_t elevation)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    char *buf = (char *)msgbuf;
    _mav_put_int16_t(buf, 0, heading);
    _mav_put_int16_t(buf, 2, elevation);
    _mav_put_uint8_t(buf, 4, target_system);
    _mav_put_uint8_t(buf, 5, target_component);

    _mav_finalize_message_chan_send(chan, MAVLINK_MSG_ID_OPENHD_ORIENTATION, buf, MAVLINK_MSG_ID_OPENHD_ORIENTATION_MIN_LEN, MAVLINK_MSG_ID_OPENHD_ORIENTATION_LEN, MAVLINK_MSG_ID_OPENHD_ORIENTATION_CRC);
#else
    mavlink_openhd_orientation_t *packet = (mavlink_openhd_orientation_t *)msgbuf;
    packet->heading = heading;
    packet->elevation = elevation;
    packet->target_system = target_system;
    packet->target_component = target_component;

    _mav_finalize_message_chan_send(chan, MAVLINK_MSG_ID_OPENHD_ORIENTATION, (const char *)packet, MAVLINK_MSG_ID_OPENHD_ORIENTATION_MIN_LEN, MAVLINK_MSG_ID_OPENHD_ORIENTATION_LEN, MAVLINK_MSG_ID_OPENHD_ORIENTATION_CRC);
#endif
}
#endif

#endif

// MESSAGE OPENHD_ORIENTATION UNPACKING


/**
 * @brief Get field target_system from openhd_orientation message
 *
 * @return  system id of the requesting system
 */
static inline uint8_t mavlink_msg_openhd_orientation_get_target_system(const mavlink_message_t* msg)
{
    return _MAV_RETURN_uint8_t(msg,  4);
}

/**
 * @brief Get field target_component from openhd_orientation message
 *
 * @return  component id of the requesting component
 */
static inline uint8_t mavlink_msg_openhd_orientation_get_target_component(const mavlink_message_t* msg)
{
    return _MAV_RETURN_uint8_t(msg,  5);
}

/**
 * @brief Get field heading from openhd_orientation message
 *
 * @return  heading
 */
static inline int16_t mavlink_msg_openhd_orientation_get_heading(const mavlink_message_t* msg)
{
    return _MAV_RETURN_int16_t(msg,  0);
}

/**
 * @brief Get field elevation from openhd_orientation message
 *
 * @return  elevation
 */
static inline int16_t mavlink_msg_openhd_orientation_get_elevation(const mavlink_message_t* msg)
{
    return _MAV_RETURN_int16_t(msg,  2);
}

/**
 * @brief Decode a openhd_orientation message into a struct
 *
 * @param msg The message to decode
 * @param openhd_orientation C-struct to decode the message contents into
 */
static inline void mavlink_msg_openhd_orientation_decode(const mavlink_message_t* msg, mavlink_openhd_orientation_t* openhd_orientation)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    openhd_orientation->heading = mavlink_msg_openhd_orientation_get_heading(msg);
    openhd_orientation->elevation = mavlink_msg_openhd_orientation_get_elevation(msg);
    openhd_orientation->target_system = mavlink_msg_openhd_orientation_get_target_system(msg);
    openhd_orientation->target_component = mavlink_msg_openhd_orientation_get_target_component(msg);
#else
        uint8_t len = msg->len < MAVLINK_MSG_ID_OPENHD_ORIENTATION_LEN? msg->len : MAVLINK_MSG_ID_OPENHD_ORIENTATION_LEN;
        memset(openhd_orientation, 0, MAVLINK_MSG_ID_OPENHD_ORIENTATION_LEN);
    memcpy(openhd_orientation, _MAV_PAYLOAD(msg), len);
#endif
}
