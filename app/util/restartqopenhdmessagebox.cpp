#include "restartqopenhdmessagebox.h"
#include "qdebug.h"
#include <sstream>

RestartQOpenHDMessageBox::RestartQOpenHDMessageBox(QObject *parent)
    : QObject{parent}
{

}

RestartQOpenHDMessageBox &RestartQOpenHDMessageBox::instance()
{
    static RestartQOpenHDMessageBox instance{};
    return instance;
}

void RestartQOpenHDMessageBox::show(){
    set_text("Please restart QOpenHD to apply.");
    set_visible(true);
}

void RestartQOpenHDMessageBox::show_with_text(QString text){
    std::stringstream full_text;
    full_text << text.toStdString() << " - Please restart QOpenHD to apply.";
    set_text(QString(full_text.str().c_str()));
    set_visible(true);
}

void RestartQOpenHDMessageBox::hide_element()
{
    qDebug()<<"RestartQOpenHDMessageBox::hide_element()";
    set_visible(false);
}
