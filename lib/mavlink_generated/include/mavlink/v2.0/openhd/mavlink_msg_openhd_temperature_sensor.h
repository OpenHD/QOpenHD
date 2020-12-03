#pragma once
// MESSAGE OPENHD_TEMPERATURE_SENSOR PACKING

#define MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR 1241

MAVPACKED(
typedef struct __mavlink_openhd_temperature_sensor_t {
 uint8_t target_system; /*<  system id of the requesting system*/
 uint8_t target_component; /*<  component id of the requesting component*/
 int8_t temperature[8]; /*< [degC] temperature*/
}) mavlink_openhd_temperature_sensor_t;

#define MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_LEN 10
#define MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_MIN_LEN 10
#define MAVLINK_MSG_ID_1241_LEN 10
#define MAVLINK_MSG_ID_1241_MIN_LEN 10

#define MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_CRC 33
#define MAVLINK_MSG_ID_1241_CRC 33

#define MAVLINK_MSG_OPENHD_TEMPERATURE_SENSOR_FIELD_TEMPERATURE_LEN 8

#if MAVLINK_COMMAND_24BIT
#define MAVLINK_MESSAGE_INFO_OPENHD_TEMPERATURE_SENSOR { \
    1241, \
    "OPENHD_TEMPERATURE_SENSOR", \
    3, \
    {  { "target_system", NULL, MAVLINK_TYPE_UINT8_T, 0, 0, offsetof(mavlink_openhd_temperature_sensor_t, target_system) }, \
         { "target_component", NULL, MAVLINK_TYPE_UINT8_T, 0, 1, offsetof(mavlink_openhd_temperature_sensor_t, target_component) }, \
         { "temperature", NULL, MAVLINK_TYPE_INT8_T, 8, 2, offsetof(mavlink_openhd_temperature_sensor_t, temperature) }, \
         } \
}
#else
#define MAVLINK_MESSAGE_INFO_OPENHD_TEMPERATURE_SENSOR { \
    "OPENHD_TEMPERATURE_SENSOR", \
    3, \
    {  { "target_system", NULL, MAVLINK_TYPE_UINT8_T, 0, 0, offsetof(mavlink_openhd_temperature_sensor_t, target_system) }, \
         { "target_component", NULL, MAVLINK_TYPE_UINT8_T, 0, 1, offsetof(mavlink_openhd_temperature_sensor_t, target_component) }, \
         { "temperature", NULL, MAVLINK_TYPE_INT8_T, 8, 2, offsetof(mavlink_openhd_temperature_sensor_t, temperature) }, \
         } \
}
#endif

/**
 * @brief Pack a openhd_temperature_sensor message
 * @param system_id ID of this system
 * @param component_id ID of this component (e.g. 200 for IMU)
 * @param msg The MAVLink message to compress the data into
 *
 * @param target_system  system id of the requesting system
 * @param target_component  component id of the requesting component
 * @param temperature [degC] temperature
 * @return length of the message in bytes (excluding serial stream start sign)
 */
static inline uint16_t mavlink_msg_openhd_temperature_sensor_pack(uint8_t system_id, uint8_t component_id, mavlink_message_t* msg,
                               uint8_t target_system, uint8_t target_component, const int8_t *temperature)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    char buf[MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_LEN];
    _mav_put_uint8_t(buf, 0, target_system);
    _mav_put_uint8_t(buf, 1, target_component);
    _mav_put_int8_t_array(buf, 2, temperature, 8);
        memcpy(_MAV_PAYLOAD_NON_CONST(msg), buf, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_LEN);
#else
    mavlink_openhd_temperature_sensor_t packet;
    packet.target_system = target_system;
    packet.target_component = target_component;
    mav_array_memcpy(packet.temperature, temperature, sizeof(int8_t)*8);
        memcpy(_MAV_PAYLOAD_NON_CONST(msg), &packet, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_LEN);
#endif

    msg->msgid = MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR;
    return mavlink_finalize_message(msg, system_id, component_id, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_MIN_LEN, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_LEN, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_CRC);
}

