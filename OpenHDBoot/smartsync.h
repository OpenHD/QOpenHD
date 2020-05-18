#ifndef SMARTSYNC_H
#define SMARTSYNC_H

#include <QObject>
#include <QtQuick>

class QUdpSocket;


enum SmartSyncState {
    SmartSyncStateInitializing,
    SmartSyncStateWaitingForTrigger,
    SmartSyncStateWaitingForAir,
    SmartSyncStateTransferring,
    SmartSyncStateNotNeeded,
    SmartSyncStateFinished,
    SmartSyncStateError,
    SmartSyncStateSkipped
};

typedef struct {
    /*
     * 0: initializing
     * 1: wait for trigger (gpio/rc)
     * 2: waiting for air to connect
     * 3: transferring
     * 4: no sync needed
     * 5: finished
     * 6: error
     * 7: skipped
     */
    uint32_t state;
    /*
     * Progress percentage 0-100
     */
    uint32_t progress;
    /*
     * RC trigger channel
     */
    uint32_t rc_channel;
    /*
     * RC trigger low value
     */
    uint32_t rc_low;
    /*
     * RC trigger high value
     */
    uint32_t rc_high;
    /*
     * RC current channel value
     */
    uint32_t rc_current_value;
    /*
     * GPIO pin 26 state
     */
    uint32_t gpio_26_state;
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
