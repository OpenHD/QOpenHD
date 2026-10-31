from pathlib import Path
import subprocess,os
root=Path(__file__).resolve().parents[1];folder=root/'build/widget-gallery-native';folder.mkdir(exist_ok=True)
method=(root/'app/util/qopenhd.cpp').read_text(encoding='utf-8').split('QString QOpenHD::widget_preview_image(QObject* grabResult) const',1)[1].split('bool QOpenHD::reset_settings()',1)[0]
source='''#include <QtQuickTest/quicktest.h>
#include <QQmlEngine>
#include <QQmlContext>
#include <QStandardPaths>
#include <QQuickItemGrabResult>
#include <QBuffer>
#include "util/widgetpreviewimage.h"
#include "osd/horizonladder.h"
#include "osd/altitudeladder.h"
#include "osd/speedladder.h"
#include "osd/headingladder.h"
#include "osd/flightpathvector.h"
#include "osd/aoagauge.h"
class Cropper:public QObject { Q_OBJECT
public: Q_INVOKABLE QString widget_preview_image(QObject* grabResult) const METHOD
Q_INVOKABLE void show_toast(QString){}
};
class Setup:public QObject { Q_OBJECT
Cropper cropper;
public slots:
 void applicationAvailable(){QCoreApplication::setOrganizationName("OpenHDTests");QCoreApplication::setApplicationName("WidgetCentering");QStandardPaths::setTestModeEnabled(true);
 qmlRegisterType<HorizonLadder>("OpenHD",1,0,"HorizonLadder");
 qmlRegisterType<AltitudeLadder>("OpenHD",1,0,"AltitudeLadder");
 qmlRegisterType<SpeedLadder>("OpenHD",1,0,"SpeedLadder");
 qmlRegisterType<HeadingLadder>("OpenHD",1,0,"HeadingLadder");
 qmlRegisterType<AoaGauge>("OpenHD",1,0,"AoaGauge");
 qmlRegisterType<FlightPathVector>("OpenHD",1,0,"FlightPathVector");}
 void qmlEngineAvailable(QQmlEngine* e){e->rootContext()->setContextProperty("_qopenhd",&cropper);}
};
QUICK_TEST_MAIN_WITH_SETUP(widget_centering,Setup)
#include "main.moc"
'''.replace('METHOD',method)
(folder/'main.cpp').write_text(source,encoding='utf-8')
cpp=['horizonladder','altitudeladder','speedladder','headingladder','flightpathvector','aoagauge']
pro='QT += core gui quick qmltest qml widgets\nCONFIG += console c++17\nTARGET = widget_centering\n'
pro+='SOURCES += main.cpp '+' '.join((root/f'app/osd/{n}.cpp').as_posix() for n in cpp)+'\n'
pro+='HEADERS += '+' '.join((root/f'app/osd/{n}.h').as_posix() for n in cpp)+'\n'
pro+='INCLUDEPATH += '+(root/'app').as_posix()+'\n'
(folder/'test.pro').write_text(pro)
qt=Path('C:/Qt/5.15.19/mingw81_64/bin');make=Path('C:/Qt/Tools/mingw810_64/bin')
env=dict(os.environ,PATH=str(qt)+';'+str(make)+';'+os.environ.get('PATH',''),QT_QUICK_BACKEND='software',QT_QUICK_CONTROLS_STYLE='Material')
for cmd in [[str(qt/'qmake.exe'),'test.pro'],[str(make/'mingw32-make.exe'),'-j4']]:
 with (folder/'compile.log').open('w') as f:r=subprocess.run(cmd,cwd=folder,env=env,stdout=f,stderr=subprocess.STDOUT)
 if r.returncode:print((folder/'compile.log').read_text());raise SystemExit(r.returncode)
r=subprocess.run([str(folder/'release/widget_centering.exe'),'-input',str(root/'tests/widget_gallery_native'),'-o',str(root/'build/native-widget-centering.txt')+',txt'],cwd=root,env=env)
print((root/'build/native-widget-centering.txt').read_text())
raise SystemExit(r.returncode)

