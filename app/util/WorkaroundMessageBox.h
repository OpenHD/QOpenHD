#ifndef MESSAGEPOPUP_H
#define MESSAGEPOPUP_H


#include <QMessageBox>
#include <QObject>
#include <QString>

#include "../../lib/lqtutils_master/lqtutils_prop.h"

// QT Message popup's (their default ones) don't work in kms, since they are opened in a new window.
// This exposes the following functionality:
// At any time in c++ code, show a message dialog to the user that only goes away if the user clicks "Okay"

// TODO: Really dirty, I quickly had to write it since we only noticed QMessagebox is not properly supported
// When I was already using it.

// Don't forget to register this one in main.cpp
// instance() is registered as _messageBoxInstance
class WorkaroundMessageBox: public QObject{
    Q_OBJECT
public:
    explicit WorkaroundMessageBox(QObject *parent = nullptr);
    static WorkaroundMessageBox& instance();
    Q_INVOKABLE void set_text_and_show(QString text){
        // We might not be called from the UI thread, which is why we use the signal workaround
        emit signal_set_text_and_show(text);
    }
    static void makePopupMessage(QString text){
        WorkaroundMessageBox::instance().set_text_and_show(text);
    }
public:
    L_RO_PROP(QString,text,set_text,"NONE");
    L_RO_PROP(bool,visible,set_visible,false);
public:
    Q_INVOKABLE void okay_button_clicked();
public:
signals:
    void signal_set_text_and_show(QString text);
private:
    void do_not_call_me_set_text_and_show(QString text);
};


#endif // MESSAGEPOPUP_H
