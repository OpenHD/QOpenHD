#pragma once
#include <imxvpuapi2/imxvpuapi2.h>
#include <imxdmabuffer/imxdmabuffer.h>

namespace nxp {
// Hantro's encoder dependency exports generic symbols such as crc32. Loading
// it into Qt's global symbol scope can redirect libpng calls into vendor code.
// Keep the entire VPU dependency tree local and resolve only its public API.
struct VpuApi {
#define NXP_API(name) decltype(&::name) name = nullptr;
    NXP_API(imx_vpu_api_dec_get_global_info)
    NXP_API(imx_vpu_api_dec_open)
    NXP_API(imx_vpu_api_dec_close)
    NXP_API(imx_vpu_api_dec_return_code_string)
    NXP_API(imx_vpu_api_dec_get_stream_info)
    NXP_API(imx_vpu_api_dec_add_framebuffers_to_pool)
    NXP_API(imx_vpu_api_dec_push_encoded_frame)
    NXP_API(imx_vpu_api_dec_decode)
    NXP_API(imx_vpu_api_dec_enable_drain_mode)
    NXP_API(imx_vpu_api_dec_get_decoded_frame)
    NXP_API(imx_vpu_api_dec_return_framebuffer_to_decoder)
    NXP_API(imx_vpu_api_dec_get_skipped_frame_info)
    NXP_API(imx_dma_buffer_allocator_new)
    NXP_API(imx_dma_buffer_allocator_destroy)
    NXP_API(imx_dma_buffer_allocate)
    NXP_API(imx_dma_buffer_deallocate)
    NXP_API(imx_dma_buffer_get_fd)
#undef NXP_API
    VpuApi();
};
const VpuApi& vpu();
}
