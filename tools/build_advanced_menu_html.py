"""Build the offline menu explorer from the inventory and current QML. Run from the repo root."""
import re, json, subprocess
from pathlib import Path
from dataclasses import dataclass, field
ROOT=Path(__file__).resolve().parents[1]
TOKEN=re.compile(r'//[^\n]*|/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|[A-Za-z_$][\w$]*|-?\d+(?:\.\d+)?|[^\s]',re.M)
@dataclass
class Node:
    kind:str
    start:int
    end:int
    body:int
    children:list=field(default_factory=list)
    props:dict=field(default_factory=dict)
    parent:object=None
class Qml:
    def __init__(self,path):
        self.path=Path(path); self.text=self.path.read_text(encoding='utf-8-sig')
        self.tokens=[m for m in TOKEN.finditer(self.text) if not m[0].startswith(('//','/*'))]
        ts=self.tokens; stack=[]; pairs={}
        for i,t in enumerate(ts):
            if t[0] in ('{','[','('): stack.append(i)
            elif t[0] in ('}',']',')') and stack:
                j=stack.pop(); pairs[j]=i
        self.nodes=[]
        for i,t in enumerate(ts[:-1]):
            if re.fullmatch(r'[A-Z][\w]*',t[0]) and ts[i+1][0]=='{' and i+1 in pairs:
                self.nodes.append(Node(t[0],t.start(),ts[pairs[i+1]].end(),i+2))
        for n in self.nodes:
            parents=[p for p in self.nodes if p.start<n.start and p.end>=n.end]
            if parents:
                n.parent=min(parents,key=lambda p:p.end-p.start); n.parent.children.append(n)
            i=n.body
            while i<len(ts) and ts[i].start()<n.end-1:
                # Skip entire nested QML/JS blocks, arrays and function calls.
                if i in pairs: i=pairs[i]+1; continue
                # Direct property declarations or property bindings.
                j=i
                if ts[j][0] in ('readonly','default','required'): j+=1
                if ts[j][0]=='property': j+=2
                if j+1>=len(ts): break
                name=ts[j][0]; k=j+1
                while k+1<len(ts) and ts[k][0]=='.': name+='.'+ts[k+1][0]; k+=2
                if re.fullmatch(r'[\w.]+',name) and ts[k][0]==':':
                    a=k+1; b=a
                    while b<len(ts) and ts[b].start()<n.end-1:
                        if ts[b][0]==';': break
                        if b>a and '\n' in self.text[ts[b-1].end():ts[b].start()]:
                            prev=ts[b-1][0]; nex=ts[b][0]
                            if prev not in ('?',':',',','+','-','=','&','|','.') and nex not in ('?',':','&','|','+'):
                                break
                        if b in pairs: b=pairs[b]+1
                        else: b+=1
                    if b>a: n.props[name]=self.text[ts[a].start():ts[b-1].end()].strip()
                    i=max(b,a); continue
                i+=1
        self.byid={n.props['id']:n for n in self.nodes if 'id' in n.props}
    def source(self,n): return f'{self.path.as_posix()}:{self.text.count(chr(10),0,n.start)+1}'

def scalar(expr):
    if expr is None:return None
    expr=expr.strip()
    if expr in ('true','false'):return expr=='true'
    if re.fullmatch(r'-?\d+(\.\d+)?',expr):return float(expr) if '.' in expr else int(expr)
    m=re.fullmatch(r'qsTr\(("(?:\\.|[^"\\])*")\)',expr)
    if m:expr=m[1]
    if expr.startswith('"'):
        try:return json.loads(expr)
        except ValueError:pass
    return re.sub(r'\s+',' ',expr)
def label(expr):
    if not expr:return None
    vals=re.findall(r'qsTr\(("(?:\\.|[^"\\])*")\)',expr)
    if vals:return ' / '.join(dict.fromkeys(json.loads(v) for v in vals))
    v=scalar(expr)
    if isinstance(v,str) and not re.search(r'[\uf000-\uf8ff]',v) and expr.startswith(('"',"'")):return v
    return None

