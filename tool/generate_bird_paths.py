#!/usr/bin/env python3
"""Compile the bird SVGs in design/ into cached Flutter paths; no runtime parser.

Every bird is a 256 x 224 SVG that shares Pip's layer conventions:

* Shapes (`path`, `ellipse`, `circle`) are drawn in document order. Fills and
  strokes use plain hex colours; `opacity`, `fill-opacity` and `stroke-opacity`
  are honoured, as are `transform` attributes on shapes and groups.
* `clip-path="url(#id)"` on a shape or group clips it to a `<clipPath>` from
  `<defs>`, so markings can follow the body outline exactly.
* Shapes inside `<g id="Wing">` form the wing, which is recorded separately and
  rotated around the `Wing pivot` circle.
* Shapes inside `<g id="Eyes">` hide while the eyes are closed. Ids ending in
  `pupil` or `catchlight` that start with `Face / Near` or `Face / Far` shrink
  towards their pupil's centre when startled.
* The hidden `<g id="Rig">` holds the `Wing pivot` circle and the `Blink`,
  `Pleased` and `Startled` overlays. Closed eyes replace the eye group where it
  sits; the startled brows are drawn on top of everything.
"""
from pathlib import Path
import math
import re
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
BIRDS = ['pip', 'peaches', 'minty', 'orbit']
NAMED = {'white': 'ffffff', 'black': '000000'}
KAPPA = 0.5522847498307936


def number(value):
    text = f'{value:.4f}'.rstrip('0').rstrip('.')
    return '0' if text in ('-0', '') else text


def color(value, opacity):
    value = value.strip().lower()
    value = NAMED.get(value, value.lstrip('#'))
    if len(value) == 3:
        value = ''.join(c * 2 for c in value)
    if not re.fullmatch(r'[0-9a-f]{6}', value):
        raise ValueError(f'Unsupported colour: {value}')
    alpha = round(max(0.0, min(1.0, opacity)) * 255)
    return f'const Color(0x{alpha:02x}{value})'


def multiply(a, b):
    """Composes affine matrices (a, b, c, d, e, f) as a after b."""
    return (
        a[0] * b[0] + a[2] * b[1], a[1] * b[0] + a[3] * b[1],
        a[0] * b[2] + a[2] * b[3], a[1] * b[2] + a[3] * b[3],
        a[0] * b[4] + a[2] * b[5] + a[4], a[1] * b[4] + a[3] * b[5] + a[5],
    )


IDENTITY = (1.0, 0.0, 0.0, 1.0, 0.0, 0.0)


def parse_transform(text):
    matrix = IDENTITY
    for name, raw in re.findall(r'(\w+)\s*\(([^)]*)\)', text or ''):
        args = [float(v) for v in re.split(r'[\s,]+', raw.strip()) if v]
        if name == 'translate':
            step = (1, 0, 0, 1, args[0], args[1] if len(args) > 1 else 0)
        elif name == 'scale':
            sy = args[1] if len(args) > 1 else args[0]
            step = (args[0], 0, 0, sy, 0, 0)
        elif name == 'rotate':
            angle = math.radians(args[0])
            cos, sin = math.cos(angle), math.sin(angle)
            step = (cos, sin, -sin, cos, 0, 0)
            if len(args) == 3:
                cx, cy = args[1], args[2]
                step = multiply((1, 0, 0, 1, cx, cy),
                                multiply(step, (1, 0, 0, 1, -cx, -cy)))
        elif name == 'matrix':
            step = tuple(args)
        else:
            raise ValueError(f'Unsupported transform: {name}')
        matrix = multiply(matrix, step)
    return matrix


def apply(matrix, x, y):
    return (matrix[0] * x + matrix[2] * y + matrix[4],
            matrix[1] * x + matrix[3] * y + matrix[5])


