from pathlib import Path
import sys,json,xml.etree.ElementTree as ET
sys.path.insert(0,str(Path(__file__).resolve().parent.parent))
from logo_tools import lettering,svg,star

OUT=Path(__file__).resolve().parent
NAVY='#142D42'; GOLD='#FFD45B'; CORAL='#F47D64'; CREAM='#FFF9ED'

def pip(x,y,s=1):
    return f'''<g transform="translate({x} {y}) scale({s}) rotate(-15)">
    <path d="M-82 34 Q-148 7-152-43 Q-110-46-78-11" fill="{CORAL}" stroke="{NAVY}" stroke-width="8" stroke-linejoin="round"/>
    <path d="M-51-65 Q-81-134-40-139 Q-22-137-16-98 Q-27-154 10-154 Q40-151 30-101 Q56-138 79-112 Q96-86 50-57" fill="{GOLD}" stroke="{NAVY}" stroke-width="8" stroke-linejoin="round"/>
    <path d="M-100 5 C-100-78-38-109 25-96 C100-83 119-18 100 36 C81 91 21 111-40 92 C-80 80-103 49-100 5Z" fill="{GOLD}" stroke="{NAVY}" stroke-width="9"/>
    <path d="M-70 44 Q-38 89 19 91 Q-52 113-86 63" fill="#F4AA46"/>
    <path d="M-43 15 C-50-11-86-24-118-14 Q-118 38-81 57 Q-56 69-43 15Z" fill="#F5AD45" stroke="{NAVY}" stroke-width="7"/>
    <ellipse cx="0" cy="-23" rx="34" ry="41" fill="{CREAM}" stroke="{NAVY}" stroke-width="7"/>
    <ellipse cx="53" cy="-28" rx="31" ry="39" fill="{CREAM}" stroke="{NAVY}" stroke-width="7"/>
    <ellipse cx="12" cy="-26" rx="13" ry="20" fill="{NAVY}"/><ellipse cx="63" cy="-31" rx="12" ry="19" fill="{NAVY}"/>
    <circle cx="16" cy="-34" r="5" fill="{CREAM}"/><circle cx="67" cy="-39" r="5" fill="{CREAM}"/>
    <path d="M52 16 Q86 0 119 16 Q96 45 62 41Z" fill="{CORAL}" stroke="{NAVY}" stroke-width="7" stroke-linejoin="round"/>
    <path d="M67 51 Q76 64 88 51" fill="none" stroke="{NAVY}" stroke-width="6" stroke-linecap="round"/>
    <ellipse cx="3" cy="32" rx="19" ry="10" fill="{CORAL}" opacity=".75"/>
    </g>'''

motion=f'''<path d="M157 669 C348 776 729 722 912 511 C971 443 1000 363 994 288 C938 437 820 565 667 616 C492 677 295 687 157 669Z" fill="{CORAL}"/>
<path d="M162 650 C355 731 692 670 869 493 C932 430 970 355 982 292 C899 444 772 538 631 583 C469 635 292 659 162 650Z" fill="{GOLD}"/>
<path d="M225 697 C380 749 590 721 708 677" fill="none" stroke="{CREAM}" stroke-width="8" stroke-linecap="round"/>
<path d="M819 556 Q874 505 907 449" fill="none" stroke="{CREAM}" stroke-width="8" stroke-linecap="round"/>'''

typebody='<g transform="rotate(-8 525 499)">'
# Offset solid extrusion gives the lettering a crisp arcade silhouette.
typebody+='<g transform="translate(0 13)">'+lettering('Push-Up',507,459,158,CORAL,weight=700,stroke=NAVY,sw=20)+lettering('Bird',508,630,235,CORAL,weight=700,stroke=NAVY,sw=22)+'</g>'
typebody+=lettering('Push-Up',507,459,158,CREAM,weight=700,stroke=NAVY,sw=15)+lettering('Bird',508,630,235,GOLD,weight=700,stroke=NAVY,sw=15)+'</g>'

body=motion+star(740,198,38,GOLD,NAVY,6)+star(965,152,22,CORAL,NAVY,0)+star(1002,558,22,CREAM,NAVY,0)+star(180,345,16,GOLD,NAVY,0)
body+=f'<path d="M682 180L661 167M730 141L726 117M787 179L808 166" stroke="{CREAM}" stroke-width="8" stroke-linecap="round"/>'
body+=typebody+pip(900,256,.94)
(OUT/'logo.svg').write_text(svg(body,NAVY))
mark=f'<path d="M69 379 C209 456 422 332 439 144 C389 271 287 348 69 379Z" fill="{CORAL}"/><path d="M66 365 C224 399 377 273 426 157 C365 258 248 328 66 365Z" fill="{GOLD}"/>'+star(160,192,35,GOLD,NAVY,0)+star(412,76,15,CREAM,NAVY,0)+pip(294,221,1.03)
(OUT/'mark.svg').write_text(svg(mark,NAVY,512,512))
(OUT/'concept.json').write_text(json.dumps({'id':5,'name':'Star Slingshot','rationale':'A sweeping comet trajectory launches Pip past tilted arcade lettering, turning the game’s star trails into a bold symbol of lift and momentum.','theme':'Arcade motion / comet slingshot','palette':[NAVY,GOLD,CORAL,CREAM]},indent=2))
for name in ['logo.svg','mark.svg']: ET.parse(OUT/name)
print(OUT)
