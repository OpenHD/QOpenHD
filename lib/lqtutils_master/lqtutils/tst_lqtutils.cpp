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

#include <QtTest>
#include <QString>
#include <QImage>
#include <QPainter>
#include <QQmlEngine>
#include <QDebug>

#include "../lqtutils_prop.h"
#include "../lqtutils_string.h"
#include "../lqtutils_settings.h"
#include "../lqtutils_enum.h"
#include "../lqtutils_autoexec.h"
#include "../lqtutils_threading.h"
#include "../lqtutils_math.h"
#include "../lqtutils_time.h"
#include "../lqtutils_ui.h"
#include "../lqtutils_bqueue.h"

class LQtUtilsObject : public QObject
{
    Q_OBJECT
    L_RW_PROP(QString, rwTest, setRwTest, QString())
    L_RW_PROP_AS(QString, rwTestAuto, QString())
    L_RW_PROP_AS(QString, rwTestAuto2, QString("rwTestAuto2"))
    L_RW_PROP_AS(QString, rwTestAuto3)
    L_RO_PROP_AS(QString, roTestAuto, QString())
    L_RO_PROP_AS(QString, roTestAuto2, QString("roTestAuto2"))
    L_RO_PROP_AS(QString, roTestAuto3)
    L_RO_PROP(QString, test, setTest, QString())
    L_RO_PROP_REF_AS(QString, refRoTestAuto)
    L_RO_PROP_REF_AS(QString, refRoTestAuto2, QString("refRoTestAuto2"))
    L_RW_PROP_CS(QString, csProp, QSL("HELLO"))
    L_RW_PROP_REF_CS(QString, csPropRef, QSL("HELLO"))
    L_RO_PROP_REF_CS(QString, csRoPropRef, QSL("csRoPropRef"))
public:
     LQtUtilsObject(QObject* parent = nullptr) :
     QObject(parent) {}

public slots:
    // Custom setter.
    void set_csProp(const QString& prop) {
        m_csProp = prop;
        m_test = QStringLiteral("csProp");
    }

    void set_csPropRef(const QString& prop) {
        m_csPropRef = prop;
        m_test = QSL("csPropRef");
    }

    void set_csRoProp(const QString& prop) {
        m_csRoPropRef = prop;
        m_test = QSL("csRoPropRef");
    }
};

L_BEGIN_GADGET(LQtUtilsGadget)
L_RO_GPROP_AS(int, someInteger, 5)
L_RO_GPROP_AS(int, someInteger2)
L_RW_GPROP_AS(int, someRwInteger, 6)
L_RW_GPROP_AS(int, someRwInteger2)
L_RO_GPROP_CS(QString, csRoProp, QSL("csRoProp"))
L_RW_GPROP_CS(QString, csRwProp, QSL("csRwProp"))
public:
    void set_csRoProp(const QString&) { set_someInteger(5); }
    void set_csRwProp(const QString&) { set_someInteger(6); }
L_END_GADGET

L_BEGIN_CLASS(LPropTest)
L_RW_PROP_REF(QStringList, myListRef, setMyListRef, QStringList() << "hello")
L_RO_PROP(QStringList, myList, setMyList, QStringList() << "hello")
L_END_CLASS

L_DECLARE_SETTINGS(LSettingsTest, new QSettings("settings.ini", QSettings::IniFormat))
L_DEFINE_VALUE(QString, string1, QString("string1"), toString)
L_DEFINE_VALUE(QSize, size, QSize(100, 100), toSize)
L_DEFINE_VALUE(double, temperature, -1, toDouble)
L_DEFINE_VALUE(QByteArray, image, QByteArray(), toByteArray)
L_END_CLASS

L_DECLARE_SETTINGS(LSettingsTestSec1, new QSettings("settings.ini", QSettings::IniFormat), "SECTION_1")
L_DEFINE_VALUE(QString, string2, QString("string2"), toString)
L_END_CLASS

L_DECLARE_ENUM(MyEnum,
               Value1 = 1,
               Value2,
               Value3)

