//
// Created by consti10 on 20.12.20.
//

#include <string>

#ifndef WIFIBROADCAST_SCHEDULINGHELPER_H
#define WIFIBROADCAST_SCHEDULINGHELPER_H

#ifndef __windows__
#include <pthread.h>
#include <sys/resource.h>
#include <unistd.h>
#include <iostream>
#include <qdebug.h>
#endif // __windows__

#include <string>

namespace SchedulingHelper {

static void printCurrentThreadPriority(const std::string& name) {
#ifndef  __windows__
  int which = PRIO_PROCESS;
  id_t pid = (id_t) getpid();
  int priority = getpriority(which, pid);
  //wifibroadcast::log::get_default()->debug("{} has priority {}",name,priority);
#endif
}

static void printCurrentThreadSchedulingPolicy(const std::string& name) {
#ifndef  __windows__
  auto self = pthread_self();
  int policy;
  sched_param param{};
  auto result = pthread_getschedparam(self, &policy, &param);
  if (result != 0) {
     qDebug()<<"Cannot get thread scheduling policy";
  }
  //wifibroadcast::log::get_default()->debug("{} has policy {} and priority {}",name,policy,param.sched_priority);
#endif
}

// this thread should run as close to realtime as possible
#ifndef  __windows__
static void setThreadParamsMaxRealtime(pthread_t target) {
  int policy = SCHED_FIFO;
  sched_param param{};
  param.sched_priority = sched_get_priority_max(policy);
  auto result = pthread_setschedparam(target, policy, &param);
  if (result != 0) {
    qDebug()<<"cannot set ThreadParamsMaxRealtime";
  }
}
#endif

static void setThreadParamsMaxRealtime() {
#ifndef  __windows__
  setThreadParamsMaxRealtime(pthread_self());
#endif
}
}
#endif //WIFIBROADCAST_SCHEDULINGHELPER_H
