#ifndef RESTARTQOPENHDMESSAGEBOX_H
#define RESTARTQOPENHDMESSAGEBOX_H

#include <QObject>
#include "../../lib/lqtutils_master/lqtutils_prop.h"

// Also Quite dirty
// There are a couple of places in QOpenHD where we need to prompt the user to restart QOpenHD.
// This provides a quick and easy way to do that, but only works on platform(s) where qopenhd is
// automatically restarted by a service (e.g. rpi)
// NOTE: THIS RESTARTS QOPENHD; NOTHING ELSE !
class RestartQOpenHDMessageBox : public QObject{
    Q_OBJECT
public:
    explicit RestartQOpenHDMessageBox(QObject *parent = nullptr);
    static RestartQOpenHDMessageBox& instance();
    // prompt the user to restart QOpenHD
    Q_INVOKABLE void show();
    // Additonally, we can show a text why a restart is needed
    Q_INVOKABLE void show_with_text(QString text);
    //
    L_RO_PROP(QString,text,set_text,"NONE");
    L_RO_PROP(bool,visible,set_visible,false);
public:
    // Hides the element - called when button okay (restart now) or cancel (skip restart) is clicked
    Q_INVOKABLE void hide_element();
};

#endif // RESTARTQOPENHDMESSAGEBOX_H
