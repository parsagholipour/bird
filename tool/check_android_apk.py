#!/usr/bin/env python3
"""Validate offline payload and 16KB ELF load alignment for every shipped ABI."""
import pathlib
import re
import subprocess
import sys
import tempfile
import zipfile
apk=pathlib.Path(sys.argv[1] if len(sys.argv)>1 else 'build/app/outputs/flutter-apk/app-release.apk')
failed=[]
with zipfile.ZipFile(apk) as z, tempfile.TemporaryDirectory() as tmp:
    names=z.namelist()
    for model in ['assets/pose_landmarker_lite.task','assets/face_landmarker.task']:
        if model not in names: failed.append('missing '+model)
    libs=[n for n in names if n.endswith('.so')]
    for name in libs:
        path=pathlib.Path(tmp)/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(z.read(name))
        header=subprocess.check_output(['readelf','-lW',str(path)],text=True)
        aligns=[int(line.split()[-1],16) for line in header.splitlines() if line.strip().startswith('LOAD ')]
        good=bool(aligns) and all(a>=16384 for a in aligns)
        print(('PASS' if good else 'FAIL')+' '+name+' LOAD alignments '+','.join(hex(a) for a in aligns))
        if not good: failed.append(name)
    print(f'{len(libs)} native libraries checked; both offline tracking models present.')
if failed: sys.exit('FAIL: '+', '.join(failed))
print('PASS: every native library supports 16KB ELF load alignment.')
