/**
 * MIT License
 *
 * Copyright (c) 2020 Luca Carlon
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 **/

#ifndef LSETTINGS_H
#define LSETTINGS_H

#include <QObject>
#include <QSettings>
#include <QMutex>
#include <QString>
#include <QHash>

// The EXPAND macro here is only needed for MSVC:
// https://stackoverflow.com/questions/5134523/msvc-doesnt-expand-va-args-correctly
#define EXPAND( x ) x
#define L_SETTINGS_GET_MACRO(_1, _2, _3, NAME,...) NAME
#define L_DECLARE_SETTINGS(...) \
    EXPAND(L_SETTINGS_GET_MACRO(__VA_ARGS__, L_DECLARE_SETTINGS3, L_DECLARE_SETTINGS2)(__VA_ARGS__))

// Defines a single value inside the settings class.
#define L_DEFINE_VALUE(type, name, def, f)                                    \
    public:                                                                   \
        type name() const {                                                   \
            return m_settings->value(sectionToPath() + #name, def).f();       \
        }                                                                     \
    public Q_SLOTS:                                                           \
        void set_##name(type value) {                                         \
            if (name() == value) return;                                      \
            m_settings->setValue(sectionToPath() + #name, value);             \
            emit name##Changed(value);                                        \
            emit notifier().name##Changed(value);                             \
        }                                                                     \
    Q_SIGNALS:                                                                \
        void name##Changed(type name);                                        \
    private:                                                                  \
        Q_PROPERTY(type name READ name WRITE set_##name NOTIFY name##Changed)

// Declares the settings class.
#define L_DECLARE_SETTINGS2(classname, qsettings) \
    L_DECLARE_SETTINGS3(classname, qsettings, "")

#define L_DECLARE_SETTINGS3(classname, qsettings, section)       \
    class classname : public QObject                             \
    {                                                            \
    private:                                                     \
        Q_OBJECT                                                 \
    public:                                                      \
        static classname& notifier() {                           \
            static classname _notifier;                          \
            return _notifier;                                    \
        }                                                        \
    public:                                                      \
        classname(QObject* parent = nullptr) : QObject(parent) { \
            m_settings = qsettings;                              \
        }                                                        \
        ~classname() { delete m_settings; }                      \
    protected:                                                   \
        QSettings* m_settings;                                   \
        QString m_section = QStringLiteral(section);             \
    private:                                                     \
        QString sectionToPath() const                            \
        { return (!m_section.isEmpty() ? m_section + "/" : ""); }

template<typename T>
class LQTCacheValue
{
public:
    T value(const QString& key, std::function<T()> init);
    void reset(const QString& key);
    void setValue(const QString& key, const T& v);
    bool isSet(const QString& key);

private:
    QHash<QString, T> m_cache;
    QMutex m_mutex;
};

template<typename T>
T LQTCacheValue<T>::value(const QString& key, std::function<T()> init)
{
    QMutexLocker locker(&m_mutex);
    if (m_cache.contains(key))
        return m_cache.value(key);
    T v = init();
    m_cache.insert(key, v);
    return v;
}

template<typename T>
void LQTCacheValue<T>::reset(const QString& key)
{
    QMutexLocker locker(&m_mutex);
    m_cache.remove(key);
}

template<typename T>
void LQTCacheValue<T>::setValue(const QString& key, const T& v)
{
    QMutexLocker locker(&m_mutex);
    m_cache.insert(key, v);
}

template<typename T>
bool LQTCacheValue<T>::isSet(const QString& key)
{
    QMutexLocker locker(&m_mutex);
    return m_cache.contains(key);
}

#endif
