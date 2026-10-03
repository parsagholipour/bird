from pathlib import Path
import sys, json
import xml.etree.ElementTree as ET
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from logo_tools import lettering, svg

OUT=Path(__file__).resolve().parent
NAVY='#181A38'
GOLD='#F6D793'
CREAM='#FFF9ED'
LAV='#B9AAF2'

def sparkle(x,y,r,color=GOLD):
    return f'<path d="M{x} {y-r} Q{x+2} {y-2} {x+r} {y} Q{x+2} {y+2} {x} {y+r} Q{x-2} {y+2} {x-r} {y} Q{x-2} {y-2} {x} {y-r}Z" fill="{color}"/>'

def emblem():
    return f'''<g id="orbit-emblem">
    <ellipse cx="600" cy="307" rx="261" ry="100" transform="rotate(-20 600 307)" fill="none" stroke="{GOLD}" stroke-width="4" opacity=".8"/>
    <path id="crescent-bird" d="M611 150 C532 112 428 181 426 295 C424 435 585 499 737 389 C650 430 592 408 569 356 C650 357 691 300 663 228 C651 193 634 170 611 150Z" fill="{LAV}" stroke="{NAVY}" stroke-width="9" stroke-linejoin="round"/>
    <path d="M457 225 Q446 161 462 128 Q486 136 511 157 L523 112 Q555 127 562 155" fill="{LAV}" stroke="{NAVY}" stroke-width="9" stroke-linejoin="round"/>
    <path d="M624 175 Q654 145 682 145 L667 190 Q669 218 672 235" fill="{LAV}" stroke="{NAVY}" stroke-width="9" stroke-linejoin="round"/>
    <path id="moon-belly" d="M441 290 C447 398 574 464 701 410 C592 495 422 416 441 290Z" fill="#8579C9"/>
    <path d="M458 208 Q474 182 495 176" fill="none" stroke="#DDD5FF" stroke-width="9" stroke-linecap="round"/>
    <ellipse cx="551" cy="239" rx="49" ry="58" fill="#DFD8FF"/>
    <ellipse cx="613" cy="243" rx="38" ry="49" fill="#DFD8FF"/>
    <ellipse cx="551" cy="240" rx="28" ry="36" fill="{CREAM}" stroke="{NAVY}" stroke-width="6"/>
    <ellipse cx="613" cy="244" rx="23" ry="31" fill="{CREAM}" stroke="{NAVY}" stroke-width="6"/>
    <ellipse cx="559" cy="241" rx="14" ry="22" fill="{GOLD}"/>
    <ellipse cx="619" cy="244" rx="11" ry="19" fill="{GOLD}"/>
    <ellipse cx="561" cy="241" rx="8" ry="16" fill="{NAVY}"/>
    <ellipse cx="620" cy="244" rx="7" ry="14" fill="{NAVY}"/>
    <circle cx="556" cy="232" r="4" fill="white"/><circle cx="616" cy="237" r="3.5" fill="white"/>
    <path d="M596 284 Q618 272 635 282 L614 305Z" fill="{GOLD}" stroke="{NAVY}" stroke-width="5" stroke-linejoin="round"/>
    <ellipse cx="546" cy="288" rx="14" ry="7" fill="#E7A9CF"/>
    <path id="folded-wing" d="M490 284 C452 309 459 366 506 391 C543 411 584 412 616 403 C557 389 529 352 522 309 Q516 288 490 284Z" fill="#6C64AF" stroke="{NAVY}" stroke-width="6"/>
    {sparkle(495,331,15)}
    <circle cx="522" cy="369" r="3" fill="{GOLD}"/>
    <circle cx="478" cy="287" r="3" fill="{GOLD}"/>
    <path id="orbit-front" d="M354 335 C303 435 563 444 783 306" fill="none" stroke="{NAVY}" stroke-width="15" stroke-linecap="round"/>
    <path d="M354 335 C303 435 563 444 783 306" fill="none" stroke="{GOLD}" stroke-width="4" stroke-linecap="round"/>
    <circle cx="783" cy="306" r="8" fill="{GOLD}"/>
    {sparkle(774,180,22)}{sparkle(376,224,12,CREAM)}
    <circle cx="750" cy="134" r="3" fill="{CREAM}"/>
    <circle cx="403" cy="156" r="3" fill="{GOLD}"/>
    </g>'''

body='''<defs><radialGradient id="night-halo"><stop offset="0" stop-color="#30294F"/><stop offset="1" stop-color="#181A38"/></radialGradient></defs>
<ellipse cx="600" cy="373" rx="500" ry="365" fill="url(#night-halo)"/>'''
body+=emblem()
body+=lettering('Push-Up',600,598,108,CREAM,weight=600,tracking=1)
body+=lettering('Bird',600,756,180,LAV,weight=650,tracking=2)
body+=f'<path d="M416 796 Q600 826 784 796" fill="none" stroke="{GOLD}" stroke-width="3" stroke-linecap="round"/>'
body+=sparkle(315,672,15)+sparkle(885,672,15)
body+='<circle cx="290" cy="606" r="3" fill="#B9AAF2"/><circle cx="910" cy="606" r="3" fill="#B9AAF2"/>'
logo=svg(body,bg=NAVY)
ET.fromstring(logo)
(OUT/'logo.svg').write_text(logo)
mark=svg('<g transform="translate(-300 0)">'+emblem()+'</g>',bg=NAVY,width=600,height=600)
ET.fromstring(mark)
(OUT/'mark.svg').write_text(mark)
(OUT/'concept.json').write_text(json.dumps({
    'id':10,'name':'Orbit After Dark',
    'rationale':'Orbit becomes a crescent bird encircled by a fine gold planetary ring, giving the arcade title a dreamy, collectible night-sky identity.',
    'theme':'Celestial arcade / crescent Orbit bird',
    'palette':[NAVY,LAV,'#8579C9','#6C64AF',GOLD,CREAM],
},indent=2)+'\n')
