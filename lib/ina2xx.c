/*
 *
 * Copyright (C) Stephen Oliver, Patrick Van Oosterwijck, Lothar Felten
 * Released under the GPL v2
 */


#include "ina2xx.h"

#if defined(ENABLE_INA2XX)

#include <unistd.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <errno.h>
#include <string.h>

#include <sys/types.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <sys/file.h>
#include <linux/i2c-dev.h>
#ifndef I2C_FUNC_I2C
#include <linux/i2c.h>
#define TOBUFTYPE(x) (x)
#else
#define TOBUFTYPE(x) ((char *)(x))
#endif


#define CONFIG_REG          0
#define SHUNT_REG           1
#define BUS_REG             2
#define POWER_REG           3
#define CURRENT_REG         4
#define CALIBRATION_REG     5

#define I2C_BUS             1
#define I2C_ADDRESS         0x40

enum {
  CONFIG_BVOLTAGERANGE_16V = 0x0000,
  CONFIG_BVOLTAGERANGE_32V = 0x2000,
};

enum {
  CONFIG_GAIN_1_40MV  = 0x0000,
  CONFIG_GAIN_2_80MV  = 0x0800,
  CONFIG_GAIN_4_160MV = 0x1000,
  CONFIG_GAIN_8_320MV = 0x1800,
};

enum {
  CONFIG_BADCRES_9BIT  = 0x0000,
  CONFIG_BADCRES_10BIT = 0x0080,
  CONFIG_BADCRES_11BIT = 0x0100,
  CONFIG_BADCRES_12BIT = 0x0180,
};

enum {
  CONFIG_SADCRES_9BIT_1S_84US     = 0x0000,
  CONFIG_SADCRES_10BIT_1S_148US   = 0x0008,
  CONFIG_SADCRES_11BIT_1S_276US   = 0x0010,
  CONFIG_SADCRES_12BIT_1S_532US   = 0x0018,
  CONFIG_SADCRES_12BIT_2S_1060US  = 0x0048,
  CONFIG_SADCRES_12BIT_4S_2130US  = 0x0050,
  CONFIG_SADCRES_12BIT_8S_4260US  = 0x0058,
  CONFIG_SADCRES_12BIT_16S_8510US = 0x0060,
  CONFIG_SADCRES_12BIT_32S_17MS   = 0x0068,
  CONFIG_SADCRES_12BIT_64S_34MS   = 0x0070,
  CONFIG_SADCRES_12BIT_128S_69MS  = 0x0078,
};

enum {
  CONFIG_MODE_POWERDOWN,
  CONFIG_MODE_SVOLT_TRIGGERED,
  CONFIG_MODE_BVOLT_TRIGGERED,
  CONFIG_MODE_SANDBVOLT_TRIGGERED,
  CONFIG_MODE_ADCOFF,
  CONFIG_MODE_SVOLT_CONTINUOUS,
  CONFIG_MODE_BVOLT_CONTINUOUS,
  CONFIG_MODE_SANDBVOLT_CONTINUOUS
};

static bool open_i2c_bus(int bus, int *file) {
    char filename[20];
    snprintf(filename, 19, "/dev/i2c-%d", bus);
    *file = open(filename, O_RDWR);
    if (*file < 0) return false;
    if (flock(*file, LOCK_EX|LOCK_NB) != 0) {
        close (*file);
        return false;
    }
    return true;
}

static bool close_i2c_bus(int file) {
    flock(file, LOCK_UN);
    close(file);
    return file >= 0;
}

static bool write_ina2xx_register(uint8_t reg, uint16_t data) {
    int file;
    if (!open_i2c_bus(I2C_BUS, &file)) {
        return false;
    }

    struct i2c_msg dwrite;
    struct i2c_rdwr_ioctl_data msgwrite = {
        &dwrite,
        1
    };

    uint8_t payload[3];
    payload[0] = reg;
    payload[1] = (data >> 8) & 0xFF;
    payload[2] = data & 0xFF;

    dwrite.addr = I2C_ADDRESS;
    dwrite.flags = 0;
    dwrite.len = 3;
    dwrite.buf = TOBUFTYPE(payload);

    bool result = ioctl(file, I2C_RDWR, &msgwrite) >= 0;
    close_i2c_bus(file);
    return result;
}

static bool read_ina2xx_register(uint8_t reg, uint8_t count, uint8_t *data) {
    int file;
    if (!open_i2c_bus(I2C_BUS, &file)) {
        return false;
    }

    struct i2c_msg dread[2];
    struct i2c_rdwr_ioctl_data msgread = {
        dread,
        2
    };
    /* Write register message */
    dread[0].addr = I2C_ADDRESS;
    dread[0].flags = 0;
    dread[0].len = 1;
    dread[0].buf = TOBUFTYPE(&reg);

    /* Read data message */
    dread[1].addr = I2C_ADDRESS;
    dread[1].flags = I2C_M_RD;
    dread[1].len = count;
    dread[1].buf = TOBUFTYPE(data);

    bool result = ioctl(file, I2C_RDWR, &msgread) >= 0;
    close_i2c_bus(file);
    return result;
}

void ina2xx_init() {
    int16_t calibration = 4096;
    if (!write_ina2xx_register(CALIBRATION_REG, calibration)) {
        fprintf( stderr, "Error setting INA2XX calibration: %s\n", strerror(errno));
    }

    uint16_t config = CONFIG_BVOLTAGERANGE_32V | CONFIG_GAIN_8_320MV | CONFIG_BADCRES_12BIT | CONFIG_SADCRES_12BIT_1S_532US | CONFIG_MODE_SANDBVOLT_CONTINUOUS;
    if (!write_ina2xx_register(CONFIG_REG, config)) {
        fprintf( stderr, "Error setting INA2XX config: %s\n", strerror(errno));
    }
}

void get_ina2xx_data(ina2xx_data *sensor_data) {
    fprintf(stderr, "Getting INA2XX data\n");
    // All data conversions necessary to match the format and units expected by
    // groundstatus_data_t should be done here
    uint8_t data[2] = {0, 0};
    float current;
    float voltage;

    sensor_data->vbat = 0.0;

    if (!read_ina2xx_register(BUS_REG, 2, (uint8_t*)&data)) {
        fprintf( stderr, "Error getting INA2XX voltage: %s\n", strerror(errno));
        return;
    }
    fprintf(stderr, "voltage raw byte1: %d, byte2: %d\n", data[0], data[1]);

    voltage = (float)((((data[0] << 8) | data[1]) & 0xFFF8) >> 1) / 1000.0;
    sensor_data->vin = voltage;

    if (!read_ina2xx_register(CURRENT_REG, 2, (uint8_t*)&data)) {
        fprintf( stderr, "Error getting INA2XX current: %s\n", strerror(errno));
        return;
    }
    fprintf(stderr, "current raw byte1: %d, byte2: %d\n", data[0], data[1]);

    current = (float)((data[0] << 8) | data[1]) / 10 / 1000.0;
    sensor_data->iout = current;

    sensor_data->vout = 0.0;

    fprintf(stderr, "voltage: %.2f\n", voltage);
    fprintf(stderr, "current: %.2f\n", current);
}

#endif
