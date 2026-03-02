import QtQuick 2.12
import QtQuick.Controls 2.12

Item {
    property var localesModel: [
        { text: qsTr("English"), locale: "en" },
        { text: qsTr("German"), locale: "de" }
    ]

    ComboBox {
        anchors.fill: parent

        model: localesModel

        textRole: "text"

        // @disable-check M223
        Component.onCompleted: {
            // @disable-check M223
            var foundIndex = -1;
            for (var i = 0; i < model.length; i++) {
                // @disable-check M222
                var choice = model[i];
                // @disable-check M223
                if (choice.locale == settings.locale) {
                    foundIndex = i;
                    currentIndex = i;
                }
            }
            if (foundIndex === -1 && model.length > 0) {
                currentIndex = 0;
                settings.locale = model[0].locale;
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
