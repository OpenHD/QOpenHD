import "../MenuTypography.js" as Typography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../openhd_settings"

FocusScope {
    id: root
    objectName: "videoSettingsPage"
    readonly property bool developer: settings_form.showDeveloperSettings === true
    readonly property bool advanced: developer || settings_form.showAdvancedSettings === true
    readonly property bool linux: _qopenhd.is_linux()
    readonly property bool android: _qopenhd.is_android()
    readonly property bool rpi: _qopenhd.is_platform_rpi()
    readonly property bool rock: _qopenhd.is_platform_rock()
    readonly property bool mobile: android || (typeof QOPENHD_IS_MOBILE !== "undefined" && QOPENHD_IS_MOBILE)
    readonly property bool avcodec: typeof QOPENHD_ENABLE_VIDEO_VIA_AVCODEC !== "undefined" && QOPENHD_ENABLE_VIDEO_VIA_AVCODEC
    readonly property bool gstreamer: typeof QOPENHD_ENABLE_GSTREAMER_QMLGLSINK !== "undefined" && QOPENHD_ENABLE_GSTREAMER_QMLGLSINK
    readonly property bool nativeVideo: typeof QOPENHD_ENABLE_NXP_VIDEO !== "undefined" && QOPENHD_ENABLE_NXP_VIDEO
    readonly property bool androidVideo: typeof QOPENHD_ENABLE_VIDEO_VIA_ANDROID !== "undefined" && QOPENHD_ENABLE_VIDEO_VIA_ANDROID
    readonly property bool playback: avcodec || gstreamer || nativeVideo || androidVideo
    readonly property bool secondary: settings.secondary_camera_available === true
    readonly property bool externalDecode: avcodec && !nativeVideo && linux && (settings.dev_always_use_generic_external_decode_service || (rpi && settings.dev_rpi_use_external_omx_decode_service))
    readonly property bool fitSupported: nativeVideo || androidVideo || (avcodec && !externalDecode)
    readonly property bool softwareSupported: !nativeVideo && !externalDecode && (avcodec || gstreamer)
    readonly property bool testSupported: !nativeVideo && !externalDecode && (avcodec || gstreamer)
    readonly property bool parserSupported: avcodec && !nativeVideo && !externalDecode
    readonly property bool servicesSupported: linux && avcodec && !nativeVideo
    readonly property bool platformOptions: parserSupported || servicesSupported
    readonly property bool desktop: !mobile
    readonly property bool twoColumns: width >= 1100 && developer && playback
    readonly property real columnWidth: twoColumns ? (scroll.width - 12) / 2 : scroll.width
    readonly property var codecOptions: [{text:qsTr("H.264"), value:0}, {text:qsTr("H.265"), value:1}]
    readonly property var cursorOptions: [
        {text:qsTr("System cursor"),value:0}, {text:qsTr("Transparent arrow"),value:1},
        {text:qsTr("White arrow"),value:2}, {text:qsTr("Green arrow"),value:3},
        {text:qsTr("White hand"),value:settings.custom_cursor_type > 4 ? settings.custom_cursor_type : 4}]
    readonly property var cursorSizes: [
        {text:qsTr("Small (16 px)"),value:settings.custom_cursor_scale > 3 ? settings.custom_cursor_scale : 0},
        {text:qsTr("Medium (32 px)"),value:1}, {text:qsTr("Large (64 px)"),value:2}, {text:qsTr("Extra large (128 px)"),value:3}]
    readonly property var rotations: [{text:qsTr("0 deg"),value:0},{text:qsTr("90 deg (experimental)"),value:90},{text:qsTr("180 deg"),value:180},{text:qsTr("270 deg (experimental)"),value:270}]
    readonly property var dpiOptions: [{text:qsTr("Disabled"),value:-1},{text:qsTr("Auto (recommended)"),value:0},{text:"50",value:50},{text:"72",value:72},{text:"100",value:100},{text:"120",value:120},{text:"150",value:150}]

    function gainFocus() { scroll.forceActiveFocus() }
    function indexOfValue(options, value) {
        for (var i=0; i<options.length; ++i) if (options[i].value === value) return i
        return -1
    }
    function codecs(value) {
        // Preserve legacy MJPEG preferences only on backends that can decode it.
        return value === 2 && (avcodec || gstreamer) && !nativeVideo
                ? codecOptions.concat([{text:qsTr("MJPEG"),value:2}]) : codecOptions
    }
    function commit(key, value, restart) {
        if (settings[key] === value) return
        settings[key] = value
        if (restart) _restartqopenhdmessagebox.show()
    }
    function softwareDecode(enabled) {
        commit("qopenhd_primary_video_force_sw", enabled, false)
        commit("qopenhd_secondary_video_force_sw", enabled, false)
    }

    Flickable {
        id: scroll
        objectName: "videoSettingsScroll"
        anchors.fill: parent; anchors.margins: 10
        clip: true; contentWidth: width; contentHeight: content.height
        boundsBehavior: Flickable.StopAtBounds
        Item {
            id: content; width: scroll.width
            height: upper.height + (upper.height > 0 ? 12 : 0) + display.height
            Item {
                id: upper; width: parent.width
                height: root.twoColumns ? Math.max(left.height, right.height) : left.height + (right.height > 0 ? 12 + right.height : 0)
                Column {
                    id: left; width: root.columnWidth; spacing: 12
                    Loader {width:parent.width; active:root.advanced && root.playback; sourceComponent:decoderSection; height:item ? item.implicitHeight : 0; visible:active}
                }
                Column {
                    id:right; width:root.columnWidth; spacing:12
                    x:root.twoColumns ? left.width+12 : 0; y:root.twoColumns ? 0 : left.height+12
                    VideoSettingsGroup {
                        objectName:"videoNetworkGroup"; width:parent.width; height:implicitHeight; visible:root.developer && root.playback
                        title:qsTr("Network Input (Developer)"); subtitle:qsTr("UDP ports and input sources"); icon:"\uf519"; collapsible:true
                        VideoSettingsRow {
                            objectName:"videoPrimaryPortRow"; width:parent.width; height:implicitHeight; visible:true
                            label:qsTr("Primary video UDP port"); hint:qsTr("Port for the incoming primary stream."); icon:""; controlWidth:210; minimumControlWidth:180
                            VideoNumberControl { objectName:"videoPrimaryPort"; anchors.fill:parent; from:1; to:6900; value:settings.qopenhd_primary_video_rtp_input_port; onModified:function(value){root.commit("qopenhd_primary_video_rtp_input_port",value,false)} }
                        }
                        VideoSettingsRow {
                            objectName:"videoSecondaryPortRow"; width:parent.width; height:implicitHeight; visible:root.secondary
                            label:qsTr("Secondary video UDP port"); hint:qsTr("Port for the incoming secondary stream."); icon:""; controlWidth:210; minimumControlWidth:180
                            VideoNumberControl { objectName:"videoSecondaryPort"; anchors.fill:parent; from:1; to:6900; value:settings.qopenhd_secondary_video_rtp_input_port; onModified:function(value){root.commit("qopenhd_secondary_video_rtp_input_port",value,false)} }
                        }
                        VideoSettingsRow {
                            objectName:"videoAndroidInputRow"; width:parent.width; height:implicitHeight; visible:root.secondary && root.android && root.androidVideo
                            label:qsTr("Secondary input (Android)"); hint:qsTr("Choose the secondary video input source."); icon:""; controlWidth:210; minimumControlWidth:180
                            CompactLinkComboBox { objectName:"videoAndroidInput"; anchors.fill:parent; model:[qsTr("UDP secondary port"),qsTr("UDP primary port"),qsTr("HTTP test clip")]; currentIndex:settings.dev_secondary_video_input_mode; onActivated:root.commit("dev_secondary_video_input_mode",currentIndex,false) }
                        }
                    }
                    VideoSettingsGroup {
                        objectName:"videoDiagnosticsGroup"; width:parent.width; height:implicitHeight; visible:root.developer && (root.testSupported || (root.android && root.playback))
                        title:qsTr("Diagnostics & Testing (Developer)"); subtitle:qsTr("Test sources and debugging"); icon:"\uf0c3"; collapsible:true
                        VideoSettingsRow {
                            objectName:"videoTestModeRow"; width:parent.width; height:implicitHeight; visible:root.testSupported
                            label:qsTr("Video test mode"); hint:qsTr("Use a test source instead of network video."); icon:""; controlWidth:210; minimumControlWidth:180
                            CompactLinkComboBox { objectName:"videoTestMode"; anchors.fill:parent; model:[qsTr("Disabled"),qsTr("Raw video"),qsTr("Decode and encode")]; currentIndex:settings.dev_test_video_mode; onActivated:root.commit("dev_test_video_mode",currentIndex,false) }
                        }
                        VideoSettingsRow {
                            objectName:"videoTestFpsRow"; width:parent.width; height:implicitHeight; visible:root.avcodec && !root.nativeVideo && settings.dev_test_video_mode !== 0
                            label:qsTr("Limit FPS in test file"); hint:qsTr("Maximum playback rate; -1 disables the limit."); icon:""; controlWidth:210; minimumControlWidth:180
                            VideoNumberControl { objectName:"videoTestFps"; anchors.fill:parent; from:-1; to:240; value:settings.dev_limit_fps_on_test_file; onModified:function(value){root.commit("dev_limit_fps_on_test_file",value,false)} }
                        }
                        VideoSettingsRow {
                            objectName:"videoDisablePrimaryRow"; width:parent.width; height:implicitHeight; visible:root.android && root.playback
                            label:qsTr("Disable primary video (Android)"); hint:qsTr("Stop primary rendering; restart required."); icon:""; controlWidth:46; minimumControlWidth:0
                            WidgetToggle { objectName:"videoDisablePrimary"; anchors.fill:parent; checked:settings.dev_disable_primary_video; onToggled:root.commit("dev_disable_primary_video",checked,true) }
                        }
                    }
                    VideoSettingsGroup {
                        objectName:"videoPlatformGroup"; width:parent.width; height:implicitHeight; visible:root.developer && root.platformOptions
                        title:qsTr("Platform Options (Developer)"); subtitle:qsTr("Platform-specific decoder controls"); icon:"\uf0ad"; collapsible:true
                        VideoSettingsRow {
                            objectName:"videoParserRow"; width:parent.width; height:implicitHeight; visible:root.parserSupported
                            label:qsTr("Low-latency RTP parser"); hint:qsTr("Use the direct RTP input path."); icon:""; controlWidth:46; minimumControlWidth:0
                            WidgetToggle { objectName:"videoParser"; anchors.fill:parent; checked:settings.dev_use_low_latency_parser_when_possible; onToggled:root.commit("dev_use_low_latency_parser_when_possible",checked,false) }
                        }
                        VideoSettingsRow {
                            objectName:"videoRpiDecodeRow"; width:parent.width; height:implicitHeight; visible:root.servicesSupported && root.rpi
                            label:qsTr("Raspberry Pi decoding (OMX)"); hint:qsTr("Use the external Raspberry Pi decoder."); icon:""; controlWidth:46; minimumControlWidth:0
                            WidgetToggle { objectName:"videoRpiDecode"; anchors.fill:parent; checked:settings.dev_rpi_use_external_omx_decode_service; onToggled:root.commit("dev_rpi_use_external_omx_decode_service",checked,false) }
                        }
                        VideoSettingsRow {
                            objectName:"videoExternalDecodeRow"; width:parent.width; height:implicitHeight; visible:root.servicesSupported
                            label:qsTr("External decoding service"); hint:qsTr("Decode outside QOpenHD using a Linux service."); icon:""; controlWidth:46; minimumControlWidth:0
                            WidgetToggle { objectName:"videoExternalDecode"; anchors.fill:parent; checked:settings.dev_always_use_generic_external_decode_service; onToggled:root.commit("dev_always_use_generic_external_decode_service",checked,false) }
                        }
                        VideoSettingsRow {
                            objectName:"videoKmsRow"; width:parent.width; height:implicitHeight; visible:root.servicesSupported && !root.rock && !settings.dev_rpi_use_external_omx_decode_service && !settings.dev_always_use_generic_external_decode_service
                            label:qsTr("KMS DRM overlay renderer"); hint:qsTr("Requires restart; external decoding must be off."); icon:""; controlWidth:46; minimumControlWidth:0
                            WidgetToggle { objectName:"videoKms"; anchors.fill:parent; checked:settings.enable_kms_renderer; onToggled:root.commit("enable_kms_renderer",checked,false) }
                        }
                    }
                }
            }
            VideoSettingsGroup {
                id:display; objectName:"videoDisplayGroup"; width:parent.width; y:upper.height+(upper.height>0?12:0); height:implicitHeight
                title:qsTr("Screen & Display"); subtitle:qsTr("Video sizing, interface and pointer settings"); icon:"\uf108"
                GridLayout {
                    id:displayRows; objectName:"videoDisplayRows"
                    width:parent.width; height:implicitHeight; columns:width>=850?2:1; columnSpacing:0; rowSpacing:0
                        VideoSettingsRow {
                            objectName:"videoFitRow"; Layout.fillWidth:true; Layout.minimumWidth:0; Layout.preferredHeight:implicitHeight; Layout.fillHeight:false; Layout.alignment:Qt.AlignTop; visible:root.fitSupported
                            label:qsTr("Scale video to fit screen"); hint:qsTr("Fit the primary video inside the display area."); icon:"\uf065"; controlWidth:46; minimumControlWidth:0
                            WidgetToggle { objectName:"videoFit"; anchors.fill:parent; checked:settings.primary_video_scale_to_fit; onToggled:root.commit("primary_video_scale_to_fit",checked,false) }
                        }
                        VideoSettingsRow {
                            objectName:"videoSwapRow"; Layout.fillWidth:true; Layout.minimumWidth:0; Layout.preferredHeight:implicitHeight; Layout.fillHeight:false; Layout.alignment:Qt.AlignTop; visible:root.secondary && root.playback
                            label:qsTr("Swap video feeds"); hint:qsTr("Exchange the primary and secondary video positions."); icon:"\uf074"; controlWidth:46; minimumControlWidth:0
                            WidgetToggle { objectName:"videoSwap"; anchors.fill:parent; checked:settings.qopenhd_switch_primary_secondary; onToggled:root.commit("qopenhd_switch_primary_secondary",checked,false) }
                        }
                    VideoSettingsRow {
                        objectName:"videoAppScaleRow"; Layout.fillWidth:true; Layout.minimumWidth:0; Layout.preferredHeight:implicitHeight; Layout.fillHeight:false; Layout.alignment:Qt.AlignTop; visible:true
                        label:qsTr("Application Scale"); hint:qsTr("Resize the application interface; restart required."); icon:""; controlWidth:210; minimumControlWidth:180
                        MapValueSlider { objectName:"videoAppScale"; anchors.fill:parent; from:0.3; to:2.5; stepSize:0.1; value:settings.global_scale; displayText:value.toFixed(1)+"x"; onMoved:root.commit("global_scale",value,true) }
                    }
                    VideoSettingsRow {
                        objectName:"videoAutoHideRow"; Layout.fillWidth:true; Layout.minimumWidth:0; Layout.preferredHeight:implicitHeight; Layout.fillHeight:false; Layout.alignment:Qt.AlignTop; visible:root.desktop
                        label:qsTr("Auto-Hide Cursor"); hint:qsTr("Hide the pointer when it is inactive."); icon:""; controlWidth:46; minimumControlWidth:0
                        WidgetToggle { objectName:"videoAutoHide"; anchors.fill:parent; checked:settings.enable_cursor_auto_hide; onToggled:{root.commit("enable_cursor_auto_hide",checked,false);_mouseHelper.set_hide_cursor_inactive_enable(checked)} }
                    }
                    VideoSettingsRow {
                        objectName:"videoCursorStyleRow"; Layout.fillWidth:true; Layout.minimumWidth:0; Layout.preferredHeight:implicitHeight; Layout.fillHeight:false; Layout.alignment:Qt.AlignTop; visible:root.desktop
                        label:qsTr("Cursor Appearance"); hint:qsTr("Choose the pointer used by the application."); icon:""; controlWidth:210; minimumControlWidth:180
                        CompactLinkComboBox { objectName:"videoCursorStyle"; anchors.fill:parent; model:root.cursorOptions; textRole:"text"; currentIndex:root.indexOfValue(model,settings.custom_cursor_type); onActivated:{root.commit("custom_cursor_type",model[currentIndex].value,false);_mouseHelper.set_active_cursor_type_and_scale(settings.custom_cursor_type,settings.custom_cursor_scale)} }
                    }
                    VideoSettingsRow {
                        objectName:"videoCursorSizeRow"; Layout.fillWidth:true; Layout.minimumWidth:0; Layout.preferredHeight:implicitHeight; Layout.fillHeight:false; Layout.alignment:Qt.AlignTop; visible:root.desktop
                        label:qsTr("Cursor Size"); hint:qsTr("Set the size of the custom pointer."); icon:""; controlWidth:210; minimumControlWidth:180
                        CompactLinkComboBox { objectName:"videoCursorSize"; anchors.fill:parent; model:root.cursorSizes; textRole:"text"; currentIndex:root.indexOfValue(model,settings.custom_cursor_scale); onActivated:{root.commit("custom_cursor_scale",model[currentIndex].value,false);_mouseHelper.set_active_cursor_type_and_scale(settings.custom_cursor_type,settings.custom_cursor_scale)} }
                    }
                    VideoSettingsRow {
                        objectName:"videoRotationRow"; Layout.fillWidth:true; Layout.minimumWidth:0; Layout.preferredHeight:implicitHeight; Layout.fillHeight:false; Layout.alignment:Qt.AlignTop; visible:root.advanced
                        label:qsTr("Screen Rotation"); hint:qsTr("Rotate the interface; 90/270 deg are experimental."); icon:""; controlWidth:210; minimumControlWidth:180
                        CompactLinkComboBox { objectName:"videoRotation"; anchors.fill:parent; model:root.rotations; textRole:"text"; currentIndex:root.indexOfValue(model,settings.general_screen_rotation); onActivated:root.commit("general_screen_rotation",model[currentIndex].value,false) }
                    }
                    VideoSettingsRow {
                        objectName:"videoFullscreenRow"; Layout.fillWidth:true; Layout.minimumWidth:0; Layout.preferredHeight:implicitHeight; Layout.fillHeight:false; Layout.alignment:Qt.AlignTop; visible:root.advanced && root.desktop && !root.nativeVideo && !root.rpi
                        label:qsTr("Fullscreen"); hint:qsTr("Use the whole desktop display."); icon:""; controlWidth:46; minimumControlWidth:0
                        WidgetToggle { objectName:"videoFullscreen"; anchors.fill:parent; checked:settings.dev_force_show_full_screen; onToggled:root.commit("dev_force_show_full_screen",checked,false) }
                    }
                    VideoSettingsRow {
                        objectName:"videoTransparentSettingsRow"; Layout.fillWidth:true; Layout.minimumWidth:0; Layout.preferredHeight:implicitHeight; Layout.fillHeight:false; Layout.alignment:Qt.AlignTop; visible:root.advanced
                        label:qsTr("Transparent Settings"); hint:qsTr("Use a transparent settings overlay."); icon:""; controlWidth:46; minimumControlWidth:0
                        WidgetToggle { objectName:"videoTransparentSettings"; anchors.fill:parent; checked:settings.screen_settings_openhd_parameters_transparent; onToggled:root.commit("screen_settings_openhd_parameters_transparent",checked,false) }
                    }
                    VideoSettingsRow {
                        objectName:"videoTransparentBackgroundRow"; Layout.fillWidth:true; Layout.minimumWidth:0; Layout.preferredHeight:implicitHeight; Layout.fillHeight:false; Layout.alignment:Qt.AlignTop; visible:root.developer && !root.nativeVideo
                        label:qsTr("Transparent Application Background"); hint:qsTr("Developer option for the window background."); icon:""; controlWidth:46; minimumControlWidth:0
                        WidgetToggle { objectName:"videoTransparentBackground"; anchors.fill:parent; checked:settings.app_background_transparent; onToggled:root.commit("app_background_transparent",checked,false) }
                    }
                    VideoSettingsRow {
                        objectName:"videoSwapIntervalRow"; Layout.fillWidth:true; Layout.minimumWidth:0; Layout.preferredHeight:implicitHeight; Layout.fillHeight:false; Layout.alignment:Qt.AlignTop; visible:root.developer && root.desktop && !root.nativeVideo
                        label:qsTr("Swap Interval 0"); hint:qsTr("Experimental rendering latency option; restart required."); icon:""; controlWidth:46; minimumControlWidth:0
                        WidgetToggle { objectName:"videoSwapInterval"; anchors.fill:parent; checked:settings.dev_set_swap_interval_zero; onToggled:root.commit("dev_set_swap_interval_zero",checked,false) }
                    }
                    VideoSettingsRow {
                        objectName:"videoFontDpiRow"; Layout.fillWidth:true; Layout.minimumWidth:0; Layout.preferredHeight:implicitHeight; Layout.fillHeight:false; Layout.alignment:Qt.AlignTop; visible:root.developer
                        label:qsTr("Font DPI"); hint:qsTr("Override text and line scaling; restart required."); icon:""; controlWidth:210; minimumControlWidth:180
                        CompactLinkComboBox { objectName:"videoFontDpi"; anchors.fill:parent; model:root.dpiOptions; textRole:"text"; currentIndex:root.indexOfValue(model,settings.screen_custom_font_dpi); onActivated:root.commit("screen_custom_font_dpi",model[currentIndex].value,true) }
                    }
                }
            }
        }
    }
    Component {
        id: decoderSection
        VideoSettingsGroup {
            objectName:"videoDecoderGroup"; width:root.columnWidth; height:implicitHeight
            title:qsTr("Decoder Settings"); subtitle:qsTr("Codec and local decoding options"); icon:"\uf2db"; collapsible:true
            VideoSettingsRow {
                objectName:"videoPrimaryCodecRow"; width:parent.width; height:implicitHeight; visible:true
                label:qsTr("Primary video codec"); hint:qsTr("Codec of the incoming primary stream."); icon:""; controlWidth:210; minimumControlWidth:180
                CompactLinkComboBox { objectName:"videoPrimaryCodec"; anchors.fill:parent; model:root.codecs(settings.qopenhd_primary_video_codec); textRole:"text"; currentIndex:root.indexOfValue(model,settings.qopenhd_primary_video_codec); displayText:currentIndex>=0?currentText:qsTr("Unsupported selection"); onActivated:root.commit("qopenhd_primary_video_codec",model[currentIndex].value,false) }
            }
            VideoSettingsRow {
                objectName:"videoSecondaryCodecRow"; width:parent.width; height:implicitHeight; visible:root.secondary
                label:qsTr("Secondary video codec"); hint:qsTr("Codec of the incoming secondary stream."); icon:""; controlWidth:210; minimumControlWidth:180
                CompactLinkComboBox { objectName:"videoSecondaryCodec"; anchors.fill:parent; model:root.codecs(settings.qopenhd_secondary_video_codec); textRole:"text"; currentIndex:root.indexOfValue(model,settings.qopenhd_secondary_video_codec); displayText:currentIndex>=0?currentText:qsTr("Unsupported selection"); onActivated:root.commit("qopenhd_secondary_video_codec",model[currentIndex].value,false) }
            }
            VideoSettingsRow {
                objectName:"videoSoftwareRow"; width:parent.width; height:implicitHeight; visible:root.softwareSupported
                label:qsTr("Use software decoding"); hint:qsTr("Force CPU decoding for both video streams."); icon:""; controlWidth:46; minimumControlWidth:0
                WidgetToggle { objectName:"videoSoftware"; anchors.fill:parent; checked:settings.qopenhd_primary_video_force_sw; onToggled:root.softwareDecode(checked) }
            }
        }
    }
}
