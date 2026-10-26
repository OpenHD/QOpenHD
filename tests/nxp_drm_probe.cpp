#include <xf86drm.h>
#include <xf86drmMode.h>
#include <fcntl.h>
#include <unistd.h>
#include <cstdio>
#include <initializer_list>
int main() {
    for (const char* path : {"/dev/dri/card0", "/dev/dri/card1"}) {
        int fd = open(path, O_RDWR | O_CLOEXEC);
        if (fd < 0) continue;
        auto version = drmGetVersion(fd);
        printf("%s driver=%s\n", path, version ? version->name : "unknown");
        if (version) drmFreeVersion(version);
        drmSetClientCap(fd, DRM_CLIENT_CAP_UNIVERSAL_PLANES, 1);
        auto planes = drmModeGetPlaneResources(fd);
        if (planes) {
            for (unsigned i=0; i<planes->count_planes; ++i) {
                auto p = drmModeGetPlane(fd, planes->planes[i]);
                printf(" plane=%u crtcs=0x%x formats:", p->plane_id, p->possible_crtcs);
                for (unsigned j=0; j<p->count_formats; ++j) {
                    auto f=p->formats[j]; printf(" %c%c%c%c", f&255, (f>>8)&255, (f>>16)&255, (f>>24)&255);
                }
                printf("\n"); drmModeFreePlane(p);
            }
            drmModeFreePlaneResources(planes);
        }
        close(fd);
    }
}
