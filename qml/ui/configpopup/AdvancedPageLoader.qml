import QtQuick 2.12

// Create only the selected page and retain its controls/state after leaving it.
Loader {
    property bool selected: false
    property bool visited: false
    property string pendingMethod: ""
    property string diagnosticName: source.toString().split("/").pop() || "inline-page"
    onStatusChanged: {
        if (selected && typeof _qopenhd !== "undefined" &&
                typeof _qopenhd.advanced_menu_stage === "function")
            _qopenhd.advanced_menu_stage("page_loader", diagnosticName + " status=" + status,
                                       status === Loader.Error)
    }
    asynchronous: true
    active: selected || visited
    onLoaded: {
        visited = true
        if (pendingMethod !== "") {
            var method = pendingMethod
            pendingMethod = ""
            invokeWhenReady(method)
        }
    }

    // Navigation can arrive before asynchronous page creation finishes.
    function invokeWhenReady(method) {
        if (item && status === Loader.Ready) {
            if (typeof item[method] === "function") item[method]()
        } else {
            pendingMethod = method
        }
    }

    onSelectedChanged: if (!selected) pendingMethod = ""
    onVisibleChanged: if (!visible) pendingMethod = ""

    function gainFocus() {
        invokeWhenReady("gainFocus")
    }
}
