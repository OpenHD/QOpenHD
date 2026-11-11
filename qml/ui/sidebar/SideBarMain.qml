/******************************************************************************
 * OpenHD
 *
 * Licensed under the GNU General Public License (GPL) Version 3.
 *
 * This software is provided "as-is," without warranty of any kind, express or
 * implied, including but not limited to the warranties of merchantability,
 * fitness for a particular purpose, and non-infringement. For details, see the
 * full license in the LICENSE file provided with this source code.
 *
 * Non-Military Use Only:
 * This software and its associated components are explicitly intended for
 * civilian and non-military purposes. Use in any military or defense
 * applications is strictly prohibited unless explicitly and individually
 * licensed otherwise by the OpenHD Team.
 *
 * Contributors:
 * A full list of contributors can be found at the OpenHD GitHub repository:
 * https://github.com/OpenHD
 *
 * © OpenHD, All Rights Reserved.
 ******************************************************************************/

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import QtQuick.Shapes 1.0
import QtQuick.Controls.Material 2.0

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../elements"
import "../widgets"
import "../configpopup"


Item {
    id: sidebar
    width: Math.max(64, sidebar_icon_size_px() + 8)
    height: Math.max(24, sidebar_icon_size_px())
    visible: settings.show_sidebar || m_extra_is_visible

    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter


    // Qt applies the app/DPI scale before these logical viewport dimensions.
    // Keep the panel and its choices inside short and narrow phone windows.
    readonly property real viewportWidth: parent ? parent.width : 800
    readonly property real viewportHeight: parent ? parent.height : 480
    readonly property real popupLayoutWidth: stack_manager.width + secondaryUiWidth + choiceSelector.width
    readonly property real fitHeightScale: (viewportHeight - 28) / secondaryUiHeight
    readonly property real automaticScale: 0.5 * Math.max(0.01, Math.min(1,
        (viewportWidth - 12) / popupLayoutWidth, fitHeightScale))
    readonly property real sidebarScale: Math.max(0.005, Math.min(automaticScale * bw_current_scale,
        (viewportWidth - 12) / (stack_manager.anchors.leftMargin + popupLayoutWidth), fitHeightScale))
    scale: m_extra_is_visible ? sidebarScale : automaticScale * 2
    transformOrigin: Item.Left
    property int secondaryUiWidth: 556
    readonly property real secondaryUiHeight: stack_manager_content.implicitHeight + 20
    readonly property color secondaryUiColor: bw_current_background_color
    readonly property real secondaryUiOpacity: bw_current_opacity

    readonly property string bw_verbose_name: qsTr("Sidebar")
    readonly property int detailPanelFontPixels: 13
    readonly property color defaultBackgroundColor: "#121e2a"
    readonly property real defaultBackgroundOpacity: 0.94
    readonly property color defaultTextColor: "#edf6ff"
    readonly property color defaultHighlightColor: "#71d4ff"
    readonly property color defaultControlColor: "#285879"
    readonly property real defaultPopupScale: 1.2
    readonly property real bw_current_scale: Math.max(0.5, Math.min(3, settings.sidebar_popup_scale))
    property real bw_current_opacity: settings.value("sidebar_popup_opacity", defaultBackgroundOpacity)
    property color bw_current_background_color: settings.value("sidebar_popup_bg_color", defaultBackgroundColor.toString())
    property color popupTextColor: settings.value("sidebar_popup_text_color", defaultTextColor.toString())
    property color popupHighlightColor: settings.value("sidebar_popup_highlight_color", defaultHighlightColor.toString())
    property color popupControlColor: settings.value("sidebar_popup_control_color", defaultControlColor.toString())
    readonly property bool customTextColor: !Qt.colorEqual(popupTextColor, defaultTextColor)
    readonly property bool customHighlightColor: !Qt.colorEqual(popupHighlightColor, defaultHighlightColor)
    readonly property bool customControlColor: !Qt.colorEqual(popupControlColor, defaultControlColor)

    function bw_set_current_scale(value) {
        settings.sidebar_popup_scale = value
    }

    function bw_set_current_opacity(value) {
        bw_current_opacity = value
        settings.setValue("sidebar_popup_opacity", value)
        settings.sync()
    }

    function saveColor(key, color, defaultColor) {
        const value = color.toString()
        if (value !== settings.value(key, defaultColor.toString())) {
            settings.setValue(key, value)
            settings.sync()
        }
    }

    onBw_current_background_colorChanged: saveColor("sidebar_popup_bg_color", bw_current_background_color, defaultBackgroundColor)
    onPopupTextColorChanged: saveColor("sidebar_popup_text_color", popupTextColor, defaultTextColor)
    onPopupHighlightColorChanged: saveColor("sidebar_popup_highlight_color", popupHighlightColor, defaultHighlightColor)
    onPopupControlColorChanged: saveColor("sidebar_popup_control_color", popupControlColor, defaultControlColor)

    function textColor(defaultColor) {
        return customTextColor ? popupTextColor : defaultColor
    }

    function highlightColor(defaultColor) {
        return customHighlightColor ? popupHighlightColor : defaultColor
    }

    function controlColor(defaultColor, brightness) {
        return customControlColor ? Qt.lighter(popupControlColor, brightness) : defaultColor
    }

    function highlightFill(defaultColor, baseColor, brightness) {
        return customHighlightColor
            ? Qt.tint(controlColor(baseColor, brightness), Qt.rgba(popupHighlightColor.r, popupHighlightColor.g, popupHighlightColor.b, 0.28))
            : controlColor(defaultColor, brightness)
    }

    function openCustomization() {
        customizePopup.open()
    }

    function containsSidebarPoint(item, point) {
        if (!m_extra_is_visible)
            return uiButton.visible && uiButton.contains(uiButton.mapFromItem(item, point.x, point.y))
        return popupBackground.contains(popupBackground.mapFromItem(item, point.x, point.y))
            || (choiceSelector.visible && choiceSelector.contains(choiceSelector.mapFromItem(item, point.x, point.y)))
    }

    // Set to true if the sidebar is active (and some HUD elements shall be disabled)
    property bool m_is_active : false

    property bool m_extra_is_visible: false
    onM_extra_is_visibleChanged: if (!m_extra_is_visible) customizePopup.close()
    property int m_stack_index: -1;
    property bool m_ui_button_long_press_handled: false
    readonly property real m_sidebar_icon_scale: clamp_sidebar_icon_scale(settings.sidebar_show_icon_scale)

    function clamp_sidebar_icon_scale(value){
        if(value < 0.7){
            return 0.7;
        }
        if(value > 2.5){
            return 2.5;
        }
        return value;
    }

    function sidebar_icon_size_px(){
        return Math.round(32 * m_sidebar_icon_scale);
    }


    // Gives (keyboard / joystick) control to this element
    function open_and_take_control(enable_joy){
        m_extra_is_visible=true;
        m_stack_index=0;
        m_is_active = true
        stack_manager.visible=true;
        if(enable_joy){
            hudOverlayGrid.focus=false;
            handover_joystick_control_to_button(m_stack_index);
        }
    }

    // This is called whenever the user clicks on the 'WBLIink' widget
    function open_category(category_index){
        open_and_take_control(false);
        m_stack_index=category_index;
    }

    function open_link_category(){
        open_category(1)
    }

    // This is called when the user clicks on the configure button of the CAM1 / CAM2 widget
    function open_video_stream_category(is_primary){
        if(is_primary){
            open_category(2)
        }
    }

    // CLoses the sidebar and gives focus back to HUD overlay grid
    function close(){
        m_stack_index=-1;
        m_is_active=false;
        m_extra_is_visible=false;
        stack_manager.visible=false;
        choiceSelector.discard_and_close();
        hudOverlayGrid.forceActiveFocus();
    }

    function regain_control_on_sidebar_stack(){
        choiceSelector.discard_and_close();
        handover_joystick_control_to_button(m_stack_index);
    }

    function update_stack_index(index_stack_new){
        choiceSelector.discard_and_close();
        if(index_stack_new<0){
            // close the sidebar
            close();
        }else{
            m_stack_index=index_stack_new;
            handover_joystick_control_to_button(m_stack_index);
        }

    }

    // Called when the sidebar is opened and the user clicked somewhere on the screen where there is no sidebar
    function notify_sidebar_user_clicked_outside(){
        if(stack_manager.visible){
            console.log("Outside area clicked, closing sidebar");
            close();
        }
    }

    function handover_joystick_control_to_button(stack_index){
        if(stack_index==0){
            b1.takeover_control();
            ensure_stack_item_visible(b1);
        }else if(stack_index==1){
            b2.takeover_control();
            ensure_stack_item_visible(b2);
        }else if(stack_index==2){
            b3.takeover_control();
            ensure_stack_item_visible(b3);
        }else if(stack_index==3){
            b4.takeover_control();
            ensure_stack_item_visible(b4);
        }else if(stack_index==4){
            b5.takeover_control();
            ensure_stack_item_visible(b5);
        }else if(stack_index==5){
            b7.takeover_control();
            ensure_stack_item_visible(b7);
        }else if(stack_index==6){
            b8.takeover_control();
            ensure_stack_item_visible(b8);
        }
    }

    function handover_joystick_control_to_panel(stack_index){
        if(stack_index==0){
            panel1.takeover_control();
        }else if(stack_index==1){
            panel2.takeover_control();
        }else if(stack_index==2){
            panel3.takeover_control();
        }else if(stack_index==3){
            panel4.takeover_control();
        }else if(stack_index==4){
            panel5.takeover_control();
        }else if(stack_index==5){
            panel7.takeover_control();
        }else if(stack_index==6){
            panel8.takeover_control();
        }
    }

    function ensure_stack_item_visible(item){
        if(!item || !stack_manager.visible){
            return;
        }
        const flickable = stack_manager.contentItem;
        if(!flickable){
            return;
        }
        const item_pos = item.mapToItem(flickable.contentItem, 0, 0);
        const item_top = item_pos.y;
        const item_bottom = item_top + item.height;
        const view_top = flickable.contentY;
        const view_bottom = view_top + stack_manager.height;
        if(item_top < view_top){
            flickable.contentY = item_top;
        }else if(item_bottom > view_bottom){
            flickable.contentY = item_bottom - stack_manager.height;
        }
    }


    // Item that opens up the sidebar
    AbstractButton {
        id: uiButton
        objectName: "sidebarLauncher"
        width: sidebar_icon_size_px()
        height: sidebar_icon_size_px()
        anchors.verticalCenter: parent.verticalCenter
        visible: m_stack_index < 0
        padding: 0
        background: null
        activeFocusOnTab: true
        Accessible.name: qsTr("Open sidebar")
        contentItem: Text {
            text: "\uf054"
            font.family: "Font Awesome 5 Free"
            font.pixelSize: Math.round(uiButton.height * 0.5)
            color: uiButton.activeFocus ? "#f2f6fb" : "grey"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        onPressed: m_ui_button_long_press_handled = false
        onClicked: if (!m_ui_button_long_press_handled) open_and_take_control()
        onPressAndHold: {
            m_ui_button_long_press_handled = true
            sidebarIconResizePopup.open()
        }
    }

    Popup {
        id: sidebarIconResizePopup
        objectName: "sidebarIconResizePopup"
        parent: Overlay.overlay
        width: Math.min(260, parent.width - 24)
        height: resizePopupColumn.implicitHeight + 16
        modal: false
        focus: true
        closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)

        background: Rectangle {
            color: "#000000"
            opacity: 0.92
            radius: 8
            border.width: 1
            border.color: "#335a73"
        }

        contentItem: Column {
            id: resizePopupColumn
            spacing: 8
            width: sidebarIconResizePopup.width - 16
            x: 8
            y: 8

            Text {
                width: parent.width
                text: qsTr("Sidebar Icon Size")
                color: "white"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                text: qsTr("Long press icon to resize")
                color: "#c7d4dd"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
            }

            RowLayout {
                width: parent.width
                spacing: 8

                AdvancedActionButton {
                    Layout.preferredWidth: 34
                    text: "-"
                    onClicked: {
                        settings.sidebar_show_icon_scale = clamp_sidebar_icon_scale(m_sidebar_icon_scale - 0.1);
                    }
                }

                Slider {
                    id: sidebarIconSizeSlider
                    Layout.fillWidth: true
                    from: 0.7
                    to: 2.5
                    stepSize: 0.1
                    value: m_sidebar_icon_scale
                    onMoved: {
                        settings.sidebar_show_icon_scale = value;
                    }
                }

                AdvancedActionButton {
                    Layout.preferredWidth: 34
                    text: "+"
                    onClicked: {
                        settings.sidebar_show_icon_scale = clamp_sidebar_icon_scale(m_sidebar_icon_scale + 0.1);
                    }
                }
            }

            RowLayout {
                width: parent.width
                spacing: 8

                AdvancedActionButton {
                    text: qsTr("Reset")
                    onClicked: {
                        settings.sidebar_show_icon_scale = 1.0;
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                AdvancedActionButton {
                    primary: true
                    text: qsTr("Done")
                    onClicked: {
                        sidebarIconResizePopup.close();
                    }
                }
            }
        }
    }

    Rectangle {
        id: popupBackground
        anchors.left: stack_manager.left
        anchors.top: stack_manager.top
        width: stack_manager.width + secondaryUiWidth
        height: secondaryUiHeight
        visible: m_extra_is_visible
        radius: 16
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.colorEqual(secondaryUiColor, defaultBackgroundColor)
                    ? "#1c2d3d" : secondaryUiColor
            }
            GradientStop { position: 1; color: secondaryUiColor }
        }
        opacity: secondaryUiOpacity
        border.color: "#40566a"
        border.width: 1
        Rectangle {
            x: stack_manager.width
            width: 1
            y: 12
            height: parent.height - 24
            color: "#40566a"
        }
    }

    Popup {
        id: customizePopup
        objectName: "sidebarCustomizePopup"
        parent: Overlay.overlay
        padding: 0
        modal: true
        dim: false
        focus: true
        closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)

        readonly property real layoutWidth: sidebarColorPicker.visible ? sidebarColorPicker.width : 300
        readonly property real layoutHeight: sidebarColorPicker.visible ? sidebarColorPicker.height : customizationLayout.implicitHeight + 24
        readonly property real fitScale: parent ? Math.max(0.01, Math.min(1,
            (parent.width - 16) / layoutWidth, (parent.height - 16) / layoutHeight)) : 1
        width: layoutWidth * fitScale
        height: layoutHeight * fitScale

        onAboutToHide: {
            if (sidebarColorPicker.visible) {
                sidebarColorPicker.cancelled()
                sidebarColorPicker.visible = false
            }
        }

        background: Rectangle { color: "black"; opacity: 0.8 }

        contentItem: Item {
            Item {
                width: customizePopup.layoutWidth
                height: customizePopup.layoutHeight
                scale: customizePopup.fitScale
                transformOrigin: Item.TopLeft

                ColumnLayout {
                    id: customizationLayout
                    x: 12
                    y: 12
                    width: parent.width - 24
                    visible: !sidebarColorPicker.visible

                    BaseWidgetDefaultUiControlElements {
                        Layout.fillWidth: true
                        show_size: false
                        show_background_color: true
                        background_color_target: sidebar
                        background_color_picker: sidebarColorPicker
                        additional_colors: [
                            { label: qsTr("Text Color"), propertyName: "popupTextColor", objectName: "sidebarTextColorSwatch" },
                            { label: qsTr("Highlight Color"), propertyName: "popupHighlightColor", objectName: "sidebarHighlightColorSwatch" },
                            { label: qsTr("Control Color"), propertyName: "popupControlColor", objectName: "sidebarControlColorSwatch" }
                        ]
                    }

                    SidebarSizeControls { Layout.fillWidth: true }

                    RowLayout {
                        Layout.fillWidth: true
                        AdvancedActionButton {
                            objectName: "sidebarCustomizeReset"
                            text: qsTr("Reset")
                            onClicked: {
                                bw_set_current_scale(defaultPopupScale)
                                settings.sidebar_show_icon_scale = 1.0
                                bw_set_current_opacity(defaultBackgroundOpacity)
                                bw_current_background_color = defaultBackgroundColor
                                popupTextColor = defaultTextColor
                                popupHighlightColor = defaultHighlightColor
                                popupControlColor = defaultControlColor
                            }
                        }
                        Item { Layout.fillWidth: true }
                        AdvancedActionButton {
                            primary: true
                            text: qsTr("Done")
                            onClicked: customizePopup.close()
                        }
                    }
                }

                ColorPicker {
                    id: sidebarColorPicker
                    objectName: "sidebarColorPicker"
                    width: 380
                    height: 264
                    currentColorType: ColorPicker.ColorType.CustomColor
                    showAlpha: false
                }
            }
        }
    }

    ScrollView{
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        id: stack_manager
        objectName: "sidebarRail"
        visible: false
        width: 68
        padding: 0
        contentWidth: width
        height: secondaryUiHeight
        clip: true
        focus: false
        activeFocusOnTab: false
        Keys.onPressed: (event)=> {
            if(event.key === Qt.Key_Left){
                handover_joystick_control_to_button(m_stack_index);
                event.accepted = true;
            }else if(event.key === Qt.Key_Right){
                handover_joystick_control_to_panel(m_stack_index);
                event.accepted = true;
            }else if(event.key === Qt.Key_Up || event.key === Qt.Key_Down){
                handover_joystick_control_to_button(m_stack_index);
                event.accepted = true;
            }
        }
        ScrollBar.vertical: ScrollBar {
            id: stack_manager_bar
            policy: ScrollBar.AlwaysOff
        }
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        Column{
            id: stack_manager_content
            width: parent.width
            y: 10
            spacing: 4
            SidebarStackButton{
                id: b0
                override_text: "\uf053"
                override_tag: "back"
                override_index: -1
            }
            SidebarStackButton{
                id: b1
                override_text: "\uf002"
                override_tag: "scan"
                override_index: 0
            }
            SidebarStackButton{
                id: b2
                override_text: "\uf1eb"
                override_tag: "link"
                override_index: 1
            }
            SidebarStackButton{
                id: b3
                override_text: "\uf03d"
                override_tag: "video"
                override_index: 2
            }
            SidebarStackButton{
                id: b4
                override_text:  "\uf030"
                override_tag: "camera"
                override_index: 3
            }
            SidebarStackButton{
                id: b5
                override_text: "\uf0c7"
                override_tag: "recording"
                override_index: 4
            }
            SidebarStackButton{
                id: b7
                override_text: "\uf26c"
                override_tag: "misc"
                override_index: 5
            }
            SidebarStackButton{
                id: b8
                override_text: "\uf55b"
                override_tag: "status"
                override_index: 6
            }
        }
    }


    Item{
        id: panels_item
        objectName: "sidebarPanels"
        width: secondaryUiWidth
        height: secondaryUiHeight
        anchors.left: stack_manager.right
        anchors.top: stack_manager.top

        Binding {
            target: panels_item.Material
            property: "foreground"
            value: sidebar.popupTextColor
            when: sidebar.customTextColor
        }
        Binding {
            target: panels_item.Material
            property: "accent"
            value: sidebar.popupHighlightColor
            when: sidebar.customHighlightColor
        }
        Binding {
            target: panels_item.Material
            property: "background"
            value: sidebar.popupControlColor
            when: sidebar.customControlColor
        }

        Panel8FindAirUnit{
            id: panel1
            visible: m_stack_index==0;
        }
        Panel1Link{
            id: panel2
            visible: m_stack_index==1;
        }
        Panel2Video{
            id: panel3
            visible: m_stack_index==2;
        }

        Panel3Camera{
            id: panel4
            visible: m_stack_index==3;
        }

        Panel4Recording{
            id: panel5
            visible: m_stack_index==4;
        }

        Panel6Misc{
            id: panel7
            visible: m_stack_index==5;
        }
        Panel7Status{
            id: panel8
            visible: m_stack_index==6;
        }
    }

    ChoiceSelector{
        id: choiceSelector
        anchors.left: panels_item.right
        anchors.top: panels_item.top
        anchors.topMargin: choiceSelector.popupTop
    }

}
