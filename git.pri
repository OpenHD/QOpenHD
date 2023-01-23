# We show the version (optained from git) in the GUI for development
QOPENHD_GIT_VERSION = $$system(git describe --always --tags --abbrev=0 --dirty)

# We show the commit hash in the GUI for development
QOPENHD_GIT_COMMIT_HASH = $$system(git rev-parse HEAD)

MacBuild | iOSBuild {
    APPLE_VERSION  = $$QOPENHD_GIT_VERSION
    message("APPLE_VERSION:" $$APPLE_VERSION)
    DEFINES += APPLE_VERSION=\"\\\"$$APPLE_VERSION\\\"\"

    APPLE_BUILD    = $$replace(QOPENHD_GIT_VERSION, "v", "")
    APPLE_BUILD    = $$replace(APPLE_BUILD, "-dirty", "")

    DEFINES += APPLE_BUILD=\"\\\"$$APPLE_BUILD\\\"\"
    message("APPLE_BUILD:" $$APPLE_BUILD)
}

DEFINES += QOPENHD_GIT_VERSION=\"\\\"$$QOPENHD_GIT_VERSION\\\"\"

DEFINES += QOPENHD_GIT_COMMIT_HASH=\"\\\"$$QOPENHD_GIT_COMMIT_HASH\\\"\"

message("QOPENHD_GIT_VERSION:" $$QOPENHD_GIT_VERSION)
message("QOPENHD_GIT_COMMIT_HASH:" $$QOPENHD_GIT_COMMIT_HASH)
