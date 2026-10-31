#pragma once
#include <QImage>
#include <QPainter>

// Ignore transparent layout space when fitting a real HUD drawing into a tile.
inline QImage cropWidgetPreviewImage(const QImage& source) {
    if (source.isNull()) return {};
    const QImage image=source.convertToFormat(QImage::Format_ARGB32);
    int left=image.width(),top=image.height(),right=-1,bottom=-1;
    for(int y=0;y<image.height();++y) {
        const auto* row=reinterpret_cast<const QRgb*>(image.constScanLine(y));
        for(int x=0;x<image.width();++x) if(qAlpha(row[x])>4 && qMax(qRed(row[x]),qMax(qGreen(row[x]),qBlue(row[x])))>64) {
            left=qMin(left,x);right=qMax(right,x);top=qMin(top,y);bottom=qMax(bottom,y);
        }
    }
    if(right<left) {
        // A deliberately dark OSD theme must still produce a preview.
        for(int y=0;y<image.height();++y) {
            const auto* row=reinterpret_cast<const QRgb*>(image.constScanLine(y));
            for(int x=0;x<image.width();++x) if(qAlpha(row[x])>4) {
                left=qMin(left,x);right=qMax(right,x);top=qMin(top,y);bottom=qMax(bottom,y);
            }
        }
    }
    if(right<left) return {};
    const QRect rect(QPoint(left,top),QPoint(right,bottom));
    QImage cropped(rect.size()+QSize(4,4),QImage::Format_ARGB32_Premultiplied);
    cropped.fill(Qt::transparent);
    QPainter painter(&cropped);painter.drawImage(QPoint(2,2),image,rect);
    return cropped;
}
