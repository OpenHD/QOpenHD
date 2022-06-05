#ifndef GST_PLATFORM_INCLUDE_H
#define GST_PLATFORM_INCLUDE_H


// Use this file to include gstreamer into your project, independend of platform
// (TODO: rn everythng except standart ubuntu has been deleted).
// exposes a initGstreamerOrThrow() method that should be called before any actual gstreamer calls.

#include "qglobal.h"
#include <gst/gst.h>
#include <QString>
#include <qquickitem.h>
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

QString get_gstreamer_version() {
    guint major, minor, micro, nano;
    gst_version(&major, &minor, &micro, &nano);
    QString gst_ver = QString();
    QTextStream s(&gst_ver);
    s << major;
    s << ".";
    s << minor;
    s << ".";
    s << micro;
    return gst_ver;
}

// link gstreamer qmlglsink to qt window
static void link_gsteamer_to_qt_window(GstElement *qmlglsink,QQuickItem *qtOutWindow){
      g_object_set(qmlglsink, "widget", qtOutWindow, NULL);
}

// find qmlglsink in gstreamer pipeline and link it to the window
static void link_gstreamer_pipe_to_qt_window(GstElement * m_pipeline,QQuickItem *qtOutWindow){
    GstElement *qmlglsink = gst_bin_get_by_name(GST_BIN(m_pipeline), "qmlglsink");
    assert(qmlglsink!=nullptr);
    link_gsteamer_to_qt_window(qmlglsink,qtOutWindow);
}

#endif // GST_PLATFORM_INCLUDE_H