class LQtUtilsTest : public QObject
{
    Q_OBJECT
public:
    LQtUtilsTest();
    ~LQtUtilsTest();

private slots:
    void test_case1();
    void test_case2();
    void test_case3();
    void test_case4();
    void test_case5();
    void test_case6();
    void test_case7();
    void test_case8();
    void test_case9();
    void test_case10();
    void test_case11();
    void test_case12();
    void test_case13();
    void test_case14();
    void test_case15();
    void test_case16();
    void test_case17();
    void test_case18();
    void test_case19();
    void test_case20();
    void test_case21();
    void test_case22();
};

LQtUtilsTest::LQtUtilsTest() {}
LQtUtilsTest::~LQtUtilsTest() {}

void LQtUtilsTest::test_case1()
{
    const QString s = QSL("HELLOOOOO!");
    LQtUtilsObject test;
    test.setTest(s);
    connect(&test, &LQtUtilsObject::testChanged, this, [] (QString) {
        qDebug() << "Valued changed";
    });
    QVERIFY(test.test() == s);
    test.setTest("HELLO");
    QVERIFY(test.test() != s);
    test.set_rwTestAuto("HELLO AUTOSET");
    QVERIFY(test.rwTestAuto() == "HELLO AUTOSET");
    QVERIFY(test.rwTestAuto2() == "rwTestAuto2");
    QVERIFY(test.rwTestAuto3().isNull());
    test.set_roTestAuto("roTestAuto");
    QVERIFY(test.roTestAuto2() == "roTestAuto2");
    QVERIFY(test.roTestAuto3().isNull());
    QVERIFY(test.refRoTestAuto2() == "refRoTestAuto2");

    test.set_csProp(QSL("csProp"));
    QVERIFY(test.test() == QSL("csProp"));
    QVERIFY(test.csProp() == QSL("csProp"));

    test.set_csPropRef(QSL("csPropRef"));
    QVERIFY(test.test() == QSL("csPropRef"));
    QVERIFY(test.csPropRef() == QSL("csPropRef"));
    test.csPropRef().replace(QSL("cs"), QSL("helloCs"));
    QVERIFY(test.csPropRef() == QSL("helloCsPropRef"));

    LQtUtilsGadget gadget;
    QVERIFY(gadget.someInteger() == 5);
    QVERIFY(gadget.someRwInteger() == 6);
    gadget.set_someInteger2(10);
    gadget.set_someRwInteger2(11);
    QVERIFY(gadget.someInteger2() == 10);
    QVERIFY(gadget.someRwInteger2() == 11);
    gadget.set_csRoProp("");
    QVERIFY(gadget.someInteger() == 5);
    gadget.set_csRwProp("");
    QVERIFY(gadget.someInteger() == 6);
}

void LQtUtilsTest::test_case2()
{
    QImage image(100, 100, QImage::Format_ARGB32);
    QByteArray data;
    QBuffer buffer(&data);
    buffer.open(QIODevice::WriteOnly);
    QPainter p(&image);
    p.setBrush(Qt::red);
    p.drawRect(image.rect());
    image.save(&buffer, "jpg");
    QVERIFY(data.size() != 0);

    {
        LSettingsTest& settings = LSettingsTest::notifier();
        settings.set_string1("some string");
        settings.set_size(QSize(250, 200));
        settings.set_temperature(36.7);
        settings.set_image(data);

        LSettingsTestSec1 sec1;
        sec1.set_string2(QSL("value_in_section"));
    }

    {
        QSettings settings("settings.ini", QSettings::IniFormat);
        QCOMPARE(settings.value(QSL("string1")), QSL("some string"));
        QCOMPARE(settings.value(QSL("size")).toSize(), QSize(250, 200));
        QCOMPARE(settings.value(QSL("temperature")).toDouble(), 36.7);
        QCOMPARE(settings.value(QSL("image")).toByteArray(), data);
        QCOMPARE(settings.value(QSL("SECTION_1/string2")), "value_in_section");
    }

    bool signalEmitted = false;
    QEventLoop loop;
    QTimer::singleShot(0, this, [] {
        LSettingsTest::notifier().set_size(QSize(1280, 720));
    });
    connect(&LSettingsTest::notifier(), &LSettingsTest::sizeChanged, this, [&signalEmitted] {
        QCOMPARE(LSettingsTest::notifier().size(), QSize(1280, 720));
        signalEmitted = true;
    });
    connect(&LSettingsTest::notifier(), &LSettingsTest::sizeChanged,
            &loop, &QEventLoop::quit);
    loop.exec();

    QCOMPARE(LSettingsTest::notifier().size(), QSize(1280, 720));
    QVERIFY(signalEmitted);
}

