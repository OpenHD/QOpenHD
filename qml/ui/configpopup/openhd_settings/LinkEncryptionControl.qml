import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../MenuTypography.js" as Typography

RowLayout {
    id: root
    objectName: "linkEncryptionControl"
    property var fleetBackend: typeof _fleetControlLte !== "undefined" ? _fleetControlLte : null
    readonly property var cameraModels: [typeof _airCameraSettingsModel !== "undefined" ? _airCameraSettingsModel : null,
                                        typeof _airCameraSettingsModel2 !== "undefined" ? _airCameraSettingsModel2 : null]
    readonly property int revision: cameraModels.reduce(function(total, model) { return total + (model ? model.update_count : 0) }, 0)
    readonly property var supportedModels: {
        revision
        return cameraModels.filter(function(model) { return model && model.param_int_exists("HIGH_ENCRYPTION") })
    }
    property double currentTime: Date.now()
    Timer { interval: 30000; running: root.visible; repeat: true; onTriggered: root.currentTime = Date.now() }
    readonly property var licence: {
        if (!fleetBackend || !fleetBackend.licenseValid) return null
        var licences = fleetBackend.licenses || []
        for (var i = 0; i < licences.length; ++i) {
            var item = licences[i]
            if (item.id !== fleetBackend.verifiedLicenseId || !item.craftId || item.status === "expired") continue
            if (item.expiresAt && !(Date.parse(item.expiresAt) > currentTime)) continue
            return item
        }
        return null
    }
    readonly property bool allEncrypted: {
        revision
        return supportedModels.length > 0 && supportedModels.every(function(model) { return model.get_cached_int("HIGH_ENCRYPTION") === 1 })
    }
    readonly property bool ready: !!licence && supportedModels.length > 0 && _ohdSystemAir.is_alive &&
                                 !_qopenhd.debugMenuPreview && !fleetBackend.busy &&
                                 supportedModels.every(function(model) { return !model.ui_is_busy })
    property string pendingLicence: ""
    visible: !!licence
    implicitHeight: visible ? Typography.controlHeight + 8 : 0
    spacing: 12

    function applyToCameras(value) {
        if (!ready) return
        for (var i = 0; i < supportedModels.length; ++i)
            if (supportedModels[i].get_cached_int("HIGH_ENCRYPTION") !== value)
                supportedModels[i].try_set_param_int_async("HIGH_ENCRYPTION", value, true)
    }
    function changeEncryption(enabled) {
        if (!ready) return
        if (enabled && (!fleetBackend.certificateInstalled || fleetBackend.certificateLicenseId !== licence.id ||
                        (fleetBackend.certificateExpiresAt && !(Date.parse(fleetBackend.certificateExpiresAt) > Date.now())))) {
            pendingLicence = licence.id
            fleetBackend.requestVideoCertificate(licence.id)
        } else applyToCameras(enabled ? 1 : 0)
    }
    Connections {
        target: root.fleetBackend
        function onStatusChanged() {
            root.currentTime = Date.now()
            if (!root.pendingLicence || !root.fleetBackend || root.fleetBackend.busy) return
            var requested = root.pendingLicence
            root.pendingLicence = ""
            if (root.licence && root.licence.id === requested && root.fleetBackend.certificateInstalled &&
                    root.fleetBackend.certificateLicenseId === requested &&
                    (!root.fleetBackend.certificateExpiresAt || Date.parse(root.fleetBackend.certificateExpiresAt) > Date.now()))
                root.applyToCameras(1)
        }
    }
    Text {
        Layout.fillWidth: true
        text: qsTr("High encryption")
        color: settings_form.primaryText
        font.family: Typography.family; font.pixelSize: Typography.body; font.bold: true
    }
    Switch {
        objectName: "linkEncryptionSwitch"
        font.family: Typography.family; font.pixelSize: Typography.body
        checked: root.allEncrypted
        enabled: root.ready
        onClicked: {
            root.changeEncryption(checked)
            checked = Qt.binding(function() { return root.allEncrypted })
        }
    }
}
