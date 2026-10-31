"""Link the simulator regression against an already built Windows QOpenHD tree."""
import argparse,os,re,subprocess
from pathlib import Path
parser=argparse.ArgumentParser()
parser.add_argument('--build-dir',required=True,type=Path)
parser.add_argument('--toolchain',default='C:/Qt/Tools/mingw810_32/bin',type=Path)
parser.add_argument('--audit',action='store_true')
a=parser.parse_args();build=a.build_dir.resolve();root=Path(__file__).resolve().parents[2]
text=(build/'Makefile.Release').read_text()
def variable(name):
 lines=text.splitlines()
 for i,line in enumerate(lines):
  match=re.match(r'^'+re.escape(name)+r'\s*=\s*(.*)',line)
  if not match:continue
  value=match.group(1)
  while value.rstrip().endswith('\\'):
   i+=1;value=value.rstrip()[:-1]+' '+lines[i].strip()
  return value
 return ''
env=os.environ.copy();env['PATH']=str(a.toolchain)+';C:/Qt/5.15.19/mingw81_32/bin;'+env['PATH']
compiler=a.toolchain/'g++.exe'
command='"'+str(compiler)+'" -c '+variable('CXXFLAGS').replace('$(DEFINES)','')+' '+variable('DEFINES')+' '+variable('INCPATH')+' -o obj/ui_simulator_smoke.o "'+str(root/('tests/widget_gallery_native/audit.cpp' if a.audit else 'tests/ui_simulator/smoke.cpp'))+'"'
subprocess.run(command,cwd=build,env=env,check=True)
objects=variable('OBJECTS').split()
objects=[o for o in objects if o.replace('\\','/')!='obj/main.o']+['obj/ui_simulator_smoke.o']
(build/'simulator-smoke-objects.rsp').write_text('\n'.join(objects))
command='"'+str(compiler)+'" '+variable('LFLAGS')+' -o release/ui-simulator-smoke.exe @simulator-smoke-objects.rsp '+variable('LIBS')
subprocess.run(command,cwd=build,env=env,check=True)
env['QT_QUICK_BACKEND']='software';env['QT_QUICK_CONTROLS_STYLE']='Material'
result=subprocess.run([str(build/'release/ui-simulator-smoke.exe')]+([str(root/'tests/widget_gallery_native/audit.qml')] if a.audit else []),cwd=build,env=env,timeout=30)
report=build/('gallery-audit-report.txt' if a.audit else 'simulator-smoke-result.txt')
if report.exists():print(report.read_text())
raise SystemExit(result.returncode)
