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

void WorkaroundMessageBox::do_not_call_me_set_text_and_show(QString text,int optional_time_until_autoremove)
{
    // Not sure if we need that mutex, but doesn't hurt
    std::lock_guard<std::mutex> lock(m_remove_after_delay_timer_mutex);
    if(m_remove_after_delay_timer!=nullptr){
        m_remove_after_delay_timer->stop();
        m_remove_after_delay_timer=nullptr;
    }
    if(optional_time_until_autoremove>0){
        set_remaining_time_seconds(optional_time_until_autoremove);
        m_remove_after_delay_timer=std::make_unique<QTimer>(this);
        QObject::connect(m_remove_after_delay_timer.get(), &QTimer::timeout, this, &WorkaroundMessageBox::update_remaining_time);
        m_remove_after_delay_timer->start(1000);
    }else{
        set_remaining_time_seconds(-1);
    }
    set_text(text);
    set_visible(true);
}


void WorkaroundMessageBox::update_remaining_time()
{
    //qDebug()<<"update_remaining_time()"<<m_remaining_time_seconds;
    set_remaining_time_seconds(m_remaining_time_seconds-1);
    if(m_remaining_time_seconds<=0){
        set_visible(false);
        m_remove_after_delay_timer->stop();
    }
}

