import QtQuick 2.12

// Create only the selected page and retain its controls/state after leaving it.
Loader {
    property bool selected: false
    property bool visited: false
    active: selected || visited
    onLoaded: visited = true

    function gainFocus() {
        if (item && item.gainFocus) item.gainFocus()
    }
}
