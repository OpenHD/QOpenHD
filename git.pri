QOPENHD_VERSION = $$system(git describe --always --tags --abbrev=0 --dirty)

MacBuild {
    MAC_VERSION  = $$QOPENHD_VERSION
    message("MAC_VERSION:" $$MAC_VERSION)
    DEFINES += MAC_VERSION=\"\\\"$$MAC_VERSION\\\"\"

    MAC_BUILD    = $$replace(QOPENHD_VERSION, "v", "")
    MAC_BUILD    = $$replace(MAC_BUILD, "-dirty", "")

    DEFINES += MAC_BUILD=\"\\\"$$MAC_BUILD\\\"\"
    message("MAC_BUILD:" $$MAC_BUILD)
}

DEFINES += QOPENHD_VERSION=\"\\\"$$QOPENHD_VERSION\\\"\"

message("QOPENHD_VERSION:" $$QOPENHD_VERSION)
