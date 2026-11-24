import QtQuick 2.12

QtObject {
    id: root
    property var model
    property bool connected: false
    property var edits: ({})
    property var queue: []
    property string writing: ""
    property string status: ""
    property bool failed: false
    readonly property bool dirty: Object.keys(edits).length > 0
    readonly property bool applying: writing !== "" || queue.length > 0

    function savedValue(id) {
        model.update_count
        if (model.param_int_exists(id)) return model.get_cached_int(id)
        if (model.param_string_exists(id)) return model.get_cached_string(id)
        return undefined
    }

    function valueFor(id) {
        return edits[id] !== undefined ? edits[id] : savedValue(id)
    }

    function stage(id, value) {
        if (applying) return
        var next = Object.assign({}, edits)
        if (savedValue(id) === value) delete next[id]
        else next[id] = value
        edits = next
        status = ""
        failed = false
    }

    function reject(message) {
        queue = []
        writing = ""
        status = message
        failed = true
    }

    function apply(steps, intended) {
        if (!connected || applying || model.ui_is_busy) return
        edits = intended
        status = ""
        failed = false
        queue = steps
        writeNext()
    }

    function writeNext() {
        while (queue.length && savedValue(queue[0].id) === queue[0].value)
            completeStep()
        if (!queue.length) {
            status = qsTr("Applied")
            return
        }
        if (!connected || model.ui_is_busy) {
            reject(qsTr("Unit busy or disconnected. Remaining changes are pending."))
            return
        }

        var step = queue[0]
        var current = savedValue(step.id)
        if (current === undefined || model.get_ui_metadata(step.id).readOnly) {
            reject(qsTr("%1 is unavailable. Remaining changes are pending.").arg(step.label))
            return
        }
        writing = step.id
        if (typeof current === "number") model.try_set_param_int_async(step.id, step.value, false)
        else model.try_set_param_string_async(step.id, step.value, false)
    }

    function completeStep() {
        var step = queue[0]
        if (edits[step.id] === step.value) {
            var next = Object.assign({}, edits)
            delete next[step.id]
            edits = next
        }
        queue = queue.slice(1)
    }

    property Connections results: Connections {
        target: root.model
        function onParameterWriteFinished(id, success) {
            if (id !== root.writing || !root.queue.length) return
            if (!success) {
                root.reject(qsTr("Could not apply %1. Remaining changes are pending.").arg(root.queue[0].label))
                return
            }
            root.completeStep()
            if (!root.queue.length) root.status = qsTr("Applied")
            root.writing = ""
            if (root.queue.length) Qt.callLater(root.writeNext)
        }
    }
}
