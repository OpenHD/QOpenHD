#include "display_host.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

int main(int argc, char **argv) {
    const char *drm_node = "/dev/dri/card0";
    const char *socket_path = "/tmp/drm-master";
    int clients = 2;
    uint16_t width = 0, height = 0;

    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "720p") == 0) {
            width = 1280;
            height = 720;
        } else if (strcmp(argv[i], "1080p") == 0) {
            width = 1920;
            height = 1080;
        } else if (strcmp(argv[i], "--socket") == 0 && i + 1 < argc) {
            socket_path = argv[++i];
        } else if (strcmp(argv[i], "--drm") == 0 && i + 1 < argc) {
            drm_node = argv[++i];
        } else if (strcmp(argv[i], "--clients") == 0 && i + 1 < argc) {
            clients = atoi(argv[++i]);
        } else {
            fprintf(stderr, "Usage: %s [720p|1080p] [--socket path] [--drm node] [--clients n]\n", argv[0]);
            return 1;
        }
    }

    pid_t pid = fork();
    if (pid == 0) {
        sleep(1);
        setenv("FPVUE_DRM_FD_SOCKET", socket_path, 1);
        execlp("fpvue", "fpvue", "--color-cycle", NULL);
        perror("execlp fpvue");
        return 1;
    }

    printf("Starting display host with DRM node %s, socket %s, expecting %d clients", drm_node, socket_path, clients);
    if (width > 0 && height > 0) {
        printf(", forcing mode %ux%u", width, height);
    }
    printf("\n");
    printf("Launched fpvue color cycle client as PID %d.\n", pid);
    printf("To run a Qt5 application against this host, set FPVUE_DRM_FD_SOCKET=%s and export QT_QPA_PLATFORM=eglfs before launching your Qt app.\n", socket_path);

    int fd = start_display_host(drm_node, socket_path, clients, width, height);
    if (fd < 0) {
        fprintf(stderr, "Failed to start display host\n");
        return 1;
    }
    printf("Display host running. DRM FD %d shared on %s\n", fd, socket_path);
    while (1) {
        sleep(60);
    }
    return 0;
}
