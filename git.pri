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

DEFINES += QOPENHD_VERSION=\"\\\"$$QOPENHD_VERSION\\\"\"

message("QOPENHD_VERSION:" $$QOPENHD_VERSION)
