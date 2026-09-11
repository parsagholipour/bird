#!/usr/bin/env python3
"""Check actual camera startup in a CAMERA_LAB build on a connected phone.

The idle UI supplies the Start button. Once camera updates begin, use the lab's
one-second packet diagnostics: UIAutomator cannot reliably dump that busy UI.
"""
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET


def adb(*args):
    return subprocess.check_output(['adb', *args], text=True, timeout=15)


def logs(pid):
    return adb('logcat', '-d', '--pid=' + pid, '-v', 'brief',
               'flutter:I', 'PushUpBird:I', '*:S').splitlines()


pid = adb('shell', 'pidof', 'com.ravanix.push_up_bird').strip()
if not pid:
    sys.exit('FAIL: open the camera lab first')
adb('shell', 'uiautomator', 'dump', '/sdcard/push-up-bird-smoke.xml')
root = ET.fromstring(adb('exec-out', 'cat', '/sdcard/push-up-bird-smoke.xml'))
button = next((n for n in root.iter('node') if
               (n.get('content-desc') or n.get('text')) in
               ('Start camera', 'Recalibrate')), None)
if button is None:
    sys.exit('FAIL: open the camera lab before running this check')
x1, y1, x2, y2 = map(int, re.findall(r'\d+', button.get('bounds')))
baseline = len(logs(pid))
adb('shell', 'input', 'tap', str((x1+x2)//2), str((y1+y2)//2))
deadline = time.monotonic() + 12
while time.monotonic() < deadline:
    time.sleep(.5)
    recent = logs(pid)[baseline:]
    if any('PushUpBird pose:' in line for line in recent):
        print('PASS: native camera and pose detector delivered a fresh Dart packet')
        sys.exit(0)
    failures = [line for line in recent if 'Detector initialization failed' in line]
    if failures:
        sys.exit('FAIL: ' + failures[0])
sys.exit('FAIL: no fresh pose packet within camera startup deadline')
