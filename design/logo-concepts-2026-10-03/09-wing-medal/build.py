from pathlib import Path
import sys,json,math,xml.etree.ElementTree as ET
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from logo_tools import svg,lettering,star
D=Path(__file__).resolve().parent
INK='#203B45'; CREAM='#FFF9ED'; GOLD='#FFD45B'; DEEP='#D9A033'; CORAL='#F47D64'

def wings():
    # Stepped flight feathers echo the game's collectible wing.
    single=f'''<path d="M455 335L163 248Q143 242 148 265L174 343Q182 364 205 370L203 390Q204 410 225 417L254 426L254 444Q256 463 279 470L310 478L317 496Q323 514 344 516L467 524Z" fill="{DEEP}" stroke="{INK}" stroke-width="9" stroke-linejoin="round"/>
    <path d="M463 326L163 242Q145 237 151 258L179 326Q185 342 208 349L433 415Z" fill="{CREAM}" stroke="{INK}" stroke-width="8" stroke-linejoin="round"/>
    <path d="M207 355L441 424L444 450L233 395Q216 391 213 378Z" fill="{CREAM}"/>
    <path d="M261 417L449 464L452 487L281 452Q268 449 265 437Z" fill="{CREAM}"/>
    <path d="M322 478L454 500L456 509L342 502Q326 499 322 478Z" fill="{CREAM}"/>
    <path d="M179 265L416 334" stroke="white" stroke-width="7" stroke-linecap="round"/>
    <path d="M228 364L423 421M283 427L435 466" stroke="{INK}" stroke-width="6" stroke-linecap="round"/>'''
    return '<g id="left-wing">'+single+'</g><g id="right-wing" transform="translate(1200 0) scale(-1 1)">'+single+'</g>'

def coin():
    parts=[f'<circle cx="600" cy="379" r="170" fill="{DEEP}" stroke="{INK}" stroke-width="9"/>',f'<circle cx="600" cy="367" r="166" fill="{GOLD}" stroke="{INK}" stroke-width="9"/>',f'<circle cx="600" cy="367" r="142" fill="{CREAM}" stroke="{INK}" stroke-width="5"/>']
    for a in range(0,360,20):
        rad=math.radians(a)
        parts.append(f'<path d="M{600+151*math.cos(rad):.1f} {367+151*math.sin(rad):.1f}L{600+157*math.cos(rad):.1f} {367+157*math.sin(rad):.1f}" stroke="{INK}" stroke-width="3" stroke-linecap="round"/>')
    parts.append(f'''<path d="M559 291C535 265 548 257 568 272C564 245 584 244 596 270C610 246 630 256 612 283" fill="{GOLD}" stroke="{INK}" stroke-width="7" stroke-linejoin="round"/>
    <path d="M508 370C506 309 538 283 588 283C644 279 685 319 687 371C691 427 657 458 604 459C548 459 510 431 508 370Z" fill="{GOLD}" stroke="{INK}" stroke-width="7"/>
    <path d="M522 392Q541 443 600 445Q658 447 676 403Q663 455 605 455Q541 455 522 414Z" fill="{DEEP}"/>
    <ellipse cx="563" cy="352" rx="25" ry="33" fill="white" stroke="{INK}" stroke-width="5"/>
    <ellipse cx="630" cy="352" rx="25" ry="33" fill="white" stroke="{INK}" stroke-width="5"/>
    <ellipse cx="570" cy="356" rx="10" ry="17" fill="{INK}"/><ellipse cx="623" cy="356" rx="10" ry="17" fill="{INK}"/>
    <circle cx="567" cy="348" r="4" fill="white"/><circle cx="620" cy="348" r="4" fill="white"/>
    <ellipse cx="541" cy="387" rx="14" ry="8" fill="{CORAL}"/><ellipse cx="658" cy="387" rx="14" ry="8" fill="{CORAL}"/>
    <path d="M577 388Q599 372 621 388Q612 414 599 414Q586 414 577 388Z" fill="{CORAL}" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>
    <path d="M579 390Q600 399 619 390" fill="none" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>
    <path d="M533 322Q541 308 554 306" fill="none" stroke="{CREAM}" stroke-width="7" stroke-linecap="round"/>''')
    return '<g id="pip-medallion">'+''.join(parts)+'</g>'

body=wings()+coin()
body+=f'''<g id="ribbon-tails"><path d="M293 494L166 514L201 569L166 634L324 614L347 552Z" fill="#D95E50" stroke="{INK}" stroke-width="8" stroke-linejoin="round"/><path d="M907 494L1034 514L999 569L1034 634L876 614L853 552Z" fill="#D95E50" stroke="{INK}" stroke-width="8" stroke-linejoin="round"/>
<path d="M260 614L319 645L342 599M940 614L881 645L858 599" fill="#A6423D" stroke="{INK}" stroke-width="7" stroke-linejoin="round"/></g>
<path id="ribbon-shadow" d="M262 489Q600 523 938 489L938 623Q600 677 262 623Z" fill="{INK}" stroke="{INK}" stroke-width="10" stroke-linejoin="round"/>
<path id="title-ribbon" d="M262 479Q600 513 938 479L938 609Q600 663 262 609Z" fill="{CORAL}" stroke="{INK}" stroke-width="8" stroke-linejoin="round"/>
<path d="M280 496Q600 529 920 496" fill="none" stroke="#FFAB8A" stroke-width="6" stroke-linecap="round"/>
'''
# Baseline stays level for effortless reading; the banner supplies the movement.
body+=lettering('Push-Up Bird',600,596,96,fill=CREAM,weight=700,stroke=INK,sw=4)
body+=star(395,220,19,fill=GOLD,sw=5)+star(805,220,19,fill=GOLD,sw=5)
body+=f'<path d="M587 680L600 693L613 680" fill="none" stroke="{DEEP}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>'
(D/'logo.svg').write_text(svg(body))
mark='<g transform="translate(-395 -162)">'+coin()+'</g>'
(D/'mark.svg').write_text(svg(mark,width=410,height=410,bg=CREAM))
(D/'concept.json').write_text(json.dumps({'id':9,'name':'Wing Medal','rationale':'Pip becomes a smiling gold achievement coin between stepped flight wings, with a coral prize ribbon giving the game a collectible arcade identity.','theme':'Vintage arcade achievement badge','palette':[INK,CREAM,GOLD,DEEP,CORAL,'#D95E50'],'files':['logo.svg','mark.svg','build.py']},indent=2)+'\n')
for file in ('logo.svg','mark.svg'): ET.parse(D/file)
print('Built and XML-validated logo.svg and mark.svg')
