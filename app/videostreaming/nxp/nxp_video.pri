!linux: error(NXP native video requires Linux)
!equals(QT_MAJOR_VERSION, 5): error(NXP native video currently targets Qt 5.15 Wayland)
QT += gui-private
CONFIG -= ltcg
CONFIG += link_pkgconfig
PKGCONFIG += wayland-client libdrm
DEFINES += QOPENHD_ENABLE_NXP_VIDEO IS_PLATFORM_NXP
LIBS += -ldl -pthread
LIBS += -lEGL
INCLUDEPATH += $$OUT_PWD/nxp-protocols
protocol_dir = $$OUT_PWD/nxp-protocols
mkpath($$protocol_dir)
isEmpty(WAYLAND_PROTOCOLS_DIR): WAYLAND_PROTOCOLS_DIR = /usr/share/wayland-protocols
isEmpty(WAYLAND_SCANNER): WAYLAND_SCANNER = wayland-scanner
dma_xml = $$WAYLAND_PROTOCOLS_DIR/unstable/linux-dmabuf/linux-dmabuf-unstable-v1.xml
view_xml = $$WAYLAND_PROTOCOLS_DIR/stable/viewporter/viewporter.xml
present_xml = $$WAYLAND_PROTOCOLS_DIR/stable/presentation-time/presentation-time.xml
!system($$WAYLAND_SCANNER client-header $$shell_quote($$dma_xml) $$shell_quote($$protocol_dir/linux-dmabuf-client-protocol.h)): error(DMA-BUF header generation failed)
!system($$WAYLAND_SCANNER private-code $$shell_quote($$dma_xml) $$shell_quote($$protocol_dir/linux-dmabuf-protocol.c)): error(DMA-BUF code generation failed)
!system($$WAYLAND_SCANNER client-header $$shell_quote($$view_xml) $$shell_quote($$protocol_dir/viewporter-client-protocol.h)): error(Viewporter header generation failed)
!system($$WAYLAND_SCANNER private-code $$shell_quote($$view_xml) $$shell_quote($$protocol_dir/viewporter-protocol.c)): error(Viewporter code generation failed)
SOURCES += $$protocol_dir/linux-dmabuf-protocol.c $$protocol_dir/viewporter-protocol.c
!system($$WAYLAND_SCANNER client-header $$shell_quote($$present_xml) $$shell_quote($$protocol_dir/presentation-time-client-protocol.h)): error(Presentation header generation failed)
!system($$WAYLAND_SCANNER private-code $$shell_quote($$present_xml) $$shell_quote($$protocol_dir/presentation-time-protocol.c)): error(Presentation code generation failed)
SOURCES += $$protocol_dir/presentation-time-protocol.c
SOURCES += $$PWD/VpuApi.cpp $$PWD/HantroDecoder.cpp $$PWD/UdpVideo.cpp $$PWD/WaylandVideo.cpp $$PWD/NxpVideoController.cpp
HEADERS += $$PWD/VpuApi.hpp $$PWD/HantroDecoder.hpp $$PWD/UdpVideo.hpp $$PWD/WaylandVideo.hpp $$PWD/NxpVideoController.hpp $$PWD/RtpAccessUnit.hpp
SOURCES += $$PWD/NxpVideoItem.cpp
HEADERS += $$PWD/NxpVideoItem.hpp
boot_dir = $$OUT_PWD/nxp-boot-video
!system(python3 $$shell_quote($$PWD/../../../tools/nxp-prepare-boot-video.py) $$shell_quote($$PWD/../../../qml/boot-video.mp4) $$shell_quote($$boot_dir)): error(NXP boot movie preparation failed)
RESOURCES += $$boot_dir/boot-video.qrc
