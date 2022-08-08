#include "WorkaroundMessageBox.h"
#include "qdebug.h"

namespace workaround{

MessageBox::MessageBox(QObject *parent):
    QObject(parent){
}

MessageBox &MessageBox::instance(){
    static MessageBox messageBox{};
    return messageBox;
}

void MessageBox::set_text(QString text){
    if(m_text==text)return;
    m_text=text;
    emit text_changed(text);
}

void MessageBox::set_show_to_user(bool show_to_user)
{
    if(show_to_user==m_show_to_user)return;
    m_show_to_user=show_to_user;
    emit show_to_user_changed(show_to_user);
}


void MessageBox::okay_button_clicked(){
    qDebug()<<"MessageBox::okay_button_clicked()";
    set_show_to_user(false);
}




}
