#ifndef MESSAGEPOPUP_H
#define MESSAGEPOPUP_H


#include <QMessageBox>
#include <QObject>
#include <QString>

// QT Message popup's (their default ones) don't work in kms, since they are opened in a new window.
// This exposes the following functionality:
// At any time in c++ code, show a message dialog to the user that only goes away if the user clicks "Okay"

// TODO: Really dirty, I quickly had to write it since we only noticed QMessagebox is not properly supported
// When I was already using it.

namespace workaround{

// Don't forget to register this one in main.cpp
// instance() is registered as _messageBoxInstance
class MessageBox: public QObject{
    Q_OBJECT
public:
    explicit MessageBox(QObject *parent = nullptr);
    static MessageBox& instance();
    Q_INVOKABLE void set_text_and_show(QString text){
        set_text(text);
        set_show_to_user(true);
    }
    // We eventually need a "restart QOpenHD" dialoque
    Q_INVOKABLE void show_text_restart_qopenhd(){
        set_text("Plase restart QOpenHD to apply");
        set_show_to_user(true);
    }
public:
    Q_PROPERTY(QString text MEMBER m_text WRITE set_text NOTIFY text_changed)
    void set_text(QString text);
    //
    Q_PROPERTY(bool show_to_user MEMBER m_show_to_user WRITE set_show_to_user NOTIFY show_to_user_changed)
    void set_show_to_user(bool show_to_user);
    //
    Q_INVOKABLE void okay_button_clicked();
signals:
    void text_changed(QString text);
    void show_to_user_changed(bool show_to_user);
private:
    QString m_text="Air and ground are out of sync - this should never happen. Please report";
    bool m_show_to_user=false;
};

// Show a message to the user he can only remove by clicking "OK".

/*static void makePopupMessage(QString message){
    QMessageBox msgBox;
    msgBox.setText(message);
    msgBox.exec();
}*/
// NOTE: doesn't check if there is already a message being displayed right now
static void makePopupMessage(QString message){
    MessageBox::instance().set_text_and_show(message);
}

}

#endif // MESSAGEPOPUP_H
