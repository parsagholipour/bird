from pathlib import Path
import sys, math, json
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from logo_tools import svg, lettering
out=Path(__file__).resolve().parent
ink='#203B45'; cream='#FFF9ED'; coral='#F47D64'; gold='#FFD45B'; orange='#D9914B'
# Rays are individual editable sectors clipped to a smooth, circular travel-poster sun.
rays=[]
for i in range(24):
    a=2*math.pi*i/24; b=2*math.pi*(i+1)/24
    rays.append(f'<path d="M600 350 L{600+202*math.cos(a):.2f} {350+202*math.sin(a):.2f} A202 202 0 0 1 {600+202*math.cos(b):.2f} {350+202*math.sin(b):.2f} Z" fill="{coral if i%2 else gold}"/>')
sun='<g id="sunburst">'+''.join(rays)+f'<circle cx="600" cy="350" r="202" fill="none" stroke="{ink}" stroke-width="7"/><circle cx="600" cy="350" r="177" fill="none" stroke="{cream}" stroke-width="3" opacity=".8"/></g>'
bird=f'''<g id="bird-silhouette" fill="{ink}"><path d="M519 351 C545 330 565 298 571 278 C593 305 597 324 603 329 C624 308 657 296 691 299 C669 308 647 323 629 345 L661 348 L643 359 L668 373 L630 368 C611 386 590 385 575 365 C555 365 535 361 519 351Z"/><path d="M522 352 L489 340 L510 364 Z"/></g>'''
# Wing-shaped ribbon extensions retain a horizontal, mid-century silhouette.
wings=f'''<g id="ribbon-wings" stroke="{ink}" stroke-width="6" stroke-linejoin="round"><path d="M355 440 L133 410 L187 467 L139 467 L203 519 L163 519 L238 571 L355 549Z" fill="{orange}"/><path d="M845 440 L1067 410 L1013 467 L1061 467 L997 519 L1037 519 L962 571 L845 549Z" fill="{orange}"/><path d="M222 458 L345 477 M250 511 L345 527 M978 458 L855 477 M950 511 L855 527" fill="none" stroke-width="3"/></g>'''
banner=f'''<g id="title-banner"><path d="M223 425 Q600 401 977 425 L977 593 Q600 623 223 593Z" fill="{ink}"/><path d="M238 440 Q600 417 962 440 L962 579 Q600 608 238 579Z" fill="none" stroke="{gold}" stroke-width="3"/></g>'''
# Condensing the outlined letterforms gives the broad ribbon a confident poster title.
typeart='<g id="outlined-title" transform="translate(600 0) scale(.86 1) translate(-600 0)">'+lettering('Push-Up Bird',600,554,132,fill=cream,weight=700,tracking=0)+'</g>'
bottom=f'''<g id="flight-lines" fill="none" stroke="{ink}" stroke-width="4" stroke-linecap="round"><path d="M466 654 H554 M646 654 H734"/><path d="M508 675 H559 M641 675 H692"/></g><path d="M585 652 L600 635 L615 652 L600 669Z" fill="{coral}" stroke="{ink}" stroke-width="3"/>'''
body=sun+bird+wings+banner+typeart+bottom
(out/'logo.svg').write_text(svg(body))
(out/'mark.svg').write_text(svg('<g transform="translate(-250 0)">'+sun+bird+'</g>',width=700,height=700))
(out/'concept.json').write_text(json.dumps({'id':19,'name':'Sunburst Flight Club','rationale':'A smooth retro sun and swift bird silhouette rise above a broad winged ribbon, giving the arcade name the optimism of a mid-century adventure poster.','theme':'Mid-century travel poster / sunny flight','palette':[ink,cream,coral,gold,orange]},indent=2))
import xml.etree.ElementTree as ET
ET.parse(out/'logo.svg'); ET.parse(out/'mark.svg')
print(out)
