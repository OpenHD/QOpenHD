import "../MenuTypography.js" as MenuTypography
import "../MenuTypography.js" as Typography
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12
import ".."
import "../openhd_settings"

FocusScope {
    id: root
    objectName:"osdStylePage"
    Material.theme:settings_form.darkMode?Material.Dark:Material.Light
    Material.accent:settings_form.accentColor
    Material.foreground:settings_form.primaryText
    readonly property bool wide:width>=1050
    readonly property real settingsWidth:wide?Math.floor((scroll.width-12)*0.57):scroll.width
    readonly property real previewWidth:wide?scroll.width-settingsWidth-12:scroll.width
    readonly property var source:typeof hudOverlayGrid!=="undefined" ? hudOverlayGrid.osdStylePreviewItem || null : null
    readonly property var keys:["smoothing","color_shape","color_glow","color_text","color_warn","color_caution","font_text","osd_opacity","osd_top_bar_background_color","osd_top_bar_text_color","osd_top_bar_font","osd_bottom_bar_background_color","osd_bottom_bar_text_color","osd_bottom_bar_font"]
    readonly property real sourceAspect:source && source.height>0?source.width/source.height:16/9
    readonly property var fontFaces:["Sans Serif", "Acme", "Aldrich", "Anonymous Pro", "Archivo", "Archivo Black", "Armata", "Bangers", "Black Ops One", "Bungee", "Carbon", "Chicle", "Digital Counter 7", "Expletus Sans", "Fjalla One", "Fredoka One", "Geostar Fill", "Iceberg", "Iceland", "Jura", "Keania One", "Larabiefont", "LED Display7", "Luckiest Guy", "Merysha", "Nixie One", "Orbitron", "Oxygen", "Passion One", "Quantico", "Quicksand", "Rammetto One", "Rationale", "Righteous", "Roboto Mono", "Russo One", "Share Tech", "Share Tech Mono", "Sigmar One", "Slackey", "Subway Ticker", "Ubuntu Mono", "Visitor TT1 BRK", "Zolan Mono BTN"]
    readonly property var presets:[
        {title:qsTr("Default"),shape:"#ffffff",text:"#ffffff",glow:"#000000",warn:"#ff0000",caution:"#ffff00",font:"Sans Serif"},
        {title:qsTr("Matrix"),shape:"#14ff00",text:"#05ff00",glow:"#000000",warn:"#ff0000",caution:"#ffff00",font:"Quicksand"},
        {title:qsTr("Trainwreck"),shape:"#ec71bf",text:"#ffff00",glow:"#000000",warn:"#ff0000",caution:"#ffff00",font:"Quicksand"},
        {title:qsTr("High contrast"),shape:"#ffff00",text:"#ffff00",glow:"#000000",warn:"#ff4035",caution:"#ff9800",font:"Sans Serif"}
    ]
    readonly property string previewStyleKey:keys.map(function(k){return String(settings[k])}).join("|")
    function requestPreview(){if(visible)previewRefresh.restart()}
    onPreviewStyleKeyChanged:Qt.callLater(requestPreview)
    onSourceChanged:Qt.callLater(requestPreview)
    Timer {id:previewRefresh;objectName:"stylePreviewRefresh";interval:60;repeat:false;onTriggered:if(root.visible&&root.source)osdTexture.scheduleUpdate()}
    readonly property color glowColor:settings.color_glow
    readonly property int selectedPreset:{
        for(var i=0;i<presets.length;i++){
            var p=presets[i]
            if(Qt.colorEqual(settings.color_shape,p.shape)&&Qt.colorEqual(settings.color_text,p.text)&&Qt.colorEqual(settings.color_glow,p.glow)&&Qt.colorEqual(settings.color_warn,p.warn)&&Qt.colorEqual(settings.color_caution,p.caution)&&settings.font_text===p.font)return i
        }
        return -1
    }
    function setStyle(key,value){settings[key]=value}
    function usePreset(index){
        var p=presets[index]
        settings.color_shape=p.shape;settings.color_text=p.text;settings.color_glow=p.glow
        settings.color_warn=p.warn;settings.color_caution=p.caution;settings.font_text=p.font
        ;["top","bottom"].forEach(function(bar){
            settings["osd_"+bar+"_bar_background_color"]=index===0?"":p.glow
            settings["osd_"+bar+"_bar_text_color"]=index===0?"":p.text
            settings["osd_"+bar+"_bar_font"]=index===0?"":p.font
        })
    }
    function resetDefaults(){usePreset(0);settings.osd_opacity=1.0;settings.smoothing=33}
    function gainFocus(){resetButton.forceActiveFocus()}
    Component.onCompleted:requestPreview()
    onVisibleChanged:{if(visible)requestPreview();else previewRefresh.stop()}

    ColumnLayout {
        anchors.fill:parent;anchors.margins:10;spacing:10
        RowLayout {
            Layout.fillWidth:true;spacing:12
            Text {text:"\uf53f";color:settings_form.accentColor;font.family:"Font Awesome 5 Free";font.pixelSize: Typography.sectionIcon}
            ColumnLayout {
                Layout.fillWidth:true;spacing:2
                Text {text:qsTr("OSD Style");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.sectionTitle;font.bold:true}

            }
        }
        Flickable {
            id:scroll;objectName:"stylePageScroll"
            Layout.fillWidth:true;Layout.fillHeight:true;clip:true
            contentWidth:width;contentHeight:panels.height
            boundsBehavior:Flickable.StopAtBounds
            Item {
                id:panels;width:scroll.width
                height:root.wide?Math.max(leftPanels.height,rightPanels.height):leftPanels.height+rightPanels.height+12
                Column {
                    id:leftPanels
                    width:root.settingsWidth;y:root.wide?0:rightPanels.height+12;spacing:12
                    Rectangle {
                        width:parent.width;height:presetColumn.implicitHeight+28
                        color:settings_form.panelBackground;radius:11;border.color:settings_form.lineColor
                        ColumnLayout {
                            id:presetColumn;width:parent.width-28;anchors.centerIn:parent;spacing:12
                            RowLayout {
                                Layout.fillWidth:true
                                Text {Layout.fillWidth:true;text:qsTr("Style presets");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.sectionTitle;font.bold:true}
                                AdvancedActionButton {id:resetButton;objectName:"styleReset";text:qsTr("Reset to default");iconText:"\uf2ea";onClicked:root.resetDefaults()}
                            }
                            Grid {
                                Layout.fillWidth:true;columns:width>=560?4:2;spacing:10
                                Repeater {
                                    model:root.presets
                                    delegate:Button {
                                        id:presetTile;objectName:"stylePreset_"+index
                                        width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;height:110
                                        Accessible.name:modelData.title
                                        onClicked:root.usePreset(index)
                                        background:Rectangle {radius:8;color:root.selectedPreset===index?"#143c61":settings_form.panelBackgroundRaised;border.color:root.selectedPreset===index||presetTile.activeFocus?settings_form.accentColor:settings_form.lineColor;border.width:root.selectedPreset===index||presetTile.activeFocus?2:1}
                                        contentItem:Column {
                                            spacing:9
                                            Rectangle {
                                                width:parent.width;height:49;radius:5;color:"#06141f";border.color:settings_form.lineColor
                                                Text {anchors.centerIn:parent;text:"OSD";font.family:modelData.font;font.pixelSize:23;color:modelData.text;font.bold:true;style:Text.Outline;styleColor:modelData.glow}
                                                Rectangle {anchors.left:parent.left;anchors.bottom:parent.bottom;anchors.margins:5;width:22;height:3;radius:1;color:modelData.shape}
                                            }
                                            Text {width:parent.width;text:modelData.title;color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;font.bold:true;horizontalAlignment:Text.AlignHCenter;wrapMode:Text.WordWrap}
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Rectangle {
                        width:parent.width;height:coloursColumn.implicitHeight+28
                        color:settings_form.panelBackground;radius:11;border.color:settings_form.lineColor
                        ColumnLayout {
                            id:coloursColumn;width:parent.width-28;anchors.centerIn:parent;spacing:12
                            Text {text:qsTr("Colours");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.sectionTitle;font.bold:true}
                            Grid {
                                Layout.fillWidth:true;columns:width>=600?3:width>=400?2:1;spacing:10
                                Repeater {
                                    model:[{key:"color_shape",label:qsTr("Shape colour"),hint:qsTr("Lines, instruments and icons")},{key:"color_glow",label:qsTr("Glow colour"),hint:qsTr("Outlines and contrast")},{key:"color_text",label:qsTr("Text colour"),hint:qsTr("Text and values")},{key:"color_caution",label:qsTr("Caution colour"),hint:qsTr("Caution indicators")},{key:"color_warn",label:qsTr("Warning colour"),hint:qsTr("Warning indicators")}]
                                    delegate:StyleColorControl {
                                        objectName:"styleColour_"+modelData.key
                                        width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;height:112
                                        label:modelData.label;hint:modelData.hint;selectedColor:settings[modelData.key]
                                        onColorSelected:function(value){root.setStyle(modelData.key,value)}
                                    }
                                }
                            }
                        }
                    }
                    Rectangle {
                        width:parent.width;height:typeColumn.implicitHeight+28
                        color:settings_form.panelBackground;radius:11;border.color:settings_form.lineColor
                        ColumnLayout {
                            id:typeColumn;width:parent.width-28;anchors.centerIn:parent;spacing:10
                            Text {text:qsTr("Typography");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.sectionTitle;font.bold:true}
                            Text {text:qsTr("Text font");color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.helper}
                            CompactLinkComboBox {
                                objectName:"styleFont";Layout.fillWidth:true;Layout.preferredHeight: Typography.controlHeight
                                model:root.fontFaces;currentIndex:Math.max(0,root.fontFaces.indexOf(settings.font_text))
                                onActivated:root.setStyle("font_text",root.fontFaces[currentIndex])
                            }
                            Text {Layout.fillWidth:true;text:"OpenHD 0123456789";color:settings.color_text;font.family:settings.font_text;font.pixelSize:24;wrapMode:Text.WordWrap;style:Text.Outline;styleColor:settings.color_glow}
                        }
                    }
                }
                Column {
                    id:rightPanels
                    width:root.previewWidth;x:root.wide?leftPanels.width+12:0;spacing:12
                    Rectangle {
                        width:parent.width;height:previewColumn.implicitHeight+28
                        color:settings_form.panelBackground;radius:11;border.color:settings_form.lineColor
                        ColumnLayout {
                            id:previewColumn;width:parent.width-28;anchors.centerIn:parent;spacing:10
                            RowLayout {
                                Text {text:"\uf06e";color:settings_form.accentColor;font.family:"Font Awesome 5 Free";font.pixelSize: Typography.sectionIcon}
                                Text {text:qsTr("OSD preview");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.sectionTitle;font.bold:true}
                            }
                            Rectangle {
                                id:preview;objectName:"liveOsdStylePreview";Layout.fillWidth:true;Layout.preferredHeight:(root.previewWidth-28)/root.sourceAspect
                                color:"#102332";radius:8;clip:true
                                Image {objectName:"stylePreviewBackground";anchors.fill:parent;scale:1.06;source:"../../../resources/osd-style-alpine.png";fillMode:Image.PreserveAspectCrop;asynchronous:true}
                                Rectangle {anchors.fill:parent;color:"#22071725"}
                                ShaderEffectSource {
                                    id:osdTexture;objectName:"styleOsdTexture"
                                    anchors.fill:parent
                                    sourceItem:root.visible?root.source:null
                                    sourceRect:root.source?Qt.rect(0,0,root.source.width,root.source.height):Qt.rect(0,0,1,1)
                                    textureSize:Qt.size(Math.max(1,Math.ceil(width*2)),Math.max(1,Math.ceil(height*2)))
                                    opacity:settings.osd_opacity
                                    hideSource:false;live:false;smooth:true
                                }
                                Text {visible:!root.source;anchors.centerIn:parent;text:qsTr("OSD not available");color:"white";font.family:Typography.family;font.pixelSize:Typography.body}
                            }
                        }
                    }
                    Rectangle {
                        width:parent.width;height:effectsColumn.implicitHeight+28
                        color:settings_form.panelBackground;radius:11;border.color:settings_form.lineColor
                        ColumnLayout {
                            id:effectsColumn;width:parent.width-28;anchors.centerIn:parent;spacing:10
                            Text {text:qsTr("Effects & appearance");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.sectionTitle;font.bold:true}
                            RowLayout {
                                Layout.fillWidth:true
                                Text {Layout.fillWidth:true;text:qsTr("Animation smoothing");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body}
                                Text {text:settings.smoothing+" ms";color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.body}
                            }
                            Slider {objectName:"styleAnimationSmoothing";Layout.fillWidth:true;from:0;to:1000;stepSize:25;value:settings.smoothing;onMoved:root.setStyle("smoothing",Math.round(value))}

                            RowLayout {
                                Layout.fillWidth:true
                                Text {Layout.fillWidth:true;text:qsTr("Glow opacity");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body}
                                Text {text:Math.round(glowSlider.value*100)+"%";color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.body}
                            }
                            Slider {id:glowSlider;objectName:"styleGlowOpacity";Layout.fillWidth:true;from:0;to:1;stepSize:0.01;value:root.glowColor.a;onMoved:root.setStyle("color_glow",Qt.rgba(root.glowColor.r,root.glowColor.g,root.glowColor.b,value).toString())}
                            RowLayout {
                                Layout.fillWidth:true
                                Text {Layout.fillWidth:true;text:qsTr("OSD opacity");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body}
                                Text {text:Math.round(opacitySlider.value*100)+"%";color:settings_form.secondaryText;font.family:Typography.family;font.pixelSize:Typography.body}
                            }
                            Slider {id:opacitySlider;objectName:"styleOsdOpacity";Layout.fillWidth:true;from:0.1;to:1;stepSize:0.01;value:settings.osd_opacity;onMoved:root.setStyle("osd_opacity",value)}
                        }
                    }
                    Rectangle {
                        width:parent.width;height:barsColumn.implicitHeight+28
                        color:settings_form.panelBackground;radius:11;border.color:settings_form.lineColor
                        ColumnLayout {
                            id:barsColumn;width:parent.width-28;anchors.centerIn:parent;spacing:12
                            Text {text:qsTr("Top & bottom bars");color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.sectionTitle;font.bold:true}
                            Repeater {
                                model:[{bar:"top",label:qsTr("Top bar")},{bar:"bottom",label:qsTr("Bottom bar")}]
                                delegate:ColumnLayout {
                                    id:barControls
                                    readonly property string bar:modelData.bar
                                    Layout.fillWidth:true;spacing:8
                                    Text {text:modelData.label;color:settings_form.primaryText;font.family:Typography.family;font.pixelSize:Typography.body;font.bold:true}
                                    Grid {
                                        Layout.fillWidth:true;columns:width>=400?2:1;spacing:10
                                        StyleColorControl {
                                            objectName:"styleBarBackground_"+barControls.bar
                                            width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;height:112
                                            label:qsTr("Background");hint:qsTr("Bar background colour")
                                            selectedColor:settings["osd_"+barControls.bar+"_bar_background_color"] || settings.link_overview_widget_bg_color
                                            onColorSelected:function(value){root.setStyle("osd_"+barControls.bar+"_bar_background_color",value)}
                                        }
                                        StyleColorControl {
                                            objectName:"styleBarText_"+barControls.bar
                                            width:(parent.width-(parent.columns-1)*parent.spacing)/parent.columns;height:112
                                            label:qsTr("Text & icons");hint:qsTr("Bar foreground colour")
                                            selectedColor:settings["osd_"+barControls.bar+"_bar_text_color"] || settings.color_text
                                            onColorSelected:function(value){root.setStyle("osd_"+barControls.bar+"_bar_text_color",value)}
                                        }
                                    }
                                    CompactLinkComboBox {
                                        objectName:"styleBarFont_"+barControls.bar
                                        Layout.fillWidth:true;Layout.preferredHeight: Typography.controlHeight
                                        model:[qsTr("Default")].concat(root.fontFaces)
                                        currentIndex:settings["osd_"+barControls.bar+"_bar_font"]?root.fontFaces.indexOf(settings["osd_"+barControls.bar+"_bar_font"])+1:0
                                        onActivated:root.setStyle("osd_"+barControls.bar+"_bar_font",currentIndex===0?"":root.fontFaces[currentIndex-1])
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

    }
}
