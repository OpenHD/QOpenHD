#ifdef __cplusplus
extern "C" {
#endif
#include "drm.h"
#ifdef __cplusplus
}
#endif
#include "display_host.h"

#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <stdlib.h>

static int send_fd(int sock, int fd) {
    struct msghdr msg = {0};
    struct iovec io = { .iov_base = (void*)" ", .iov_len = 1 };
    char cmsgbuf[CMSG_SPACE(sizeof(fd))];
    memset(cmsgbuf, 0, sizeof(cmsgbuf));
    msg.msg_iov = &io;
    msg.msg_iovlen = 1;
    msg.msg_control = cmsgbuf;
    msg.msg_controllen = sizeof(cmsgbuf);

    struct cmsghdr *cmsg = CMSG_FIRSTHDR(&msg);
    cmsg->cmsg_level = SOL_SOCKET;
    cmsg->cmsg_type = SCM_RIGHTS;
    cmsg->cmsg_len = CMSG_LEN(sizeof(fd));
    memcpy(CMSG_DATA(cmsg), &fd, sizeof(fd));

    msg.msg_controllen = cmsg->cmsg_len;
    if (sendmsg(sock, &msg, 0) < 0) {
        return -1;
    }
    return 0;
}

int send_drm_fd_to_socket(int fd, const char *socket_path) {
    struct sockaddr_un addr;
    int sock = socket(AF_UNIX, SOCK_STREAM, 0);
    if (sock < 0) {
        return -1;
    }
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, socket_path, sizeof(addr.sun_path) - 1);
    if (connect(sock, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        close(sock);
        return -1;
    }
    int ret = send_fd(sock, fd);
    close(sock);
    return ret;
}

int receive_fd_from_socket(const char *socket_path) {
    struct sockaddr_un addr;
    int sock = socket(AF_UNIX, SOCK_STREAM, 0);
    if (sock < 0)
        return -1;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, socket_path, sizeof(addr.sun_path) - 1);
    if (connect(sock, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        close(sock);
        return -1;
    }
    struct msghdr msg = {0};
    char m_buffer[1];
    struct iovec io = { .iov_base = m_buffer, .iov_len = sizeof(m_buffer) };
    msg.msg_iov = &io;
    msg.msg_iovlen = 1;

    char cmsgbuf[CMSG_SPACE(sizeof(int))];
    msg.msg_control = cmsgbuf;
    msg.msg_controllen = sizeof(cmsgbuf);
    if (recvmsg(sock, &msg, 0) < 0) {
        close(sock);
        return -1;
    }
    struct cmsghdr *cmsg = CMSG_FIRSTHDR(&msg);
    if (!cmsg || cmsg->cmsg_len != CMSG_LEN(sizeof(int))) {
        close(sock);
        return -1;
    }
    if (cmsg->cmsg_level != SOL_SOCKET || cmsg->cmsg_type != SCM_RIGHTS) {
        close(sock);
        return -1;
    }
    int fd;
    memcpy(&fd, CMSG_DATA(cmsg), sizeof(fd));
    close(sock);
    return fd;
}

int start_display_host(const char *drm_node, const char *socket_path, int clients, uint16_t mode_width, uint16_t mode_height) {
    int fd;
    if (modeset_open(&fd, drm_node) < 0) {
        fprintf(stderr, "Failed to open DRM node %s\n", drm_node);
        return -1;
    }
    printf("Opened DRM node %s with fd %d\n", drm_node, fd);

    if (mode_width > 0 && mode_height > 0) {
        printf("Setting mode to %ux%u\n", mode_width, mode_height);
        struct modeset_output *out = (struct modeset_output *)malloc(sizeof(struct modeset_output));
        if (!out) {
            close(fd);
            return -1;
        }
        if (modeset_prepare(fd, out, mode_width, mode_height, 60) == 0) {
            struct modeset_buf buf = {0};
            buf.width = mode_width;
            buf.height = mode_height;
            if (modeset_create_fb(fd, &buf) == 0) {
                modeset_perform_modeset(fd, out, out->video_request, &out->video_plane, buf.fb, mode_width, mode_height, 0);
                modeset_destroy_fb(fd, &buf);
            }
            drmModeAtomicFree(out->video_request);
            modeset_cleanup(fd, out);
        } else {
            free(out);
        }
    }

    unlink(socket_path);
    int server = socket(AF_UNIX, SOCK_STREAM, 0);
    if (server < 0) {
        close(fd);
        return -1;
    }
    printf("Listening on socket %s for %d clients\n", socket_path, clients);
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, socket_path, sizeof(addr.sun_path) - 1);
    if (bind(server, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        close(server);
        close(fd);
        return -1;
    }
    if (listen(server, clients) < 0) {
        close(server);
        close(fd);
        return -1;
    }
    for (int i = 0; i < clients; ++i) {
        printf("Waiting for client %d/%d...\n", i + 1, clients);
        int client = accept(server, NULL, NULL);
        if (client >= 0) {
            printf("Client %d connected, sending DRM FD\n", i + 1);
            send_fd(client, fd);
            close(client);
        } else {
            perror("accept");
        }
    }
    close(server);
    printf("All clients connected. Display host ready\n");
    return fd;
}

