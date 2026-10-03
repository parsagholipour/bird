from pathlib import Path
import sys,json,xml.etree.ElementTree as ET,copy,re
OUT=Path(__file__).resolve().parent
sys.path.insert(0,str(OUT.parent/'logo-concepts-2026-10-03'))
from logo_tools import svg,asset,lettering,star
INK='#203B45'; CREAM='#FFF9ED'; GOLD='#FFD45B'; CORAL='#F47D64'

def clean(raw):
    ET.register_namespace('','http://www.w3.org/2000/svg')
    root=ET.fromstring(re.sub(r'&(?!amp;|lt;|gt;|quot;|apos;|#)', '&amp;', raw))
    for parent in list(root.iter()):
        for child in list(parent):
            if child.get('paint-order')=='stroke fill':
                child.attrib.pop('paint-order')
                under=copy.deepcopy(child);under.set('fill','none');child.set('stroke','none')
                parent.insert(list(parent).index(child),under)
    return ET.tostring(root,encoding='unicode')

def title(text,size=170,face=CREAM):
    body='<g transform="rotate(-3 600 160)">'
    body+=lettering(text,600,221,size,INK,weight=700,stroke=CREAM,sw=17)
    body+=lettering(text,600,209,size,face,weight=700,stroke=INK,sw=12)
    body+='</g>'
    return clean(svg(body,bg=None,width=1200,height=320))

def unwrap(raw):return raw[raw.index('>')+1:raw.rindex('</svg>')]

entries=[
 dict(id='beakbound',name='Beakbound',reason='My recommendation. A bird adventure name that can grow with worlds, bosses and mini-games.',bg='#225D69',accent=GOLD),
 dict(id='sky-club',name='Sky Club',reason='The strongest connection to the existing courier story and its four playable birds.',bg='#6FC4D6',accent=CREAM),
 dict(id='pip-and-co',name='Pip & Co.',reason='A friendly cast-led direction, with Pip as the face of the wider bird adventure.',bg='#EC7766',accent=GOLD)
]

for e in entries:
    folder=OUT/e['id'];folder.mkdir(parents=True,exist_ok=True)
    if e['id']=='beakbound':
        body='<circle cx="399" cy="85" r="162" fill="#337F86"/>'
        body+='<path d="M-30 414 Q171 501 469 354" fill="none" stroke="#53AA99" stroke-width="56"/>'
        body+=asset('pip',-45,-11,640,'beakbound')
        body+=star(423,390,47,GOLD,INK,8)
    elif e['id']=='sky-club':
        body='<circle cx="255" cy="231" r="187" fill="#A7E2E2"/>'
        body+=asset('pip',-1,-25,567,'sky-club')
        body+='<g transform="rotate(-12 285 375)"><rect x="144" y="302" width="280" height="151" rx="24" fill="#FFF9ED" stroke="#203B45" stroke-width="8"/><path d="M157 319L278 397Q285 403 294 397L412 319M156 441L240 370M412 441L332 370" fill="none" stroke="#D7BF97" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/><circle cx="285" cy="375" r="34" fill="#F47D64"/>'+star(285,375,20,GOLD,INK,0)+'</g>'
    else:
        body='<path d="M0 94 Q231 -19 512 94V0H0Z" fill="#FF9981"/>'
        body+=asset('minty',-76,115,434,'company-minty')
        body+=asset('peaches',239,97,381,'company-peaches')
        body+=asset('pip',35,16,512,'company-pip')
        body+='<path d="M-24 494 Q260 422 550 487V532H-24Z" fill="#D75E4F"/>'
    icon=clean(svg(body,e['bg'],512,512))
    (folder/'app-icon.svg').write_text(icon)
    logo=title(e['name'],160 if e['id']=='beakbound' else 190, e['accent'])
    (folder/'menu-logo.svg').write_text(logo)
    # Placement study uses the game's actual island and bird artwork on a landscape canvas.
    scene='<defs><linearGradient id="sky" x2="0" y2="1"><stop stop-color="#7DCDDD"/><stop offset="1" stop-color="#EDF3D9"/></linearGradient></defs><rect width="1000" height="450" fill="url(#sky)"/>'
    scene+='<circle cx="803" cy="80" r="100" fill="#FFF5CE"/>'
    scene+='<g transform="translate(31 45) scale(.45)">'+unwrap(logo)+'</g>'
    scene+=asset('island',601,197,342,e['id']+'-island')
    scene+=asset('pip',648,98,234,e['id']+'-bird')
    scene+='<rect x="91" y="213" width="420" height="77" rx="28" fill="#D75E4F"/><rect x="91" y="205" width="420" height="77" rx="28" fill="#F47D64" stroke="#203B45" stroke-width="4"/>'
    scene+=lettering('Play',301,257,47,CREAM,weight=650)
    scene+='<rect x="91" y="306" width="420" height="58" rx="23" fill="#FFF9ED" stroke="#203B45" stroke-width="3"/>'
    scene+=lettering('Adventure',301,345,32,INK,weight=600)
    scene+=star(594,109,13,GOLD,INK,2)+star(570,179,8,CREAM,INK,0)
    (folder/'menu-placement.svg').write_text(clean(svg(scene,bg=None,width=1000,height=450)))
    (folder/'concept.json').write_text(json.dumps(e,indent=2))

(OUT/'manifest.json').write_text(json.dumps(entries,indent=2))
print('Created three app-icon and menu identity directions.')
