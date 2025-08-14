#include <QColor>

#ifdef Q_OS_ANDROID
#include <QJniObject>
#include <QNativeInterface>
#endif

// Minimal C-style API: call from main.cpp; no QML involved.
// Hides ONLY the bottom navigation bar; keeps the status bar visible.
// Pass "#000000" to make the top bar solid black.
extern "C" Q_DECL_EXPORT void openhd_hide_navbar(bool transientSwipe, const char* statusBarColorHex)
{
#ifdef Q_OS_ANDROID
    QJniObject ctx = QNativeInterface::QAndroidApplication::context();
    if (!ctx.isValid()) return;

    QJniObject win   = ctx.callObjectMethod("getWindow", "()Landroid/view/Window;");
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
