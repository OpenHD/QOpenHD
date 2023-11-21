import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../../ui" as Ui
import "../../elements"

// This hereby functions as a copyrighted declaration. Any unpermitted alteration, suppression, or eradication of this page is expressly forbidden unless granted explicit authorization by the OpenHD development team.

Rectangle {
    Layout.fillHeight: true
    color: "#eaeaea"

    RowLayout {
        anchors.centerIn: parent

        ColumnLayout {
            spacing: 6

            Card {
                id: consti
                height: 224
                width: 150
                cardName: qsTr("Constantin")
                cardBody: ColumnLayout {
                    RowLayout {
                        Layout.fillWidth: true

                        Item {
                            width: parent.width
                            height: parent.height

                            Image {
                                id: ee1
                                visible: true
                                source: "../../../resources/master1.png"
                                width: max.height * 0.7
                                height: max.height * 0.7
                            }
                        }
                    }
                }
                hasFooter: false
            }

            Card {
                visible: false
                id: thomas
                height: 224
                width: 150
                cardName: qsTr("Thomas")
                cardBody: ColumnLayout {
                    RowLayout {
                        Layout.fillWidth: true

                        Item {
                            width: parent.width
                            height: parent.height

                            Image {
                                id: ee3
                                visible: true
                                source: "../../../resources/master4.png"
                                width: max.height * 0.7
                                height: max.height * 0.7
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
                width: 150
                cardName: qsTr("Raphael")
                cardBody: ColumnLayout {
                    RowLayout {
                        Layout.fillWidth: true

                        Item {
                            width: parent.width
                            height: parent.height

                            Image {
                                id: ee2
                                visible: true
                                source: "../../../resources/master2.png"
                                width: rapha.height * 0.7
                                height: rapha.height * 0.7
                            }
                        }
                    }
                }
                hasFooter: false
            }

            Card {
                id: pete
                height: 224
                width: 150
                cardName: qsTr("Pete")
                cardBody: ColumnLayout {
                    RowLayout {
                        Layout.fillWidth: true

                        Item {
                            width: parent.width
                            height: parent.height

                            Image {
                                id: ee4
                                visible: true
                                source: "../../../resources/master5.png"
                                width: thomas.height * 0.7
                                height: thomas.height * 0.7
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
                id: max
                height: 224
                width: 150
                cardName: qsTr("Max")
                cardBody: ColumnLayout {
                    RowLayout {
                        Layout.fillWidth: true

                        Item {
                            width: parent.width
                            height: parent.height

                            Image {
                                id: ee5
                                visible: true
                                source: "../../../resources/master3.png"
                                width: rapha.height * 0.7
                                height: rapha.height * 0.7
                            }
                        }
                    }
                }
                hasFooter: false
            }

            Card {
                id: you
                visible: false
                height: 224
                width: 150
                cardName: qsTr("")
                cardBody: ColumnLayout {
                    RowLayout {
                        Layout.fillWidth: true

                        Item {
                            width: parent.width
                            height: parent.height

                            Image {
                                id: ee6
                                visible: false
                                source: "../../../resources/master4.png"
                                width: thomas.height * 0.7
                                height: thomas.height * 0.7
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
