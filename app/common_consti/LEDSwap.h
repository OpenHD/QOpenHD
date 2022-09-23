//
// Created by consti10 on 16.02.22.
//

#ifndef HELLO_DRMPRIME_LEDSWAP_H
#define HELLO_DRMPRIME_LEDSWAP_H

#include <stdlib.h>
#include <iostream>
//extern "C" {
//#include <wiringPi.h>
//}

static bool initialized=false;
static bool led_on=false;

void switch_led_on_off(){
    /*if(!initialized){
        if (wiringPiSetup () == -1){
            std::cout<<"Cannot setup wiringPi\n";
            return;
        }
        pinMode (0, OUTPUT) ;
        initialized=true;
    }*/
    int result;
    led_on=!led_on;
    //digitalWrite (0, led_on ? 1 : 0);
    if(led_on){
        result=system("echo 1 > /sys/class/leds/led1/brightness");
    }else{
        result=system("echo 0 > /sys/class/leds/led1/brightness");
    }
    printf("Switched LED %s Syscall:%d\n",led_on ? "on":"off",result);
}


#endif //HELLO_DRMPRIME_LEDSWAP_H
