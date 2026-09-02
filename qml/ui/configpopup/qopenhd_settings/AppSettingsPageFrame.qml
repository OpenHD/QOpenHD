import QtQuick 2.12

FocusScope {
    id: root
    default property alias pageData: content.data
    signal backRequested()

    function gainFocus() {
        forceActiveFocus()
        var next = nextItemInFocusChain(true)
        if (next && next !== root)
            next.forceActiveFocus()
    }

    Item { id: content; anchors.fill: parent }

    Keys.onEscapePressed: {
        backRequested()
        event.accepted = true
    }
}
