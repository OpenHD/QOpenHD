#include "documentedparam.h"
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <map>
#include <mutex>
#include <QRegularExpression>
#include <cmath>

namespace {
std::mutex metadata_mutex;
std::map<std::pair<int,int>,QJsonObject> device_metadata;
QJsonObject fallback() {
    static const auto catalog=[] {
        QFile file(":/settings/catalog.json");
        if (!file.open(QIODevice::ReadOnly)) return QJsonObject{};
        QJsonObject result;
        for (const auto value:QJsonDocument::fromJson(file.readAll()).object()["settings"].toArray()) {
            const auto entry=value.toObject(); result.insert(entry["id"].toString(),entry);
        }
        return result;
    }();
    return catalog;
}
}

bool DocumentedParam::is_camera_setting(const QString& id) {
    return fallback().value(id).toObject().value("cameraOnly").toBool();
}

QString DocumentedParam::camera_setting_category(const QString& id) {
    return fallback().value(id).toObject().value("cameraCategory").toString();
}

bool DocumentedParam::camera_setting_supported(const QString& id,int cameraType,int platformType) {
    if (cameraType < 0 || cameraType == 255) return false;
    const auto entry = fallback().value(id).toObject();
    const auto types = entry.value("supportedCameraTypes").toArray();
    if (!types.isEmpty() && !types.contains(cameraType)) return false;
    if (entry.value("excludedPlatforms").toArray().contains(platformType)) return false;
    // External and dummy sources have no local image sensor or ISP controls.
    if (cameraType == 0 || cameraType == 2 || cameraType == 3 || cameraType == 4) {
        const auto category = entry.value("cameraCategory").toString();
        if (category == "IMAGE" || category == "EXPOSURE") return false;
    }
    return true;
}

bool DocumentedParam::install_metadata(int sys,int comp,const QByteArray& bytes) {
    if (bytes.size()>1024*1024) return false;
    const auto doc=QJsonDocument::fromJson(bytes).object();
    if (doc["version"].toInt()!=1 || doc["systemId"].toInt()!=sys || doc["componentId"].toInt()!=comp || !doc["settings"].isArray()) return false;
    QJsonObject entries;
    for (const auto value:doc["settings"].toArray()) {
        const auto e=value.toObject(); const auto id=e["id"].toString();
        if (!QRegularExpression("^[A-Za-z0-9_.-]{1,16}$").match(id).hasMatch() || entries.contains(id) ||
            (e["type"]!="int32" && e["type"]!="string")) return false;
        if(e.contains("choices")) {
            if(!e["choices"].isArray()) return false;
            for(const auto choice:e["choices"].toArray()) {
                const auto c=choice.toObject();
                if(!c["label"].isString()) return false;
                if(e["type"]=="int32") {
                    const auto number=c["value"].toDouble();
                    if(!c["value"].isDouble() || std::floor(number)!=number || number<INT32_MIN || number>INT32_MAX) return false;
                } else if(!c["value"].isString() || c["value"].toString().toUtf8().size()>128 || c["value"].toString().contains(QChar('\0'))) return false;
            }
        }
        entries.insert(id,e);
    }
    std::lock_guard<std::mutex> lock(metadata_mutex);
    device_metadata[{sys,comp}]=entries;
    return true;
}

QJsonObject DocumentedParam::metadata(const std::string& id,int sys,int comp) {
    std::lock_guard<std::mutex> lock(metadata_mutex);
    const auto it=device_metadata.find({sys,comp});
    return (it==device_metadata.end() ? fallback() : it->second).value(QString::fromStdString(id)).toObject();
}
void DocumentedParam::invalidate_metadata(int sys,int comp) {
    std::lock_guard<std::mutex> lock(metadata_mutex);
    device_metadata.erase({sys,comp});
}
bool DocumentedParam::has_device_metadata(int sys,int comp) {
    std::lock_guard<std::mutex> lock(metadata_mutex);
    return device_metadata.count({sys,comp})!=0;
}

std::optional<DocumentedParam::XParam> DocumentedParam::find_param(const std::string& name,int sys,int comp) {
    const auto e=metadata(name,sys,comp);
    if (e.isEmpty()) return std::nullopt;
    std::optional<ImprovedIntSetting> integer;
    std::optional<ImprovedStringSetting> string;
    if (e["type"]=="int32") {
        std::vector<ImprovedIntSetting::Item> values;
        for (const auto c:e["choices"].toArray()) values.push_back({c.toObject()["label"].toString().toStdString(),c.toObject()["value"].toInt()});
        integer=ImprovedIntSetting(e["minimum"].toInt(std::numeric_limits<int>::min()),e["maximum"].toInt(std::numeric_limits<int>::max()),values);
    } else if (e["type"]=="string") {
        std::vector<ImprovedStringSetting::Item> values;
        for (const auto c:e["choices"].toArray()) values.push_back({c.toObject()["label"].toString().toStdString(),c.toObject()["value"].toString().toStdString()});
        string=ImprovedStringSetting(values);
    }
    return XParam{name,integer,string,e["description"].toString().toStdString(),e["requiresReboot"].toBool(),
        e["readOnly"].toBool() || !e["writable"].toBool(true) || !e["available"].toBool(true)};
}
bool DocumentedParam::is_param_whitelisted(const std::string& id,int sys,int comp) {
    return metadata(id,sys,comp)["hidden"].toBool();
}

bool DocumentedParam::read_only(const std::string& id,int sys,int comp) {
    const auto e=metadata(id,sys,comp);
    return e["readOnly"].toBool() || !e["writable"].toBool(true) || !e["available"].toBool(true);
}
bool DocumentedParam::requires_reboot(const std::string& id,int sys,int comp) {
    return metadata(id,sys,comp)["requiresReboot"].toBool();
}
std::string DocumentedParam::get_short_description(const std::string& id,int sys,int comp) {
    return metadata(id,sys,comp)["description"].toString(QString::fromStdString(id)).toStdString();
}
std::optional<ImprovedIntSetting> DocumentedParam::get_improved_for_int(const std::string& id,int sys,int comp) {
    const auto p=find_param(id,sys,comp); return p ? p->improved_int : std::nullopt;
}
std::optional<ImprovedStringSetting> DocumentedParam::get_improved_for_string(const std::string id,int sys,int comp) {
    const auto p=find_param(id,sys,comp); return p ? p->improved_string : std::nullopt;
}
std::optional<std::string> DocumentedParam::int_param_to_enum_string_if_known(const std::string id,int value,int sys,int comp) {
    const auto p=get_improved_for_int(id,sys,comp);
    return p && p->has_enum_mapping() ? std::optional<std::string>(p->value_to_string(value)) : std::nullopt;
}
std::optional<std::string> DocumentedParam::string_param_to_enum_string_if_known(const std::string id,std::string value,int sys,int comp) {
    const auto p=get_improved_for_string(id,sys,comp); return p ? p->value_to_key(value) : std::nullopt;
}
