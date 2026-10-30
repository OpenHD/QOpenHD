import QtQuick 2.12
import QtQuick.Controls 2.12

// Selected buttons provide their own fill; omit the style's extra underline.
TabBar {
    id: control
    readonly property bool compactTabs: {
        var needed = 0, visibleCount = 0
        for (var i = 0; i < count; ++i) {
            var tab = itemAt(i)
            if (!tab || tab.hasContent === false) continue
            needed += tab.naturalWidth !== undefined ? tab.naturalWidth : tab.implicitWidth
            visibleCount++
        }
        return width > 0 && needed + Math.max(0, visibleCount - 1) * spacing > width
    }
    function available(index) {
        var tab = itemAt(index)
        return tab && tab.hasContent !== false
    }
    function firstAvailable(from, step) {
        for (var i = from; i >= 0 && i < count; i += step)
            if (available(i)) return i
        return -1
    }
    function ensureAvailableTab() {
        if (available(currentIndex)) return
        var previous = itemAt(currentIndex)
        var restoreFocus = previous && previous.activeFocus
        currentIndex = firstAvailable(0, 1)
        if (restoreFocus && currentIndex >= 0) itemAt(currentIndex).forceActiveFocus()
    }
    function moveAvailable(step) {
        var next = firstAvailable(currentIndex + step, step)
        if (next < 0) next = firstAvailable(step > 0 ? 0 : count - 1, step)
        if (next >= 0) {
            currentIndex = next
            itemAt(next).forceActiveFocus()
        }
    }
    onCountChanged: Qt.callLater(ensureAvailableTab)
    onCurrentIndexChanged: ensureAvailableTab()
    Component.onCompleted: ensureAvailableTab()
    Keys.onLeftPressed: moveAvailable(-1)
    Keys.onRightPressed: moveAvailable(1)
    background: Item {}
    contentItem: ListView {
        model: control.contentModel
        currentIndex: control.currentIndex
        spacing: control.spacing
        orientation: ListView.Horizontal
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.AutoFlickIfNeeded
        snapMode: ListView.SnapToItem
        highlight: null
    }
}
