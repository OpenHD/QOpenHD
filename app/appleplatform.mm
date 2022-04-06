

#include "appleplatform.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


static ApplePlatform* _instance = nullptr;

ApplePlatform* ApplePlatform::instance() {
    if (_instance == nullptr) {
        _instance = new ApplePlatform();
    }
    return _instance;
}


ApplePlatform::ApplePlatform(QObject *parent): QObject(parent) {

}


void ApplePlatform::disableScreenLock() {
    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
}


void ApplePlatform::registerNotifications() {
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];

    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                      object:nil
                                                      queue:mainQueue
                                                 usingBlock:^void(NSNotification *notification) {
        emit didEnterBackground();
    }];

    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                      object:nil
                                                      queue:mainQueue
                                                 usingBlock:^void(NSNotification *notification) {
        emit willEnterForeground();
    }];
}
