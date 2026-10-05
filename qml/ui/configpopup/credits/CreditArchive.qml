import QtQuick 2.12
import QtQuick.Controls 2.12

Popup {
    id: terminal
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.max(0, Math.min(900, parent ? parent.width - 24 : 900))
    height: Math.max(0, Math.min(720, parent ? parent.height - 24 : 720))
    padding: 18
    modal: true
    dim: false
    focus: true
    closePolicy: Popup.CloseOnEscape

    property string reportText: ""
    property int revealedCharacters: 0
    readonly property color phosphor: "#ffbc65"

    FontLoader { id: terminalFont; source: "qrc:/osdfonts/ShareTechMono-Regular.ttf" }

    onOpened: {
        revealedCharacters = 0
        transcript.contentY = 0
        if (reportText.length === 0)
            reportText = _qopenhd.credit_archive_text()
        closeButton.forceActiveFocus()
    }
    onClosed: revealedCharacters = 0

    background: Rectangle {
        color: "#eb05080a"
        radius: 6
        border.color: terminal.phosphor
        border.width: 1
        clip: true
        Repeater {
            model: Math.ceil(terminal.height / 4)
            Rectangle { y: index * 4; width: terminal.width; height: 1; color: "#10000000" }
        }
    }

    contentItem: Item {
        Row {
            id: heading
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.right: closeButton.left
            anchors.rightMargin: 10
            spacing: 10
            Rectangle { width: 3; height: 36; color: terminal.phosphor }
            Column {
                Text {
                    text: "OPENHD // PERSONNEL ARCHIVE"
                    color: terminal.phosphor
                    font.family: terminalFont.name
                    font.pixelSize: terminal.width < 500 ? 11 : 16
                    font.bold: true
                }
                Text {
                    text: "SUBJECT 001 / LEAD DEVELOPER"
                    color: "#d39750"
                    font.family: terminalFont.name
                    font.pixelSize: 10
                }
            }
        }
        Button {
            id: closeButton
            objectName: "creditArchiveClose"
            anchors.top: parent.top
            anchors.right: parent.right
            width: 76
            height: 36
            text: qsTr("Close")
            Accessible.name: qsTr("Close developer terminal")
            onClicked: terminal.close()
            contentItem: Text {
                text: closeButton.text
                color: terminal.phosphor
                font.family: terminalFont.name
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: closeButton.down ? "#805b3610" : "#40100e09"
                border.color: terminal.phosphor
                border.width: closeButton.activeFocus || closeButton.hovered ? 2 : 1
                radius: 3
            }
        }
        Rectangle {
            id: separator
            anchors.top: closeButton.bottom
            anchors.topMargin: 12
            width: parent.width
            height: 1
            color: "#80ffbc65"
        }
        Flickable {
            id: transcript
            objectName: "creditArchiveTranscript"
            anchors.top: separator.bottom
            anchors.bottom: statusLine.top
            anchors.topMargin: 14
            anchors.bottomMargin: 14
            width: parent.width
            clip: true
            contentWidth: width
            contentHeight: report.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { }
            Text {
                id: report
                width: transcript.width - 16
                text: terminal.reportText.substring(0, terminal.revealedCharacters) + "\u2588"
                textFormat: Text.PlainText
                color: terminal.phosphor
                font.family: terminalFont.name
                font.pixelSize: terminal.width < 500 ? 12 : 15
                wrapMode: Text.Wrap
                lineHeight: 1.25
            }
        }
        Text {
            id: statusLine
            anchors.bottom: parent.bottom
            width: parent.width
            text: terminal.revealedCharacters < terminal.reportText.length
                  ? "ACCESS GRANTED // PRINTING PERSONNEL REPORT..."
                  : "END OF REPORT // OPENHD CONTINUES."
            color: "#d39750"
            font.family: terminalFont.name
            font.pixelSize: 10
            wrapMode: Text.Wrap
        }
    }

    Timer {
        interval: 30
        repeat: true
        running: terminal.opened && !transcript.dragging && !transcript.flicking
                 && terminal.revealedCharacters < terminal.reportText.length
        onTriggered: {
            terminal.revealedCharacters = Math.min(terminal.reportText.length, terminal.revealedCharacters + 3)
            transcript.contentY = Math.max(0, report.implicitHeight - transcript.height)
        }
    }

    // Load audio only while the terminal is open. Menu navigation does not
    // depend on the optional QtMultimedia plugin being installed.
    Loader {
        active: terminal.opened
        source: _qopenhd && _qopenhd.qtMajorVersion >= 6
                ? "CreditArchiveAudioQt6.qml" : "CreditArchiveAudio.qml"
    }
}
