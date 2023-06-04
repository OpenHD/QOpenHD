import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

Rectangle {
    Layout.fillHeight: true
    color: "#eaeaea"

    RowLayout {
        anchors.top: infoPanel.bottom
        anchors.topMargin: 24
        anchors.left: parent.left
        anchors.leftMargin: 20
        spacing: 6
        height: 300

        ColumnLayout {
            spacing: 6

            Card {
                id: consti
                height: 224
                width: 224
                cardName: qsTr("Constantin")
                cardBody: ColumnLayout {
                    RowLayout {
                        Layout.fillWidth: true

                        Item {
                            width: parent.width
                            height: parent.height
                            Layout.leftMargin: 20

                            Image {
                                id: ee1
                                visible: true
                                source: "../../resources/master1.png"
                                width: consti.height * 0.8
                                height: consti.height * 0.8
                            }
                        }
                    }
                }
                hasFooter: false
            }

            Card {
                id: max
                height: 224
                width: 224
                cardName: qsTr("Max")
                cardBody: ColumnLayout {
                    RowLayout {
                        Layout.fillWidth: true

                        Item {
                            width: parent.width
                            height: parent.height
                            Layout.leftMargin: 20

                            Image {
                                id: ee3
                                visible: true
                                source: "../../resources/master3.png"
                                width: max.height * 0.8
                                height: max.height * 0.8
                            }
                        }
                    }
                }
                hasFooter: false
            }
        }

        ColumnLayout {
            spacing: 6

            Card {
                id: rapha
                height: 224
                width: 224
                cardName: qsTr("Raphael")
                cardBody: ColumnLayout {
                    RowLayout {
                        Layout.fillWidth: true

                        Item {
                            width: parent.width
                            height: parent.height
                            Layout.leftMargin: 20

                            Image {
                                id: ee2
                                visible: true
                                source: "../../resources/master2.png"
                                width: rapha.height * 0.8
                                height: rapha.height * 0.8
                            }
                        }
                    }
                }
                hasFooter: false
            }

            Card {
                id: thomas
                height: 224
                width: 224
                cardName: qsTr("Thomas")
                cardBody: ColumnLayout {
                    RowLayout {
                        Layout.fillWidth: true

                        Item {
                            width: parent.width
                            height: parent.height
                            Layout.leftMargin: 20

                            Image {
                                id: ee4
                                visible: true
                                source: "../../resources/master4.png"
                                width: thomas.height * 0.8
                                height: thomas.height * 0.8
                            }
                        }
                    }
                }
                hasFooter: false
            }
        }

        ColumnLayout {
            spacing: 6

            Card {
                id: honorableMentions
                height: 448
                width: 224
                cardName: qsTr("      Honorable Mentions")
                cardBody: ColumnLayout {
                    Repeater {
                        model: [
                            "petea",
                            "pilotnbr1",
                            "limitlessgreen",
                            "michell",
                            "roman",
                            "patemil",
                            "jweijs",
                            "user1321",
                            "flavio",
                            "hdfpv",
                            "htcohio",
                            "raymond",
                            "yes21",
                            "mjc506",
                            "cq112358",
                            "steveatinfincia",
                            "norbert",
                            "macdaddyfpv"
                        ]

                        delegate: Text {
                            text: modelData
                            font.pixelSize: 14
                            color: "#333333"
                            Layout.leftMargin: 70
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
                hasFooter: false
            }
        }
    }
}