def path_segments(data):
    """Absolute segments [(method, [x, y, ...])] from SVG path data."""
    tokens = re.findall(r'[A-Za-z]|-?(?:\d*\.\d+|\d+)(?:e[-+]?\d+)?', data)
    counts = {'M': 2, 'L': 2, 'H': 1, 'V': 1, 'C': 6, 'Q': 4, 'Z': 0}
    segments, index, command = [], 0, None
    x = y = start_x = start_y = 0.0
    while index < len(tokens):
        if re.fullmatch(r'[A-Za-z]', tokens[index]):
            command = tokens[index]
            index += 1
        if command is None or command.upper() not in counts:
            raise ValueError(f'Unsupported SVG command: {command}')
        upper, relative = command.upper(), command.islower()
        count = counts[upper]
        args = [float(v) for v in tokens[index:index + count]]
        if len(args) != count:
            raise ValueError('Incomplete SVG path')
        index += count
        if upper == 'Z':
            segments.append(('close', []))
            x, y = start_x, start_y
            continue
        if upper == 'H':
            args = [args[0] + (x if relative else 0), y]
            upper = 'L'
        elif upper == 'V':
            args = [x, args[0] + (y if relative else 0)]
            upper = 'L'
        elif relative:
            args = [v + (x if i % 2 == 0 else y) for i, v in enumerate(args)]
        x, y = args[-2], args[-1]
        if upper == 'M':
            start_x, start_y = x, y
            segments.append(('moveTo', args))
            # Further pairs after a move are implicit line segments.
            command = 'l' if relative else 'L'
        else:
            segments.append(({'L': 'lineTo', 'C': 'cubicTo',
                              'Q': 'quadraticBezierTo'}[upper], args))
    return segments


def ellipse_segments(cx, cy, rx, ry):
    kx, ky = rx * KAPPA, ry * KAPPA
    return [
        ('moveTo', [cx + rx, cy]),
        ('cubicTo', [cx + rx, cy + ky, cx + kx, cy + ry, cx, cy + ry]),
        ('cubicTo', [cx - kx, cy + ry, cx - rx, cy + ky, cx - rx, cy]),
        ('cubicTo', [cx - rx, cy - ky, cx - kx, cy - ry, cx, cy - ry]),
        ('cubicTo', [cx + kx, cy - ry, cx + rx, cy - ky, cx + rx, cy]),
        ('close', []),
    ]


def transformed(segments, matrix):
    if matrix == IDENTITY:
        return segments
    output = []
    for method, args in segments:
        points = []
        for i in range(0, len(args), 2):
            points.extend(apply(matrix, args[i], args[i + 1]))
        output.append((method, points))
    return output


