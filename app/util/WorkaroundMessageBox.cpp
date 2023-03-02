#include "WorkaroundMessageBox.h"
#include "qdebug.h"

namespace workaround{

MessageBox::MessageBox(QObject *parent):
    QObject(parent){
    connect(this, &MessageBox::signal_set_text_and_show, this, &MessageBox::do_not_call_me_set_text_and_show);
}

MessageBox &MessageBox::instance(){
    static MessageBox messageBox{};
    return messageBox;
}

void MessageBox::okay_button_clicked(){
    qDebug()<<"MessageBox::okay_button_clicked()";
    set_visible(false);
}

void MessageBox::do_not_call_me_set_text_and_show(QString text)
{
    set_text(text);
    set_visible(true);
}



}
