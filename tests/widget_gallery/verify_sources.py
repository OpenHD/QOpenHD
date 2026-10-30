"""Verify every gallery entry resolves to an existing production HUD widget."""
from pathlib import Path
import json,re
root=Path(__file__).resolve().parents[2]
catalog=(root/'qml/ui/configpopup/qopenhd_settings/WidgetCatalog.js').read_text()
widgets,_=json.JSONDecoder().raw_decode(catalog.split('var widgets = ',1)[1])
hud=(root/'qml/ui/HUDOverlayGrid.qml').read_text()
registry=hud.split('readonly property var widgetPreviewTargets: ({',1)[1].split('    })',1)[0]
sources=dict(re.findall(r'"([^"\n]+)": ([\w.]+)',registry))
ids=set(re.findall(r'\bid:\s*(\w+)',hud))
assert len(sources)==len(widgets)==57
assert set(sources)=={w['key'] for w in widgets}
assert all(target.split('.')[0] in ids for target in sources.values())
assert all('preview' not in w and 'sample' not in w for w in widgets)
print('PASS: all 57 gallery settings map to existing HUD widgets; no generic preview fixtures remain')