import copy
import os
os.chdir(ROOT)
inventory=json.loads(Path('docs/advanced_menu_tree.json').read_text(encoding='utf8'))
catalog=inventory['parameter_catalog']
extra=inventory['firmware_parameters_beyond_fallback']
allparams={**catalog,**extra}
FLAGS=('settings.dev_show_advanced_button','settings.dev_show_whitelisted_params')

def node(name,children=None,**kwargs):
    return {'name':name,'children':children or [],**kwargs}

def gate(expressions):
    """Classify only unambiguous flag conjunctions; do not evaluate arbitrary QML."""
    for expr in expressions:
        s=str(expr)
        if any(f in s for f in FLAGS) and '||' not in s:
            return 'normal' if any('!'+f in s for f in FLAGS) else 'advanced'
    return 'both'

def rawparam(pid,meta=None):
    meta=copy.deepcopy(meta or allparams.get(pid,{}))
    hidden=meta.get('hidden',False) or pid in ('WB_N_CARDS','WB_N_RX_CARDS') or pid.startswith(('TX_POWER_I_','TX_POWER_IA_','TX_POWER_MW_','TX_POWER_MWA_','CARD_TYPE_'))
    return node(meta.get('label') or pid,parameter=pid,mode='advanced' if hidden else 'both',conditional=True,details=meta,kind='parameter')

def control(e):
    e=copy.deepcopy(e)
    if e.get('parameter') in allparams:
        meta=allparams[e['parameter']]
        for k in ('choices','minimum','maximum','description','readOnly','requiresReboot'):
            if k in meta:e.setdefault('parameter_'+k,meta[k])
    mode='advanced' if e.get('advanced_only') else gate(e.get('visible_when',[]))
    if 'Show Retransmission Stats' in e['name']:mode='advanced'
    # Existence of quick controls is independent of the raw-model hidden filter.
    dynamic={'parameter':e.get('parameter'),'mode':mode,'details':e,'kind':'control','conditional':bool(e.get('visible_when') or e.get('enabled_when'))}
    if e.get('parameter')=='TX_PWR_LVL' and 'WifiBroadcastLinkCard' in e.get('source',''):
        dynamic['optionsByMode']={'normal':'Slider 0–100%, step 10%','advanced':'Slider 0–150%, step 10%; detent at 100%'}
    return node(e['name'],**dynamic)

def convert(name,obj):
    children=[]
    for e in obj.get('settings_and_actions',[]):
        if e.get('parameter')=='model.unique_id' or e.get('name')=='warning_whitelisted':continue
        if e.get('control') in ('AdvancedTabButton','TabButton'):continue
        children.append(control(e))
    for title,sub in obj.get('submenus',{}).items():children.append(convert(title,sub))
    details={k:obj[k] for k in ('source','availability','runtime_parameters','content') if k in obj}
    return node(name,children,details=details,kind='menu')

