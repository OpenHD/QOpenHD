#ifndef HUDLOGMESSAGESMODEL_H
#define HUDLOGMESSAGESMODEL_H

#include <QAbstractListModel>
#include <QObject>
#include <qcolor.h>
#include <qtimer.h>


// We need to be carefully to not spam the HUD, since it is "always on", even during flight.
// Inspired by stephens javascript code, but I don't think doing a model in javascript is the way to
// go here ;)
// (Archived links)
// https://github.com/OpenHD/QOpenHD/blob/6cbb8c1791ac0cf2748f9bea72605f71071efd60/qml/ui/widgets/MessageHUD.qml
// https://github.com/OpenHD/QOpenHD/blob/6cbb8c1791ac0cf2748f9bea72605f71071efd60/qml/ui/widgets/MessageHUDRow.ui.qml
//
// TODO
class HUDLogMessagesModel : public QAbstractListModel
{
    Q_OBJECT
public:
    explicit HUDLogMessagesModel(QObject *parent = nullptr);
    static HUDLogMessagesModel& instance();

    // add new message to be shown on the HUD
    // the message will dissappear after a specific amount of time or when a new message
    // pushes it out (more than MAX_N_ELEMENTS messages)
    Q_INVOKABLE void add_message(int severity,QString message);
    // These are just utility for common severity levels
    Q_INVOKABLE void add_message_info(QString message);
    Q_INVOKABLE void add_message_warning(QString message);
private:
    struct Element{
        QString message;
        int severity;
        std::chrono::steady_clock::time_point added_time_point=std::chrono::steady_clock::now();
    };
    enum Roles {
        MessageRole =Qt::UserRole,
        LevelRole
    };
    int rowCount(const QModelIndex& parent= QModelIndex()) const override;
    QVariant data( const QModelIndex& index, int role = Qt::DisplayRole ) const override;
    QHash<int, QByteArray> roleNames() const override;
    // see logmessagesmodel to why this workaround is needed
    void do_not_call_me_addLogMessage(int severity,QString message);
public slots:
    void removeData(int row);
    void addData(HUDLogMessagesModel::Element logMessageData);
private:
    QVector<HUDLogMessagesModel::Element> m_data;
    QTimer* m_cleanup_timer;
    void handle_cleanup();
    static constexpr int MAX_N_ELEMENTS=6;
public:
signals:
    void signalAddLogMessage(int severity,QString message);
};

#endif // HUDLOGMESSAGESMODEL_H
