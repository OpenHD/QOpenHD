#include <QApplication>
#include <QQuickWindow>
#include <QElapsedTimer>
#include <QThread>
#include <QImage>
#include <iostream>
#include <cstring>
#include "videostreaming/avcodec/QSGVideoTextureItem.h"

AVFrame* solid(int y, int u, int v) {
    AVFrame* frame=av_frame_alloc();
    frame->format=AV_PIX_FMT_YUV420P; frame->width=160; frame->height=120;
    if(av_frame_get_buffer(frame,32)<0) return nullptr;
    for(int plane=0;plane<3;++plane) {
        const int height=plane==0?120:60;
        for(int row=0;row<height;++row)
            std::memset(frame->data[plane]+row*frame->linesize[plane],plane==0?y:(plane==1?u:v),frame->linesize[plane]);
    }
    return frame;
}
int main(int argc,char** argv) {
    QCoreApplication::setAttribute(Qt::AA_UseOpenGLES);
    QApplication app(argc,argv);
    QQuickWindow window; window.resize(640,480); window.setColor(Qt::black);
    QSGVideoTextureItem primary,secondary;
    primary.setParentItem(window.contentItem()); primary.setSize(QSizeF(640,480));
    secondary.setPrimaryStream(false); secondary.setParentItem(window.contentItem());
    secondary.setPosition(QPointF(0,360)); secondary.setSize(QSizeF(160,120));
    window.show();
    auto* red=solid(81,90,240); auto* blue=solid(41,240,110);
    QElapsedTimer timer;timer.start();
    while(timer.elapsed()<1800) {
        TextureRenderer::instance().queue_new_frame_for_display(red,true);
        TextureRenderer::instance().queue_new_frame_for_display(blue,false);
        window.update(); app.processEvents(); QThread::msleep(10);
    }
    QImage image=window.grabWindow();image.save("secondary-render-test.png");
    av_frame_free(&red);av_frame_free(&blue);
    const auto main=image.pixelColor(320,240),pip=image.pixelColor(80,420);
    std::cout<<"Primary "<<main.name().toStdString()<<" secondary "<<pip.name().toStdString()<<std::endl;
    return main.red()>180 && main.blue()<70 && pip.blue()>180 && pip.red()<70?0:1;
}
