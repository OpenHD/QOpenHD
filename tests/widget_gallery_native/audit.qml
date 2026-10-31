import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12
import "qrc:/ui" as UI
import "qrc:/ui/elements" as Elements
import "../../qml/ui/configpopup/qopenhd_settings" as Gallery
import "../../qml/ui/configpopup/qopenhd_settings/WidgetCatalog.js" as Catalog
Window {
 id:applicationWindow;width:1280;height:900;visible:true;color:"#091827"
 property bool globalDragLock:false
 property int detailPanelFontPixels:13
 property real globalScale:1
 Elements.AppSettings {id:settings;show_widgets:false;selected_map_provider:2}
 QtObject {id:quickPanel;property bool visible:false}
 QtObject {id:settings_panel;function openSettings(){}}
 QtObject {id:settings_form;property bool darkMode:true;property bool showDeveloperSettings:true;property color pageBackground:"#091827";property color panelBackground:"#102235";property color panelBackgroundRaised:"#15283b";property color lineColor:"#26394c";property color primaryText:"white";property color secondaryText:"#aebdcb";property color accentColor:"#278cff"}
 UI.HUDOverlayGrid {id:hudOverlayGrid;anchors.fill:parent;visible:false;widgetGalleryPreviewActive:true}
 property int categoryIndex:0
 property var entries:Catalog.widgets.filter(function(w){return w.category===Catalog.categories[categoryIndex].id})
 function selectCategory(index){categoryIndex=index}
 function audit(){return entries.map(function(w){var i=entries.indexOf(w),tile=tiles.itemAt(i);return w.key+":"+(tile&&tile.snapshot.length?"rendered":"EMPTY")}).join("\n")}
 Text {x:10;y:10;text:Catalog.categories[categoryIndex].title;color:"white";font.pixelSize:20}
 Grid {x:10;y:50;columns:4;spacing:10
  Repeater {id:tiles;model:applicationWindow.entries
   Rectangle {width:300;height:200;color:"#15283b";property alias snapshot:preview.snapshot
    Gallery.WidgetPreview {id:preview;x:74;y:8;width:152;height:152;widgetKey:modelData.key}
    Text {anchors.bottom:parent.bottom;anchors.horizontalCenter:parent.horizontalCenter;text:modelData.title;color:"white";font.pixelSize:12}
   }
  }
 }
}

