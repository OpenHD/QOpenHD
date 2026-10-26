#include "VpuApi.hpp"
#include <dlfcn.h>
#include <stdexcept>
#include <string>

namespace nxp {
VpuApi::VpuApi() {
    void* handle = dlopen("libimxvpuapi2.so.2", RTLD_NOW | RTLD_LOCAL | RTLD_DEEPBIND);
    if (!handle) throw std::runtime_error(std::string("load NXP VPU API: ") + dlerror());
    try {
#define NXP_API(name) \
        name = reinterpret_cast<decltype(name)>(dlsym(handle, #name)); \
        if (!name) throw std::runtime_error("missing NXP API symbol: " #name);
        NXP_API(imx_vpu_api_dec_get_global_info)
        NXP_API(imx_vpu_api_dec_open)
        NXP_API(imx_vpu_api_dec_close)
        NXP_API(imx_vpu_api_dec_return_code_string)
        NXP_API(imx_vpu_api_dec_get_stream_info)
        NXP_API(imx_vpu_api_dec_add_framebuffers_to_pool)
        NXP_API(imx_vpu_api_dec_push_encoded_frame)
        NXP_API(imx_vpu_api_dec_decode)
        NXP_API(imx_vpu_api_dec_get_decoded_frame)
        NXP_API(imx_vpu_api_dec_return_framebuffer_to_decoder)
        NXP_API(imx_vpu_api_dec_get_skipped_frame_info)
        NXP_API(imx_dma_buffer_allocator_new)
        NXP_API(imx_dma_buffer_allocator_destroy)
        NXP_API(imx_dma_buffer_allocate)
        NXP_API(imx_dma_buffer_deallocate)
        NXP_API(imx_dma_buffer_get_fd)
#undef NXP_API
    } catch (...) { dlclose(handle); throw; }
    // Deliberately retain the local library for process lifetime. VPU frame
    // leases can outlive the receiver or a QML window during teardown.
}
const VpuApi& vpu() { static const VpuApi api; return api; }
}
