from pathlib import Path
import sys,json
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
sys.path.insert(0,str(Path(__file__).resolve().parent.parent))
from logo_tools import svg,star
OUT=Path(__file__).resolve().parent
INK='#203B45'; CORAL='#F47D64'; CREAM='#FFF9ED'
f=TTFont('/usr/share/fonts/opentype/urw-base35/Z003-MediumItalic.otf'); gs=f.getGlyphSet(); cmap=f.getBestCmap(); up=f['head'].unitsPerEm

def script(word,x,y,size):
    scale=size/up
    parts=[]
    for ch in word:
        name=cmap[ord(ch)]; pen=SVGPathPen(gs); gs[name].draw(pen)
        parts.append(f'<path d="{pen.getCommands()}" transform="translate({x} {y}) scale({scale} {-scale})" fill="{INK}" stroke="{INK}" stroke-width="13" stroke-linejoin="round"/>')
        x+=gs[name].width*scale-6
    return '<g>'+''.join(parts)+'</g>'
# Broad tapered swashes echo the pressure changes of a brush pen.
feather='''<g id="feather-hyphen"><path d="M525 361 C550 315 617 309 671 329 C644 347 627 376 574 379 L533 382 Z" fill="#F47D64"/><path d="M530 378 Q589 344 650 331" fill="none" stroke="#203B45" stroke-width="6" stroke-linecap="round"/><path d="M571 357 L568 333 M595 347 L599 325 M617 340 L627 325" fill="none" stroke="#FFF9ED" stroke-width="4" stroke-linecap="round"/></g>'''
body='''<ellipse cx="600" cy="487" rx="419" ry="269" fill="#FFEED8"/>
<path d="M247 346 C186 301 192 270 237 268 C275 266 282 300 257 324 C284 300 303 288 328 288 C279 328 261 341 247 346Z" fill="#F47D64"/>
'''
body+=script('Push',252,418,180)+feather+script('Up',687,418,180)
body+=script('Bird',392,625,244)
body+='''<path id="rising-swash" d="M337 639 C473 695 698 697 828 620 C884 586 911 546 934 507 C929 557 907 608 854 648 C739 735 480 752 328 678 C284 656 271 628 287 609 C282 626 307 632 337 639Z" fill="#F47D64"/>
<path d="M396 611 C355 632 332 630 302 625 C338 645 370 639 407 623 Z" fill="#203B45"/>
<path d="M481 402 Q444 426 384 416 Q423 432 476 422Z" fill="#203B45"/>
'''
body+=star(946,478,22,fill='#FFD45B',stroke=INK,sw=3)
body+=star(245,510,12,fill='#FFD45B',stroke='none',sw=0)
body+='<circle cx="918" cy="418" r="5" fill="#F47D64"/>'
(OUT/'logo.svg').write_text(svg(body))
mark='<path d="M104 291 C127 166 262 110 382 136 C333 180 331 257 219 281 L127 320 Z" fill="#F47D64"/><path d="M120 309 Q231 203 344 155" stroke="#203B45" stroke-width="12" fill="none" stroke-linecap="round"/>'+star(386,105,28,stroke=INK,sw=4)
(OUT/'mark.svg').write_text(svg(mark,width=512,height=512))
(OUT/'concept.json').write_text(json.dumps({'id':12,'name':'Feather Script','rationale':'Flowing brushlike script and a feather hyphen turn the title into an airy signature, with a rising coral swash carrying the arcade energy toward a star.','theme':'Playful retro script / flight','palette':[INK,CREAM,CORAL,'#FFD45B','#FFEED8']},indent=2))
import xml.etree.ElementTree as ET
ET.parse(OUT/'logo.svg'); ET.parse(OUT/'mark.svg')