/**
 * @brief Pack a openhd_temperature_sensor message on a channel
 * @param system_id ID of this system
 * @param component_id ID of this component (e.g. 200 for IMU)
 * @param chan The MAVLink channel this message will be sent over
 * @param msg The MAVLink message to compress the data into
 * @param target_system  system id of the requesting system
 * @param target_component  component id of the requesting component
 * @param temperature [degC] temperature
 * @return length of the message in bytes (excluding serial stream start sign)
 */
static inline uint16_t mavlink_msg_openhd_temperature_sensor_pack_chan(uint8_t system_id, uint8_t component_id, uint8_t chan,
                               mavlink_message_t* msg,
                                   uint8_t target_system,uint8_t target_component,const int8_t *temperature)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    char buf[MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_LEN];
    _mav_put_uint8_t(buf, 0, target_system);
    _mav_put_uint8_t(buf, 1, target_component);
    _mav_put_int8_t_array(buf, 2, temperature, 8);
        memcpy(_MAV_PAYLOAD_NON_CONST(msg), buf, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_LEN);
#else
    mavlink_openhd_temperature_sensor_t packet;
    packet.target_system = target_system;
    packet.target_component = target_component;
    mav_array_memcpy(packet.temperature, temperature, sizeof(int8_t)*8);
        memcpy(_MAV_PAYLOAD_NON_CONST(msg), &packet, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_LEN);
#endif

    msg->msgid = MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR;
    return mavlink_finalize_message_chan(msg, system_id, component_id, chan, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_MIN_LEN, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_LEN, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_CRC);
}

/**
 * @brief Encode a openhd_temperature_sensor struct
 *
 * @param system_id ID of this system
 * @param component_id ID of this component (e.g. 200 for IMU)
 * @param msg The MAVLink message to compress the data into
 * @param openhd_temperature_sensor C-struct to read the message contents from
 */
static inline uint16_t mavlink_msg_openhd_temperature_sensor_encode(uint8_t system_id, uint8_t component_id, mavlink_message_t* msg, const mavlink_openhd_temperature_sensor_t* openhd_temperature_sensor)
{
    return mavlink_msg_openhd_temperature_sensor_pack(system_id, component_id, msg, openhd_temperature_sensor->target_system, openhd_temperature_sensor->target_component, openhd_temperature_sensor->temperature);
}

/**
 * @brief Encode a openhd_temperature_sensor struct on a channel
 *
 * @param system_id ID of this system
 * @param component_id ID of this component (e.g. 200 for IMU)
 * @param chan The MAVLink channel this message will be sent over
 * @param msg The MAVLink message to compress the data into
 * @param openhd_temperature_sensor C-struct to read the message contents from
 */
static inline uint16_t mavlink_msg_openhd_temperature_sensor_encode_chan(uint8_t system_id, uint8_t component_id, uint8_t chan, mavlink_message_t* msg, const mavlink_openhd_temperature_sensor_t* openhd_temperature_sensor)
{
    return mavlink_msg_openhd_temperature_sensor_pack_chan(system_id, component_id, chan, msg, openhd_temperature_sensor->target_system, openhd_temperature_sensor->target_component, openhd_temperature_sensor->temperature);
}

/**
 * @brief Send a openhd_temperature_sensor message
 * @param chan MAVLink channel to send the message
 *
 * @param target_system  system id of the requesting system
 * @param target_component  component id of the requesting component
 * @param temperature [degC] temperature
 */
#ifdef MAVLINK_USE_CONVENIENCE_FUNCTIONS

static inline void mavlink_msg_openhd_temperature_sensor_send(mavlink_channel_t chan, uint8_t target_system, uint8_t target_component, const int8_t *temperature)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    char buf[MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_LEN];
    _mav_put_uint8_t(buf, 0, target_system);
    _mav_put_uint8_t(buf, 1, target_component);
    _mav_put_int8_t_array(buf, 2, temperature, 8);
    _mav_finalize_message_chan_send(chan, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR, buf, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_MIN_LEN, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_LEN, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_CRC);
#else
    mavlink_openhd_temperature_sensor_t packet;
    packet.target_system = target_system;
    packet.target_component = target_component;
    mav_array_memcpy(packet.temperature, temperature, sizeof(int8_t)*8);
    _mav_finalize_message_chan_send(chan, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR, (const char *)&packet, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_MIN_LEN, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_LEN, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_CRC);
#endif
}

