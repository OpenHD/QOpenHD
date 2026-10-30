#pragma once
#include <QObject>
#include <QQmlContext>
#include <QVariantMap>
#include <QVariantList>
#include <QMap>
#include <QTimer>
#include <QQmlPropertyMap>
#include <atomic>
class AOHDSystem;
class CameraStreamModel;
class MavlinkSettingsModel;
class WiFiCard;
class FCMavlinkSystem;
class WBLinkSettingsHelper;
class PollutionHelper;
class OHDAction;
class RCChannelsModel;

// Separate UI-only models: live singleton caches are never overwritten.
class UiSimulator : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool active READ active NOTIFY activeChanged)
    Q_PROPERTY(bool developerUnlocked MEMBER m_unlocked NOTIFY developerUnlockedChanged)
    Q_PROPERTY(QVariantMap profile READ profile NOTIFY profileChanged)
    Q_PROPERTY(QObject* localSettings READ localSettings CONSTANT)
    Q_PROPERTY(QString lastAction READ lastAction NOTIFY lastActionChanged)
public:
    explicit UiSimulator(QObject* parent=nullptr);
    static UiSimulator& instance();
    static bool isActive();
    bool active() const { return m_active.load(); }
    QVariantMap profile() const { return m_profile; }
    QString lastAction() const { return m_lastAction; }
    QObject* localSettings() { return &m_localSettings; }
    void install(QQmlContext* context);
    Q_INVOKABLE bool start(const QVariantMap& profile);
    Q_INVOKABLE void stop();
    Q_INVOKABLE QVariantList platforms() const;
    Q_INVOKABLE QVariantList cameras(int platform) const;
    Q_INVOKABLE QVariantList radios() const;
    bool setParameter(int system,int component,const QString& id,const QVariant& value);
    void recordAction(const QString& action);
    void startRadioOperation(bool analysis);
    bool storageAction(int action,int id);
    QObject* simulatedObject(const QString& name) const { return m_simulated.value(name); }
signals:
    void activeChanged();
    void profileChanged();
    void developerUnlockedChanged();
    void lastActionChanged();
private:
    void createModels();
    void refresh();
    void seedParameters(MavlinkSettingsModel*,int system,int component,int platform,int camera);
    QQmlContext* m_context=nullptr;
    QMap<QString,QObject*> m_live,m_simulated;
    static std::atomic_bool s_active;
    std::atomic_bool m_active{false};
    bool m_unlocked=false;
    QVariantMap m_profile;
    QString m_lastAction;
    AOHDSystem *m_air=nullptr,*m_ground=nullptr;
    CameraStreamModel *m_cameras[2]{};
    MavlinkSettingsModel *m_airParams=nullptr,*m_groundParams=nullptr,*m_cameraParams[2]{};
    WiFiCard* m_radios[5]{};
    FCMavlinkSystem* m_fc=nullptr;
    WBLinkSettingsHelper* m_linkHelper=nullptr;
    PollutionHelper* m_pollution=nullptr;
    OHDAction* m_actions=nullptr;
    RCChannelsModel* m_rc=nullptr;
    QVariantList m_storage;
    int m_radioProgress=-1;
    bool m_analyzing=false;
    bool m_refreshing=false;
    QQmlPropertyMap m_localSettings;
    QTimer m_tick;
    int m_seconds=0;
};
