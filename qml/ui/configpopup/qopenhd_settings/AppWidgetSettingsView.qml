import "../MenuTypography.js" as MenuTypography
import "../MenuTypography.js" as Typography
import "WidgetCatalog.js" as Catalog
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."
import "../openhd_settings"

FocusScope {
    id: root
    objectName: "widgetGallery"
    readonly property bool wide: width >= 1000
    readonly property bool developer: settings_form.showDeveloperSettings === true
    property string category: "flight"
    property int revision: 0
    property int presetIndex: 0
    readonly property var availableWidgets: Catalog.widgets.filter(function(w){return !w.developer || root.developer})
    readonly property var categories: Catalog.categories.filter(function(c){return c.id!=="developer" || root.developer})
    readonly property var sections: Catalog.categories.filter(function(c){return root.category===c.id && root.matches(c.id).length>0})
    onDeveloperChanged: { if (!developer && category === "developer") category = "flight"; updatePreviewSession() }
    function enabledWidget(w) { return settings[w.key] === true }
    function countCategory(id) { return availableWidgets.filter(function(w){return w.category===id}).length }
    function matches(id) {
        return availableWidgets.filter(function(w){ return w.category===id })
    }
    function changeWidget(w,value) { settings[w.key]=value;revision++;presetIndex=0 }
    function applyPreset(index) {
        if(index===0)return
        var basic=["show_link_overview_widget","show_air_battery","show_horizon","show_flight_mode","show_home_distance","show_arrow","show_gps"]
        var flight=basic.concat(["altitude_ladder_show","speed_ladder_show","show_heading","show_vertical_speed_gauge_widget","show_flight_time","show_map"])
        Catalog.widgets.forEach(function(w){settings[w.key]=!w.developer && (index===3 || (index===1?basic:flight).indexOf(w.key)>=0)})
        settings.show_widgets=true;revision++;presetIndex=index
    }
    function gainFocus() { master.forceActiveFocus() }
    function updatePreviewSession() {
        if (typeof hudOverlayGrid.widgetGalleryPreviewActive !== "undefined")
            hudOverlayGrid.widgetGalleryPreviewActive = visible && developer
    }
    onVisibleChanged: updatePreviewSession()
    Component.onDestruction: if (typeof hudOverlayGrid.widgetGalleryPreviewActive !== "undefined") hudOverlayGrid.widgetGalleryPreviewActive = false
    Component.onCompleted: {
        updatePreviewSession()
        // Fail visibly during development if a catalog key drifts from settings.
        for(var i=0;i<Catalog.widgets.length;i++)
            if(typeof settings[Catalog.widgets[i].key]!=="boolean")console.warn("Unknown widget setting: "+Catalog.widgets[i].key)
    }

    RowLayout {
        anchors.fill: parent;anchors.margins:10;spacing:12
        Rectangle {
            objectName:"widgetCategoryRail"
            Layout.preferredWidth:root.wide?208:60;Layout.minimumWidth:root.wide?208:60;Layout.maximumWidth:root.wide?208:60;Layout.fillHeight:true
            color:settings_form.panelBackground;radius:10;border.color:settings_form.lineColor
            ColumnLayout {
                anchors.fill:parent;anchors.margins:root.wide?10:6;spacing:8
                Text { visible:root.wide;text:qsTr("Widget categories");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.sectionTitle;font.bold:true;Layout.bottomMargin:10 }
                ScrollView {
                    Layout.fillWidth:true;Layout.fillHeight:true;clip:true;contentWidth:availableWidth
                    ScrollBar.vertical.policy:ScrollBar.AlwaysOff
                    ScrollBar.horizontal.policy:ScrollBar.AlwaysOff
                    Column {
                        width:parent.width;spacing:5
                        Repeater {
                            model:root.categories
                            delegate: AdvancedActionButton {
                                id:categoryButton
                                objectName:"widgetCategory_"+modelData.id
                                width:parent.width;height:Typography.controlHeight
                                Accessible.name:modelData.title
                                onClicked:{root.category=modelData.id;gallery.contentY=0}
                                background:Rectangle { radius:7;color:root.category===modelData.id?settings_form.accentColor:categoryButton.hovered?settings_form.panelBackgroundRaised:"transparent";border.color:categoryButton.activeFocus?settings_form.accentColor:"transparent" }
                                contentItem:RowLayout {
                                    spacing:10
                                    Text {text:modelData.icon;color:root.category===modelData.id?"white":modelData.color;font.family:"Font Awesome 5 Free";font.pixelSize: Typography.sectionIcon;Layout.preferredWidth:25;Layout.fillWidth:!root.wide;horizontalAlignment:Text.AlignHCenter}
                                    Text {objectName:"widgetCategoryLabel_"+modelData.id;visible:root.wide;text:modelData.title;color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;Layout.fillWidth:true}
                                    Text {visible:root.wide;text:root.countCategory(modelData.id);color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper}
                                }
                            }
                        }
                    }
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth:true;Layout.fillHeight:true;spacing:10
            Flow {
                Layout.fillWidth:true;Layout.preferredHeight:childrenRect.height;spacing:12
                Row {
                    spacing:8;height:38
                    WidgetToggle {id:master;objectName:"widgetMasterSwitch";height:38;checked:settings.show_widgets;onToggled:settings.show_widgets=checked}
                    Text {anchors.verticalCenter:parent.verticalCenter;text:qsTr("Enable OSD widgets");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;font.bold:true}
                }
                Row {
                    spacing:8;height:38
                    Text {anchors.verticalCenter:parent.verticalCenter;text:qsTr("Preset");color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.body}
                    CompactLinkComboBox {objectName:"widgetPreset";width:154;height:38;model:[qsTr("Custom"),qsTr("Minimal"),qsTr("Flight"),qsTr("All widgets")];currentIndex:root.presetIndex;onActivated:root.applyPreset(currentIndex)}
                }
            }
            Flickable {
                id:gallery;objectName:"widgetGalleryScroll"
                Layout.fillWidth:true;Layout.fillHeight:true;clip:true
                contentWidth:width;contentHeight:sectionColumn.height
                boundsBehavior:Flickable.StopAtBounds
                ScrollBar.vertical:ScrollBar {policy:ScrollBar.AlwaysOff}
                Column {
                    id:sectionColumn;width:gallery.width;spacing:16
                    Repeater {
                        model:root.sections
                        delegate:Column {
                            id:section
                            readonly property var entries:root.matches(modelData.id)
                            readonly property var info:modelData
                            width:sectionColumn.width;spacing:8
                            Grid {
                                width:parent.width;columns:Math.max(1,Math.floor((width+10)/300));spacing:10
                                Repeater {
                                    model:section.entries
                                    delegate:Rectangle {
                                        id:card
                                        objectName:"widgetCard_"+modelData.key
                                        readonly property var entry:modelData
                                        width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;height:100
                                        radius:8;color:settings_form.panelBackgroundRaised;border.color:toggle.activeFocus?settings_form.accentColor:settings_form.lineColor;border.width:toggle.activeFocus?2:1
                                        RowLayout {
                                            anchors.fill:parent;anchors.margins:9;spacing:9
                                            WidgetPreview {Layout.preferredWidth:76;Layout.preferredHeight:76;widgetKey:card.entry.key}
                                            ColumnLayout {
                                                Layout.fillWidth:true;spacing:4
                                                Text {Layout.fillWidth:true;text:card.entry.title;color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;font.bold:true;wrapMode:Text.WordWrap}
                                                Text {Layout.fillWidth:true;text:card.entry.description;color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper;wrapMode:Text.WordWrap;visible:text!==card.entry.title}
                                            }
                                            WidgetToggle {id:toggle;objectName:"widgetToggle_"+card.entry.key;Layout.preferredWidth:42;Layout.preferredHeight:32;checked:settings[card.entry.key];onToggled:root.changeWidget(card.entry,checked);Accessible.name:card.entry.title}
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Text {visible:root.sections.length===0;width:parent.width;text:qsTr("No widgets in this category.");color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.body;wrapMode:Text.WordWrap;padding:12}
                }
            }
        }
    }
}
