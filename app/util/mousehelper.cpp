#include "mousehelper.h"
#include "qdebug.h"
#include "qpixmap.h"

#include <QMouseEvent>
#include <QPainter>
#include <QQuickPaintedItem>
#include <QQuickWindow>
#include <qsettings.h>

namespace {
class HudCursor : public QQuickPaintedItem {
public:
    explicit HudCursor(QQuickItem* parent) : QQuickPaintedItem(parent) {
        setZ(1e6);
        setAcceptedMouseButtons(Qt::NoButton);
        setVisible(false);
    }

    void setAppearance(const QCursor& cursor) {
        image_ = cursor.pixmap();
        hotspot_ = cursor.hotSpot();
        setSize(QSizeF(image_.size()) / image_.devicePixelRatio());
        update();
    }

    void movePointer(const QPointF& position) {
        setPosition(position - hotspot_);
    }

    void paint(QPainter* painter) override {
        painter->drawPixmap(0, 0, image_);
    }

private:
    QPixmap image_;
    QPoint hotspot_;
};
}

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
    const bool enable_cursor_auto_hide=settings.value("enable_cursor_auto_hide",cursor_auto_hide_default()).toBool();
    set_active_cursor_type_and_scale(custom_cursor_type,custom_cursor_scale);
    set_hide_cursor_inactive_enable(enable_cursor_auto_hide);
}

bool MouseHelper::cursor_auto_hide_default() const
{
    return qEnvironmentVariableIntValue("QOPENHD_CURSOR_AUTO_HIDE_DEFAULT") == 1;
}

void MouseHelper::attach_hud_cursor(QQuickWindow* window)
{
    if (!window || !QGuiApplication::platformName().startsWith("wayland") ||
        qEnvironmentVariableIntValue("QOPENHD_HUD_CURSOR") != 1) return;

    m_hud_window = window;
    m_hud_cursor = new HudCursor(window->contentItem());
    QCoreApplication::instance()->installEventFilter(this);
    update_cursor_state();
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
        m_timer.start(m_inactivity_duration_msec);
    }else{
        if (!m_hud_cursor) QCoreApplication::instance()->removeEventFilter(this);
        m_enable_hide_cursor_when_inactive=false;
        m_timer.stop();
        m_cursor_state_active=true;
        update_cursor_state();
    }
}

bool MouseHelper::eventFilter(QObject *pWatched, QEvent *pEvent){
    const auto type = pEvent->type();
    const bool mouseActivity = type == QEvent::MouseMove || type == QEvent::MouseButtonPress ||
                               type == QEvent::Wheel;
    if (m_hud_cursor && pWatched == m_hud_window) {
        switch (type) {
        case QEvent::MouseMove:
        case QEvent::MouseButtonPress:
            m_pointer_position = static_cast<QMouseEvent*>(pEvent)->localPos();
            m_pointer_inside = true;
            break;
        case QEvent::Enter:
            m_pointer_position = static_cast<QEnterEvent*>(pEvent)->localPos();
            m_pointer_inside = true;
            break;
        case QEvent::Leave:
            m_pointer_inside = false;
            m_hud_cursor->setVisible(false);
            break;
        default:
            break;
        }
        if (type == QEvent::Enter || mouseActivity) {
            on_mouse_event();
            auto* cursor = static_cast<HudCursor*>(m_hud_cursor.data());
            cursor->movePointer(m_pointer_position);
            cursor->setVisible(m_pointer_inside && m_cursor_state_active);
        }
    } else if (m_enable_hide_cursor_when_inactive && mouseActivity) {
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
    if (m_enable_hide_cursor_when_inactive) m_timer.start(m_inactivity_duration_msec);
}

void MouseHelper::update_cursor_state(){
    if (m_hud_cursor) {
        if (m_cursor_state_active) {
            auto* cursor = static_cast<HudCursor*>(m_hud_cursor.data());
            cursor->setAppearance(create_custom_cursor(m_cursor_type == 0 ? 2 : m_cursor_type,
                                                       m_cursor_scale));
            cursor->movePointer(m_pointer_position);
        }
        m_hud_cursor->setVisible(m_pointer_inside && m_cursor_state_active);
        const auto* current = QApplication::overrideCursor();
        if (current) QApplication::changeOverrideCursor(Qt::BlankCursor);
        else QApplication::setOverrideCursor(Qt::BlankCursor);
        return;
    }
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
