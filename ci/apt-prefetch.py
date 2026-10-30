"""Fetch signed APT-index packages concurrently, validating each SHA-256.

APT still resolves and installs packages; this only populates its archive cache.
"""
import argparse
import concurrent.futures
import hashlib
import os
from pathlib import Path
import re
import shlex
import subprocess
import time
import urllib.parse
import urllib.request

p = argparse.ArgumentParser()
p.add_argument('--container')
p.add_argument('--root', type=Path)
p.add_argument('--cache', type=Path, default=Path('/var/cache/apt/archives'))
p.add_argument('packages', nargs='+')
args = p.parse_args()
if args.container and args.root:
    p.error('Choose --container or --root')
prefix = ['docker', 'exec', args.container] if args.container else (['chroot', str(args.root)] if args.root else [])
def command(*cmd):
    return subprocess.check_output(prefix + list(cmd), text=True)

metadata = command('apt-cache', 'dumpavail')
hashes = {}
for paragraph in metadata.split('\n\n'):
    fields = dict(re.findall(r'(?m)^([\w-]+): (.*)$', paragraph))
    if 'Filename' in fields and 'SHA256' in fields:
        hashes[urllib.parse.unquote(Path(fields['Filename']).name)] = fields['SHA256']
del metadata
plan = command('apt-get', '-o', 'Debug::NoLocking=true', '--no-install-recommends',
               '--print-uris', '--yes', '--download-only', 'install', *args.packages)
args.cache.mkdir(parents=True, exist_ok=True)
files = []
for line in plan.splitlines():
    if not line.startswith("'"):
        continue
    url, filename, size = shlex.split(line)[:3]
    url = url.replace('http://', 'https://', 1)
    sha = hashes.get(urllib.parse.unquote(Path(urllib.parse.urlparse(url).path).name))
    if not sha:
        raise RuntimeError('No SHA-256 in authenticated APT metadata for ' + filename)
    destination = args.cache / filename
    if destination.exists() and hashlib.sha256(destination.read_bytes()).hexdigest() == sha:
        continue
    files.append((url, destination, int(size), sha))

chunk_size = 4 * 1024 * 1024
def fetch(url, start, end, destination):
    expected = end - start + 1
    if destination.exists() and destination.stat().st_size == expected:
        return
    for attempt in range(4):
        try:
            request = urllib.request.Request(url, headers={'Range': f'bytes={start}-{end}'})
            with urllib.request.urlopen(request, timeout=90) as response:
                if response.status != 206:
                    raise RuntimeError('Range response required: ' + url)
                with destination.open('wb') as output:
                    while block := response.read(128 * 1024):
                        output.write(block)
            if destination.stat().st_size != expected:
                raise RuntimeError('Truncated package range: ' + url)
            return
        except Exception:
            if attempt == 3:
                raise
            time.sleep(1 + attempt)

jobs = []
with concurrent.futures.ThreadPoolExecutor(max_workers=16) as pool:
    for url, destination, size, sha in files:
        for start in range(0, size, chunk_size):
            part = destination.with_name(destination.name + f'.range-{start}')
            jobs.append(pool.submit(fetch, url, start, min(size - 1, start + chunk_size - 1), part))
    for index, future in enumerate(concurrent.futures.as_completed(jobs), 1):
        future.result()
        if index % 25 == 0:
            print(f'APT download ranges: {index}/{len(jobs)}', flush=True)
for url, destination, size, sha in files:
    temporary = destination.with_suffix('.prefetch')
    digest = hashlib.sha256()
    with temporary.open('wb') as output:
        for start in range(0, size, chunk_size):
            part = destination.with_name(destination.name + f'.range-{start}')
            with part.open('rb') as source:
                while block := source.read(128 * 1024):
                    digest.update(block)
                    output.write(block)
    if digest.hexdigest() != sha:
        temporary.unlink()
        raise RuntimeError('APT SHA-256 mismatch: ' + destination.name)
    os.replace(temporary, destination)
    for start in range(0, size, chunk_size):
        destination.with_name(destination.name + f'.range-{start}').unlink()
print(f'Validated {len(files)} APT packages', flush=True)
