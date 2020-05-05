#ifndef SMARTSYNC_H
#define SMARTSYNC_H

#include <QObject>
#include <QtQuick>

class QUdpSocket;


enum SmartSyncState {
    SmartSyncStateInitializing,
    SmartSyncStateWaitingForAir,
    SmartSyncStateTransferring,
    SmartSyncStateNotNeeded,
    SmartSyncStateFinished,
    SmartSyncStateError
};

typedef struct {
    /*
     * 0: initializing
     * 1: waiting for air to connect
     * 2: transferring
     * 3: no sync needed
     * 4: finished
     * 5: error
     */
    uint8_t state;
    /*
     * Progress percentage 0-100
     */
    uint8_t progress;
}
#ifndef _MSC_VER
__attribute__((packed))
#endif
smartsync_status_t;



class SmartSync: public QObject {
    Q_OBJECT

public:
    explicit SmartSync(QObject *parent = nullptr);
    static SmartSync* instance();


    Q_PROPERTY(QString message MEMBER m_message WRITE setMessage NOTIFY messageChanged)
    void setMessage(QString message);


    Q_PROPERTY(int state MEMBER m_state WRITE setState NOTIFY stateChanged)
    void setState(int state);

    Q_PROPERTY(int progress MEMBER m_progress WRITE setProgress NOTIFY progressChanged)
    void setProgress(int progress);

signals:
    void messageChanged(QString message);
    void stateChanged(int state);
    void progressChanged(int progress);

public slots:
    void onStarted();

private slots:
    void processDatagrams();

    void processSmartSyncMessage(smartsync_status_t status);

private:
    QUdpSocket *smartSyncSocket = nullptr;

    QString m_message = "Initializing";

    int m_state = SmartSyncStateInitializing;

    int m_progress = 0;
};

#endif
