#include "mousehelper.h"
#include "qdebug.h"
#include "qpixmap.h"

#include <qsettings.h>

static QCursor create_custom_cursor(const int cursor_type,const int cursor_scale){
    assert(cursor_type!=0);
    QPixmap pixmap;
    if(cursor_type==1){
        pixmap=QPixmap("://resources/cursors/arrow_512_transparent.png");
    }else if(cursor_type==2){
        pixmap=QPixmap("://resources/cursors/arrow_512_white.png");
    }else if(cursor_type==3){
        pixmap=QPixmap("://resources/cursors/arrow_512_green.png");
    }else{
        pixmap=QPixmap("://resources/cursors/hand_white.png");
    }
    int size_px= 16;
    if(cursor_scale==0){
        size_px =16;
    }else if(cursor_scale==1){
        size_px = 32;
    }else if(cursor_scale==2){
        size_px=64;
    }else if(cursor_scale==3){
        size_px= 128;
    }
    pixmap = pixmap.scaled(size_px,size_px);
    // position is a bit of a mess
    QCursor cursor;
    // arrow - roughly
    if(cursor_type==1 || cursor_type==2 || cursor_type==3){
        cursor=QCursor(pixmap,pixmap.width()/16,pixmap.height()/16);
    }else{
        // The hand is a bit different
        cursor=QCursor(pixmap,pixmap.width()/3,pixmap.height()/4);
    }
    return cursor;
}


MouseHelper &MouseHelper::instance()
{
    static MouseHelper i;
    return i;
}

MouseHelper::MouseHelper()
{
    m_timer.setSingleShot(true);
    m_timer.callOnTimeout([this]() {on_timeout();});
    init_from_settings();
}

void MouseHelper::init_from_settings()
{
    QSettings settings;
    const int custom_cursor_type=settings.value("custom_cursor_type",0).toInt();
    const int custom_cursor_scale=settings.value("custom_cursor_scale",1).toInt();
    const bool enable_cursor_auto_hide=settings.value("enable_cursor_auto_hide",false).toBool();
    set_active_cursor_type_and_scale(custom_cursor_type,custom_cursor_scale);
    set_hide_cursor_inactive_enable(enable_cursor_auto_hide);
}

void MouseHelper::set_active_cursor_type_and_scale(const int cursor_type, const int cursor_scale)
{
    m_cursor_type=cursor_type;
    m_cursor_scale=cursor_scale;
    update_cursor_state();
}

void MouseHelper::set_hide_cursor_inactive_enable(bool enable)
{
    if(enable){
        QCoreApplication::instance()->installEventFilter(this);
        m_enable_hide_cursor_when_inactive=true;
    }else{
        QCoreApplication::instance()->removeEventFilter(this);
        m_enable_hide_cursor_when_inactive=false;
        m_timer.stop();
        m_cursor_state_active=true;
        update_cursor_state();
    }
}

bool MouseHelper::eventFilter(QObject *pWatched, QEvent *pEvent){
    if (pEvent->type() == QEvent::MouseMove){
        on_mouse_event();
    }
    return QObject::eventFilter(pWatched, pEvent);
}

void MouseHelper::on_timeout(){
    if(m_cursor_state_active){
        m_cursor_state_active= false;
        update_cursor_state();
    }
}

void MouseHelper::on_mouse_event(){
    if(!m_cursor_state_active){
        m_cursor_state_active= true;
        update_cursor_state();
    }
    // restarts the timer if already running
    m_timer.start(m_inactivity_duration_msec);
}

void MouseHelper::update_cursor_state(){
    if(m_cursor_state_active){
        if(m_cursor_type==0){
            // Default application cursor
            QApplication::restoreOverrideCursor();
        }else{
            // Install the custom cursor
            QApplication::restoreOverrideCursor();
            auto custom_cursor=create_custom_cursor(m_cursor_type,m_cursor_scale);
            QApplication::setOverrideCursor(custom_cursor);
        }
    }else{
        QApplication::restoreOverrideCursor();
        QApplication::setOverrideCursor(Qt::BlankCursor);
    }
}
