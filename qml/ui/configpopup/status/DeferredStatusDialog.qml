import QtQuick 2.12

// Resolve the dialog's dependency tree only when its action is requested.
Loader {
    active: false
    asynchronous: true
    anchors.centerIn: parent
    z: 20
    property string pendingMethod: ""
    property var pendingArguments: []

    function open(method, args) {
        pendingMethod = method
        pendingArguments = args
        active = true
        invokePending()
    }
    function invokePending() {
        if (status !== Loader.Ready || !item || pendingMethod === "") return
        var method = pendingMethod
        var args = pendingArguments
        pendingMethod = ""
        pendingArguments = []
        item[method].apply(item, args)
    }
    function close() {
        pendingMethod = ""
        pendingArguments = []
        if (item) item.visible = false
    }
    onLoaded: invokePending()
}
