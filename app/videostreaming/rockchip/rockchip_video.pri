!linux: error(Rockchip native video requires Linux)
!equals(QT_MAJOR_VERSION, 5): error(Rockchip native video requires Qt 5 Wayland)
QT += gui-private
CONFIG -= ltcg
CONFIG += link_pkgconfig
PKGCONFIG += wayland-client libdrm
# Retain the existing QML native-presentation feature flag and item names.
DEFINES += QOPENHD_ENABLE_NXP_VIDEO QOPENHD_ENABLE_ROCKCHIP_VIDEO
LIBS += -lrockchip_mpp -lEGL -pthread
isEmpty(ROCKCHIP_MPP_INCLUDE): ROCKCHIP_MPP_INCLUDE = /usr/local/include/rockchip
INCLUDEPATH += $$ROCKCHIP_MPP_INCLUDE $$OUT_PWD/nxp-protocols
native_dir = $$PWD/../nxp
protocol_dir = $$OUT_PWD/nxp-protocols
mkpath($$protocol_dir)
isEmpty(WAYLAND_PROTOCOLS_DIR): WAYLAND_PROTOCOLS_DIR = /usr/share/wayland-protocols
isEmpty(WAYLAND_SCANNER): WAYLAND_SCANNER = wayland-scanner
protocols = linux-dmabuf viewporter presentation-time
for(proto, protocols) {
    equals(proto, linux-dmabuf): xml = $$WAYLAND_PROTOCOLS_DIR/unstable/linux-dmabuf/linux-dmabuf-unstable-v1.xml
    equals(proto, viewporter): xml = $$WAYLAND_PROTOCOLS_DIR/stable/viewporter/viewporter.xml
    equals(proto, presentation-time): xml = $$WAYLAND_PROTOCOLS_DIR/stable/presentation-time/presentation-time.xml
    !system($$WAYLAND_SCANNER client-header $$shell_quote($$xml) $$shell_quote($$protocol_dir/$${proto}-client-protocol.h)): error(Wayland header generation failed)
    !system($$WAYLAND_SCANNER private-code $$shell_quote($$xml) $$shell_quote($$protocol_dir/$${proto}-protocol.c)): error(Wayland code generation failed)
    SOURCES += $$protocol_dir/$${proto}-protocol.c
}
SOURCES += $$PWD/MppDecoder.cpp $$native_dir/UdpVideo.cpp $$native_dir/WaylandVideo.cpp $$native_dir/NxpVideoController.cpp $$native_dir/NxpVideoItem.cpp
HEADERS += $$PWD/MppDecoder.hpp $$native_dir/DecodedFrame.hpp $$native_dir/UdpVideo.hpp $$native_dir/WaylandVideo.hpp $$native_dir/NxpVideoController.hpp $$native_dir/NxpVideoItem.hpp $$native_dir/RtpAccessUnit.hpp
boot_dir = $$OUT_PWD/nxp-boot-video
!system(python3 $$shell_quote($$PWD/../../../tools/nxp-prepare-boot-video.py) $$shell_quote($$PWD/../../../qml/boot-video.mp4) $$shell_quote($$boot_dir)): error(Native boot movie preparation failed)
RESOURCES += $$boot_dir/boot-video.qrc
