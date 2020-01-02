#pragma once

#if defined(ENABLE_INA2XX)

typedef struct ina2xx_data {
    float vin;
    float vout;
    float iout;
    float vbat;
} ina2xx_data;

void ina2xx_init();
void get_ina2xx_data(ina2xx_data *sensor_data);
#endif

