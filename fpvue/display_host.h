#ifndef DISPLAY_HOST_H
#define DISPLAY_HOST_H

#include <stdint.h>

int send_drm_fd_to_socket(int fd, const char *socket_path);
int receive_fd_from_socket(const char *socket_path);
int start_display_host(const char *drm_node, const char *socket_path, int clients, uint16_t mode_width, uint16_t mode_height);

#endif // DISPLAY_HOST_H
