from pathlib import Path
import json,sys,math,xml.etree.ElementTree as ET
sys.path.insert(0,str(Path(__file__).resolve().parent.parent))
from logo_tools import svg,lettering,font_data,star
OUT=Path(__file__).resolve().parent
INK='#203B45'; CREAM='#FFF9ED'; BG='#F16C60'
def bird(x,y,r,color,kind,angle=0):
    body=f'M {-r} 20 C {-r-8} {-r*.75} {-r*.55} {-r} 0 {-r} C {r*.7} {-r} {r+8} {-r*.5} {r} 20 Q {r} {r} 0 {r} Q {-r} {r} {-r} 20Z'
    if kind=='mint':
        crest=f'<path d="M-22 {-r+5} Q-104 {-r-64} -115 {-r-23} Q-63 {-r-7} -22 {-r+5}Z" fill="#69BB93" stroke="{CREAM}" stroke-width="29" stroke-linejoin="round"/><path d="M-22 {-r+5} Q-104 {-r-64} -115 {-r-23} Q-63 {-r-7} -22 {-r+5}Z" fill="#69BB93" stroke="{INK}" stroke-width="6" stroke-linejoin="round"/>'
    elif kind=='orbit':
        crest=f'<path d="M-85 {-r+35} L-94 {-r-51} L-37 {-r+3} M85 {-r+35} L94 {-r-51} L37 {-r+3}" fill="{color}" stroke="{CREAM}" stroke-width="32" stroke-linejoin="round"/><path d="M-85 {-r+35} L-94 {-r-51} L-37 {-r+3} M85 {-r+35} L94 {-r-51} L37 {-r+3}" fill="{color}" stroke="{INK}" stroke-width="7" stroke-linejoin="round"/>'
    else:
        d=f'M-30 {-r+15} C-74 {-r-29} -43 {-r-40} -18 {-r-18} C-22 {-r-62} 14 {-r-64} 19 {-r-24} C49 {-r-55} 70 {-r-31} 38 {-r+14}'
        crest=f'<path d="{d}" fill="{color}" stroke="{CREAM}" stroke-width="31" stroke-linejoin="round"/><path d="{d}" fill="{color}" stroke="{INK}" stroke-width="7" stroke-linejoin="round"/>'
    eye=''
    for ex in [-36,36]:
        eye+=f'<ellipse cx="{ex}" cy="-19" rx="30" ry="37" fill="{CREAM}" stroke="{INK}" stroke-width="6"/><ellipse cx="{ex+5}" cy="-12" rx="12" ry="20" fill="{INK}"/><circle cx="{ex+1}" cy="-22" r="5" fill="white"/>'
    cheek=f'<ellipse cx="-70" cy="26" rx="17" ry="10" fill="#E7796B"/><ellipse cx="70" cy="26" rx="17" ry="10" fill="#E7796B"/>'
    beak=f'<path d="M-23 21 Q0 0 24 21 L0 47Z" fill="#F47D64" stroke="{INK}" stroke-width="6" stroke-linejoin="round"/>'
    detail=''
    if kind=='orbit':detail=star(-72,-60,12,CREAM,INK,0)
    return f'<g transform="translate({x} {y}) rotate({angle})">{crest}<path d="{body}" fill="{color}" stroke="{CREAM}" stroke-width="34"/><path d="{body}" fill="{color}" stroke="{INK}" stroke-width="7"/><ellipse cx="0" cy="91" rx="73" ry="45" fill="{CREAM}" opacity=".65"/>{eye}{cheek}{beak}{detail}</g>'

def flock():
    return bird(325,408,117,'#A8D8B4','mint',-13)+bird(872,409,115,'#B9AAF2','orbit',12)+bird(485,316,128,'#FFD45B','pip',-6)+bird(711,329,122,'#FF9BAD','peaches',8)

def arctext(text,cx,base,size,fill):
    f,gs,cmap,u=font_data('Fredoka',650)
    adv=[gs[cmap[ord(c)]].width*size/u for c in text]; total=sum(adv); cursor=-total/2; parts=''
    for c,w in zip(text,adv):
        mid=cursor+w/2; py=base+21*(mid/(total/2))**2; angle=8*mid/(total/2)
        parts+=f'<g transform="translate({cx+mid} {py}) rotate({angle})">'+lettering(c,0,0,size,fill=fill)+'</g>'
        cursor+=w
    return parts
fl=flock()
# Continuous lower sticker supports a compact, highly legible two-line game title.
plaque=f'<path d="M214 488 Q590 425 986 485 L1002 657 Q1007 759 922 785 Q592 856 285 785 Q196 764 199 686Z" fill="{INK}" stroke="{CREAM}" stroke-width="23" stroke-linejoin="round"/>'
# Small feather tabs unite the four characters visually with the nameplate.
wings=f'<path d="M238 486 Q201 440 231 414 Q267 417 298 477 M904 479 Q938 416 966 430 Q985 463 956 492" fill="#A8D8B4" stroke="{INK}" stroke-width="7" stroke-linejoin="round"/>'
words=arctext('PUSH-UP',600,631,156,CREAM)+arctext('BIRD',600,781,200,'#FFD45B')
accent=star(170,303,24,CREAM,CREAM,0)+star(1038,303,23,'#FFD45B',CREAM,7)+f'<path d="M170 455L145 442M1007 171L1020 146" stroke="{CREAM}" stroke-width="11" stroke-linecap="round"/>'
logo=svg(accent+fl+plaque+words,BG)
(OUT/'logo.svg').write_text(logo)
# The four-bird roster doubles as a recognizable standalone squad badge.
mark=svg('<g transform="translate(-83 178) scale(.99)">'+fl+'</g>',BG,width=1024,height=1024)
(OUT/'mark.svg').write_text(mark)
(OUT/'concept.json').write_text(json.dumps({'id':8,'name':'Flock Friends','rationale':'Pip, Minty, Peaches and Orbit huddle above a bold rising wordmark, turning the playable roster into a warm four-color sticker emblem.','theme':'Character camaraderie / collectible squad sticker','palette':[BG,INK,CREAM,'#FFD45B','#A8D8B4','#FF9BAD','#B9AAF2']},indent=2)+'\n')
ET.fromstring(logo);ET.fromstring(mark)
print(OUT)
