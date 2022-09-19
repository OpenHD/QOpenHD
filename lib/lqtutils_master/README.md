# LQtUtils
This is a module containing a few tools that I typically use in Qt apps. Using this module in your app is simple: add a submodule to your git repo and include the headers. Most of the code is in independent headers, so you don't need to build anything separately.
A couple of headers need the related source file to be compiled explicitly; in that case I typically add the source file to my pro or cmake file.

## How to Include

To include in a qmake app:

```
include(lqtutils/lqtutils.pri)
```

To include in a cmake app:

```
include(${CMAKE_CURRENT_SOURCE_DIR}/lqtutils/CMakeLists.txt)
set(PROJECT_SOURCES
    ${lqtutils_src}
    main.cpp
    ...
)
```

## Synthetize Qt properties in a short way (lqtutils_prop.h)
Contains a few useful macros to synthetize Qt props. For instance:
```c++
class Fraction : public QObject
{
    Q_OBJECT
    L_RW_PROP(double, numerator, setNumerator, 5)
    L_RW_PROP(double, denominator, setDenominator, 9)
public:
    Fraction(QObject* parent = nullptr) : QObject(parent) {}
};
```
instead of:
```c++
class Fraction : public QObject
{
    Q_OBJECT
    Q_PROPERTY(double numerator READ numerator WRITE setNumerator NOTIFY numeratorChanged)
    Q_PROPERTY(double denominator READ denominator WRITE setDenominator NOTIFY denominatorChanged)
public:
    Fraction(QObject* parent = nullptr) :
        QObject(parent),
        m_numerator(5),
        m_denominator(9)
        {}

    double numerator() const {
        return m_numerator;
    }

    double denominator() const {
        return m_denominator;
    }

public slots:
    void setNumerator(double numerator) {
        if (m_numerator == numerator)
            return;
        m_numerator = numerator;
        emit numeratorChanged(numerator);
    }

    void setDenominator(double denominator) {
        if (m_denominator == denominator)
            return;
        m_denominator = denominator;
        emit denominatorChanged(denominator);
    }

signals:
    void numeratorChanged(double numerator);
    void denominatorChanged(double denominator);

private:
    double m_numerator;
    double m_denominator;
};
```
When the QObject subclass is not supposed to have a particular behavior, the two macros L_BEGIN_CLASS and L_END_CLASS can speed up the declaration even more:
```c++
L_BEGIN_CLASS(Fraction)
L_RW_PROP(double, numerator, setNumerator, 5)
L_RW_PROP(double, denominator, setDenominator, 9)
L_END_CLASS
```
The L_RW_PROP and L_RO_PROP macros are overloaded, and can therefore be used with three or four params. The last param is used if you want to init the prop to some specific value automatically.

This makes the usage of Qt properties more synthetic and speeds up the development. It is very useful when many properties are needed to expose data to QML.

### References

If you need to be able to modify the property itself from C++ instead of resetting it, you can use the *_REF alternatives of L_RW_PROP and L_RO_PROP. In that case, getter methods return a reference to the type in C++.

### Signals With or Without Parameters

By default, signals are generated with the value passed in the argument. If you prefer signals without params, you can define LQTUTILS_OMIT_ARG_FROM_SIGNAL **before** including the header.

### Autosetter

It is also possible to omit the name of the setter in the declaration. This results in the auto-generation of a setter with the name "set_<property name>". To obtain this behavior, simply use the variants of the above macros with the suffix "_AS". This should work for all property types: ro, rw, ref and all gadget props.

### Custom Setter

