import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import ".."

FocusScope {
    id: root

    signal backRequested()

    property var settingsModel: _airCameraSettingsModel
    property var streamModel: _cameraStreamModelPrimary
    property bool secondary: false
    property string activeCategory: "VIDEO"

    readonly property bool raspberryPi: _ohdSystemAir.ohd_platform_type >= 10 &&
                                        _ohdSystemAir.ohd_platform_type <= 13
    readonly property bool busy: _ohdSystemGroundSettings.ui_is_busy ||
                                 _ohdSystemAirSettingsModel.ui_is_busy ||
                                 _airCameraSettingsModel.ui_is_busy ||
                                 _airCameraSettingsModel2.ui_is_busy
    readonly property bool ready: _ohdSystemAir.is_alive && settingsModel.has_params_fetched
    readonly property int paramRevision: settingsModel ? settingsModel.update_count : 0

    Material.theme: settings_form.darkMode ? Material.Dark : Material.Light
    Material.accent: settings_form.accentColor
    Material.foreground: settings_form.primaryText
    Material.background: settings_form.panelBackgroundRaised

    ListModel {
        id: categoryModel
        ListElement { categoryKey: "VIDEO"; title: qsTr("VIDEO"); icon: "\uf03d" }
        ListElement { categoryKey: "CAMERA"; title: qsTr("CAMERA"); icon: "\uf030" }
        ListElement { categoryKey: "IMAGE"; title: qsTr("IMAGE"); icon: "\uf03e" }
        ListElement { categoryKey: "COLOR"; title: qsTr("COLOR"); icon: "\uf53f" }
        ListElement { categoryKey: "EXPOSURE"; title: qsTr("EXPOSURE"); icon: "\uf042" }
        ListElement { categoryKey: "CONNECTION"; title: qsTr("IP CAMERA"); icon: "\uf1eb" }
        ListElement { categoryKey: "ADVANCED"; title: qsTr("ADVANCED"); icon: "\uf013" }
    }

    function categoryFor(id) {
        if (["IP_CAM_ADDRESS", "IP_CAM_PIPELINE"].indexOf(id) >= 0)
            return "CONNECTION"
        if (["AIR_RECORDING_E", "STREAMING_E", "BITRATE_MBITS", "VIDEO_CODEC",
             "KEYFRAME_I", "RESOLUTION_FPS"].indexOf(id) >= 0)
            return "VIDEO"
        if (id.indexOf("AWB") >= 0 || id.indexOf("WHITE_BALANCE") >= 0)
            return "COLOR"
        if (id.indexOf("EXP") >= 0 || id.indexOf("SHUTTER") >= 0 ||
                id.indexOf("METERING") >= 0 || id === "ISO")
            return "EXPOSURE"
        if (id.indexOf("BRIGHTNESS") >= 0 || id.indexOf("CONTRAST") >= 0 ||
                id.indexOf("SATURATION") >= 0 || id.indexOf("SHARPNESS") >= 0 ||
                id.indexOf("DENOISE") >= 0)
            return "IMAGE"
        if (["CAMERA_TYPE", "ROTATION_FLIP", "ROTATION_DEG"].indexOf(id) >= 0)
            return "CAMERA"
        return "ADVANCED"
    }

    function categoryDescription(category) {
        if (category === "VIDEO") return qsTr("Streaming, recording, format and encoder settings")
        if (category === "CAMERA") return qsTr("Connected camera hardware and image orientation")
        if (category === "IMAGE") return qsTr("Brightness, contrast, color intensity and detail")
        if (category === "COLOR") return qsTr("White-balance behavior for the current lighting")
        if (category === "EXPOSURE") return qsTr("Exposure, metering, shutter and ISO controls")
        if (category === "CONNECTION") return qsTr("RTSP source and video-link reservation for an Ethernet camera")
        return qsTr("Expert encoder and camera options")
    }

    function categoryCount(category) {
        var revision = paramRevision
        var count = 0
        var ids = settingsModel ? settingsModel.param_ids() : []
        for (var i = 0; i < ids.length; ++i)
            if (categoryFor(ids[i]) === category) ++count
        return count
    }

    function categoryIndex(category) {
        for (var i = 0; i < categoryModel.count; ++i)
            if (categoryModel.get(i).categoryKey === category) return i
        return -1
    }

    function categoryAvailable(index) {
        return index >= 0 && index < categoryModel.count &&
               categoryCount(categoryModel.get(index).categoryKey) > 0
    }

    function firstAvailableCategory(from, step) {
        for (var i = from; i >= 0 && i < categoryModel.count; i += step)
            if (categoryAvailable(i)) return i
        return -1
    }

    function ensureActiveCategory() {
        var current = categoryIndex(activeCategory)
        if (categoryAvailable(current)) return
        var first = firstAvailableCategory(0, 1)
        if (first >= 0) activeCategory = categoryModel.get(first).categoryKey
    }

    function focusCategory(index) {
        if (!categoryAvailable(index)) return
        var item = categoryRepeater.itemAt(index)
        if (item) {
            item.forceActiveFocus()
            categoryScroller.ensureVisible(item)
        }
    }

    function focusActiveCategory() {
        ensureActiveCategory()
        focusCategory(categoryIndex(activeCategory))
    }

    function selectCategory(index, focusContent) {
        if (!categoryAvailable(index)) return
        activeCategory = categoryModel.get(index).categoryKey
        categoryScroller.ensureVisible(categoryRepeater.itemAt(index))
        settingsFlick.contentY = 0
        if (focusContent) Qt.callLater(focusFirstSetting)
    }

    function moveCategory(index, step) {
        var next = firstAvailableCategory(index + step, step)
        if (next >= 0) {
            selectCategory(next, false)
            focusCategory(next)
        } else if (step < 0) {
            backRequested()
        }
    }

    function firstVisibleSettingIndex() {
        for (var i = 0; i < settingRepeater.count; ++i) {
            var item = settingRepeater.itemAt(i)
            if (item && item.visible) return i
        }
        return -1
    }

    function focusFirstSetting() {
        if (activeCategory === "CONNECTION") {
            connectionPanel.gainFocus()
            return
        }
        var first = firstVisibleSettingIndex()
        if (first >= 0) focusSetting(first)
        else focusActiveCategory()
    }

    function focusSetting(index) {
        var item = settingRepeater.itemAt(index)
        if (!item || !item.visible) return
        item.gainFocus()
        ensureSettingVisible(item)
    }

    function moveSetting(sourceIndex, step) {
        for (var i = sourceIndex + step; i >= 0 && i < settingRepeater.count; i += step) {
            var item = settingRepeater.itemAt(i)
            if (item && item.visible) {
                focusSetting(i)
                return
            }
        }
        if (step < 0) focusActiveCategory()
    }

    function ensureSettingVisible(item) {
        if (!item) return
        var point = item.mapToItem(settingsColumn, 0, 0)
        var top = point.y - 12
        var bottom = point.y + item.height + 12
        if (top < settingsFlick.contentY)
            settingsFlick.contentY = Math.max(0, top)
        else if (bottom > settingsFlick.contentY + settingsFlick.height)
            settingsFlick.contentY = Math.min(bottom - settingsFlick.height,
                                              Math.max(0, settingsFlick.contentHeight - settingsFlick.height))
    }

    function statusText() {
        if (!_ohdSystemAir.is_alive) return qsTr("Air unit offline")
        if (streamModel.camera_status === 1) return qsTr("Streaming")
        if (streamModel.camera_status === 2) return qsTr("Restarting")
        if (streamModel.camera_status === 0) return qsTr("Camera detected")
        return qsTr("Status unavailable")
    }

    function statusColor() {
        if (!_ohdSystemAir.is_alive || streamModel.camera_status < 0) return settings_form.secondaryText
        if (streamModel.camera_status === 1) return settings_form.goodColor
        if (streamModel.camera_status === 2) return settings_form.darkMode ? "#ffd479" : "#936300"
        if (streamModel.camera_status === 0) return settings_form.accentColor
        return settings_form.errorColor
    }

    function cameraName() {
        var name = streamModel.camera_type_to_string(streamModel.camera_type)
        return name === "N/A" ? qsTr("Camera not reported") : name
    }

    function formatText() {
        var value = String(streamModel.curr_set_video_format)
        if (!value.length) return qsTr("Not reported")
        var parts = value.split("@")
        var dimensions = parts[0].replace("x", " \u00d7 ")
        return parts.length > 1 ? dimensions + "  /  " + parts[1] + qsTr(" fps") : dimensions
    }

    function codecText() {
        if (streamModel.encoding_codec < 0) return qsTr("Not reported")
        return String(streamModel.camera_codec_to_string(streamModel.encoding_codec)).toUpperCase()
    }

    function gainFocus() {
        if (ready) focusActiveCategory()
        else if (reloadButton.visible && reloadButton.enabled) reloadButton.forceActiveFocus()
        else forceActiveFocus()
    }

    onParamRevisionChanged: ensureActiveCategory()
    onVisibleChanged: {
        if (visible && _ohdSystemAir.is_alive && !settingsModel.has_params_fetched && !settingsModel.ui_is_busy)
            settingsModel.try_refetch_all_parameters_async(false)
        if (visible) Qt.callLater(ensureActiveCategory)
    }
    Component.onCompleted: ensureActiveCategory()
    Keys.onEscapePressed: root.backRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 9

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 78
            radius: 11
            color: settings_form.panelBackgroundRaised
            border.color: settings_form.lineColor

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    radius: 10
                    color: settings_form.darkMode ? "#173b61" : "#dcecff"
                    Text {
                        anchors.centerIn: parent
                        text: "\uf030"
                        font.family: "Font Awesome 5 Free"
                        font.pixelSize: 20
                        color: settings_form.accentColor
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 150
                    spacing: 3
                    Text {
                        Layout.fillWidth: true
                        text: root.secondary ? qsTr("AIR CAMERA 2") : qsTr("AIR CAMERA 1")
                        color: settings_form.primaryText
                        font.pixelSize: 16
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 7
                        Rectangle {
                            Layout.preferredWidth: 8
                            Layout.preferredHeight: 8
                            radius: 4
                            color: root.statusColor()
                        }
                        Text {
                            text: root.statusText()
                            color: root.statusColor()
                            font.pixelSize: 10
                            font.bold: true
                        }
                        Text { text: "\u2022"; color: settings_form.secondaryText; font.pixelSize: 9 }
                        Text {
                            Layout.fillWidth: true
                            text: root.cameraName()
                            color: settings_form.secondaryText
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }
                }

                BusyIndicator {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    visible: root.busy
                    running: visible
                }

                Rectangle {
                    visible: root.width >= 760
                    Layout.preferredWidth: 150
                    Layout.preferredHeight: 48
                    radius: 8
                    color: settings_form.panelBackground
                    border.color: settings_form.lineColor
                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text { text: qsTr("FORMAT"); color: settings_form.secondaryText; font.pixelSize: 8; font.bold: true }
                        Text { width: 132; text: root.formatText(); color: settings_form.primaryText; font.pixelSize: 10; font.bold: true; elide: Text.ElideRight }
                    }
                }

                Rectangle {
                    visible: root.width >= 940
                    Layout.preferredWidth: 96
                    Layout.preferredHeight: 48
                    radius: 8
                    color: settings_form.panelBackground
                    border.color: settings_form.lineColor
                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text { text: qsTr("CODEC"); color: settings_form.secondaryText; font.pixelSize: 8; font.bold: true }
                        Text { text: root.codecText(); color: settings_form.primaryText; font.pixelSize: 10; font.bold: true }
                    }
                }

                Rectangle {
                    visible: root.width >= 1100 && streamModel.curr_recomended_video_bitrate_string !== "N/A"
                    Layout.preferredWidth: 112
                    Layout.preferredHeight: 48
                    radius: 8
                    color: settings_form.panelBackground
                    border.color: settings_form.lineColor
                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text { text: qsTr("TARGET"); color: settings_form.secondaryText; font.pixelSize: 8; font.bold: true }
                        Text { text: streamModel.curr_recomended_video_bitrate_string; color: settings_form.primaryText; font.pixelSize: 10; font.bold: true }
                    }
                }
            }
        }

        Flickable {
            id: categoryScroller
            Layout.fillWidth: true
            Layout.preferredHeight: root.ready ? 38 : 0
            visible: root.ready
            contentWidth: categoryRow.width
            contentHeight: height
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

            function ensureVisible(item) {
                if (!item) return
                if (item.x < contentX) contentX = item.x
                else if (item.x + item.width > contentX + width)
                    contentX = item.x + item.width - width
            }

            Row {
                id: categoryRow
                height: parent.height
                spacing: 7
                Repeater {
                    id: categoryRepeater
                    model: categoryModel
                    delegate: AdvancedTabButton {
                        id: categoryButton
                        property int itemCount: root.categoryCount(model.categoryKey)
                        visible: itemCount > 0
                        width: visible ? implicitWidth : 0
                        height: 36
                        text: model.title
                        iconText: model.icon
                        checked: root.activeCategory === model.categoryKey
                        onClicked: root.selectCategory(index, false)
                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Left) {
                                root.moveCategory(index, -1); event.accepted = true
                            } else if (event.key === Qt.Key_Right) {
                                root.moveCategory(index, 1); event.accepted = true
                            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.selectCategory(index, true); event.accepted = true
                            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Escape) {
                                root.backRequested(); event.accepted = true
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: settingsSurface
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.ready
            radius: 11
            color: settings_form.panelBackgroundRaised
            border.color: settings_form.lineColor
            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    Layout.leftMargin: 18
                    Layout.rightMargin: 18
                    spacing: 10
                    Text {
                        text: categoryModel.get(Math.max(0, root.categoryIndex(root.activeCategory))).icon
                        color: settings_form.accentColor
                        font.family: "Font Awesome 5 Free"
                        font.pixelSize: 15
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: categoryModel.get(Math.max(0, root.categoryIndex(root.activeCategory))).title
                            color: settings_form.primaryText
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.categoryDescription(root.activeCategory)
                            color: settings_form.secondaryText
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }
                    Rectangle {
                        implicitWidth: countLabel.implicitWidth + 16
                        implicitHeight: 26
                        radius: 7
                        color: settings_form.panelBackground
                        border.color: settings_form.lineColor
                        Text {
                            id: countLabel
                            anchors.centerIn: parent
                            text: root.activeCategory === "CONNECTION"
                                  ? qsTr("SETUP") : String(root.categoryCount(root.activeCategory))
                            color: settings_form.secondaryText
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: settings_form.lineColor }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Flickable {
                        id: settingsFlick
                        anchors.fill: parent
                        anchors.margins: 8
                        visible: root.activeCategory !== "CONNECTION"
                        contentWidth: width
                        contentHeight: Math.max(height, settingsColumn.height + 8)
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        Behavior on contentY { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        Column {
                            id: settingsColumn
                            width: Math.min(1180, Math.max(280, settingsFlick.width - 12))
                            x: Math.round((settingsFlick.width - width) / 2)
                            spacing: 3

                            Repeater {
                                id: settingRepeater
                                model: root.settingsModel
                                delegate: CameraSettingRow {
                                    width: settingsColumn.width
                                    visible: root.categoryFor(model.unique_id) === root.activeCategory &&
                                             root.activeCategory !== "CONNECTION"
                                    settingsModel: root.settingsModel
                                    categoryKey: root.activeCategory
                                    modelIndex: index
                                    paramId: model.unique_id
                                    valueType: model.valueType
                                    paramValue: model.value
                                    displayValue: model.extraValue
                                    description: model.shortDescription === "TODO" ? "" : model.shortDescription
                                    readOnly: model.read_only
                                    whitelisted: model.whitelisted
                                    busy: root.busy || !_ohdSystemAir.is_alive
                                    raspberryPi: root.raspberryPi
                                    streamModel: root.streamModel
                                    platformType: _ohdSystemAir.ohd_platform_type
                                    onMoveRequested: function(sourceIndex, step) { root.moveSetting(sourceIndex, step) }
                                    onExitRequested: root.focusActiveCategory()
                                    onCategoryRequested: root.focusActiveCategory()
                                    onFocusRequested: function(sourceIndex) {
                                        var item = settingRepeater.itemAt(sourceIndex)
                                        if (item) root.ensureSettingVisible(item)
                                    }
                                }
                            }
                        }
                    }

                    CameraConnectionPanel {
                        id: connectionPanel
                        anchors.fill: parent
                        visible: root.activeCategory === "CONNECTION"
                        settingsModel: root.settingsModel
                        busy: root.busy
                        onCategoryRequested: root.focusActiveCategory()
                        onBackRequested: root.focusActiveCategory()
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.ready

            ColumnLayout {
                width: Math.min(460, parent.width - 32)
                anchors.centerIn: parent
                spacing: 12

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: _ohdSystemAir.is_alive ? "\uf030" : "\uf127"
                    font.family: "Font Awesome 5 Free"
                    font.pixelSize: 42
                    color: settings_form.secondaryText
                    opacity: 0.7
                }
                Text {
                    Layout.fillWidth: true
                    text: !_ohdSystemAir.is_alive ? qsTr("Air unit offline")
                          : (settingsModel.ui_is_busy ? qsTr("Loading camera settings")
                                                     : qsTr("Camera settings are not loaded"))
                    color: settings_form.primaryText
                    font.pixelSize: 16
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    Layout.fillWidth: true
                    text: !_ohdSystemAir.is_alive
                          ? qsTr("Connect the air unit to view and change this camera.")
                          : qsTr("Load the parameters reported by this camera component.")
                    color: settings_form.secondaryText
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
                ProgressBar {
                    Layout.fillWidth: true
                    visible: settingsModel.ui_is_busy
                    from: 0; to: 100
                    value: Math.max(0, settingsModel.curr_get_all_progress_perc)
                }
                AdvancedActionButton {
                    id: reloadButton
                    Layout.alignment: Qt.AlignHCenter
                    visible: _ohdSystemAir.is_alive && !settingsModel.ui_is_busy
                    text: qsTr("Load camera settings")
                    iconText: "\uf2f1"
                    primary: true
                    enabled: visible && !root.busy
                    onClicked: settingsModel.try_refetch_all_parameters_async(true)
                    Keys.onEscapePressed: root.backRequested()
                }
            }
        }
    }
}
