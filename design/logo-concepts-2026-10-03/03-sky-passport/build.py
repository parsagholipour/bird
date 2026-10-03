from pathlib import Path
import sys, math, json
sys.path.insert(0,str(Path(__file__).resolve().parent.parent))
from logo_tools import lettering, svg, star
D=Path(__file__).resolve().parent
INK='#203B45'; CREAM='#FFF9ED'; CORAL='#F47D64'
# The shallow, tightly spaced lobes recall a perforated passport stamp.
pts=[]
for i in range(720):
    a=2*math.pi*i/720
    r=340+5*math.cos(a*48)
    pts.append(f'{600+r*math.cos(a):.3f},{450+r*math.sin(a):.3f}')
seal=f'<path d="M'+ ' L'.join(pts)+' Z" fill="'+INK+'"/>'
seal+='<circle cx="600" cy="450" r="325" fill="'+CREAM+'"/><circle cx="600" cy="450" r="309" fill="none" stroke="'+INK+'" stroke-width="3"/><circle cx="600" cy="450" r="298" fill="none" stroke="'+CORAL+'" stroke-width="3" stroke-dasharray="1 12" stroke-linecap="round"/>'
# The travel globe is intentionally spare, leaving the bird and title dominant.
globe='''<g fill="none" stroke="#F47D64" stroke-width="4" stroke-linecap="round">
<circle cx="600" cy="316" r="112"/>
<ellipse cx="600" cy="316" rx="54" ry="112"/>
<path d="M488 316H712 M503 371Q600 329 697 371 M503 261Q600 303 697 261"/>
</g>'''
# Custom Pip silhouette: three crest feathers, plump flying body, beak and rising wing.
bird='''<g transform="translate(590 289) rotate(-8)">
<path d="M-43 22 C-88 24-104 0-115-16 C-92-17-75-10-57-3 C-70-48-51-75-41-74 C-27-73-19-47-8-31 C4-46 22-46 35-44 C29-55 33-65 39-63 L50-48 C50-68 59-72 65-66 L68-46 C76-61 85-59 84-51 L81-32 C111-17 109 21 88 39 C57 65 5 62-22 46 C-29 39-37 31-43 22 Z" fill="#203B45" stroke="#FFF9ED" stroke-width="9" stroke-linejoin="round"/>
<path d="M100-11L126 3L103 15Z" fill="#F47D64" stroke="#FFF9ED" stroke-width="5" stroke-linejoin="round"/>
<circle cx="78" cy="-6" r="6" fill="#FFF9ED"/>
<path d="M-10-2Q15 23 49 17Q32 46 1 33Q-16 26-10-2Z" fill="#F47D64"/>
</g>'''
seal+=globe+bird
# Wide cream strip clears the globe below and makes the title feel pressed in ink.
seal+='<path d="M362 453Q600 417 838 453L838 522Q600 500 362 522Z" fill="'+CREAM+'"/>'
seal+=lettering('PUSH-UP',600,528,104,INK,weight=650,tracking=0)
seal+=lettering('BIRD',600,657,164,INK,weight=650,tracking=5)
seal+=star(600,708,17,CORAL,CORAL,0)
seal+='<path d="M486 704H549 M651 704H714" stroke="'+CORAL+'" stroke-width="5" stroke-linecap="round"/>'
body='<g transform="rotate(-5 600 450)">'+seal+'</g>'
(D/'logo.svg').write_text(svg(body))
(D/'mark.svg').write_text(svg('<g transform="translate(-168 -51) scale(.78)">'+body+'</g>',width=600,height=600))
(D/'concept.json').write_text(json.dumps({'id':3,'name':'Sky Passport','rationale':'A scalloped passport seal turns Pip’s flights around the world into a collectible travel badge, with warm ink lettering and a coral globe.','theme':'Vintage travel stamp','palette':[INK,CREAM,CORAL]},indent=2)+'\n')
import xml.etree.ElementTree as ET
ET.parse(D/'logo.svg'); ET.parse(D/'mark.svg')
print(D)
