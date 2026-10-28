import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Item {
    id: card
    // One coordinate system keeps header, rows and footer in proportion.
    // Fit height as well as width so a short window does not crop the footer.
    readonly property real designHeight: 535
    property real maximumCardHeight: Number.POSITIVE_INFINITY
    property real cardScale: Math.max(0.55, Math.min(width / 490, maximumCardHeight / designHeight))
    implicitHeight: designHeight * cardScale
    Layout.minimumWidth: 240
    property string title: ""
    property string iconText: "\uf519"
    property color iconColor: "#38a5ff"
    property bool alive: false
    property bool actionsAvailable: alive
    property int systemType: 0
    property Component bodyComponent
    signal detailsRequested()
    function actionButtons() { return [detailsButton] }
    function handleNavigation(event) {
        if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
            statusPanel.moveFocus(1); event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            statusPanel.moveFocus(-1); event.accepted = true
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Escape) {
            settings_form.side_bar_regain_focus(); event.accepted = true
        }
    }
    Item {
        id: surface
        objectName: "statusCardSurface"
        width: card.width / card.cardScale
        height: card.designHeight
        scale: card.cardScale
        transformOrigin: Item.TopLeft
        Rectangle {
            anchors.fill: parent
            radius: 18
            color: "#091f2e"
            border.color: "#153c53"
            border.width: 1
        }
        RowLayout {
            id: header
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            anchors.margins: 18
            height: 70
            spacing: 22
            Rectangle {
                Layout.preferredWidth: header.height
                Layout.preferredHeight: header.height
                radius: 11
                gradient: Gradient {
                    GradientStop { position: 0; color: "#0c3a5b" }
                    GradientStop { position: 1; color: "#0a3150" }
                }
                Text { anchors.centerIn: parent; text: card.iconText; color: card.iconColor; font.family: "Font Awesome 5 Free"; font.pixelSize: header.height * 0.56 }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: card.title.toUpperCase(); color: "#edf3fa"
                    font.family: "Archivo"; font.pixelSize: 20; font.bold: true
                    elide: Text.ElideRight
                }
                Row {
                    spacing: 10
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 19; height: width; radius: width / 2; color: statusText.color }
                    Text {
                        id: statusText
                        text: card.alive ? (card.systemType === 2 ? qsTr("Connected") : qsTr("Online")) : qsTr("Offline")
                        color: card.alive ? "#3bda69" : "#94a9b9"
                        font.family: "Archivo"; font.pixelSize: 20
                    }
                }
            }
        }
        Loader {
            id: bodyLoader
            anchors.top: header.bottom; anchors.topMargin: 21
            anchors.left: parent.left; anchors.right: parent.right
            height: item ? item.implicitHeight : 0
            sourceComponent: card.bodyComponent
        }
        Button {
            id: detailsButton
            objectName: "craftDetailsButton"
            anchors.top: bodyLoader.bottom; anchors.topMargin: 20
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: 20; anchors.rightMargin: 20
            height: 52
            text: qsTr("Details")
            font.capitalization: Font.MixedCase
            font.family: "Archivo"; font.pixelSize: 20
            Accessible.name: qsTr("%1 details").arg(card.title)
            onClicked: card.detailsRequested()
            onActiveFocusChanged: if (activeFocus) statusPanel.syncFocus(detailsButton)
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    card.detailsRequested(); event.accepted = true
                } else card.handleNavigation(event)
            }
            background: Rectangle {
                radius: 11
                color: detailsButton.down ? "#105384" : (detailsButton.hovered ? "#104670" : "#0b395f")
                border.color: detailsButton.activeFocus ? "#38a5ff" : "#075080"
                border.width: detailsButton.activeFocus ? 2 : 1
            }
            contentItem: Text { text: detailsButton.text; font: detailsButton.font; color: "#e4edf7"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }
    }
}
