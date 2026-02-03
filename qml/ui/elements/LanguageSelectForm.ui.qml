import QtQuick 2.12
import QtQuick.Controls 2.12

Item {
    property var localesModel: [
        { text: qsTr("German"), locale: "de" },
        { text: qsTr("Ukrainian"), locale: "uk" },
        { text: qsTr("Russian"), locale: "ru" },
        { text: qsTr("English"), locale: "en" },
        { text: qsTr("French"), locale: "fr" },
        { text: qsTr("Spanish"), locale: "es" },
        { text: qsTr("Dutch"), locale: "nl" },
        { text: qsTr("Romanian"), locale: "ro" },
        { text: qsTr("Chinese"), locale: "zh" },
        { text: qsTr("Italian"), locale: "it" }
    ]

    ComboBox {
        anchors.fill: parent

        model: localesModel

        textRole: "text"

        // @disable-check M223
        Component.onCompleted: {
            // @disable-check M223
            for (var i = 0; i < model.length; i++) {
                // @disable-check M222
                var choice = model[i];
                // @disable-check M223
                if (choice.locale == settings.locale) {
                    currentIndex = i;
                }
            }
            _qopenhd.switchToLanguage(settings.locale);
        }

        onActivated: {
            settings.locale = model[currentIndex].locale

            _qopenhd.switchToLanguage(settings.locale);
            _restartqopenhdmessagebox.show_with_text(qsTr("Language change will apply after restart."));
        }
    }
}
