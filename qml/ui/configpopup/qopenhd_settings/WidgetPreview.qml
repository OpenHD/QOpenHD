import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12

Rectangle {
    id: root
    property string widgetKey: ""
    readonly property var target: typeof hudOverlayGrid !== "undefined" && hudOverlayGrid.widgetPreviewTargets
                                 ? hudOverlayGrid.widgetPreviewTargets[widgetKey] || null : null
    readonly property rect bounds: target ? (target.widgetPreviewRect || Qt.rect(0,0,target.width,target.height)) : Qt.rect(0,0,1,1)
    readonly property real captureScale: Math.min(2,1024/Math.max(1,bounds.width,bounds.height))
    readonly property real aspect: Math.max(1,bounds.width)/Math.max(1,bounds.height)
    radius: 8
    color: "#071b29"
    border.color: "#274457"
    clip: true
    function refresh() { if (visible && target) texture.scheduleUpdate() }
    onBoundsChanged: Qt.callLater(refresh)
    onTargetChanged: Qt.callLater(refresh)
    onVisibleChanged: if (visible) Qt.callLater(refresh)
    Component.onCompleted: Qt.callLater(refresh)
    // Render the real HUD item, including disabled/hidden source items. The
    // preview neither reparents the item nor changes its visibility or settings.
    ShaderEffectSource {
        id: texture
        objectName: "actualWidgetTexture"
        anchors.centerIn: parent
        width: Math.min(parent.width-8,(parent.height-8)*root.aspect)
        height: width/root.aspect
        sourceItem: root.visible ? root.target : null
        sourceRect: root.bounds
        textureSize: Qt.size(Math.max(1,Math.ceil(root.bounds.width*root.captureScale)),Math.max(1,Math.ceil(root.bounds.height*root.captureScale)))
        hideSource: false
        live: false
        smooth: true
    }
    Text {
        anchors.fill:parent;anchors.margins:5
        visible:!root.target
        text:qsTr("Unavailable")
        color:"#aebdcb";font.family: MenuTypography.family;font.pixelSize: MenuTypography.helper
        horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;wrapMode:Text.WordWrap
    }
}
