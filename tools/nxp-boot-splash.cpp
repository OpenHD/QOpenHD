// Early userspace splash matching the Pi Plymouth theme. Does not own DRM.
// Weston stops this framebuffer writer before taking over the display.
#include <linux/fb.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <png.h>
#include <signal.h>
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <thread>
#include <vector>

static volatile sig_atomic_t stopping = 0;
static void stop(int) { stopping = 1; }
int main(int argc, char** argv) {
    if (argc != 2) return 2;
    signal(SIGTERM, stop); signal(SIGINT, stop);
    int fd = -1;
    for (unsigned i = 0; i < 30 && !stopping; ++i) {
        fd = open("/dev/fb0", O_RDWR | O_CLOEXEC);
        if (fd >= 0) break;
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    if (fd < 0 || stopping) return 0; // A missing monitor must not block boot.
    fb_fix_screeninfo fix{}; fb_var_screeninfo var{};
    if (ioctl(fd, FBIOGET_FSCREENINFO, &fix) || ioctl(fd, FBIOGET_VSCREENINFO, &var)) { close(fd); return 1; }
    const auto bpp = var.bits_per_pixel / 8;
    const uint64_t end = uint64_t(var.yoffset + var.yres) * fix.line_length;
    if (!var.xres || !var.yres || (bpp != 2 && bpp != 3 && bpp != 4) ||
        uint64_t(var.xoffset + var.xres) * bpp > fix.line_length || end > fix.smem_len ||
        var.red.length > 8 || var.green.length > 8 || var.blue.length > 8 ||
        var.red.offset + var.red.length > var.bits_per_pixel ||
        var.green.offset + var.green.length > var.bits_per_pixel ||
        var.blue.offset + var.blue.length > var.bits_per_pixel) { close(fd); return 1; }
    auto pixels = static_cast<unsigned char*>(mmap(nullptr, fix.smem_len, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0));
    if (pixels == MAP_FAILED) { close(fd); return 1; }
    png_image image{}; image.version = PNG_IMAGE_VERSION;
    if (!png_image_begin_read_from_file(&image, argv[1])) { munmap(pixels, fix.smem_len); close(fd); return 1; }
    if (image.width > 2048 || image.height > 2048) { png_image_free(&image); munmap(pixels, fix.smem_len); close(fd); return 1; }
    image.format = PNG_FORMAT_RGBA;
    std::vector<unsigned char> logo(PNG_IMAGE_SIZE(image));
    if (!png_image_finish_read(&image, nullptr, logo.data(), 0, nullptr)) { png_image_free(&image); munmap(pixels, fix.smem_len); close(fd); return 1; }
    auto pixel = [&](unsigned x, unsigned y, unsigned r, unsigned g, unsigned b) {
        if (x >= var.xres || y >= var.yres) return;
        const uint32_t value = ((r >> (8 - var.red.length)) << var.red.offset) |
            ((g >> (8 - var.green.length)) << var.green.offset) |
            ((b >> (8 - var.blue.length)) << var.blue.offset);
        memcpy(pixels + (y + var.yoffset) * fix.line_length + (x + var.xoffset) * bpp, &value, bpp);
    };
    for (unsigned y = 0; y < var.yres; ++y)
        memset(pixels + (y + var.yoffset) * fix.line_length + var.xoffset * bpp, 0, var.xres * bpp);
    const unsigned size = std::max(1u, std::min(var.xres, var.yres) * 24 / 100);
    const unsigned left = (var.xres - size)/2, top = (var.yres - size)/2;
    for (unsigned y = 0; y < size; ++y) for (unsigned x = 0; x < size; ++x) {
        auto p = &logo[((uint64_t(y) * image.height / size) * image.width + uint64_t(x) * image.width / size) * 4];
        pixel(left+x, top+y, unsigned(p[0])*p[3]/255, unsigned(p[1])*p[3]/255, unsigned(p[2])*p[3]/255);
    }
    png_image_free(&image);
    fprintf(stderr, "OpenHD early framebuffer splash: %ux%u framebuffer ready\n", var.xres, var.yres);
    // Match the Pi's 6-pixel dots and 10-pixel spacing. A bounded lifetime also
    // leaves Air/headless boots independent of any later UI service.
    for (unsigned frame = 0; frame < 500 && !stopping; ++frame) {
        for (int i = 0; i < 3; ++i) {
            const double alpha = .25 + .75 * (std::cos(frame * .15 - i * .9) + 1)/2;
            for (int y = 0; y < 6; ++y) for (int x = 0; x < 6; ++x) {
                const bool inside = (x-2.5)*(x-2.5)+(y-2.5)*(y-2.5) <= 9;
                pixel(int(var.xres/2)-19+i*16+x, top+size+24+y,
                      0, inside ? unsigned(174*alpha) : 0, inside ? unsigned(239*alpha) : 0);
            }
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    munmap(pixels, fix.smem_len); close(fd);
    return 0;
}
