#include <QtCore/qglobal.h>
#include <QString>
#include <QColor>

#ifdef Q_OS_ANDROID
#include <QJniObject>
#endif

// Minimal C-style API: call from main.cpp; no QML involved.
// Hides ONLY the bottom navigation bar; keeps the status bar visible.
// Pass "#000000" to make the top bar solid black.
extern "C" Q_DECL_EXPORT void openhd_hide_navbar(bool transientSwipe, const char* statusBarColorHex)
{
#ifdef Q_OS_ANDROID
    // Get the Activity via Qt's QtNative helper (no QtAndroid/QNativeInterface needed)
    QJniObject activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative",
        "activity",
        "()Landroid/app/Activity;");
    if (!activity.isValid()) return;

    QJniObject win   = activity.callObjectMethod("getWindow", "()Landroid/view/Window;");
    QJniObject decor = win.callObjectMethod("getDecorView", "()Landroid/view/View;");
    if (!win.isValid() || !decor.isValid()) return;


    if (statusBarColorHex && statusBarColorHex[0]) {
        const QColor c(QString::fromUtf8(statusBarColorHex));
        const jint colorInt = (jint)((c.alpha() & 0xFF) << 24 |
                                     (c.red()   & 0xFF) << 16 |
                                     (c.green() & 0xFF) << 8  |
                                     (c.blue()  & 0xFF));
        win.callMethod<void>("setStatusBarColor","(I)V", colorInt);
    }

    const jint sdk = QJniObject::getStaticField<jint>("android/os/Build$VERSION","SDK_INT");
    if (sdk >= 30) {
        QJniObject controller = win.callObjectMethod(
            "getInsetsController",
            "(Landroid/view/View;)Landroid/view/WindowInsetsController;",
            decor.object());
        if (!controller.isValid()) return;

        const jint navBars = QJniObject::callStaticMethod<jint>(
            "android/view/WindowInsets$Type","navigationBars","()I");
        controller.callMethod<void>("hide","(I)V", navBars);

        if (transientSwipe) {
            const jint behavior = QJniObject::getStaticField<jint>(
                "android/view/WindowInsetsController",
                "BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE");
            controller.callMethod<void>("setSystemBarsBehavior","(I)V", behavior);
        }
    } else {
        jint flags =
            QJniObject::getStaticField<jint>("android/view/View","SYSTEM_UI_FLAG_LAYOUT_STABLE") |
            QJniObject::getStaticField<jint>("android/view/View","SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION") |
            QJniObject::getStaticField<jint>("android/view/View","SYSTEM_UI_FLAG_HIDE_NAVIGATION") |
            QJniObject::getStaticField<jint>("android/view/View","SYSTEM_UI_FLAG_IMMERSIVE_STICKY");
        decor.callMethod<void>("setSystemUiVisibility","(I)V", flags);
    }
#else
    Q_UNUSED(transientSwipe)
    Q_UNUSED(statusBarColorHex)
#endif
}
