#ifndef MESSAGEPOPUP_H
#define MESSAGEPOPUP_H


#include <QMessageBox>
#include <QObject>
#include <QString>
#include <mutex>
#include <QTimer>

#include "lib/lqtutils_master/lqtutils_prop.h"

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
    // Can be called from any thread
    // Sets the popup text and opens the popup
    // @param optional_time_until_autoremove :
    // time until the message is automatically removed (for goggles users) - leave at -1 if the message shall stay there
    // until the user clicks okay
    Q_INVOKABLE void set_text_and_show(QString text,int optional_time_until_autoremove_seconds=-1){
        // We might not be called from the UI thread, which is why we use the signal workaround
        emit signal_set_text_and_show(text,optional_time_until_autoremove_seconds);
    }
    static void makePopupMessage(QString text,int optional_time_until_autoremove_seconds=-1){
        WorkaroundMessageBox::instance().set_text_and_show(text,optional_time_until_autoremove_seconds);
    }
public:
    L_RO_PROP(QString,text,set_text,"NONE");
    L_RO_PROP(bool,visible,set_visible,false);
    // decreasing counter until the message disappears - if it is set to -1, it should not be shown
    // (aka the message shall stay there infinitely)
    L_RO_PROP(int,remaining_time_seconds,set_remaining_time_seconds,-1)
public:
    Q_INVOKABLE void okay_button_clicked();
public:
signals:
    void signal_set_text_and_show(QString text,int optional_time_until_autoremove);
private:
    void do_not_call_me_set_text_and_show(QString text,int optional_time_until_autoremove);
    std::mutex m_remove_after_delay_timer_mutex;
    std::unique_ptr<QTimer> m_remove_after_delay_timer=nullptr;
    void update_remaining_time();
};


#endif // MESSAGEPOPUP_H
