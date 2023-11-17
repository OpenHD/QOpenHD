#ifndef QMOUSEHIDER_H
#define QMOUSEHIDER_H

#include <atomic>

#include <QCoreApplication>
#include <QTimer>
#include <qapplication.h>

// adds 2 features
// 1) high visibility cursor for people in the field
// 2) cursor auto hide
class MouseHelper : public QObject
{
    Q_OBJECT
public:
    static MouseHelper& instance();
    explicit MouseHelper();
    // update when settings change
    Q_INVOKABLE void set_active_cursor_type_and_scale(const int cursor_type,const int cursor_scale);
    // Enable / disable auto hide
    Q_INVOKABLE void set_hide_cursor_inactive_enable(bool enable);
private:
    void init_from_settings();
    const int m_inactivity_duration_msec=2000;
    QTimer m_timer;
    int m_cursor_type=0;
    int m_cursor_scale=1;
    bool m_enable_hide_cursor_when_inactive=false;
    bool m_cursor_state_active= true; // active by default

    bool eventFilter(QObject *pWatched, QEvent *pEvent) override;
    void on_mouse_event();
    void on_timeout();
    void update_cursor_state();

};


#endif // QMOUSEHIDER_H
