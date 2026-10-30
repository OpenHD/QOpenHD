from pathlib import Path
import argparse,os,subprocess
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--qt-bin',type=Path,required=True);p.add_argument('--make-bin',type=Path,required=True);args=p.parse_args()
folder=ROOT/'build'/('settings-backup-'+args.qt_bin.parent.name);folder.mkdir(exist_ok=True)
pro='QT += core gui testlib\nCONFIG += console c++17\nTARGET = settings_backup_test\n'
pro+='SOURCES += '+(ROOT/'app/util/settingsbackup.cpp').as_posix()+' '+(ROOT/'tests/settings_backup/test_settings_backup.cpp').as_posix()+'\n'
pro+='HEADERS += '+(ROOT/'app/util/settingsbackup.h').as_posix()+'\nINCLUDEPATH += '+(ROOT/'app/util').as_posix()+'\n'
(folder/'test.pro').write_text(pro)
env=os.environ.copy();env['PATH']=str(args.qt_bin)+os.pathsep+str(args.make_bin)+os.pathsep+env.get('PATH','')
for command in [[str(args.qt_bin/'qmake.exe'),'test.pro'],[str(args.make_bin/'mingw32-make.exe'),'-j4']]:
    with (folder/'build.log').open('w') as log:result=subprocess.run(command,cwd=folder,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=120)
    if result.returncode:print((folder/'build.log').read_text());raise SystemExit(result.returncode)
result=subprocess.run([str(folder/'release/settings_backup_test.exe'),'-o',str(folder/'result.txt')+',txt'],cwd=ROOT,env=env,timeout=90)
print((folder/'result.txt').read_text(encoding='utf-8'))
raise SystemExit(result.returncode)
