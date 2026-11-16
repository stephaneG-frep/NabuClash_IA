#!/usr/bin/env python3
"""Package only this project's sources and its freshly built APK."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
import sys
import zipfile

root=Path(__file__).resolve().parents[1]
apk=root/'build/app/outputs/flutter-apk/app-release.apk'
subprocess.run([sys.executable,str(root/'tool/verify_apk.py'),str(apk)],check=True)
out=root/'delivery';out.mkdir(exist_ok=True)
shutil.copy2(apk,out/'NabuClash_AI_arm64_release.apk')
exclude={'.private','.git','.dart_tool','.idea','build','delivery','.gradle','.kotlin','__pycache__'}
files=[]
for p in sorted(root.rglob('*')):
    if not p.is_file() or set(p.relative_to(root).parts)&exclude:continue
    if p.name in {'local.properties','.flutter-plugins-dependencies'} or p.suffix in {'.jks','.keystore','.apk','.zip','.iml','.pyc'}:continue
    files.append(p)
manifest={str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
(out/'source_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
with zipfile.ZipFile(out/'NabuClash_AI_source.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in files:z.write(p,Path('NabuClash_IA')/p.relative_to(root))
    z.write(out/'source_manifest.json','NabuClash_IA/SOURCE_MANIFEST.json')
shutil.copy2(root/'README.md',out/'README.md')
checks=[]
for name in ['NabuClash_AI_arm64_release.apk','NabuClash_AI_source.zip','README.md']:
    p=out/name;checks.append(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {name}')
(out/'SHA256SUMS.txt').write_text('\n'.join(checks)+'\n')
print('\n'.join(checks))
