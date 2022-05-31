#ifndef GST_PLATFORM_INCLUDE_H
#define GST_PLATFORM_INCLUDE_H


// Use this file to include gstreamer into your project, independend of platform
// (TODO: rn everythng except standart ubuntu has been deleted).
// exposes a initGstreamerOrThrow() method that should be called before any actual gstreamer calls.

#include <gst/gst.h>
#include <stdexcept>


static void initGstreamerOrThrow(){
    GError* error = nullptr;
    if (!gst_init_check(nullptr,nullptr, &error)) {
        throw std::runtime_error("Cannot initialize gstreamer\n");
    }
}

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


#endif // GST_PLATFORM_INCLUDE_H
