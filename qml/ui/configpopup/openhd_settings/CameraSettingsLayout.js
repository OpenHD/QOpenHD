.pragma library

// Shared by the category strips and their parent tab. Hidden expert-only
// settings do not count as content in normal mode.
function categoryFor(id, model) {
        if (model && typeof model.get_ui_metadata === "function") {
            var category = model.get_ui_metadata(id).cameraCategory
            if (category) return category
        }
        if (id.indexOf("GX_") === 0) return "IMAGE"
        if (id.indexOf("ISP_") === 0 || id.indexOf("ARDUCAM_") === 0 || id.indexOf("VEYE_") === 0 || id === "COLOR_PALETE") return "IMAGE"
        if (["IP_CAM_ADDRESS", "IP_CAM_PIPELINE"].indexOf(id) >= 0)
            return "CONNECTION"
        if (["AIR_RECORDING_E", "STREAMING_E", "BITRATE_MBITS", "VIDEO_CODEC",
             "KEYFRAME_I", "RESOLUTION_FPS"].indexOf(id) >= 0)
            return "VIDEO"
        if (id.indexOf("AWB") >= 0 || id.indexOf("WHITE_BALANCE") >= 0)
            return "IMAGE"
        if (id.indexOf("EXP") >= 0 || id.indexOf("SHUTTER") >= 0 ||
                id.indexOf("METERING") >= 0 || id === "ISO")
            return "EXPOSURE"
        if (id.indexOf("BRIGHTNESS") >= 0 || id.indexOf("CONTRAST") >= 0 ||
                id.indexOf("SATURATION") >= 0 || id.indexOf("SHARPNESS") >= 0 ||
                id.indexOf("DENOISE") >= 0)
            return "IMAGE"
        if (["CAMERA_TYPE", "ROCKCHIP_IMPL",
             "ROTATION_FLIP", "ROTATION_DEG"].indexOf(id) >= 0)
            return "CAMERA"
        return "ADVANCED"
    }


function visibleInMode(id, advanced, model) {
    if (id === "HIGH_ENCRYPTION") return false
    var metadata = model && typeof model.get_ui_metadata === "function" ? model.get_ui_metadata(id) : ({})
    if (metadata.cameraSupported === false) return false
    // Camera registry type 64 is VEYE GX/GXC IMX662 with the GX ISP.
    // Apply the hardware gate before Advanced mode can expose hidden controls.
    if (id.indexOf("GX_") === 0 && (!model || !model.param_int_exists("CAMERA_TYPE") || Number(model.get_cached_int("CAMERA_TYPE")) !== 64)) return false
    if (advanced) return true
    if (metadata.hidden) return false
    return categoryFor(id, model) !== "ADVANCED"
}
function availableParameterIds(model, advanced) {
    return model.param_ids().filter(function(id) { return visibleInMode(id, advanced, model) })
}
