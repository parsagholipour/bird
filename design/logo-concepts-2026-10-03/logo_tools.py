"""Shared source artwork and outlined lettering for the logo exploration."""
from pathlib import Path
from functools import lru_cache
import re
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools.pens.svgPathPen import SVGPathPen

ROOT = Path(__file__).resolve().parents[2]

@lru_cache(None)
def font_data(family='Fredoka', weight=650):
    f = TTFont(ROOT / 'assets/fonts' / (family + '.ttf'))
    if 'fvar' in f:
        values = {a.axisTag: (weight if a.axisTag == 'wght' else a.defaultValue) for a in f['fvar'].axes}
        f = instantiateVariableFont(f, values, inplace=True)
    return f, f.getGlyphSet(), f.getBestCmap(), f['head'].unitsPerEm

def lettering(text, x, y, size, fill='#203B45', family='Fredoka', weight=650, anchor='middle', tracking=0, stroke=None, sw=0):
    f, gs, cmap, upem = font_data(family, weight)
    scale = size / upem
    advances = [gs[cmap.get(ord(c), '.notdef')].width * scale for c in text]
    width = sum(advances) + max(0,len(text)-1)*tracking
    start = x - (width/2 if anchor=='middle' else width if anchor=='end' else 0)
    parts=[]
    for c, advance in zip(text, advances):
        pen=SVGPathPen(gs)
        gs[cmap.get(ord(c),'.notdef')].draw(pen)
        attrs=f'fill="{fill}"'
        if stroke:
            attrs+=f' stroke="{stroke}" stroke-width="{sw/scale}" stroke-linejoin="round" paint-order="stroke fill"'
        parts.append(f'<path d="{pen.getCommands()}" transform="translate({start:.3f} {y}) scale({scale:.6f} {-scale:.6f})" {attrs}/>')
        start+=advance+tracking
    return '<g aria-label="'+text+'">'+''.join(parts)+'</g>'

def asset(name, x, y, width, prefix='asset'):
    raw=(ROOT/'design'/f'{name}.svg').read_text()
    match=re.search(r'viewBox="([^"]+)"', raw)
    _,_,w,h=map(float, match.group(1).split())
    inner=raw[raw.index('>')+1:raw.rindex('</svg>')]
    inner=re.sub(r'<g id="Rig"[\s\S]*?</g>\s*$', '', inner)
    inner=re.sub(r'id="([^"]+)"', lambda m:'id="'+prefix+'-'+re.sub(r'[^a-zA-Z0-9_-]','-',m.group(1))+'"',inner)
    inner=re.sub(r'url\(#([^\)]+)\)', lambda m:'url(#'+prefix+'-'+re.sub(r'[^a-zA-Z0-9_-]','-',m.group(1))+')',inner)
    inherited_fill = re.search(r'<svg[^>]*\bfill="([^"]+)"', raw)
    fill = inherited_fill.group(1) if inherited_fill else 'black'
    return f'<g fill="{fill}" transform="translate({x} {y}) scale({width/w})">{inner}</g>'

def svg(body, bg='#FFF9ED', width=1200, height=900):
    background=f'<rect width="{width}" height="{height}" fill="{bg}"/>' if bg else ''
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">{background}{body}</svg>'

def star(x,y,r=20,fill='#FFD45B',stroke='#203B45',sw=3):
    import math
    pts=[]
    for i in range(10):
        a=-math.pi/2+i*math.pi/5; radius=r if i%2==0 else r*.46
        pts.append(f'{x+math.cos(a)*radius:.2f},{y+math.sin(a)*radius:.2f}')
    return f'<polygon points="{" ".join(pts)}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round"/>'
