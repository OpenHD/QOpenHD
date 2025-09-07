//
// Created by consti10 on 09.04.24.
//

#ifndef FPVUE_SCHEDULINGHELPER_H
#define FPVUE_SCHEDULINGHELPER_H

#include <pthread.h>
#include <sys/resource.h>
#include <unistd.h>

#include <iostream>
#include <sstream>
#include <string>

namespace SchedulingHelper {

// Only 'low' in comparison to other realtime tasks
static constexpr int PRIORITY_REALTIME_LOW=30;
static constexpr int PRIORITY_REALTIME_MID=40;

// this thread should run as close to realtime as possible
// https://youtu.be/NrjXEaTSyrw?t=647
// COMMENT: Please don't ever use 99 for your application, there are some kernel
// threads that run at 99 that are really important So ... lets use 90 for now
static void set_thread_params_max_realtime(const std::string& tag,
                                           const int priority = 90) {
    pthread_t target = pthread_self();
    int policy = SCHED_FIFO;
    sched_param param{};
    // param.sched_priority = sched_get_priority_max(policy);
    param.sched_priority = priority;
    auto result = pthread_setschedparam(target, policy, &param);
    if (result != 0) {
        std::stringstream ss;
        ss << "Cannot setThreadParamsMaxRealtime " << result;
        std::cerr << ss.str() << std::endl;
    } else {
        std::stringstream ss;
        ss << "Changed prio ";
        if (!tag.empty()) {
            ss << "for " << tag << " ";
        }
        ss << "to SCHED_FIFO:" << param.sched_priority;
        std::cout << ss.str() << std::endl;
    }
}

static bool check_root() {
    const auto uid = getuid();
    const bool root = uid ? false : true;
    return root;
}

}  // namespace SchedulingHelper

#endif //FPVUE_SCHEDULINGHELPER_H
