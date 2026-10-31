import "../MenuTypography.js" as MenuTypography
import QtQuick 2.12

Rectangle {
    id: root
    property string widgetKey: ""
    property int revision: 0
    property string snapshot: ""
    property bool capturePending: false
    property bool refreshAgain: false
    property int captureGeneration: 0
    readonly property var target: typeof hudOverlayGrid !== "undefined" && hudOverlayGrid.widgetPreviewTargets
                                 ? hudOverlayGrid.widgetPreviewTargets[widgetKey] || null : null
    readonly property rect bounds: target ? (target.widgetPreviewRect || Qt.rect(0,0,target.width,target.height)) : Qt.rect(0,0,1,1)
    readonly property real captureScale: Math.min(2,1024/Math.max(1,bounds.width,bounds.height))
    readonly property real aspect: Math.max(1,bounds.width)/Math.max(1,bounds.height)
    radius: 8
    color: "#071b29"
    border.color: "#274457"
    clip: true
    function refresh() {
        if (!visible || !target) return
        if (capturePending) { refreshAgain = true; return }
        settle.restart()
    }
    function captureDrawing() {
        if (!capturePending) return
        var generation = captureGeneration
        // Rendering to a larger image retains small text and thin ladder lines.
        texture.grabToImage(function(result) {
            if (generation !== root.captureGeneration) return
            if (typeof _qopenhd !== "undefined" && typeof _qopenhd.widget_preview_image === "function")
                root.snapshot = _qopenhd.widget_preview_image(result)
            root.capturePending = false
            if (root.refreshAgain) { root.refreshAgain = false; root.refresh() }
        }, Qt.size(Math.max(1,Math.ceil(bounds.width*captureScale)),Math.max(1,Math.ceil(bounds.height*captureScale))))
    }
    Timer {
        id: settle; interval: 48; repeat: false
        onTriggered: {
            if (!root.visible || !root.target) return
            root.capturePending = true
            if (typeof root.target.refreshWidgetPreviewBounds === "function") root.target.refreshWidgetPreviewBounds()
            root.snapshot = ""
            texture.scheduleUpdate()
        }
    }
    onBoundsChanged: if (!capturePending) refresh()
    onRevisionChanged: refresh()
    onTargetChanged: { captureGeneration++; capturePending=false; snapshot=""; refresh() }
    onVisibleChanged: if (visible) refresh()
    Component.onCompleted: refresh()
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
        onScheduledUpdateCompleted: root.captureDrawing()
    }
    Rectangle { anchors.fill: parent; anchors.margins: 1; radius: 7; color: root.color; visible: root.snapshot.length > 0 }
    Image {
        objectName: "centeredWidgetImage"
        anchors.fill: parent; anchors.margins: 6
        visible: root.snapshot.length > 0
        source: root.snapshot
        fillMode: Image.PreserveAspectFit
        horizontalAlignment: Image.AlignHCenter
        verticalAlignment: Image.AlignVCenter
        cache: false; smooth: true
    }
    Text {
        anchors.fill:parent;anchors.margins:5
        visible:!root.target
        text:qsTr("Unavailable")
        color:"#aebdcb";font.family: MenuTypography.family;font.pixelSize: MenuTypography.helper
        horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;wrapMode:Text.WordWrap
    }
}