It is possible to generate a property without its setter implementation. The setter con be implemented with a slot explicitly by writing a method named "set_<propname>" returning void. An example can be found [here](lqtutils/tst_lqtutils.cpp#L52).

### Complete List of Available Macros

For QObjects:

    L_RW_PROP(type, name, setter)
    L_RW_PROP(type, name, setter, default)
    L_RW_PROP_AS(type, name)
    L_RW_PROP_AS(type, name, default)
    L_RW_PROP_CS(type, name)
    L_RW_PROP_CS(type, name, default)
    L_RW_PROP_REF(type, name, setter)
    L_RW_PROP_REF(type, name, setter, default)
    L_RW_PROP_REF_AS(type, name)
    L_RW_PROP_REF_AS(type, name, default)
    L_RW_PROP_REF_CS(type, name)
    L_RW_PROP_REF_CS(type, name, default)
    L_RO_PROP(type, name, setter)
    L_RO_PROP(type, name, setter, default)
    L_RO_PROP_AS(type, name)
    L_RO_PROP_AS(type, name, default)
    L_RO_PROP_CS(type, name)
    L_RO_PROP_CS(type, name, default)
    L_RO_PROP_REF(type, name, setter)
    L_RO_PROP_REF(type, name, setter, default)
    L_RO_PROP_REF_AS(type, name)
    L_RO_PROP_REF_AS(type, name, default)
    L_RO_PROP_REF_CS(type, name)
    L_RO_PROP_REF_CS(type, name, default)
    L_BEGIN_CLASS(name)
    L_END_CLASS

For gadgets:

    L_RW_GPROP(type, name, setter)
    L_RW_GPROP(type, name, setter, default)
    L_RW_GPROP_AS(type, name)
    L_RW_GPROP_AS(type, name, default)
    L_RW_GPROP_CS(type, name)
    L_RW_GPROP_CS(type, name, default)
    L_RO_GPROP(type, name, setter)
    L_RO_GPROP(type, name, setter, default)
    L_RO_GPROP_AS(type, name)
    L_RO_GPROP_AS(type, name, default)
    L_RO_GPROP_CS(type, name)
    L_RO_GPROP_CS(type, name, default)
    L_BEGIN_GADGET(name)
    L_END_GADGET

## Synthetize Qt settings with support for signals (lqtutils_settings.h)
Contains a few tools that can be used to speed up writing simple settings to a file. Settings will still use QSettings and are therefore fully compatible. The macros are simply shortcuts to synthetise code. I only used this for creating ini files, but should work for other formats. An example:
```c++
L_DECLARE_SETTINGS(LSettingsTest, new QSettings("settings.ini", QSettings::IniFormat))
L_DEFINE_VALUE(QString, string1, QString("string1"), toString)
L_DEFINE_VALUE(QSize, size, QSize(100, 100), toSize)
L_DEFINE_VALUE(double, temperature, -1, toDouble)
L_DEFINE_VALUE(QByteArray, image, QByteArray(), toByteArray)
L_END_CLASS

L_DECLARE_SETTINGS(LSettingsTestSec1, new QSettings("settings.ini", QSettings::IniFormat), "SECTION_1")
L_DEFINE_VALUE(QString, string2, QString("string2"), toString)
L_END_CLASS
```
This will provide an interface to a "strong type" settings file containing a string, a QSize value, a double, a jpg image and another string, in a specific section of the ini file. Each class is reentrant like QSettings and can be instantiated in multiple threads.
Each class also provides a unique notifier: the notifier can be used to receive notifications when any thread in the code changes the settings, and can also be used in bindings in QML code. For an example, refer to LQtUtilsQuick:
```c++
Window {
    visible: true
    x: settings.appX
    y: settings.appY
    width: settings.appWidth
    height: settings.appHeight
    title: qsTr("Hello World")

    Connections {
        target: settings
        onAppWidthChanged:
            console.log("App width saved:", settings.appWidth)
        onAppHeightChanged:
            console.log("App width saved:", settings.appHeight)
    }

    Binding { target: settings; property: "appWidth"; value: width }
    Binding { target: settings; property: "appHeight"; value: height }
    Binding { target: settings; property: "appX"; value: x }
    Binding { target: settings; property: "appY"; value: y }
}
```
## Synthetize Qt enums and quickly expose to QML (lqtutils_enum.h)
Contains a macro to define a enum and register it with the meta-object system. This enum can then be exposed to the QML. To create the enum simply do:
```c++
L_DECLARE_ENUM(MyEnum,
               Value1 = 1,
               Value2,
               Value3)
```
This enum is exposed using a namespace without subclassing QObject. Register with the QML engine with:
```c++
MyEnum::registerEnum("com.luke", 1, 0);
```

## Cache values and init automatically
```LQTCacheValue``` caches values of any type in a hash and calls the provided lambda if the value was never initialized. This is useful when writing settings classes and you want to read only once.

## lqtutils_fsm.h
A QState subclass that includes a state name and prints it to stdout when each state is entered.

## lqtutils_threading.h
```LQTRecursiveMutex``` is a simple QMutex subclass defaulting to recursive mode.

```INVOKE_AWAIT_ASYNC``` is a wrapper around QMetaObject::invokeMethod that allows to execute a slot or lambda in the thread of an obj, synchronously awaiting for the result. E.g.:
```c++
QThread* t = new QThread;
t->start();
QObject* obj = new QObject;
obj->moveToThread(t);
INVOKE_AWAIT_ASYNC(obj, [&i, currentThread, t] {
    i++;
    QCOMPARE(t, QThread::currentThread());
    QVERIFY(QThread::currentThread() != currentThread);
    QCOMPARE(i, 11);
});
QCOMPARE(i, 11);
```

```lqt_run_in_thread``` runs a lambda in a specific QThread asynchronously.

## lqtutils_autoexec.h
A class that can be used to execute a lambda whenever the current scope ends, e.g.:
```c++
int i = 9;
{
    LQTAutoExec autoexec([&] {
        i++;
    });
    QCOMPARE(i, 9);
}
QCOMPARE(i, 10);
```

```LQTSharedAutoExec```: a class that can create copiable autoexec objects. Useful to implement locks with a function being executed when the lock is released.

## lqtutils_freq.h

```LQTFreqMeter``` is a class that allows to measure the rate of any sampling activity. For example the refresh rate (see lqtutils_ui.h) or the rate of some kind of processing.

## lqtutils_ui.h

```LQTFrameRateMonitor``` is a class that can be used to measure the current frame rate of a QQuickWindow. The class monitors the frequency of frame swaps and provides a property with a value reporting the frame rate during the last second.

### How to Use

To use it, simply instantiate it when you need it like this:

```c++
QQuickView view;
LQTFrameRateMonitor* monitor = new LQTFrameRateMonitor(&view);
```

expose it to QML if you need it:

```c++
view.engine()->rootContext()->setContextProperty("fpsmonitor", monitor);
```

and use it in QML (or in C++ if you prefer):

```js
Text { text: qsTr("fps: ") + fpsmonitor.freq }
```

### Details

The frame rate is provided in a notifiable property of the ```LQTFrameRateMonitor``` class:

```c++
L_RO_PROP_AS(int, freq, 0)
```

Note that this property is defined using the prop macros provided by this library. The property is recomputed when each frame is swapped or after a second. The overhead of the component should be minimal.

## lqtutils_perf.h

```measure_time``` is a shortcut to quickly measure a procedure provided in a lambda for benchmarking it. The macro ```L_MEASURE_TIME``` can be used to be able to enable/disable the measurement through ```L_ENABLE_BENCHMARKS``` at project level reducing overhead to zero.

### How to Use

This is an exmaple:

```c++
measure_time([&] {
    const uchar* rgba = ...
    for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
            [process pixel]
        }
    }
}, [] (qint64 time) {
    qWarning() << "Image processed in:" << time;
});
```

## lqtutils_bqueue.h

This header contains a simple blocking queue. It allows blocking/nonblocking insertions with timeout, blocking/nonblocking removal and a safe processing of the queue. This is an example of the producer/consumer pattern:

```c++
struct LQTTestProducer : public QThread
{
    LQTTestProducer(LQTBlockingQueue<int>* queue) : QThread(), m_queue(queue) {}
    void run() override {
        static int i = 0;
        while (!isInterruptionRequested()) {
            QThread::msleep(10);
            m_queue->enqueue(i++);
            QVERIFY(m_queue->size() <= 10);
        }
    }
    void requestDispose() {
        requestInterruption();
        m_queue->requestDispose();
    }

private:
    LQTBlockingQueue<int>* m_queue;
};

struct LQTTestConsumer : public QThread
{
    LQTTestConsumer(LQTBlockingQueue<int>* queue) : QThread(), m_queue(queue) {}
    void run() override {
        static int i = 0;
        while (!isInterruptionRequested()) {
            QThread::msleep(15);
            std::optional<int> ret = m_queue->dequeue();
            if (!ret)
                return;
            QVERIFY(*ret == i++);
            QVERIFY(lqt_in_range(m_queue->size(), 0, 11));
        }
    }
    void requestDispose() {
        requestInterruption();
        m_queue->requestDispose();
    }

private:
    LQTBlockingQueue<int>* m_queue;
};

[...]

LQTBlockingQueue<int> queue(10, QSL("display_name"));
LQTTestConsumer consumer(&queue);
LQTTestProducer producer(&queue);
consumer.start();
producer.start();

QEventLoop loop;
QTimer::singleShot(30*1000, this, [&] { loop.quit(); });
loop.exec();

producer.requestDispose();
producer.wait();
consumer.requestDispose();
consumer.wait();
```