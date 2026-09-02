import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."

AdvancedPage {
    id: root
    pageIcon: "\uf005"
    pageTitle: qsTr("CREDITS")
    pageSubtitle: qsTr("Built by developers and sustained by the OpenHD community")
    initialFocusItem: peopleGrid
    onBackRequested: settings_form.side_bar_regain_focus()

    readonly property int portraitColumns: Math.max(1, Math.min(3, Math.floor(scroll.width / 230)))
    readonly property int portraitHeight: scroll.width < 620 ? 218 : 246

    ListModel {
        id: people
        ListElement { personName: "Raphael"; portrait: "../../../resources/rapha.png" }
        ListElement { personName: "Max"; portrait: "../../../resources/max.png" }
        ListElement { personName: "Thomas"; portrait: "../../../resources/thomas.png" }
        ListElement { personName: "Pete"; portrait: "../../../resources/pete.png" }
        ListElement { personName: "Luka"; portrait: "../../../resources/luka.png" }
    }

    ListModel {
        id: contributors
        ListElement { contributorName: "pilotnbr1" }
        ListElement { contributorName: "limitlessgreen" }
        ListElement { contributorName: "michell" }
        ListElement { contributorName: "roman" }
        ListElement { contributorName: "jweijs" }
        ListElement { contributorName: "user1321" }
        ListElement { contributorName: "flavio" }
        ListElement { contributorName: "hdfpv" }
        ListElement { contributorName: "htcohio" }
        ListElement { contributorName: "raymond" }
        ListElement { contributorName: "yes21" }
        ListElement { contributorName: "mjc506" }
        ListElement { contributorName: "cq112358" }
        ListElement { contributorName: "norbert" }
        ListElement { contributorName: "macdaddyfpv" }
        ListElement { contributorName: "ivan" }
    }

    function reveal(item) {
        var point = item.mapToItem(creditContent, 0, 0)
        if (point.y < scroll.contentY)
            scroll.contentY = Math.max(0, point.y - 8)
        else if (point.y + item.height > scroll.contentY + scroll.height)
            scroll.contentY = Math.min(scroll.contentHeight - scroll.height,
                                       point.y + item.height - scroll.height + 8)
    }

    Flickable {
        id: scroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: creditContent.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

        ColumnLayout {
            id: creditContent
            width: scroll.width
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text { text: qsTr("CORE TEAM"); color: settings_form.accentColor; font.pixelSize: 12; font.bold: true }
                Rectangle { Layout.fillWidth: true; height: 1; color: settings_form.lineColor }
            }

            GridView {
                id: peopleGrid
                Layout.fillWidth: true
                Layout.preferredHeight: Math.ceil(count / root.portraitColumns) * root.portraitHeight
                cellWidth: width / root.portraitColumns
                cellHeight: root.portraitHeight
                model: people
                interactive: false
                focus: true
                keyNavigationWraps: false
                delegate: Item {
                    width: peopleGrid.cellWidth
                    height: peopleGrid.cellHeight
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 5
                        radius: 13
                        color: settings_form.panelBackground
                        border.width: GridView.isCurrentItem && peopleGrid.activeFocus ? 2 : 1
                        border.color: GridView.isCurrentItem && peopleGrid.activeFocus ? settings_form.accentColor : settings_form.lineColor
                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: Math.min(184, peopleGrid.cellWidth - 34)
                                height: width
                                radius: 12
                                color: settings_form.panelBackgroundRaised
                                clip: true
                                Image { anchors.fill: parent; anchors.margins: 5; source: portrait; fillMode: Image.PreserveAspectFit; smooth: true; mipmap: true }
                            }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: personName; color: settings_form.primaryText; font.pixelSize: 16; font.bold: true }
                        }
                        MouseArea { anchors.fill: parent; onClicked: { peopleGrid.currentIndex = index; peopleGrid.forceActiveFocus() } }
                    }
                }
                Keys.onPressed: function(event) {
                    if ((event.key === Qt.Key_Left && currentIndex === 0) || event.key === Qt.Key_Escape) {
                        settings_form.side_bar_regain_focus(); event.accepted = true
                    } else if (event.key === Qt.Key_Down && currentIndex >= count - root.portraitColumns) {
                        honorableCard.forceActiveFocus(); root.reveal(honorableCard); event.accepted = true
                    }
                }
            }

            AdvancedCard {
                id: honorableCard
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(300, contributorFlow.childrenRect.height + formerFlow.childrenRect.height + 154)
                activeFocusOnTab: true
                border.width: activeFocus ? 2 : 1
                border.color: activeFocus ? settings_form.accentColor : settings_form.lineColor
                Column {
                    anchors.fill: parent
                    spacing: 6
                    Text { text: qsTr("HONORABLE MENTIONS"); color: settings_form.accentColor; font.pixelSize: 16; font.bold: true }
                    Text { width: parent.width; text: qsTr("Community members whose testing, development, documentation and support helped shape OpenHD."); color: settings_form.secondaryText; font.pixelSize: 12; wrapMode: Text.WordWrap }
                    Flow {
                        id: contributorFlow
                        width: parent.width
                        spacing: 7
                        Repeater {
                            model: contributors
                            Rectangle {
                                width: contributorLabel.implicitWidth + 24
                                height: 32
                                radius: 16
                                color: settings_form.darkMode ? "#173b61" : "#e1effd"
                                border.color: settings_form.lineColor
                                Text { id: contributorLabel; anchors.centerIn: parent; text: contributorName; color: settings_form.primaryText; font.pixelSize: 11; font.bold: true }
                            }
                        }
                    }
                    Rectangle { width: parent.width; height: 1; color: settings_form.lineColor }
                    Text { text: qsTr("FORMER DEVELOPERS"); color: settings_form.accentColor; font.pixelSize: 16; font.bold: true }
                    Text { width: parent.width; text: qsTr("Previous core contributors whose engineering work remains part of the project."); color: settings_form.secondaryText; font.pixelSize: 12; wrapMode: Text.WordWrap }
                    Flow {
                        id: formerFlow
                        width: parent.width
                        spacing: 7
                        Repeater {
                            model: ["consti10", "steveatinfincia", "rodizio1", "befinitv"]
                            Rectangle {
                                width: formerLabel.implicitWidth + 24
                                height: 32
                                radius: 16
                                color: settings_form.darkMode ? "#173b61" : "#e1effd"
                                border.color: settings_form.lineColor
                                Text { id: formerLabel; anchors.centerIn: parent; text: modelData; color: settings_form.primaryText; font.pixelSize: 11; font.bold: true }
                            }
                        }
                    }
                }
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Up) { peopleGrid.forceActiveFocus(); root.reveal(peopleGrid); event.accepted = true }
                    else if (event.key === Qt.Key_Left || event.key === Qt.Key_Escape) { settings_form.side_bar_regain_focus(); event.accepted = true }
                }
            }
        }
    }
}
