import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12
import ".."
import "../MenuTypography.js" as Typography
import "AirSettingsLayout.js" as AirLayout

FocusScope {
    id: root
    signal backRequested()
    property bool groundMode: false
    property var settingsModel: groundMode ? _ohdSystemGroundSettings : _ohdSystemAirSettingsModel
    property var systemModel: groundMode ? _ohdSystemGround : _ohdSystemAir
    property string activeCategory: "fc"
    Material.theme: settings_form.darkMode ? Material.Dark : Material.Light
    Material.accent: settings_form.accentColor
    Material.foreground: settings_form.primaryText
    readonly property int revision: settingsModel.update_count
    readonly property bool preview: _qopenhd.debugMenuPreview
    readonly property bool advanced: settings_form.showAdvancedSettings
    readonly property bool developer: settings_form.showDeveloperSettings === true
    readonly property var categories: AirLayout.categories.filter(function(c) { return (c.id !== "expert" || root.advanced) && (c.id !== "ethernet" || root.advanced || root.developer) && (c.id !== "developer" || root.developer) && root.categoryCount(c.id) > 0 })
    readonly property string parameterKey: {
        var changed = revision
        var previewChanged = preview
        var includeAdvanced = advanced
        var includeDeveloper = developer
        return (groundMode ? AirLayout.availableGroundParameterIds(settingsModel, includeAdvanced, includeDeveloper, previewChanged) : AirLayout.availableParameterIds(settingsModel, includeAdvanced, includeDeveloper, previewChanged)).join("|")
    }
    readonly property var parameterIds: parameterKey.length ? parameterKey.split("|") : []
    readonly property var category: {
        for (var i=0;i<AirLayout.categories.length;i++) if(AirLayout.categories[i].id===activeCategory) return AirLayout.categories[i]
        return AirLayout.categories[0]
    }
    readonly property int wifiMode: {
        revision
        return settingsModel.param_int_exists("WIFI_MODE") ? settingsModel.get_cached_int("WIFI_MODE") : 1
    }
    function wifiParameterVisible(id) {
        if (id.indexOf("WIFI_CL_") === 0) return wifiMode === 2
        if (id.indexOf("WIFI_HS_") === 0 || id === "WIFI_HOTSPOT_E") return wifiMode === 1
        return true
    }
    function idsForSection(id) {
        if (!parameterIds) return []
        var result = [], preferred = []
        for(var i=0;i<AirLayout.sections.length;i++) if(AirLayout.sections[i].id === id) preferred = AirLayout.sections[i].ids
        for(var j=0;j<preferred.length;j++) if(parameterIds.indexOf(preferred[j])>=0) result.push(preferred[j])
        for(var k=0;k<parameterIds.length;k++) if(AirLayout.sectionFor(parameterIds[k]) === id && result.indexOf(parameterIds[k])<0) result.push(parameterIds[k])
        return id === "wifi" ? result.filter(root.wifiParameterVisible) : result
    }
    function sectionsForCategory(id) {
        var sections = AirLayout.sections.filter(function(section) { return section.categories.indexOf(id)>=0 && root.idsForSection(section.id).length>0 })
        if (id === "expert") {
            var order = ["rcRadio", "radio", "artosyn"]
            sections.sort(function(a,b) { return order.indexOf(a.id) - order.indexOf(b.id) })
        }
        return sections
    }
    function categoryCount(id) {
        var sections = sectionsForCategory(id), result = 0
        for(var i=0;i<sections.length;i++) result += idsForSection(sections[i].id).length
        return result
    }
    readonly property var rfCodingIds: ["WB_E_STBC", "WB_E_LDPC", "WB_E_SHORT_GUARD"]
    function refresh() { if(!preview && root.systemModel.is_alive && !settingsModel.ui_is_busy) settingsModel.ensure_parameters_available() }
    function validateUart(id, value) {
        if (["FC_UART_CONN","OHD_UART_TLM","OHD_UART_EN"].indexOf(id) < 0) return ""
        function port(key) { return key === id ? String(value).trim() : settingsModel.param_string_exists(key) ? settingsModel.get_cached_string(key) : "" }
        var enabled = id === "OHD_UART_EN" ? Number(value) !== 0 : settingsModel.param_int_exists("OHD_UART_EN") && settingsModel.get_cached_int("OHD_UART_EN") !== 0
        if (enabled && !port("OHD_UART_TLM")) return qsTr("Choose a UART port before enabling the Air-Ground link.")
        var fc = port("FC_UART_CONN"), link = port("OHD_UART_TLM")
        if (enabled && fc && fc !== "DEFAULT" && fc === link) return qsTr("Flight-controller MAVLink and the Air-Ground link need separate UART ports.")
        return ""
    }
    function ensureActiveCategory() {
        for (var i = 0; i < categories.length; ++i)
            if (categories[i].id === activeCategory) return
        activeCategory = categories.length ? categories[0].id : ""
    }
    onCategoriesChanged: ensureActiveCategory()
    function gainFocus() {
        ensureActiveCategory()
        for (var i = 0; i < categories.length; ++i) {
            if (categories[i].id === activeCategory && categoryCards.itemAt(i)) {
                categoryCards.itemAt(i).forceActiveFocus()
                return
            }
        }
        forceActiveFocus()
    }
    onVisibleChanged: if(visible) refresh()
    Component.onCompleted: refresh()
    onAdvancedChanged: ensureActiveCategory()
    onDeveloperChanged: ensureActiveCategory()
    Connections { target: root.systemModel; function onIs_aliveChanged() { if(root.visible) root.refresh() } }
    Timer { interval: 1200; repeat: true; running: root.visible && !root.preview && root.systemModel.is_alive && !root.settingsModel.has_params_fetched; onTriggered: root.refresh() }
    Keys.onEscapePressed: backRequested()

    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        Flickable {
            id: categoryScroller
            objectName: "airCategoryStrip"
            Layout.fillWidth: true
            Layout.minimumHeight: 44
            Layout.preferredHeight: Typography.controlHeight
            Layout.maximumHeight: 44
            contentWidth: categoryRow.width
            contentHeight: height
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            function reveal(button) {
                if (button.x < contentX) contentX = button.x
                else if (button.x + button.width > contentX + width) contentX = button.x + button.width - width
            }
            Row {
                id: categoryRow
                height: parent.height
                spacing: 8
                Repeater {
                    id: categoryCards
                    model: root.categories
                    delegate: AdvancedActionButton {
                        id: categoryButton
                        objectName: "airCategory_" + modelData.id
                        readonly property bool selected: root.activeCategory === modelData.id
                        width: categoryLabel.implicitWidth + 48
                        height: Typography.controlHeight
                        padding: 10
                        topInset: 0; bottomInset: 0; leftInset: 0; rightInset: 0
                        Accessible.name: modelData.title
                        onClicked: { root.activeCategory = modelData.id; scroller.contentY = 0; categoryScroller.reveal(categoryButton) }
                        onActiveFocusChanged: if(activeFocus) categoryScroller.reveal(categoryButton)
                        Keys.onEscapePressed: root.backRequested()
                        background: Rectangle {
                            radius: 8; color: categoryButton.selected ? settings_form.accentColor : settings_form.panelBackground
                            border.width: categoryButton.activeFocus ? 2 : 1
                            border.color: categoryButton.selected || categoryButton.activeFocus ? settings_form.accentColor : settings_form.lineColor
                        }
                        contentItem: Row {
                            spacing: 8
                            anchors.centerIn: parent
                            Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.icon; font.family: "Font Awesome 5 Free"; font.pixelSize: Typography.rowIcon; color: categoryButton.selected ? "white" : settings_form.accentColor }
                            Text { id: categoryLabel; anchors.verticalCenter: parent.verticalCenter; text: modelData.title; font.family: Typography.family; font.pixelSize: Typography.body; font.bold: true; color: categoryButton.selected ? "white" : settings_form.primaryText }
                        }
                    }
                }
            }
        }

        AdvancedCard {
            objectName: "airSettingsBody"
            Layout.fillWidth: true; Layout.fillHeight: true
            contentMargin: 12
            ColumnLayout {
                anchors.fill: parent
                spacing: 10
                Flickable {
                    id: scroller
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentWidth: width; contentHeight: sectionGrid.implicitHeight
                    clip: true; boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }
                    GridLayout {
                        id: sectionGrid
                        width: scroller.width
                        columns: root.activeCategory === "peripherals" || root.activeCategory === "system" ? 1 : (scroller.width >= 640 ? 2 : 1)
                        readonly property bool stackControllerCards: root.activeCategory === "fc" && columns === 2 && root.sectionsForCategory("fc").length === 3
                        columnSpacing: 10; rowSpacing: 10
                        Repeater {
                            model: root.sectionsForCategory(root.activeCategory)
                            delegate: AdvancedCard {
                                id: sectionCard
                                readonly property var section: modelData
                                readonly property bool collapsible: section.id === "artosyn"
                                property bool expanded: false
                                property bool codingExpanded: false
                                readonly property bool showContents: !collapsible || expanded
                                readonly property var codingIds: section.id === "radio" ? root.idsForSection(section.id).filter(function(id){return root.rfCodingIds.indexOf(id)>=0}) : []
                                objectName: "airSection_" + section.id
                                Layout.columnSpan: sectionCard.collapsible ? sectionGrid.columns : 1
                                Layout.column: sectionCard.collapsible ? 0 : sectionGrid.stackControllerCards ? (index === 0 ? 0 : 1) : index % sectionGrid.columns
                                Layout.row: sectionCard.collapsible ? Math.ceil((root.sectionsForCategory(root.activeCategory).length - 1) / sectionGrid.columns) : sectionGrid.stackControllerCards ? Math.max(0, index - 1) : Math.floor(index / sectionGrid.columns)
                                Layout.rowSpan: sectionGrid.stackControllerCards && index === 0 ? 2 : 1
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                Layout.minimumWidth: 0
                                Layout.preferredHeight: sectionContent.implicitHeight + 24
                                contentMargin: 12
                                color: settings_form.panelBackgroundRaised
                                Column {
                                    id: sectionContent
                                    anchors.left: parent.left; anchors.right: parent.right
                                    spacing: 6
                                    RowLayout {
                                        id: sectionHeader
                                        width: parent.width; height: Math.max(Typography.controlHeight, implicitHeight); spacing: 10
                                        Text { text: sectionCard.section.icon; color: settings_form.accentColor; font.family: "Font Awesome 5 Free"; font.pixelSize: Typography.sectionIcon }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { Layout.fillWidth: true; text: sectionCard.section.title; color: settings_form.primaryText; font.family: Typography.family; font.pixelSize: Typography.body; font.bold: true; wrapMode: Text.Wrap }

                                        }
                                        AdvancedActionButton {
                                            objectName: "airSectionToggle_" + sectionCard.section.id
                                            visible: sectionCard.collapsible
                                            implicitWidth: Typography.controlHeight
                                            iconText: sectionCard.expanded ? "\uf078" : "\uf054"
                                            Accessible.name: sectionCard.section.title
                                            onClicked: sectionCard.expanded = !sectionCard.expanded
                                        }
                                    }
                                    Rectangle { visible: sectionCard.showContents; width: parent.width; height: visible ? 1 : 0; color: settings_form.lineColor }
                                    RowLayout {
                                        objectName: "wifiModeSwitch"
                                        visible: sectionCard.showContents && sectionCard.section.id === "wifi" && root.settingsModel.param_int_exists("WIFI_MODE")
                                        width: parent.width; height: visible ? Typography.rowHeight : 0
                                        Text { Layout.fillWidth: true; Layout.minimumWidth: 0; text: qsTr("Wi-Fi mode"); color: settings_form.primaryText; font.family: Typography.family; font.pixelSize: Typography.body; font.bold: true; elide: Text.ElideRight }
                                        Repeater {
                                            model: [{label:qsTr("Off"),value:0},{label:qsTr("Hotspot"),value:1},{label:qsTr("Client"),value:2}]
                                            AdvancedActionButton {
                                                objectName: "wifiMode" + modelData.value
                                                text: modelData.label; primary: root.wifiMode === modelData.value
                                                implicitWidth: Math.max(62,text.length*8+20)
                                                enabled: !root.preview && root.systemModel.is_alive && !root.settingsModel.ui_is_busy
                                                onClicked: root.settingsModel.try_set_param_int_async("WIFI_MODE",modelData.value,true)
                                            }
                                        }
                                    }
                                    Repeater {
                                        model: sectionCard.showContents ? root.idsForSection(sectionCard.section.id).filter(function(id){return (sectionCard.section.id !== "wifi" || id !== "WIFI_MODE") && sectionCard.codingIds.indexOf(id)<0}) : []
                                        delegate: AirSettingRow {
                                            width: parent.width; paramId: modelData; settingsModel: root.settingsModel
                                            connectionAlive: root.systemModel.is_alive
                                            stacked: sectionCard.section.id === "rcRadio"
                                            validateChange: root.validateUart
                                            onValidationFailed: function(reason) { _messageBoxInstance.set_text_and_show(reason) }
                                            onBackRequested: root.gainFocus()
                                        }
                                    }
                                    Column {
                                        width: parent.width
                                        visible: sectionCard.codingIds.length > 0
                                        height: visible ? implicitHeight : 0
                                        AdvancedActionButton {
                                            objectName: "airRfCodingToggle_" + sectionCard.section.id
                                            width: parent.width
                                            text: qsTr("Advanced RF coding")
                                            iconText: sectionCard.codingExpanded ? "\uf078" : "\uf054"
                                            onClicked: sectionCard.codingExpanded = !sectionCard.codingExpanded
                                        }
                                        Repeater {
                                            model: sectionCard.codingExpanded ? sectionCard.codingIds : []
                                            AirSettingRow {
                                                width: parent.width; paramId: modelData; settingsModel: root.settingsModel
                                                connectionAlive: root.systemModel.is_alive
                                                onBackRequested: root.gainFocus()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.columnSpan: sectionGrid.columns
                            visible: root.sectionsForCategory(root.activeCategory).length === 0
                            text: root.preview ? qsTr("No matching settings in this preview.") : !root.systemModel.is_alive ? (root.groundMode ? qsTr("Ground disconnected") : qsTr("Air disconnected")) : root.settingsModel.has_params_fetched ? qsTr("No settings reported for this category.") : qsTr("Loading settings...")
                            color: settings_form.secondaryText; font.family: Typography.family; font.pixelSize: Typography.body; wrapMode: Text.Wrap
                            padding: 16
                        }
                    }
                }
            }
        }
    }
}
