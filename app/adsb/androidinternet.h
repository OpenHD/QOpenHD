#pragma once

#include <QByteArray>
#include <QString>
#ifdef Q_OS_ANDROID
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
#include <QtAndroid>
#include <QAndroidJniObject>
using InternetJniObject = QAndroidJniObject;
#else
#include <QJniObject>
#include <QCoreApplication>
using InternetJniObject = QJniObject;
#endif

inline QByteArray androidInternetJson(const QString& url) {
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    const auto context = QtAndroid::androidContext();
#else
    const auto context = QNativeInterface::QAndroidApplication::context();
#endif
    const auto address = InternetJniObject::fromString(url);
    const auto reply = InternetJniObject::callStaticObjectMethod(
        "org/openhd/InternetJson", "get",
        "(Landroid/content/Context;Ljava/lang/String;)Ljava/lang/String;",
        context.object(), address.object<jstring>());
    return reply.toString().toUtf8();
}
#endif
