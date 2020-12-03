linux {
    linux-g++ | linux-g++-64 | linux-g++-32 | linux-clang {
        message("LinuxBuild")
        CONFIG += LinuxBuild
        DEFINES += __desktoplinux__
        DEFINES += __STDC_LIMIT_MACROS
        linux-clang {
            message("Linux clang")
            QMAKE_CXXFLAGS += -Qunused-arguments -fcolor-diagnostics
        }
    } else : linux-rpi-g++ | linux-rpi-vc4-g++ | linux-rasp-pi-g++ {
        message("RaspberryPiBuild")
        CONFIG += RaspberryPiBuild
        DEFINES += __STDC_LIMIT_MACROS __rasp_pi__
        LIBS += -lrt
        message($$LIBS)
    } else : android-g++ | android-clang {
        CONFIG += AndroidBuild MobileBuild
        DEFINES += __mobile__
        DEFINES += __android__
        DEFINES += __STDC_LIMIT_MACROS
        target.path = $$DESTDIR
        equals(ANDROID_TARGET_ARCH, x86)  {
            CONFIG += Androidx86Build
            DEFINES += __androidx86__
        }
        equals(ANDROID_TARGET_ARCH, arm64-v8a)  {
            message("AndroidARM64Build")
            CONFIG += AndroidARM64Build
            DEFINES += __androidarm64__
        }
    } else {
        error("Compiler/platform not supported")
    }
}

win32 {
    CONFIG += WindowsBuild
    DEFINES += __windows__
    DEFINES += __STDC_LIMIT_MACROS
}

macx {
    message("MacBuild")
    CONFIG += MacBuild
    DEFINES += __macos__
    DEFINES += __apple__
    CONFIG += x86_64
    CONFIG -= x86
    QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.12
    QMAKE_CXXFLAGS += -fvisibility=hidden
    QMAKE_CXXFLAGS += -Wno-address-of-packed-member
}

ios {
    message("iOSBuild")
    CONFIG  += iOSBuild MobileBuild app_bundle
    DEFINES += __ios__
    DEFINES += __apple__
    DEFINES += __mobile__
    QMAKE_IOS_DEPLOYMENT_TARGET = 12.1
    QMAKE_APPLE_TARGETED_DEVICE_FAMILY = 1,2
    QMAKE_LFLAGS += -Wl
}

MobileBuild {
    DEFINES += __mobile__
}
