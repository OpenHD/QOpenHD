#ifndef AIRPISETTINGSMODEL_H
#define AIRPISETTINGSMODEL_H

#include <QObject>
#include <QAbstractListModel>


class AirPiSettingsModel : public QAbstractListModel
{
    Q_OBJECT
public:
     static AirPiSettingsModel& instance();
    explicit AirPiSettingsModel(QObject *parent = nullptr);
    enum Roles {
        UniqueIdRole = Qt::UserRole,
        ValueRole
    };
    int rowCount(const QModelIndex& parent= QModelIndex()) const override;
    QVariant data( const QModelIndex& index, int role = Qt::DisplayRole ) const override;
    QHash<int, QByteArray> roleNames() const override;
    struct AirPiSettingData{
        QString unique_id;
        qint32 value;
    };
public slots:
    void removeData(int row);
    void addData(AirPiSettingData data);
private:
    QVector< AirPiSettingData > m_data;
};

#endif // AIRPISETTINGSMODEL_H