void LQtUtilsTest::test_case3()
{
    QMutex mutex;
    int count = 0;

    QEventLoop loop;

    QThreadPool::globalInstance()->setMaxThreadCount(500);
    for (int i = 0; i < 1000; i++) {
        QThreadPool::globalInstance()->start(QRunnable::create([&mutex, &count, &loop] {
            LSettingsTest settings;
            settings.set_string1(QSL("runnable1"));
            settings.set_temperature(35.5);

            QMutexLocker locker(&mutex);
            count++;
            if (count >= 2000)
                loop.quit();
        }));
        QThreadPool::globalInstance()->start(QRunnable::create([&mutex, &count, &loop] {
            LSettingsTest settings;
            settings.set_string1(QSL("runnable2"));
            settings.set_temperature(37.5);

            QMutexLocker locker(&mutex);
            count++;
            if (count >= 2000)
                loop.quit();
        }));
    }

    loop.exec();

    {
        QSettings settings("settings.ini", QSettings::IniFormat);
        QVERIFY(settings.value(QSL("string1")) == QSL("runnable1") ||
                settings.value(QSL("string1")) == QSL("runnable2"));
        QVERIFY(settings.value(QSL("temperature")).toDouble() == 35.5 ||
                settings.value(QSL("temperature")).toDouble() == 37.5);
    }
}

void LQtUtilsTest::test_case4()
{
    QBENCHMARK {
        for (int i = 0; i < 1000; i++) {
            LSettingsTestSec1 sec1;
            sec1.set_string2(QSL("value"));
        }
    }
}

void LQtUtilsTest::test_case5()
{
    QBENCHMARK {
        for (int i = 0; i < 1000; i++) {
            QSettings settings("settings.ini", QSettings::IniFormat);
            settings.setValue(QSL("string2"), QSL("value"));
        }
    }
}

void LQtUtilsTest::test_case6()
{
    QBENCHMARK {
        for (int i = 0; i < 1000; i++) {
            LSettingsTestSec1 sec1;
            QCOMPARE(sec1.string2(), QSL("value"));
        }
    }
}

void LQtUtilsTest::test_case7()
{
    QBENCHMARK {
        for (int i = 0; i < 1000; i++) {
            QSettings settings("settings.ini", QSettings::IniFormat);
            QCOMPARE(settings.value(QSL("string2")), QSL("value"));
        }
    }
}

void LQtUtilsTest::test_case8()
{
    MyEnum::qmlRegisterMyEnum("com.luke", 1, 0);
    QCOMPARE(MyEnum::Value1, 1);
    QCOMPARE(MyEnum::Value2, 2);
    QCOMPARE(QMetaEnum::fromType<MyEnum::Value>().valueToKey(MyEnum::Value3), QSL("Value3"));
}

void LQtUtilsTest::test_case9()
{
    LPropTest test;
    test.myList().append("Luca");

    LPropTest testRef;
    testRef.myListRef().append("Luca");

    QCOMPARE(test.myList().size(), 1);
    QCOMPARE(test.myList().at(0), "hello");
    QCOMPARE(testRef.myListRef().size(), 2);
    QCOMPARE(testRef.myListRef().at(0), "hello");
    QCOMPARE(testRef.myListRef().at(1), "Luca");
}

