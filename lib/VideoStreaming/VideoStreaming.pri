# -------------------------------------------------
# QGroundControl - Micro Air Vehicle Groundstation
# Please see our website at <http://qgroundcontrol.org>
# Maintainer:
# Lorenz Meier <lm@inf.ethz.ch>
# (c) 2009-2015 QGroundControl Developers
#
# This file is part of the open groundstation project
# QGroundControl is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# QGroundControl is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with QGroundControl. If not, see <http://www.gnu.org/licenses/>.
#
# Author: Gus Grubba <mavlink@grubba.com>
# -------------------------------------------------

#
#-- Depends on gstreamer, which can be found at: http://gstreamer.freedesktop.org/download/
#

LinuxBuild {
    CONFIG += link_pkgconfig
    packagesExist(gstreamer-1.0) {
        PKGCONFIG   += gstreamer-1.0  gstreamer-video-1.0 gstreamer-gl-1.0
        CONFIG      += VideoEnabled
    }
} else: JetsonBuild {
    CONFIG += link_pkgconfig
    packagesExist(gstreamer-1.0) {
        PKGCONFIG   += gstreamer-1.0  gstreamer-video-1.0 gstreamer-gl-1.0
        CONFIG      += VideoEnabled
    }
} else: RaspberryPiBuild {
    CONFIG += link_pkgconfig
    packagesExist(gstreamer-1.0) {
        PKGCONFIG   += gstreamer-1.0  gstreamer-video-1.0 gstreamer-gl-1.0
        CONFIG      += VideoEnabled
    }
} else:MacBuild {
    #- gstreamer framework installed by the gstreamer devel installer
    GST_ROOT = /Library/Frameworks/GStreamer.framework
    exists($$GST_ROOT) {
        CONFIG      += VideoEnabled
        INCLUDEPATH += $$GST_ROOT/Headers
        LIBS        += -F/Library/Frameworks -framework GStreamer
    }
} else:iOSBuild {
    #- gstreamer framework installed by the gstreamer iOS SDK installer (default to home directory)
    GST_ROOT = $$(HOME)/Library/Developer/GStreamer/iPhone.sdk/GStreamer.framework
    exists($$GST_ROOT) {
        CONFIG      += VideoEnabled
        INCLUDEPATH += $$GST_ROOT/Headers
        LIBS        += -F$$(HOME)/Library/Developer/GStreamer/iPhone.sdk -framework GStreamer -liconv -lresolv
    }
} else:WindowsBuild {
    #- gstreamer installed by default under c:/gstreamer
    GST_ROOT = c:/gstreamer/1.0/x86
    exists($$GST_ROOT) {
        CONFIG      += VideoEnabled

        LIBS        += -L$$GST_ROOT/lib -lopengl32

        LIBS += -lgstfft-1.0  \
                -lgstnet-1.0 -lgio-2.0 \
                -lgstaudio-1.0 -lgstcodecparsers-1.0 -lgstbase-1.0 \
                -lgstreamer-1.0 -lgstrtp-1.0 -lgstpbutils-1.0 -lgstrtsp-1.0 -lgsttag-1.0 \
                -lgstvideo-1.0 \ #-lavformat -lavcodec -lavutil -lx264 -lavfilter -lswresample \
                -lgstriff-1.0 -lgstcontroller-1.0 -lgstapp-1.0 \
                -lgstsdp-1.0 -lbz2 -lgobject-2.0 \
                -lgstgl-1.0  -lgraphene-1.0 -lpng16 -ljpeg -lgstphotography-1.0 \
                -lgmodule-2.0 -lglib-2.0 -lorc-0.4 -lffi -lintl


        INCLUDEPATH += \
            $$GST_ROOT/include/gstreamer-1.0 \
            $$GST_ROOT/include/glib-2.0 \
            $$GST_ROOT/lib/gstreamer-1.0/include \
            $$GST_ROOT/lib/glib-2.0/include

        DESTDIR_WIN = $$replace(DESTDIR, "/", "\\")
        GST_ROOT_WIN = $$replace(GST_ROOT, "/", "\\")

        # Copy main GStreamer runtime files
        QMAKE_POST_LINK +=$${PWD}/../../win_deploy_gstreamer.cmd \"$$DESTDIR_WIN\" $$escape_expand(\\n)
   }
} else:AndroidBuild {
    #- gstreamer assumed to be installed in $$PWD/../../gstreamer-1.0-android-universal-1.14.4/armv7 (or x86)
    Androidx86Build {
        GST_ROOT = $$PWD/../../gstreamer-1.0-android-universal-1.14.4/x86
    } AndroidARM64Build {
        GST_ROOT = $$PWD/../../gstreamer-1.0-android-universal-1.14.4/arm64
    } else {
        GST_ROOT = $$PWD/../../gstreamer-1.0-android-universal-1.14.4/armv7
    }
    exists($$GST_ROOT) {
        QMAKE_CXXFLAGS  += -pthread
        CONFIG          += VideoEnabled

        # We want to link these plugins statically
        LIBS += -L$$GST_ROOT/lib/gstreamer-1.0

        SHARED_LIB_FILES = $$files($$GST_ROOT/lib/gstreamer-1.0/*.a)
        for(FILE, SHARED_LIB_FILES) {
            BASENAME = $$basename(FILE)
            BASENAME = $$replace(BASENAME,^lib,)

            LIBS += -l$$replace(BASENAME,\.a,)
        }

        # Rest of GStreamer dependencies
        LIBS += -L$$GST_ROOT/lib \
            -lgstfft-1.0 -lm  \
            -lgstnet-1.0 -lgio-2.0 \
            -lgstaudio-1.0 -lgstcodecparsers-1.0 -lgstbase-1.0 \
            -lgstreamer-1.0 -lgstrtp-1.0 -lgstpbutils-1.0 -lgstrtsp-1.0 -lgsttag-1.0 \
            -lgstvideo-1.0 -lavformat -lavcodec -lavutil -lx264 -lavfilter -lswresample \
            -lgstriff-1.0 -lgstcontroller-1.0 -lgstapp-1.0 \
            -lgstsdp-1.0 -lbz2 -lgobject-2.0 \
            -lgstgl-1.0  -lgraphene-1.0 -lpng16 -ljpeg -lgstphotography-1.0 -lEGL \
            -Wl,--export-dynamic -lgmodule-2.0 -pthread -lglib-2.0 -lorc-0.4 -liconv -lffi -lintl \

        INCLUDEPATH += \
            $$GST_ROOT/include/gstreamer-1.0 \
            $$GST_ROOT/lib/gstreamer-1.0/include \
            $$GST_ROOT/include/glib-2.0 \
            $$GST_ROOT/lib/glib-2.0/include
    }
}

VideoEnabled {

    message("Including support for video streaming")


    !LinuxBuild {
        !RaspberryPiBuild {
            DEFINES += GST_PLUGIN_BUILD_STATIC

            INCLUDEPATH += \
                $$PWD/qmlgl

            HEADERS += \
                $$PWD/qmlgl/qtwindow.h \
                $$PWD/qmlgl/gstqsgtexture.h \
                $$PWD/qmlgl/gstqtgl.h \
                $$PWD/qmlgl/gstqtglutility.h \
                $$PWD/qmlgl/gstqtsink.h \
                $$PWD/qmlgl/gstqtsrc.h \
                $$PWD/qmlgl/qtitem.h

            SOURCES += \
                $$PWD/qmlgl/gstplugin.cc \
                $$PWD/qmlgl/gstqsgtexture.cc \
                $$PWD/qmlgl/gstqtglutility.cc \
                $$PWD/qmlgl/gstqtsink.cc \
                $$PWD/qmlgl/gstqtsrc.cc \
                $$PWD/qmlgl/qtitem.cc \
                $$PWD/qmlgl/qtwindow.cc
        }
    }

    iOSBuild {
        OBJECTIVE_SOURCES += \
            $$PWD/../../src/gst_ios_init.m
    }

} else {
    LinuxBuild|MacBuild|iOSBuild|WindowsBuild|AndroidBuild|RaspberryPiBuild|JetsonBuild {
        message("Skipping support for video streaming (GStreamer libraries not installed)")
        message("Installation instructions here: https://github.com/mavlink/qgroundcontrol/blob/master/src/VideoStreaming/README.md")
    } else {
        message("Skipping support for video streaming (Unsupported platform)")
    }
}

