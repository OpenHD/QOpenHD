#!/usr/bin/env python3
"""Ground-only service condition, shared by the compositor and native UI."""
import json
from pathlib import Path
import sys

def enabled(root='/'):
    root = Path(root)
    if not (root / 'etc/qopenhd-rockchip/native-video-enabled').is_file():
        return False
    try:
        config = json.loads((root / 'usr/local/share/OpenHD/SysUtils/config.json').read_text())
    except FileNotFoundError:
        config = {}
    except (OSError, ValueError):
        return False
    if not isinstance(config, dict):
        return False
    mode = config.get('run_mode')
    if mode is not None:
        # SysUtils treats an absent/invalid mode as Ground; Air/Record disable UI.
        return str(mode).strip().lower() not in ('air', 'record')
    return not any((root / directory / 'openhd/air.txt').exists() for directory in ['Config', 'conf', 'boot'])


if __name__ == '__main__':
    sys.exit(0 if enabled() else 1)
