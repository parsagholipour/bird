from pathlib import Path
import sys,json,xml.etree.ElementTree as ET
sys.path.insert(0,str(Path(__file__).resolve().parent.parent))
from logo_tools import lettering,svg,star
OUT=Path(__file__).resolve().parent
INK='#203B45'; CREAM='#FFF9ED'; MINT='#A8D8B4'; TEAL='#4B948C'; CORAL='#F47D64'; YELLOW='#FFD45B'
body='''
<g stroke="#203B45" stroke-linejoin="round" stroke-linecap="round">
<!-- gate shadows and sculpted garden pillars -->
<path d="M270 647V284H358V647M842 647V284H930V647" fill="#203B45" stroke-width="12"/>
<path d="M251 631V269H339V631M823 631V269H911V631" fill="#A8D8B4" stroke-width="9"/>
<path d="M316 283H338V630H316M888 283H910V630H888" fill="#4B948C" stroke="none"/>
<path d="M241 264L295 213L349 264V286H241ZM813 264L867 213L921 264V286H813Z" fill="#A8D8B4" stroke-width="9"/>
<path d="M266 309V563M838 309V563" fill="none" stroke="#FFF9ED" stroke-width="8"/>
<!-- pennant is a playful park landmark -->
<path d="M295 214V137" fill="none" stroke-width="9"/>
<path d="M300 139L570 150L531 187L570 224L300 212Z" fill="#F47D64" stroke-width="7"/>
<path d="M321 161L487 168M321 189L475 195" fill="none" stroke="#FFF9ED" stroke-width="5"/>
<!-- speed traces open into the central gate -->
<path d="M370 402H461M365 443H428M397 485H455" fill="none" stroke="#4B948C" stroke-width="12"/>
<!-- bespoke Pip silhouette, flying through the obstacle -->
<path d="M523 487L465 478L502 449L465 422L535 427" fill="#FFD45B" stroke-width="8"/>
<path d="M522 371C551 328 621 309 677 341C699 351 719 372 727 398C743 450 714 505 665 526C610 550 541 526 519 482C500 443 501 401 522 371Z" fill="#FFD45B" stroke-width="9"/>
<path d="M553 360L548 323Q559 310 577 341L586 304Q602 296 611 338L630 311Q646 313 636 340" fill="#FFD45B" stroke-width="8"/>
<path d="M531 421C564 407 601 424 614 449C593 481 559 484 534 466" fill="#F2B940" stroke-width="7"/>
<path d="M647 350C676 344 696 363 695 390C695 417 677 436 654 430C630 425 621 405 627 381C631 363 638 354 647 350Z" fill="#FFF9ED" stroke-width="7"/>
<ellipse cx="671" cy="389" rx="11" ry="17" fill="#203B45" stroke="none"/>
<circle cx="675" cy="382" r="4" fill="#FFF9ED" stroke="none"/>
<path d="M703 401L752 416L714 441Z" fill="#F47D64" stroke-width="7"/>
<path d="M645 496Q666 504 684 491" fill="none" stroke-width="5"/>
<circle cx="695" cy="456" r="11" fill="#F47D64" stroke="none"/>
<!-- bottom crossbar is the lettering carrier -->
<path d="M208 626H992V749H208Z" fill="#203B45" stroke-width="9"/>
<path d="M190 611H974V734H190Z" fill="#4B948C" stroke-width="9"/>
<path d="M206 623H958V722H206Z" fill="none" stroke="#A8D8B4" stroke-width="3"/>
<circle cx="221" cy="674" r="6" fill="#FFF9ED" stroke="none"/>
<circle cx="943" cy="674" r="6" fill="#FFF9ED" stroke="none"/>
</g>
'''
body+=lettering('Push-Up Bird',582,700,94,fill=CREAM,weight=650,tracking=0)
body+=star(771,322,22,fill=CORAL,sw=0)
body+=star(756,510,13,fill=TEAL,sw=0)
art=svg(body)
ET.fromstring(art)
(OUT/'logo.svg').write_text(art)
(OUT/'concept.json').write_text(json.dumps({'id':14,'name':'Gate Dash','rationale':'A park gate becomes the emblem: Pip shoots between mint pillars while the title forms its sturdy teal crossbar and a coral pennant signals arcade adventure.','theme':'1950s garden park adventure signage','palette':[INK,CREAM,MINT,TEAL,CORAL,YELLOW]},indent=2)+'\n')
