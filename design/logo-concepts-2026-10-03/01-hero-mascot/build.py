from pathlib import Path
import sys,json
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from logo_tools import svg,lettering,asset,star
D=Path(__file__).parent
INK='#203B45'; CREAM='#FFF9ED'; SKY='#BDE9F6'; CORAL='#F47D64'; YELLOW='#FFD45B'
parts=[]
# Soft sky halo and graphic take-off streaks form a compact arcade crest.
parts.append('<circle cx="600" cy="367" r="241" fill="#BDE9F6"/>')
parts.append('<path d="M332 423C317 336 352 266 403 230M787 227C845 268 878 337 866 410" fill="none" stroke="#FFF9ED" stroke-width="15" stroke-linecap="round"/>')
parts.append('<path d="M302 454C246 445 214 410 220 384C267 384 314 397 353 428M897 454C953 445 985 410 979 384C932 384 885 397 846 428" fill="#F47D64" stroke="#203B45" stroke-width="7" stroke-linejoin="round"/>')
parts.append('<path d="M315 421L259 405M885 421L941 405" fill="none" stroke="#FFF9ED" stroke-width="7" stroke-linecap="round"/>')
parts.append('<path d="M373 303L344 279M827 303L856 279M392 220L375 188M808 220L825 188" stroke="#F47D64" stroke-width="12" stroke-linecap="round"/>')
# Pip uses the actual editable game mascot, enlarged as the face of the brand.
parts.append('<g transform="rotate(-9 600 300)">'+asset('pip',408,67,440,'hero')+'</g>')
parts.append(star(295,300,32,YELLOW,INK,5))
parts.append(star(919,303,26,YELLOW,INK,5))
parts.append(star(743,134,22,CORAL,INK,4))
parts.append('<circle cx="298" cy="348" r="7" fill="#F47D64"/><circle cx="893" cy="242" r="8" fill="#F47D64"/>')
# Flat vector extrusion is deliberately editable: cream keyline, dark block depth,
# colored side face, and the outlined rounded letter face are separate groups.
def dimension(word,y,size,face,side):
    bits=[]
    bits.append(lettering(word,600,y+20,size,fill=INK,stroke=CREAM,sw=35))
    for dy in range(20,-1,-2):
        bits.append(lettering(word,600,y+dy,size,fill=side,stroke=INK,sw=13))
    bits.append(lettering(word,600,y,size,fill=face,stroke=INK,sw=12))
    return '<g>'+''.join(bits)+'</g>'
parts.append(dimension('PUSH-UP',514,180,CREAM,CORAL))
parts.append(dimension('BIRD',739,335,YELLOW,CORAL))
# A small upward flourish makes the exercise input legible without gym imagery.
parts.append('<path d="M376 785Q600 822 824 785" fill="none" stroke="#203B45" stroke-width="8" stroke-linecap="round"/>')
parts.append('<path d="M427 790Q600 811 773 790" fill="none" stroke="#F47D64" stroke-width="6" stroke-linecap="round"/>')
(D/'logo.svg').write_text(svg(''.join(parts)))
mark='<circle cx="300" cy="300" r="238" fill="#BDE9F6" stroke="#203B45" stroke-width="10"/>'+star(468,145,33,YELLOW,INK,6)+asset('pip',72,70,465,'mark')
(D/'mark.svg').write_text(svg(mark,bg=CREAM,width=600,height=600))
(D/'concept.json').write_text(json.dumps({'id':1,'name':'Hero Mascot','rationale':'Pip takes centre stage above bold dimensional arcade lettering, with coral wing bursts and stars making the push-up-powered adventure feel joyful and instantly familiar.','theme':'Character-led arcade crest','palette':[INK,CREAM,SKY,CORAL,YELLOW]},indent=2)+'\n')
import xml.etree.ElementTree as ET
ET.parse(D/'logo.svg');ET.parse(D/'mark.svg')
