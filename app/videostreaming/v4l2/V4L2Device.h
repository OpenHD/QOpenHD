//
// Created by buldo on 1/22/26.
//

#ifndef QOPENHDPROJECT_V4L2DEVICE_H
#define QOPENHDPROJECT_V4L2DEVICE_H

#include <memory>
#include <string>

class V4L2Device {
private:
    int fd_ = -1;

    // Private constructor - only factory method can create instances
    explicit V4L2Device(int fd);

public:
    // Delete all copy and move operations for strict lifetime control
    V4L2Device(const V4L2Device&) = delete;
    V4L2Device& operator=(const V4L2Device&) = delete;
    V4L2Device(V4L2Device&&) = delete;
    V4L2Device& operator=(V4L2Device&&) = delete;

    // Destructor closes the device
    ~V4L2Device();

    // Factory method to open a V4L2 device
    static std::unique_ptr<V4L2Device> Open(const std::string& devicePath);

    // Get file descriptor
    int GetFd() const { return fd_; }

};

#endif //QOPENHDPROJECT_V4L2DEVICE_H
