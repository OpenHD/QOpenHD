#include "drm_fd_socket.h"

#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <cstring>
#include <cstdio>

int receive_fd_from_socket(const char* path)
{
    if (!path) {
        return -1;
    }

    int sock = ::socket(AF_UNIX, SOCK_STREAM, 0);
    if (sock < 0) {
        return -1;
    }

    sockaddr_un addr;
    std::memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    if (std::strlen(path) >= sizeof(addr.sun_path)) {
        ::close(sock);
        return -1;
    }
    std::strncpy(addr.sun_path, path, sizeof(addr.sun_path) - 1);

    if (::connect(sock, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) < 0) {
        ::close(sock);
        return -1;
    }

    // Prepare to receive a single fd
    char buf[1];
    iovec io;
    io.iov_base = buf;
    io.iov_len = sizeof(buf);

    char cmsgbuf[CMSG_SPACE(sizeof(int))];
    std::memset(cmsgbuf, 0, sizeof(cmsgbuf));

    msghdr msg;
    std::memset(&msg, 0, sizeof(msg));
    msg.msg_iov = &io;
    msg.msg_iovlen = 1;
    msg.msg_control = cmsgbuf;
    msg.msg_controllen = sizeof(cmsgbuf);

    ssize_t n = ::recvmsg(sock, &msg, 0);
    if (n <= 0) {
        ::close(sock);
        return -1;
    }

    cmsghdr* cmsg = CMSG_FIRSTHDR(&msg);
    if (!cmsg || cmsg->cmsg_level != SOL_SOCKET || cmsg->cmsg_type != SCM_RIGHTS) {
        ::close(sock);
        return -1;
    }

    int fd = -1;
    std::memcpy(&fd, CMSG_DATA(cmsg), sizeof(int));

    ::close(sock);
    return fd;
}