# Discover which component declares parameters. Shared transport declarations stay conditional.
fw=Path('../OpenHD'); sources={}; constants={}
files=[p for base in ['ohd_common','ohd_interface','ohd_telemetry','ohd_video'] for p in (fw/base).rglob('*') if p.suffix in ('.cpp','.h','.hpp') and not any(s in p.parts for s in ('lib','test','tests','nexmon')) and p.name!='openhd_settings_imp.cpp']
def uncomment(s):
    return re.sub(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|//[^\n]*|/\*[\s\S]*?\*/',lambda m: ''.join('\n' if c=='\n' else ' ' for c in m[0]) if m[0].startswith(('//','/*')) else m[0],s)
texts={p:uncomment(p.read_text(encoding='utf8',errors='replace')) for p in files}
for p,t in texts.items():
    for m in re.finditer(r'\b(?:constexpr\s+(?:auto|char\s*\*)|const\s+char\s*\*)\s+(\w+)\s*=\s*"([A-Z][A-Z0-9_]{0,15})"',t):constants.setdefault(m[1],set()).add(m[2])
pattern=re.compile(r'(?:\b(?:openhd::)?Setting\s*[{(]|\b(?:openhd::)?create_read_only_(?:int|string)\s*\()\s*("[A-Z][A-Z0-9_]*"|(?:\w+::)*[A-Z][A-Z0-9_]*)\s*[,)]')
for p,t in texts.items():
    for match in pattern.finditer(t):
        token=match[1];vals=[token.strip('"')] if token.startswith('"') else constants.get(token.split('::')[-1],set())
        if len(vals)==1:
            pid=next(iter(vals));sources.setdefault(pid,[]).append(p.as_posix())
for pid,m in extra.items():
    sources.setdefault(pid,[]).extend(x.rsplit(':',1)[0] for x in m.get('firmware_sources',[]))

def component_for(path):
    s=path.lower()
    if '/ohd_video/' in s:return 'air' if 'ohd_video_air.cpp' in s else 'camera'
    if 'groundtelemetry' in s:return 'ground'
    if 'airtelemetry' in s:return 'air'
    return 'shared'

def fallback_group(pid):
    for prefix,g in [('DEV_','DEVOURER'),('AR_','ARTOSYN'),('MICROHARD_','MICROHARD'),('MH_','MICROHARD'),('TX_POWER','TX POWER'),('TX_PWR','TX POWER'),('WB_RTX_','RETRANSMISSION'),('WB_UDP_','UDP DATALINK'),('WIFI_','NETWORK'),('ETHERNET','NETWORK'),('HOTSPOT_','NETWORK'),('NW_','NETWORK'),('V_','VIDEO')]:
        if pid.startswith(prefix):return g
    if pid=='WB_ENABLE_RETRA':return 'RETRANSMISSION'
    return 'GENERAL'

nav=inventory['Advanced']['submenus']
advanced=[convert('OSD' if name.startswith('OSD /') else name,obj) for name,obj in nav.items()]
openhd=next(n for n in advanced if n['name']=='OpenHD')
ohd={n['name']:n for n in openhd['children']}
# Raw Air/Ground parameter rows belong inside the actual parameter-group menus.
assigned=set()
for role,title in [('air','AIR'),('ground','GROUND')]:
    groups={}
    for pid,paths in sorted(sources.items()):
        components={component_for(p) for p in paths}
        if role not in components and 'shared' not in components:continue
        if pid in ('IP_CAM_ADDRESS','IP_CAM_PIPELINE') or (title=='AIR' and pid=='ACTIVE_LINKS'):continue
        meta=allparams.get(pid,{})
        n=rawparam(pid,meta);n['details']['placement_basis']=paths
        n['details']['availability']='Source declares this parameter for this component or shared transport. Runtime role, hardware and firmware decide whether it is reported.'
        g=meta.get('group') or fallback_group(pid)
        groups.setdefault(g,[]).append(n);assigned.add(pid)
    target=ohd[title]
    target['children']=[node(g,rows,kind='menu') for g,rows in groups.items()]+target['children']
    target['details']['note']='Groups follow fallback metadata; device metadata may rename groups or override options. Shared transport declarations are candidates, not a live endpoint export.'

# Camera selectors and categoryFor(id), including camera-specific firmware parameters.
cam_original=nav['OpenHD']['submenus']['CAMERA']
camids=set()
for sub in cam_original.get('submenus',{}).values():camids.update(sub.get('catalog_parameter_candidates',{}))
camids.update(pid for pid,paths in sources.items() if any(component_for(p)=='camera' for p in paths))
camids.update(['CAMERA_TYPE','SENSOR_MODE'])
def camera_category(pid):
    if pid in ['IP_CAM_ADDRESS','IP_CAM_PIPELINE']:return 'IP CAMERA'
    if pid in ['AIR_RECORDING_E','STREAMING_E','BITRATE_MBITS','VIDEO_CODEC','KEYFRAME_I','RESOLUTION_FPS']:return 'VIDEO'
    if 'AWB'in pid or 'WHITE_BALANCE'in pid:return 'COLOR'
    if any(x in pid for x in ['EXP','SHUTTER','METERING']) or pid=='ISO':return 'EXPOSURE'
    if any(x in pid for x in ['BRIGHTNESS','CONTRAST','SATURATION','SHARPNESS','DENOISE']):return 'IMAGE'
    if pid in ['CAMERA_TYPE','ROCKCHIP_IMPL','ROTATION_FLIP','ROTATION_DEG']:return 'CAMERA'
    return 'ADVANCED'
qrow=Qml('qml/ui/configpopup/openhd_settings/CameraSettingRow.qml')
friendly={m[1]:json.loads(m[2]) for m in re.finditer(r'"([A-Z0-9_]+)":\s*qsTr\(("(?:\\.|[^"\\])*")\)',qrow.text.split('function friendlyName',1)[1].split('function ',1)[0])}
cameras=[]
for camname in ['CAMERA 1','CAMERA 2']:
    cats={c:[] for c in ['VIDEO','CAMERA','IMAGE','COLOR','EXPOSURE','IP CAMERA','ADVANCED']}
    for pid in sorted(camids):
        if camera_category(pid)=='IP CAMERA':continue # Dedicated IP connection controls replace these raw rows.
        n=rawparam(pid);n['name']=friendly.get(pid,n['name'])
        if pid in ('SENSOR_MODE','LIBCAMERA_IMPL'):n['mode']='advanced'
        if pid=='RESOLUTION_FPS':
            n['children'].append(node('Frame rate',mode='advanced',conditional=True,details={'options':'Supported frame rates for selected resolution','source':'qml/ui/configpopup/openhd_settings/CameraSettingRow.qml:452'},kind='control'))
        cats[camera_category(pid)].append(n);assigned.add(pid)
    # VARIABLE_BITRATE is a dedicated quick toggle from the Air model, so normal mode still shows it.
    cats['VIDEO'].insert(0,node('Variable bitrate',parameter='VARIABLE_BITRATE',mode='both',conditional=True,details=catalog.get('VARIABLE_BITRATE',{}),kind='control'))
    ip=convert('IP CAMERA',cam_original['submenus']['IP CAMERA']);cats['IP CAMERA']=ip['children']
    cameras.append(node(camname,[node(k,v,kind='menu') for k,v in cats.items()],kind='menu',conditional=True,details={'availability':'Only parameters reported by selected camera; Camera 2 additionally requires secondary-camera parameters. Empty categories are hidden by the application.','source':'qml/ui/configpopup/openhd_settings/CameraDualPanel.qml'}))
ohd['CAMERA']['children']=cameras
# Keep row editor templates out of navigation; real camera rows now contain the settings.
# Distinguish navigation destinations from dialogs.
for n in advanced:
    if n['name']=='Developer tools (version label)':n['name']='Developer tools · version label'

# Sidebar nodes are read from the actual panel components and choice models.
mapped=Qml('qml/ui/sidebar/MappedMavlinkChoices.qml')
models={}
for name,n in mapped.byid.items():
    if n.kind=='ListModel':models[name]=[{k:scalar(v) for k,v in c.props.items()} for c in n.children if c.kind=='ListElement']
maptext=uncomment(mapped.text)
model_for={}
for match in re.finditer(r'param_id\s*==+\s*"(\w+)"\s*\)\s*\{?\s*return\s+(\w+)\s*;',maptext):model_for[match[1]]=match[2]
side_controls={'MavlinkChoiceElement2','MavlinkChoiceElement','MavlinkSwitch','PowerChoiceElement','PitModeElement','ActionElement','BaseJoyEditElement2','Switch','Button','Slider','SpinBox','ComboBox','CheckBox','InfoElement2'}
side=[]
for filename in ['Panel8FindAirUnit','Panel1Link','Panel2Video','Panel3Camera','Panel4Recording','Panel5RC','Panel6Misc','Panel7Status']:
    q=Qml('qml/ui/sidebar/'+filename+'.qml');root=q.nodes[0]
    panel=node(scalar(root.props.get('override_title',json.dumps(filename))),kind='menu',details={'source':q.path.as_posix()})
    for n in q.nodes:
        if n.kind not in side_controls:continue
        parent=n.parent;conds=[]
        while parent:
            if 'visible'in parent.props:conds.append(parent.props['visible'])
            parent=parent.parent
        if 'visible'in n.props:conds.append(n.props['visible'])
        title=label(n.props.get('m_title') or n.props.get('text') or n.props.get('override_text_left')) or scalar(n.props.get('m_title') or n.props.get('id') or json.dumps(n.kind))
        pid=scalar(n.props.get('m_param_id'))
        aliases={'mPARAM_ID_FREQUENCY':'WB_FREQUENCY','mPARAM_ID_CHANNEL_WIDTH':'WB_CHANNEL_W','mPARAM_ID_RATE':'WB_MCS_INDEX'}
        pid=aliases.get(pid,pid)
        base={'source':q.source(n),'control':n.kind,'visible_when':conds}
        if 'm_settings_model'in n.props:base['model']=n.props['m_settings_model']
        if 'enabled'in n.props:base['enabled_when']=n.props['enabled']
        if pid in allparams:base['parameter_metadata']=allparams[pid]
        lookup={'WB_FREQUENCY':'FREQUENCY','WB_CHANNEL_W':'CHANNEL_WIDTH','WB_MCS_INDEX':'RATE'}.get(pid,pid)
        chosen=models.get(model_for.get(lookup,''))
        if chosen:base['options']=chosen
        if pid=='RESOLUTION_FPS':base['options']='Device metadata or supported camera resolutions; Arducam HDR: 1280x720@30 / 1920x1080@30'
        if pid=='WB_FREQUENCY':base['options']='Ground-supported frequencies; selected frequency filter and camera/platform restrictions apply'
        if pid=='WB_CHANNEL_W':base['options']='20 / 40 MHz; 10 MHz when supported'
        if n.kind in ('Switch','CheckBox'):base['options']=[False,True]
        for key in ('from','to','stepSize'):
            if key in n.props:base[key]=scalar(n.props[key])
        # Repeater delegates become concrete rows, keeping their exact per-row conditions.
        if n.props.get('m_param_id')=='modelData[1]':
            rep=n.parent
            while rep and rep.kind!='Repeater':rep=rep.parent
            entries=re.findall(r'\["([^"]+)",\s*"([A-Z0-9_]+)"\]',rep.props.get('model','')) if rep else []
            for title,pid2 in entries:
                d=copy.deepcopy(base);d['parameter_metadata']=allparams.get(pid2,{});d['visible_when'].append('VEYE GX camera' if pid2.startswith('GX_') else 'Arducam camera')
                if pid2 in ['ISP_EXPOSURE_US','ISP_GAIN']:d['visible_when'].append('Manual exposure')
                if pid2=='ISP_AE_PROFILE':d['visible_when'].append('Auto exposure and ISP_AE_PROFILE reported')
                if pid2=='ISP_WB_K':d['visible_when'].append('Manual white balance')
                opts=models.get(model_for.get(pid2,''))
                if opts:d['options']=opts
                panel['children'].append(node(title,parameter=pid2,mode='both',conditional=True,details=d,kind='control'))
            continue
        item=node(str(title).replace('\n',' / '),parameter=pid,mode=gate(conds),conditional=bool(conds or pid),details=base,kind='control')
        if n.kind=='PowerChoiceElement':
            item['name']='Power';item['parameter']='TX_PWR_LVL'
            item['details']['target']=['Air','Ground']
            item['optionsByMode']={'normal':'0%, 20%, 40%, 60%, 80%, 100%','advanced':'0%, 20%, 40%, 60%, 80%, 100%, 110%, 120%, 130%, 140%, 150%'}
            item['details']['source']='qml/ui/sidebar/PowerChoiceElement.qml:37'
        if n.kind=='PitModeElement':item['name']='Pit mode';item['parameter']='WB_PIT_MODE';item['details']['options']=['Off','On']
        if filename=='Panel8FindAirUnit':
            if title=='Channels':item['details']['options']=['OpenHD [1–7]','2.4G','5.8G']
            if title=='Bandwidth':item['details']['options']='20 / 40 MHz; 10 MHz when ground supports it and passive Nexmon scanning is off'
        panel['children'].append(item)
    if filename=='Panel3Camera':
        preview=node('Colour tuning preview (Windows)',conditional=True,kind='menu',details={'visible_when':'_qopenhd.is_windows()','source':'qml/ui/sidebar/ColorPreviewControls.qml'})
        for title,opts in [('Enable colour preview',[False,True]),('Temperature (relative K)',{'from':2000,'to':12000,'step':100}),('Red gain',{'from':.25,'to':4,'step':.01}),('Green gain',{'from':.25,'to':4,'step':.01}),('Blue gain',{'from':.25,'to':4,'step':.01}),('Reset / bypass','action'),('Export findings','action')]:preview['children'].append(node(title,kind='control',details={'options':opts}))
        panel['children'].insert(7,preview)
    if filename=='Panel5RC':panel['children'].append(node('RC channels 1–4',kind='readout',details={'options':'Live yaw / roll / pitch / throttle values; source chosen by control_widget_use_fc_channels'}))
    if filename=='Panel4Recording':panel['children'].append(node('Status',kind='readout',details={'options':'Current air-unit recording state'}))
    side.append(panel)
side.insert(0,node('Sidebar icon · press and hold',[node('Sidebar Icon Size',kind='control',details={'range':'0.5–2.0, step 0.1','source':'qml/ui/sidebar/SideBarMain.qml:299'}),node('Reset',kind='control',details={'options':'Reset icon scale to 1.0'})],kind='menu'))

# A complete reference remains available, while the menu view contains concrete placements.
reference=[]
for g in dict.fromkeys(meta.get('group','General') for meta in catalog.values()):
    reference.append(node(g,[rawparam(pid,meta) for pid,meta in catalog.items() if meta.get('group','General')==g],kind='menu'))
reference.append(node('Additional firmware parameters',[rawparam(pid,meta) for pid,meta in extra.items()],kind='menu'))
reference.append(node('Generated per-device parameters',[node(pid,mode='advanced' if pid!='AUD_DEV_0..7' else 'both',conditional=True,kind='parameter',details={'description':desc}) for pid,desc in inventory['dynamic_parameter_families'].items()],kind='menu'))
# Match component nesting for status, mLRS and audio playback.
status=advanced[0]
actions=next((n for n in status['children'] if n['name']=='Status card actions'),None)
byname={n['name']:n for n in status['children']}
if actions:
    cards=[]
    for name,old,allowed in [('Ground station','Ground status',['WiFi hotspot','REBOOT','SHUTDOWN']),('Air unit','Air status',['WiFi hotspot','Request FC Rates','REBOOT','SHUTDOWN']),('Flight controller','Flight controller',['CRAFT DETAILS'])]:
        card=byname.get(old,node(name));card['name']=name
        card['children']=[copy.deepcopy(a) for a in actions['children'] if a['name'] in allowed]+card['children']
        card['conditional']=True;cards.append(card)
    status['children']=cards+[n for n in status['children'] if n['name'] in ['Power actions','Craft details']]
link=ohd['LINK']
link['children']=[n for n in link['children'] if n['name']!='STBC / LDPC'] # Uninstantiated legacy component.
mlrs=next((n for n in link['children'] if n['name']=='mLRS'),None)
rc=next(n for n in advanced if n['name']=='RC')
mlrs_controls=next((n for n in rc['children'] if n['name']=='mLRS settings (from overview)'),None)
if mlrs is not None and mlrs_controls:mlrs['children']=mlrs_controls['children']
rc['children']=[n for n in rc['children'] if n is not mlrs_controls]
extras=ohd['EXTRAS'];audio=next((n for n in extras['children'] if n['name']=='AUDIO'),None)
if audio:
    playback=[n for n in extras['children'] if n['kind']=='control']
    audio['children'].append(node('Received audio playback',playback,kind='menu'))
    extras['children']=[n for n in extras['children'] if n not in playback]

# Stable IDs let expansion state survive changes to filters and global mode.
def identify(nodes,prefix):
    for i,n in enumerate(nodes):
        n['id']=prefix+'/'+str(i)
        identify(n['children'],n['id'])
data={'advanced':advanced,'sidebar':side,'reference':reference,'unplaced':sorted(set(allparams)-assigned)}
for surface in ('advanced','sidebar','reference'):identify(data[surface],surface)

TEMPLATE=Path('tools/advanced_menu_explorer.template.html').read_text(encoding='utf8')
embedded=json.dumps(data,ensure_ascii=False,separators=(',',':')).replace('<','\\u003c').replace('\u2028','\\u2028').replace('\u2029','\\u2029')
Path('docs/advanced_menu_tree.html').write_text(TEMPLATE.replace('__MENU_DATA__',embedded),encoding='utf8')
print('Built docs/advanced_menu_tree.html from current menu layout and sidebar QML.')