/**
 * @brief Send a openhd_temperature_sensor message
 * @param chan MAVLink channel to send the message
 * @param struct The MAVLink struct to serialize
 */
static inline void mavlink_msg_openhd_temperature_sensor_send_struct(mavlink_channel_t chan, const mavlink_openhd_temperature_sensor_t* openhd_temperature_sensor)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    mavlink_msg_openhd_temperature_sensor_send(chan, openhd_temperature_sensor->target_system, openhd_temperature_sensor->target_component, openhd_temperature_sensor->temperature);
#else
    _mav_finalize_message_chan_send(chan, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR, (const char *)openhd_temperature_sensor, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_MIN_LEN, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_LEN, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_CRC);
#endif
}

#if MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_LEN <= MAVLINK_MAX_PAYLOAD_LEN
/*
  This varient of _send() can be used to save stack space by re-using
  memory from the receive buffer.  The caller provides a
  mavlink_message_t which is the size of a full mavlink message. This
  is usually the receive buffer for the channel, and allows a reply to an
  incoming message with minimum stack space usage.
 */
static inline void mavlink_msg_openhd_temperature_sensor_send_buf(mavlink_message_t *msgbuf, mavlink_channel_t chan,  uint8_t target_system, uint8_t target_component, const int8_t *temperature)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    char *buf = (char *)msgbuf;
    _mav_put_uint8_t(buf, 0, target_system);
    _mav_put_uint8_t(buf, 1, target_component);
    _mav_put_int8_t_array(buf, 2, temperature, 8);
    _mav_finalize_message_chan_send(chan, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR, buf, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_MIN_LEN, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_LEN, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_CRC);
#else
    mavlink_openhd_temperature_sensor_t *packet = (mavlink_openhd_temperature_sensor_t *)msgbuf;
    packet->target_system = target_system;
    packet->target_component = target_component;
    mav_array_memcpy(packet->temperature, temperature, sizeof(int8_t)*8);
    _mav_finalize_message_chan_send(chan, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR, (const char *)packet, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_MIN_LEN, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_LEN, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_CRC);
#endif
}
#endif

#endif

// MESSAGE OPENHD_TEMPERATURE_SENSOR UNPACKING


/**
 * @brief Get field target_system from openhd_temperature_sensor message
 *
 * @return  system id of the requesting system
 */
static inline uint8_t mavlink_msg_openhd_temperature_sensor_get_target_system(const mavlink_message_t* msg)
{
    return _MAV_RETURN_uint8_t(msg,  0);
}

/**
 * @brief Get field target_component from openhd_temperature_sensor message
 *
 * @return  component id of the requesting component
 */
static inline uint8_t mavlink_msg_openhd_temperature_sensor_get_target_component(const mavlink_message_t* msg)
{
    return _MAV_RETURN_uint8_t(msg,  1);
}

/**
 * @brief Get field temperature from openhd_temperature_sensor message
 *
 * @return [degC] temperature
 */
static inline uint16_t mavlink_msg_openhd_temperature_sensor_get_temperature(const mavlink_message_t* msg, int8_t *temperature)
{
    return _MAV_RETURN_int8_t_array(msg, temperature, 8,  2);
}

/**
 * @brief Decode a openhd_temperature_sensor message into a struct
 *
 * @param msg The message to decode
 * @param openhd_temperature_sensor C-struct to decode the message contents into
 */
static inline void mavlink_msg_openhd_temperature_sensor_decode(const mavlink_message_t* msg, mavlink_openhd_temperature_sensor_t* openhd_temperature_sensor)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    openhd_temperature_sensor->target_system = mavlink_msg_openhd_temperature_sensor_get_target_system(msg);
    openhd_temperature_sensor->target_component = mavlink_msg_openhd_temperature_sensor_get_target_component(msg);
    mavlink_msg_openhd_temperature_sensor_get_temperature(msg, openhd_temperature_sensor->temperature);
#else
        uint8_t len = msg->len < MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_LEN? msg->len : MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_LEN;
        memset(openhd_temperature_sensor, 0, MAVLINK_MSG_ID_OPENHD_TEMPERATURE_SENSOR_LEN);
    memcpy(openhd_temperature_sensor, _MAV_PAYLOAD(msg), len);
#endif
}
