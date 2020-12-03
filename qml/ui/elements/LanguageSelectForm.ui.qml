import QtQuick 2.12
import QtQuick.Controls 2.12

Item {
    ComboBox {
        anchors.fill: parent

        model: ListModel {
            id: locales
            ListElement { text: "German"; locale: "de" }
            ListElement { text: "Russian"; locale: "ru" }
            ListElement { text: "English"; locale: "en" }
            ListElement { text: "French"; locale: "fr" }
            ListElement { text: "Spanish"; locale: "es" }
            ListElement { text: "Dutch"; locale: "nl" }
            ListElement { text: "Romanian"; locale: "ro" }
            ListElement { text: "Chinese"; locale: "zh" }
            ListElement { text: "Italian"; locale: "it" }
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
            OpenHD.switchToLanguage(settings.locale);
        }

        onActivated: {
            settings.locale = locales.get(currentIndex).locale

            OpenHD.switchToLanguage(settings.locale);
        }
    }
}
