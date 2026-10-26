"""Reject Android packages/deployment settings without Qt 5's HTTPS libraries."""
import json
from pathlib import Path
import sys
import zipfile

path = Path(sys.argv[1])
required = {'libssl_1_1.so', 'libcrypto_1_1.so'}
if path.suffix in {'.apk', '.aab'}:
    with zipfile.ZipFile(path) as archive:
        found = {Path(name).name for name in archive.namelist() if '/lib/' in '/' + name}
else:
    value = json.loads(path.read_text()).get('android-extra-libs', [])
    entries = value.split(',') if isinstance(value, str) else value
    found = {Path(entry.strip()).name for entry in entries}
missing = required - found
if missing:
    raise SystemExit('Missing Android HTTPS runtime: ' + ', '.join(sorted(missing)))
print('Android HTTPS runtime verified:', path.name)
