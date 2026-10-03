from pathlib import Path
import sys, json
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from logo_tools import lettering, asset, svg, star

OUT=Path(__file__).resolve().parent
ink='#203B45'

def cloud(x,y,s=1):
    return f'<g transform="translate({x} {y}) scale({s})"><path d="M0 28C-11 8 9-11 29-3C36-34 87-30 89 0C112-9 132 7 124 28Z" fill="#FFF9ED"/></g>'

island='''<g id="floating-island" stroke="#203B45" stroke-width="7" stroke-linejoin="round">
<path d="M235 525L290 624L369 644L430 714L493 669L602 756L661 687L731 707L779 640L874 609L947 519Z" fill="#C79976"/>
<path d="M235 525L290 624L369 644L430 714L456 605L368 552Z" fill="#A97259" stroke="none"/>
<path d="M602 756L604 626L691 561L661 687Z" fill="#A97259" stroke="none"/>
<path d="M731 707L752 595L874 609L779 640Z" fill="#A97259" stroke="none"/>
<path d="M364 610L425 625L451 655M511 667L539 687M671 629L702 612" fill="none" stroke="#EAC3A3" stroke-width="7" stroke-linecap="round"/>
<path d="M239 503C277 470 352 462 416 473C477 443 544 450 593 467C660 440 739 454 782 474C850 461 910 478 948 507C966 522 949 551 915 563C864 587 806 581 768 576C714 604 648 600 596 585C538 611 468 601 423 580C350 601 282 571 250 555C225 543 218 521 239 503Z" fill="#62AF99"/>
<path d="M239 503C277 470 352 462 416 473C477 443 544 450 593 467C660 440 739 454 782 474C850 461 910 478 948 507C935 529 896 542 862 538C811 558 755 550 725 543C676 562 628 553 596 545C531 565 474 551 445 541C365 562 294 540 239 503Z" fill="#A8D8B4" stroke="none"/>
<path d="M287 521L281 505M301 518L308 500M868 517L868 500M885 521L895 507" fill="none" stroke="#498A72" stroke-width="5" stroke-linecap="round"/>
</g>'''

body='''<g id="sky"><circle cx="600" cy="399" r="256" fill="#DCEFF0"/>
<path d="M426 191C474 158 535 143 598 145" fill="none" stroke="#BDE9F6" stroke-width="8" stroke-linecap="round"/>
<path d="M749 178L762 184" stroke="#BDE9F6" stroke-width="8" stroke-linecap="round"/>
</g>'''
body+=cloud(230,340,.8)+cloud(815,280,.86)+cloud(170,448,.53)+cloud(914,427,.58)
body+=island
body+='''<g id="small-foliage" fill="#62AF99" stroke="#203B45" stroke-width="5" stroke-linejoin="round"><path d="M270 490C237 482 211 450 222 413C251 418 275 450 270 490Z"/><path d="M274 489C260 454 276 423 305 409C321 438 305 475 274 489Z"/><path d="M897 494C887 462 904 441 930 434C941 461 923 484 897 494Z"/></g>'''
body+=asset('pip',507,160,206,'island-pip')
body+=star(420,242,18,'#FFD45B',ink,4)+star(786,343,16,'#FFD45B',ink,4)
body+='''<circle cx="374" cy="282" r="5" fill="#F47D64"/><circle cx="825" cy="396" r="5" fill="#F47D64"/>'''
body+='<g id="title-shadow">'+lettering('Push-Up',600,412,157,fill=ink,stroke=ink,sw=22)+lettering('Bird',600,563,214,fill=ink,stroke=ink,sw=22)+'</g>'
body+='<g id="outlined-title">'+lettering('Push-Up',600,403,157,fill='#FFF9ED',stroke=ink,sw=13)+lettering('Bird',600,554,214,fill='#FFD45B',stroke=ink,sw=13)+'</g>'
body+='''<g id="floating-pebbles" fill="#C79976" stroke="#203B45" stroke-width="4" stroke-linejoin="round"><path d="M333 677L352 684L345 704L331 696Z"/><path d="M775 742L790 745L784 761L772 752Z"/></g>'''
(OUT/'logo.svg').write_text(svg(body))

mark='<circle cx="450" cy="418" r="325" fill="#DCEFF0"/>'
mark+='<g transform="translate(-18 40) scale(.78)">'+island+'</g>'
mark+=asset('pip',231,161,440,'island-mark-pip')
mark+=star(209,267,23,'#FFD45B',ink,5)+star(698,309,19,'#FFD45B',ink,5)
(OUT/'mark.svg').write_text(svg(mark,width=900,height=900))
(OUT/'concept.json').write_text(json.dumps({'id':4,'name':'Island Adventure','rationale':'A warm storybook wordmark rests on a floating grassy island, with Pip perched above and a faceted rock point giving the game an unmistakable adventure silhouette.','theme':'Floating island storybook adventure','palette':['#203B45','#FFF9ED','#FFD45B','#A8D8B4','#62AF99','#C79976','#DCEFF0']},indent=2)+'\n')
