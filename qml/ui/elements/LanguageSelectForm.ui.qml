import QtQuick 2.12
import QtQuick.Controls 2.12

Item {
    ComboBox {
        anchors.fill: parent

        model: ListModel {
            id: locales
            ListElement { text: "DE"; locale: "de" }
            ListElement { text: "RU"; locale: "ru" }
            ListElement { text: "EN"; locale: "en" }
            ListElement { text: "FR"; locale: "fr" }
            ListElement { text: "ES"; locale: "es" }
            ListElement { text: "NL"; locale: "nl" }
        }

        textRole: "text"

        // @disable-check M223
        Component.onCompleted: {
            // @disable-check M223
            for (var i = 0; i < model.count; i++) {
                // @disable-check M222
                var choice = model.get(i);
                // @disable-check M223
                if (choice.locale == settings.locale) {
                    currentIndex = i;
                }
            }
        }

        onCurrentIndexChanged: {
            settings.locale = locales.get(currentIndex).locale

            OpenHD.switchToLanguage(settings.locale);
        }
    }
}
