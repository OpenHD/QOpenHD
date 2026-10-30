.pragma library

// Shared by the category strips and their parent tab. Hidden expert-only
// settings do not count as content in normal mode.
function categoryFor(id) {
        if (["IP_CAM_ADDRESS", "IP_CAM_PIPELINE"].indexOf(id) >= 0)
            return "CONNECTION"
        if (["AIR_RECORDING_E", "STREAMING_E", "BITRATE_MBITS", "VIDEO_CODEC",
             "KEYFRAME_I", "RESOLUTION_FPS"].indexOf(id) >= 0)
            return "VIDEO"
        if (id.indexOf("AWB") >= 0 || id.indexOf("WHITE_BALANCE") >= 0)
            return "COLOR"
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
    if (advanced) return true
    if (model && typeof model.get_ui_metadata === "function" && model.get_ui_metadata(id).hidden) return false
    return categoryFor(id) !== "ADVANCED"
}
function availableParameterIds(model, advanced) {
    return model.param_ids().filter(function(id) { return visibleInMode(id, advanced, model) })
}
