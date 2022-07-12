#ifndef QOPENHD_H
#define QOPENHD_H

#include <QFont>
#include <QObject>
#include <QQmlApplicationEngine>
#include <QTranslator>

#ifdef ENABLE_SPEECH
#include <QTextToSpeech>
#endif

/**
 * Dirty, but for some reason stephen made translation(s) and a bit more work this way.
 */
class QOpenHD : public QObject
{
    Q_OBJECT
public:
    explicit QOpenHD(QObject *parent = nullptr);
    static QOpenHD& instance();
    Q_INVOKABLE void switchToLanguage(const QString &language);
    void setEngine(QQmlApplicationEngine *engine);
    Q_PROPERTY(QString fontFamily MEMBER m_fontFamily WRITE setFontFamily NOTIFY fontFamilyChanged)
    void setFontFamily(QString fontFamily);
    void textToSpeech_sayMessage(QString message);
signals:
    void fontFamilyChanged(QString fontFamily);
private:
     QQmlApplicationEngine *m_engine = nullptr;
     QTranslator m_translator;
     QString m_fontFamily;
     QFont m_font;
#if defined(ENABLE_SPEECH)
    QTextToSpeech *m_speech;
#endif
};

#endif // QOPENHD_H
