QOPENHD_VERSION = $$system(git describe --always --tags --abbrev=0 --dirty)

MacBuild | iOSBuild {
    APPLE_VERSION  = $$QOPENHD_VERSION
    message("APPLE_VERSION:" $$APPLE_VERSION)
    DEFINES += APPLE_VERSION=\"\\\"$$APPLE_VERSION\\\"\"

    APPLE_BUILD    = $$replace(QOPENHD_VERSION, "v", "")
    APPLE_BUILD    = $$replace(APPLE_BUILD, "-dirty", "")

    DEFINES += APPLE_BUILD=\"\\\"$$APPLE_BUILD\\\"\"
    message("APPLE_BUILD:" $$APPLE_BUILD)
}

WindowsBuild {
    DEFINES += BUILDER_VERSION=""
    DEFINES += OPENHD_VERSION=""
}

LinuxBuild | iOSBuild | MacBuild | AndroidBuild {
    BUILDER_VERSION = $$system(cat .builder_version)
    DEFINES += BUILDER_VERSION=\"\\\"$$BUILDER_VERSION\\\"\"
    message("BUILDER_VERSION:" $$BUILDER_VERSION)

    OPENHD_VERSION = $$system(cat .openhd_version)
    DEFINES += OPENHD_VERSION=\"\\\"$$OPENHD_VERSION\\\"\"
    message("OPENHD_VERSION:" $$OPENHD_VERSION)
}


DEFINES += QOPENHD_VERSION=\"\\\"$$QOPENHD_VERSION\\\"\"

message("QOPENHD_VERSION:" $$QOPENHD_VERSION)
