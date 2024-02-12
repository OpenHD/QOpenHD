import QtQuick 2.0

SideBarBasePanel{
    override_title: "Link"

    Column {
        anchors.top: parent.top
        anchors.topMargin: secondaryUiHeight/8
        spacing: 5

        EditFrequencyElement{
            id: edit_frequency_element
        }

        EditChannelWidthElement{
            id: edit_channel_width_element
        }

        EditRateElement{
            id: edit_rate_element
        }

        /*Text{
                text: "Range -> Quality" + "  (MCS" + _ohdSystemAir.curr_mcs_index + ")"
                font.pixelSize: 14
                font.family: "AvantGarde-Medium"
                color: "#ffffff"
                smooth: true
            }
            Slider {
                id: valueSlider
                from: 0
                to: 3
                stepSize: 1
                //snapMode: Slider.SnapToStep
                value: 0 // Initial value
                Material.accent: Material.Grey
                onValueChanged: {
                    // Handle the slider value change here
                    console.log("MCS Slider:", value)
                }
            }
            Text{
                text: "Frequency" + "   (" + _ohdSystemGround.curr_channel_mhz + ")"
                font.pixelSize: 14
                font.family: "AvantGarde-Medium"
                color: "#ffffff"
                smooth: true
            }
            ComboBox {
                width: 200
                model: [ "2312", "2332", "2352", "2372", "2392", "2412", "2432", "2452", "2472", "2492", "2512", "2532", "2572", "2592", "2612", "2632", "2652", "2672", "2692", "2712", "5180", "5200", "5220", "5240", "5260", "5280", "5300", "5320", "5500", "5520", "5540", "5560", "5580", "5600", "5620", "5640", "5660", "5680", "5700", "5745", "5765", "5785", "5805", "5825", "5845", "5865", "5885" ]
            }
            Text{
                text: "TX Power Air" + "   (" + "TODO" + ")"
                font.pixelSize: 14
                font.family: "AvantGarde-Medium"
                color: "#ffffff"
                smooth: true
            }
            Slider {
                id: txPowerAirSlider
                from: 22
                to: 58
                stepSize: 4
                //snapMode: Slider.SnapToStep
                value: 22 // Initial value
                Material.accent: Material.Grey
                onValueChanged: {
                    // Handle the slider value change here
                    console.log("TX Power Air Slider:", value)
                }
            }
            Text{
                text: "Bandwith"
                font.pixelSize: 14
                font.family: "AvantGarde-Medium"
                color: "#ffffff"
                smooth: true
            }
            TabBar {
                id: control
                Material.accent: "#fff"
                Material.foreground: "white"
                background: Rectangle {
                    implicitWidth: 100
                    implicitHeight: 40
                    color: secondaryUiColor
                }
                TabButton {
                    text: qsTr("20MHZ")
                }
                TabButton {
                    text: qsTr("40MHZ")
                }
            }*/

    }

}