void LQtUtilsTest::test_case10()
{
    int i = 9;
    {
        LQTAutoExec autoexec([&] {
            i++;
        });
        QCOMPARE(i, 9);
    }
    QCOMPARE(i, 10);
}

void LQtUtilsTest::test_case11()
{
    int i = 9;
    QThread* currentThread = QThread::currentThread();
    INVOKE_AWAIT_ASYNC(this, [&i, currentThread] {
        i++;
        QCOMPARE(QThread::currentThread(), currentThread);
        QCOMPARE(i, 10);
    });
    QCOMPARE(i, 10);

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
}

void LQtUtilsTest::test_case12()
{
    int i = 9;

    {
        LQTSharedAutoExec lock2;
        {
            LQTSharedAutoExec lock;
            {
                lock = LQTSharedAutoExec([&i] {
                    i++;
                });
                QCOMPARE(i, 9);
            }
            QCOMPARE(i, 9);
            lock2 = lock;
        }
        QCOMPARE(i, 9);
    }
    QCOMPARE(i, 10);
}

void LQtUtilsTest::test_case13()
{
    QVERIFY(lqt_in_range(0, -1, 1));
    QVERIFY(lqt_in_range(19.0, -10.0, 19.1));
    QVERIFY(lqt_in_range(QSL("f"), QSL("a"), QSL("s")));
    QVERIFY(lqt_in_range(QDateTime::currentDateTime(),
                         QDateTime::currentDateTime().addDays(-4),
                         QDateTime::currentDateTime().addSecs(1)));
    QVERIFY(!lqt_in_range(QDateTime::currentDateTime(),
                          QDateTime::currentDateTime().addDays(4),
                          QDateTime::currentDateTime().addSecs(1)));
}

void LQtUtilsTest::test_case14()
{
    QDateTime now = QDateTime::currentDateTime();
    QVERIFY(lqtutils::today().date() == now.date());
    QVERIFY(lqtutils::today().time() == QTime(0, 0, 0, 0));
    QVERIFY(lqtutils::tomorrow().date() != now.date());
    QVERIFY(lqtutils::tomorrow().time() == QTime(0, 0, 0, 0));
    QVERIFY(lqtutils::today().msecsTo(lqtutils::tomorrow()) == 1000*60*60*24);
}

void LQtUtilsTest::test_case15()
{
    QScopedPointer<LQTFrameRateMonitor> mon(new LQTFrameRateMonitor);
}

void LQtUtilsTest::test_case16()
{
    QRectF r(10, 20, 123.45, 678.90);
    QString s = string_from_rect(r);
    QVERIFY(s == QSL("10,20,123.45,678.9"));
    QRectF r2 = string_to_rect(s);
    QVERIFY(qFuzzyCompare(r.x(), r2.x()));
    QVERIFY(qFuzzyCompare(r.y(), r2.y()));
    QVERIFY(qFuzzyCompare(static_cast<float>(r.width()), static_cast<float>(r2.width())));
    QVERIFY(qFuzzyCompare(static_cast<float>(r.height()), static_cast<float>(r2.height())));
}

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

void LQtUtilsTest::test_case17()
{
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
}

void LQtUtilsTest::test_case18()
{
    LQTBlockingQueue<int> queue(2);
    queue.enqueue(0);
    queue.enqueue(1);
    QVERIFY(queue.size() == 2);
    QVERIFY(!queue.enqueue(2, 5));
    QVERIFY(queue.size() == 2);

    queue.lockQueue([] (QList<int>* queue) {
        QVERIFY((*queue)[0] == 0);
        QVERIFY((*queue)[1] == 1);
    });

    QVERIFY(queue.enqueueDropFirst(2, 0));
    QVERIFY(queue.size() == 2);

    queue.lockQueue([] (QList<int>* queue) {
        QVERIFY((*queue)[0] == 1);
        QVERIFY((*queue)[1] == 2);
    });

    queue.dequeue();
    queue.dequeue();
    QVERIFY(queue.dequeue(0) == std::nullopt);

    for (int i = 0; i < 1E5; i++)
        queue.dequeue(0);
    QVERIFY(queue.isEmpty());
}

