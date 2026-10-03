import sys,json
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent.parent))
from logo_tools import lettering,svg,star
out=Path(__file__).resolve().parent
ink='#203B45';coral='#F47D64'
# The ribbon is a closed editable contour: a wing folds into one open loop and rises into the head.
mark='''<g>
<path d="M 360,350 C 402,377 445,386 487,371 C 451,346 407,297 393,260 C 454,286 499,298 542,288 C 499,267 463,228 452,194 C 510,218 562,228 607,226 C 576,199 558,175 555,154 C 608,180 650,203 681,227 C 705,207 743,202 769,219 C 790,232 802,255 799,277 L 836,295 L 795,311 C 770,354 729,382 680,407 C 591,453 487,475 438,438 C 408,416 416,390 442,382 C 418,415 457,433 508,422 C 556,412 601,391 641,365 C 607,376 574,378 546,373 C 499,422 418,415 360,350 Z" fill="#F47D64" stroke="#203B45" stroke-width="10" stroke-linejoin="round"/>
<path d="M 448,273 C 486,303 521,320 562,320 M 500,224 C 537,246 572,255 608,256" fill="none" stroke="#FFD1B0" stroke-width="11" stroke-linecap="round"/>
<path d="M 682,237 C 651,263 638,298 641,326" fill="none" stroke="#CB584B" stroke-width="16" stroke-linecap="round"/>
<circle cx="758" cy="253" r="9" fill="#203B45"/>
<path d="M 800,277 L 836,295 L 796,310" fill="#FFD45B" stroke="#203B45" stroke-width="8" stroke-linejoin="round"/>
</g>'''
body='<ellipse cx="600" cy="339" rx="263" ry="226" fill="#BDE9F6" opacity=".48"/>'
body+='<path d="M 345 436 C 319 378 322 306 350 258" fill="none" stroke="#A8D8B4" stroke-width="12" stroke-linecap="round"/><path d="M 323 272 L 350 248 L 357 283" fill="none" stroke="#A8D8B4" stroke-width="12" stroke-linecap="round" stroke-linejoin="round"/>'
body+=mark
body+=star(875,199,21,sw=0)+star(329,184,12,fill=coral,sw=0)
body+='<g transform="translate(600 0) skewX(-9) translate(-600 0)">'
body+=lettering('Push-Up',670,609,132,fill=ink,weight=680)
body+=lettering('Bird',685,747,162,fill=coral,weight=680,stroke=ink,sw=6)
body+='</g>'
body+='<path d="M 417 789 Q 620 809 793 773" fill="none" stroke="#FFD45B" stroke-width="14" stroke-linecap="round"/>'
(out/'logo.svg').write_text(svg(body))
(out/'mark.svg').write_text(svg('<g transform="translate(-265 0)">'+mark+'</g>',width=600,height=600))
(out/'concept.json').write_text(json.dumps({'id':11,'name':'Motion Ribbon','rationale':'A continuous coral ribbon curls through an exercise loop into an ascending bird, paired with a slanted, buoyant game wordmark.','theme':'Sporty playful motion, repetition and upward flight','palette':['#203B45','#FFF9ED','#BDE9F6','#F47D64','#FFD45B','#A8D8B4']},indent=2))
import xml.etree.ElementTree as ET
ET.parse(out/'logo.svg')
