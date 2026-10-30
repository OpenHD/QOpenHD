"""Build Qt 6 QML resources without changing the Qt 5 source resources."""
import argparse
import re
from pathlib import Path
from xml.etree import ElementTree as ET

p = argparse.ArgumentParser()
p.add_argument('source', type=Path)
p.add_argument('output', type=Path)
args = p.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
tree = ET.parse(args.source / 'qml.qrc')
for resource in tree.getroot().findall('qresource'):
    for file in resource.findall('file'):
        relative = file.text
        original = (args.source / relative).resolve()
        file.set('alias', file.get('alias', relative))
        if original.suffix == '.qml':
            content = original.read_text(encoding='utf-8')
            content = re.sub(r'(?m)^(import Qt[\w.]+)\s+\d+\.\d+', r'\1', content)
            if relative.endswith(('map/MapComponent.qml', 'map/OfflineMapSelection.qml')):
                # Qt 6 Map uses pointer handlers instead of MapGestureArea.
                content = re.sub(r'(?m)^\s*gesture\..*\n', '\n', content)
                enabled = '!root.drawing' if relative.endswith('OfflineMapSelection.qml') else 'true'
                stop_follow = '' if relative.endswith('OfflineMapSelection.qml') else 'followDrone = false;'
                handlers = '''
    property var qt6PinchCoordinate
    DragHandler {
        target: null
        enabled: ENABLED
        onActiveChanged: if (active) { STOP_FOLLOW }
        onTranslationChanged: (delta) => map.pan(-delta.x, -delta.y)
    }
    PinchHandler {
        id: qt6Pinch
        target: null
        enabled: ENABLED
        onActiveChanged: if (active) {
            STOP_FOLLOW
            map.qt6PinchCoordinate = map.toCoordinate(centroid.position, false)
        }
        onScaleChanged: (delta) => {
            map.zoomLevel += Math.log2(delta)
            map.alignCoordinateToPoint(map.qt6PinchCoordinate, centroid.position)
        }
        onRotationChanged: (delta) => {
            map.bearing -= delta
            map.alignCoordinateToPoint(map.qt6PinchCoordinate, centroid.position)
        }
        grabPermissions: PointerHandler.TakeOverForbidden
    }
    WheelHandler {
        enabled: ENABLED
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        rotationScale: 1 / 120
        property: "zoomLevel"
    }
'''.replace('ENABLED', enabled).replace('STOP_FOLLOW', stop_follow)
                content = re.sub(r'\bid: map\b', 'id: map\n' + handlers, content, count=1)
            if relative.endswith('MapWidgetForm.ui.qml'):
                content = re.sub(r'fragmentShader:\s*".*?"',
                    'fragmentShader: "qrc:/qt6-shaders/map-mask.frag.qsb"', content, flags=re.S)
            if relative.endswith('colorwheel/Wheel.qml'):
                for stage in ('vertex', 'fragment'):
                    suffix = 'vert' if stage == 'vertex' else 'frag'
                    content = re.sub(stage + r'Shader:\s*".*?"',
                        stage + f'Shader: "qrc:/qt6-shaders/color-wheel.{suffix}.qsb"', content, flags=re.S)
            destination = args.output / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_text(content, encoding='utf-8')
            file.text = str(destination)
        else:
            file.text = str(original)
tree.write(args.output / 'qml-qt6.qrc', encoding='utf-8')