void LQtUtilsTest::test_case19()
{
    QVERIFY(qFuzzyCompare(string_to_float(QSL("1.6"), 1.6), 1.6f));
    QVERIFY(qFuzzyCompare(string_to_float(QSL("abc"), 1.6), 1.6f));
    QVERIFY(string_to_int(QSL("5"), 5) == 5);
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Woverflow"
    QVERIFY(string_to_int(QString("%1").arg(std::numeric_limits<qint64>::max() + 100), 1) == 1);
    QVERIFY(string_to_int64(QString("%1").arg(std::numeric_limits<qint64>::max() + 100),
                            1) == std::numeric_limits<qint64>::max() + 100);
#pragma GCC diagnostic pop
}

void LQtUtilsTest::test_case20()
{
    QThread t;
    t.start();
    QEventLoop loop;
    QVERIFY(&t != QThread::currentThread());
    lqt_run_in_thread(&t, [&loop, &t] {
        QVERIFY(&t == QThread::currentThread());
        loop.quit();
    });
    loop.exec();
    t.quit();
    t.wait();
}

void LQtUtilsTest::test_case21()
{
    LQTCacheValue<bool> boolCache;
    QVERIFY(boolCache.value("value1", [] () -> bool { return true; }) == true);
    QVERIFY(boolCache.value("value1", [] () -> bool { return false; }) == true);
    QVERIFY(boolCache.value("value2", [] () -> bool { return false; }) == false);
    QVERIFY(boolCache.value("value2", [] () -> bool { return true; }) == false);
    QVERIFY(boolCache.isSet("value1"));
    QVERIFY(boolCache.isSet("value2"));
    QVERIFY(!boolCache.isSet("value3"));
    boolCache.reset("value1");
    boolCache.reset("value2");
    QVERIFY(!boolCache.isSet("value1"));
    QVERIFY(!boolCache.isSet("value2"));
    boolCache.setValue("value1", false);
    QVERIFY(!boolCache.value("value1", [] { return false; }) == true);

    LQTCacheValue<MyEnum::Value> enumCache;
    QVERIFY(enumCache.value("value1", [] () -> MyEnum::Value { return MyEnum::Value1; }) == MyEnum::Value1);
    QVERIFY(enumCache.value("value1", [] () -> MyEnum::Value { return MyEnum::Value2; }) == MyEnum::Value1);
    QVERIFY(enumCache.value("value2", [] () -> MyEnum::Value { return MyEnum::Value1; }) == MyEnum::Value1);
    QVERIFY(enumCache.value("value2", [] () -> MyEnum::Value { return MyEnum::Value2; }) == MyEnum::Value1);
    QVERIFY(enumCache.value("value3", [] () -> MyEnum::Value { return MyEnum::Value3; }) == MyEnum::Value3);
}

void LQtUtilsTest::test_case22()
{
    QThread* t = new QThread;
    t->start();

    QVERIFY(t != QThread::currentThread());

    lqt_run_in_thread_sync(t, [t] {
        QVERIFY(t == QThread::currentThread());
    });

    QObject* o = new QObject;
    o->moveToThread(t);
    lqt_run_in_thread_sync(o, [t] {
        QVERIFY(t == QThread::currentThread());
        return;
    });

    int testValue = 1;
    QVERIFY(lqt_run_in_thread_sync<bool>(t, [&testValue] () -> bool {
        QThread::sleep(3);
        testValue = 5;
        return true;
    }));
    QVERIFY(testValue == 5);

    QVERIFY(lqt_run_in_thread_sync<bool>(o, [] () -> bool {
        return true;
    }));

    o->deleteLater();
    t->quit();
    t->wait();
    t->deleteLater();
}

QTEST_GUILESS_MAIN(LQtUtilsTest)

#include "tst_lqtutils.moc"
