"""Reject per-page menu font sizes; OSD rendering samples keep their native fonts."""
from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
allowed={('AppWidgetStyleSettingsView.qml','text:"OSD"'),('AppWidgetStyleSettingsView.qml','text:"OpenHD 0123456789"')}
failures=[]
for path in (root/'qml/ui/configpopup').rglob('*.qml'):
    for number,line in enumerate(path.read_text(encoding='utf-8').splitlines(),1):
        if re.search(r'font\.pixelSize\s*:\s*(?:\d|(?:MenuTypography|Typography)\.\w+\s*\+)',line):
            if not any(path.name==name and sample in line for name,sample in allowed):
                failures.append(f'{path.relative_to(root)}:{number}: use a shared typography role')
assert not failures,'\n'.join(failures)
map_button=(root/'qml/ui/configpopup/qopenhd_settings/MapActionButton.qml').read_text(encoding='utf-8')
assert 'AdvancedActionButton {}' in map_button,'Map must use the shared action button'
print('Shared menu font roles and action button inheritance verified')
