import QtQuick 2.12
import QtQuick.Controls 2.12

Item {

    property string dummy_listener: settings.font_text

    function update_selection(){
        for (var i = 0; i < fontDropdown.model.count; i++) {
            var choice = fontDropdown.model.get(i);
            if (choice.text == settings.font_text) {
                fontDropdown.currentIndex = i;
            }
        }
    }

    onDummy_listenerChanged: {
        update_selection();
    }

    ComboBox {
        id: fontDropdown
        anchors.fill: parent
        font.pixelSize: 14

        model: ListModel {
            id: font_text
            ListElement { text: "Sans Serif" }
            ListElement { text: "Acme" }
            ListElement { text: "Aldrich" }
            ListElement { text: "Anonymous Pro" }
            ListElement { text: "Archivo" }
            ListElement { text: "Archivo Black" }
            ListElement { text: "Armata" }
            ListElement { text: "Bangers" }
            ListElement { text: "Black Ops One" }
            ListElement { text: "Bungee" }
            ListElement { text: "Carbon" }
            ListElement { text: "Chicle" }
            ListElement { text: "Digital Counter 7" }
            ListElement { text: "Expletus Sans" }
            ListElement { text: "Fjalla One" }
            ListElement { text: "Fredoka One" }
            ListElement { text: "Geostar Fill" }
            ListElement { text: "Iceberg" }
            ListElement { text: "Iceland" }
            ListElement { text: "Jura" }
            ListElement { text: "Keania One" }
            ListElement { text: "Larabiefont" }
            ListElement { text: "LED Display7" }
            ListElement { text: "Luckiest Guy" }
            ListElement { text: "Merysha" }
            ListElement { text: "Nixie One" }
            ListElement { text: "Orbitron" }
            ListElement { text: "Oxygen" }
            ListElement { text: "Passion One" }
            ListElement { text: "Quantico" }
            ListElement { text: "Quicksand" }
            ListElement { text: "Rammetto One" }
            ListElement { text: "Rationale" }
            ListElement { text: "Righteous" }
            ListElement { text: "Roboto Mono" }
            ListElement { text: "Russo One" }
            ListElement { text: "Share Tech" }
            ListElement { text: "Share Tech Mono" }
            ListElement { text: "Sigmar One" }
            ListElement { text: "Slackey" }
            ListElement { text: "Subway Ticker" }
            ListElement { text: "Ubuntu Mono" }
            ListElement { text: "Visitor TT1 BRK" }
            ListElement { text: "Zolan Mono BTN" }
        }

        textRole: "text"
        // @disable-check M223
        Component.onCompleted: {

            fontDropdown.popup.contentItem.implicitHeight = Qt.binding(function () {
                return Math.min(250, fontDropdown.popup.contentItem.contentHeight);
            });
            update_selection();

        }
        onCurrentIndexChanged: {
            const selected_font=font_text.get(currentIndex).text
            if(settings.font_text!=selected_font){
                settings.font_text=selected_font;
                console.log("Selected font:"+settings.font_text)
            }
        }
    }
}
