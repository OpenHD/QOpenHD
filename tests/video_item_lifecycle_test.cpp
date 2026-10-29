#include <QApplication>
#include <QQuickWindow>
#include <iostream>
#include "videostreaming/avcodec/QSGVideoTextureItem.h"

int main(int argc, char** argv) {
    QApplication app(argc, argv);
    QQuickWindow first, second;
    first.resize(640,480); second.resize(640,480);
    for (int pass=0; pass<100; ++pass) {
        QSGVideoTextureItem item;
        item.setPrimaryStream(false);
        item.sync(); // No window yet.
        item.setParentItem(first.contentItem());
        item.sync();
        item.setParentItem(nullptr);
        item.sync(); // The startup crash: a queued sync after Loader detachment.
        item.setParentItem(second.contentItem());
        item.sync();
        item.setParentItem(nullptr);
        item.sync();
    }
    std::cout << "Video item attach, detach, window replacement and destruction passed (100 cycles)\n";
    return 0;
}
