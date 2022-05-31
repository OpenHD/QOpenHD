#ifndef QOPENHDVIDEOHELPER_H
#define QOPENHDVIDEOHELPER_H

#include <qqmlapplicationengine.h>
#include <qquickitem.h>
#include <qquickwindow.h>



namespace QOpenHDVideoHelper{


/**
 * Find the qt window where video is outut to.
 * @param isMainStream QOpenHD supports upt to 2 simultaneous streams, they each have their own respective window.
 * @return nullptr if window cannot be found, the window to display video with otherwise.
 */
static QQuickItem* find_qt_video_window(QQmlApplicationEngine *m_engine,const bool isMainStream=true){

    QString m_elementName;
    if(isMainStream){
         m_elementName = "mainVideoGStreamer";
    }else{
         m_elementName = "pipVideoGStreamer";
    }
    QQuickItem *videoItem;
    QQuickWindow *rootObject;
    auto rootObjects = m_engine->rootObjects();
    if (rootObjects.length() < 1) {
        qDebug() << "Failed to obtain root object list!";
        return nullptr;
    }
    rootObject = static_cast<QQuickWindow *>(rootObjects.first());
    videoItem = rootObject->findChild<QQuickItem *>(m_elementName.toUtf8());
    qDebug() << "Setting element on " << m_elementName;
    if (videoItem == nullptr) {
        qDebug() << "Failed to obtain video item pointer for " << m_elementName;
        return nullptr;
    }
    return videoItem;
}


}

// Must be in sync with OpenHD
namespace OHDIntegration{
static constexpr auto OHD_VIDEO_GROUND_VIDEO_STREAM_1_UDP = 5620; // first (primary) stream
static constexpr auto OHD_VIDEO_GROUND_VIDEO_STREAM_2_UDP = 5621; // secondary stream
}

#endif // QOPENHDVIDEOHELPER_H
