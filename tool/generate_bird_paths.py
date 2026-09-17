#!/usr/bin/env python3
"""Compile the existing Figma SVG into cached Flutter paths; no runtime parser."""
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
COLORS = {
    '#ffd45b': 'primary', '#e8a73c': 'secondary', '#fff9ed': 'cream',
    '#203b45': 'ink', '#d75e4f': 'coralDeep', '#f47d64': 'coral',
    'white': 'white', '#ffffff': 'white',
}
COMMANDS = {'M': ('moveTo', 2), 'L': ('lineTo', 2), 'C': ('cubicTo', 6),
            'Q': ('quadraticBezierTo', 4), 'Z': ('close', 0)}


def path_code(data):
    tokens = re.findall(r'[A-Za-z]|-?(?:\d*\.\d+|\d+)(?:e[-+]?\d+)?', data)
    output = ['Path()']
    index = 0
    while index < len(tokens):
        command = tokens[index]
        if command not in COMMANDS:
            raise ValueError(f'Unsupported SVG command: {command}')
        method, count = COMMANDS[command]
        arguments = tokens[index + 1:index + count + 1]
        if len(arguments) != count:
            raise ValueError('Incomplete SVG path')
        output.append(f'..{method}({", ".join(arguments)})')
        index += count + 1
    return '\n      '.join(output)


layers = []
for element in ET.parse(ROOT / 'design/pip.svg').iter():
    if not element.tag.endswith('}path'):
        continue
    attributes = element.attrib
    options = []
    for key in ['fill', 'stroke']:
        value = attributes.get(key, 'none').lower()
        if value != 'none':
            options.append(f'{key}: _BirdTone.{COLORS[value]}')
    if 'stroke' in attributes:
        options.append(f'strokeWidth: {attributes.get("stroke-width", "1")}')
        if attributes.get('stroke-linecap') == 'round':
            options.append('roundCap: true')
        if attributes.get('stroke-linejoin') == 'round':
            options.append('roundJoin: true')
    if attributes.get('id') in ['Vector_7', 'Vector_8']:
        options.append('wing: true')
    eyes = {
        'Face / Far eye': 'farEye', 'Face / Near eye': 'nearEye',
        'Face / Near pupil': 'nearPupil', 'Face / Far pupil': 'farPupil',
        'Face / Near catchlight': 'nearCatchlight', 'Face / Far catchlight': 'farCatchlight',
    }
    if attributes.get('id') in eyes:
        options.append(f'eye: _BirdEye.{eyes[attributes["id"]]}')
    layers.append('  _BirdLayer(\n    ' + path_code(attributes['d']) + ',\n    ' + ',\n    '.join(options) + ',\n  ),')

header = """// Generated from design/pip.svg by tool/generate_bird_paths.py.
// The geometry is the existing Figma bird; palette and motion are applied later.
part of 'bird_puppet.dart';

final _birdLayers = <_BirdLayer>[
"""
(ROOT / 'lib/game/bird_vector_paths.dart').write_text(header + '\n'.join(layers) + '\n];\n')
