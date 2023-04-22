#include "WorkaroundMessageBox.h"
#include "qdebug.h"


WorkaroundMessageBox::WorkaroundMessageBox(QObject *parent):
    QObject(parent){
    connect(this, &WorkaroundMessageBox::signal_set_text_and_show, this, &WorkaroundMessageBox::do_not_call_me_set_text_and_show);
}

WorkaroundMessageBox &WorkaroundMessageBox::instance(){
    static WorkaroundMessageBox messageBox{};
    return messageBox;
}

void WorkaroundMessageBox::okay_button_clicked(){
    qDebug()<<"WorkaroundMessageBox::okay_button_clicked()";
    set_visible(false);
}

void WorkaroundMessageBox::do_not_call_me_set_text_and_show(QString text)
{
    set_text(text);
    set_visible(true);
}