def centre(segments):
    xs = [a for _, args in segments for a in args[0::2]]
    ys = [a for _, args in segments for a in args[1::2]]
    return (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2


def path_code(segments, even_odd):
    output = ['Path()']
    if even_odd:
        output.append('..fillType = PathFillType.evenOdd')
    for method, args in segments:
        output.append(f'..{method}({", ".join(number(a) for a in args)})')
    return '\n            '.join(output)


def shape_segments(element, matrix):
    tag = element.tag.split('}')[-1]
    attributes = element.attrib
    if tag == 'path':
        segments = path_segments(attributes['d'])
    elif tag == 'ellipse':
        segments = ellipse_segments(
            float(attributes.get('cx', 0)), float(attributes.get('cy', 0)),
            float(attributes['rx']), float(attributes['ry']))
    elif tag == 'circle':
        radius = float(attributes['r'])
        segments = ellipse_segments(
            float(attributes.get('cx', 0)), float(attributes.get('cy', 0)),
            radius, radius)
    else:
        return None
    return transformed(segments, matrix)


def layer_code(element, segments, eye, clip):
    attributes = element.attrib
    opacity = float(attributes.get('opacity', 1))
    options = []
    for key in ['fill', 'stroke']:
        value = attributes.get(key, 'none').lower()
        if value != 'none':
            alpha = opacity * float(attributes.get(f'{key}-opacity', 1))
            options.append(f'{key}: {color(value, alpha)}')
    if 'stroke' in attributes:
        options.append(f'strokeWidth: {attributes.get("stroke-width", "1")}')
        if attributes.get('stroke-linecap') == 'round':
            options.append('roundCap: true')
        if attributes.get('stroke-linejoin') == 'round':
            options.append('roundJoin: true')
    if eye:
        options.append(f'eye: _BirdEye.{eye}')
    if clip:
        options.append(f'clip: {path_code(clip, False)}')
    even_odd = attributes.get('fill-rule') == 'evenodd'
    return ('_BirdLayer(\n            ' + path_code(segments, even_odd) +
            ',\n            ' + ',\n            '.join(options) + ',\n          ),')


def eye_role(identifier):
    name = identifier.lower()
    side = 'near' if 'near' in name else 'far' if 'far' in name else None
    if side and name.endswith('pupil'):
        return f'{side}Pupil'
    if side and name.endswith('catchlight'):
        return f'{side}Glint'
    return 'eye'


def compile_bird(name):
    groups = {key: [] for key in ['body', 'wing', 'Blink', 'Pleased', 'Startled']}
    rig = {}

    def visit(element, matrix, context, eyes, clip):
        attributes = element.attrib
        identifier = attributes.get('id', '')
        tag = element.tag.split('}')[-1]
        if tag in ('defs', 'clipPath'):
            return
        matrix = multiply(matrix, parse_transform(attributes.get('transform')))
        if reference := re.fullmatch(r'url\(#(.+)\)', attributes.get('clip-path', '')):
            clip = clips[reference.group(1)]
        if identifier == 'Wing':
            context = 'wing'
        elif identifier in ('Blink', 'Pleased', 'Startled'):
            context = identifier
        elif identifier == 'Eyes':
            eyes = True
        segments = shape_segments(element, matrix)
        if segments is not None:
            if identifier == 'Wing pivot':
                rig['pivot'] = centre(segments)
                return
            role = eye_role(identifier) if eyes else None
            if role in ('nearPupil', 'farPupil'):
                rig[role] = centre(segments)
            if context is None:
                raise ValueError(f'{name}: shape {identifier!r} outside a layer')
            groups[context].append(layer_code(element, segments, role, clip))
            return
        if identifier == 'Rig':
            context = 'rig'
        elif context is None and element.tag.endswith('}g'):
            context = 'body'
        for child in element:
            visit(child, matrix, context, eyes, clip)

    svg = ET.parse(ROOT / f'design/{name}.svg').getroot()
    clips = {}
    for definition in svg.iter():
        if definition.tag.endswith('}clipPath'):
            clips[definition.attrib['id']] = [
                segment for shape in definition
                for segment in shape_segments(
                    shape, parse_transform(shape.attrib.get('transform')))]
    for child in svg:
        visit(child, IDENTITY, None, False, None)
    for key in ['pivot', 'nearPupil', 'farPupil']:
        if key not in rig:
            raise ValueError(f'{name}: missing {key}')
    groups.pop('rig', None)

    def offset(point):
        return f'const Offset({number(point[0])}, {number(point[1])})'

    def layers(key):
        return '\n          '.join(groups[key])

    return f"""  // design/{name}.svg
  _BirdRig(
    wingPivot: {offset(rig['pivot'])},
    nearPupil: {offset(rig['nearPupil'])},
    farPupil: {offset(rig['farPupil'])},
    body: [
          {layers('body')}
    ],
    wing: [
          {layers('wing')}
    ],
    blink: [
          {layers('Blink')}
    ],
    pleased: [
          {layers('Pleased')}
    ],
    startled: [
          {layers('Startled')}
    ],
  ),"""


header = """// Generated from design/{pip,peaches,minty,orbit}.svg by
// tool/generate_bird_paths.py. Edit the SVGs and regenerate; do not edit here.
part of 'bird_puppet.dart';

final _birdRigs = <_BirdRig>[
"""
OUTPUT = ROOT / 'lib/game/bird_vector_paths.dart'
OUTPUT.write_text(
    header + '\n'.join(compile_bird(name) for name in BIRDS) + '\n];\n')
subprocess.run(['dart', 'format', str(OUTPUT)], check=True)
