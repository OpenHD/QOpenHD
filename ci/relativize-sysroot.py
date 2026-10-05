#!/usr/bin/env python3
"""Keep absolute target links inside the sysroot without following directories."""
import os
from pathlib import Path
import sys

root = Path(sys.argv[1]).resolve()
for directory, dirs, files in os.walk(root, followlinks=False):
    for name in dirs + files:
        path = Path(directory, name)
        if path.is_symlink():
            target = os.readlink(path)
            if target.startswith('/'):
                relative = os.path.relpath(root / target.lstrip('/'), path.parent)
                path.unlink()
                path.symlink_to(relative)
