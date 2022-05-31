#ifndef GST_PLATFORM_INCLUDE_H
#define GST_PLATFORM_INCLUDE_H


// Use this file to include gstreamer into your project, independend of platform
// (TODO: rn everythng except standart ubuntu has been deleted).
// exposes a initGstreamerOrThrow() method that should be called before any actual gstreamer calls.

#include "qglobal.h"
#include <gst/gst.h>
#include <QString>
#include <stdexcept>

/**
 * @brief initGstreamer, throw a run time exception when failing
 */
static void initGstreamerOrThrow(){
    GError* error = nullptr;
    if (!gst_init_check(nullptr,nullptr, &error)) {
        throw std::runtime_error("Cannot initialize gstreamer\n");
    }
}

/**
 * @brief Not sure if still needed nowadays, init qml sink or throw run time exception ??!!
 */
static void initQmlGlSinkOrThrow(){
    /* If qmlgl plugin was dynamically linked, this will force GStreamer to go find it and
     * load it before the QML gets loaded in main.cpp (without this, Qt will complain that
     * it can't find org.freedesktop.gstreamer.GLVideoItem)
     */
    GstElement *sink = gst_element_factory_make("qmlglsink", NULL);
    if(sink==nullptr){
        throw std::runtime_error("Cannot initialize gstreamer\n");
   }
}

// not sure, customize the path where gstreamer log is written to
static void customizeGstreamerLogPath(){
    char debuglevel[] = "*:3";
    #if defined(__android__)
    char logpath[] = "/sdcard";
    #else
    char logpath[] = "/tmp";
    #endif
    qputenv("GST_DEBUG", debuglevel);
    QString file = QString("%1/%2").arg(logpath).arg("gstreamer-log.txt");
    qputenv("GST_DEBUG_NO_COLOR", "1");
    qputenv("GST_DEBUG_FILE", file.toStdString().c_str());
    qputenv("GST_DEBUG_DUMP_DOT_DIR", logpath);
}


#endif // GST_PLATFORM_INCLUDE_H
