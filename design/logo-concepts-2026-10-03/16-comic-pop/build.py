from pathlib import Path
import sys,json,math
sys.path.insert(0,str(Path(__file__).resolve().parent.parent))
from logo_tools import lettering,svg,star
P=Path(__file__).resolve().parent
ink='#203B45';cream='#FFF9ED';coral='#F47D64';yellow='#FFD45B'
# A deliberately irregular, angular comic explosion keeps the silhouette energetic.
points=[(164,407),(263,394),(204,287),(360,334),(375,189),(478,296),(561,183),(615,295),(778,208),(766,335),(968,279),(898,423),(1064,462),(950,535),(1028,670),(860,646),(865,775),(714,711),(616,796),(560,709),(377,778),(391,670),(210,713),(261,575),(135,534),(250,482)]
def poly(ps,fill,stroke=ink,sw=8):return f'<polygon points="'+ ' '.join(f'{x},{y}' for x,y in ps)+f'" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round"/>'
body=poly([(x+12,y+17) for x,y in points],ink)
body+=poly(points,yellow)
# Screenprinted halftone clusters, retained as individual editable circles.
for x in range(240,1000,24):
 for y in range(250,750,24):
  if ((x-635)/345)**2+((y-520)/237)**2<1 and (x>790 or y>620 or x<330):
   body+=f'<circle cx="{x}" cy="{y}" r="{3.7 if x<800 else 4.8}" fill="{ink}" opacity=".18"/>'
body+='<path d="M148 286l-46-36M145 342l-65-6M1018 349l50-45M1071 576l55 17M172 685l-38 31" fill="none" stroke="'+ink+'" stroke-width="12" stroke-linecap="round"/>'
# Compact slanted header on a heavy caption slug.
body+='<g transform="rotate(-5 583 339)"><path d="M345 272H820L839 387H328Z" fill="'+ink+'"/>'
body+=lettering('PUSH-UP',581,361,100,fill=cream,tracking=2,weight=650)+'</g>'
# Four independent glyphs create the bouncing, oversized comic wordmark.
letters=[('B',328,602,-8),('I',503,584,5),('R',659,611,-4),('D',863,589,9)]
for c,x,y,a in letters:
 body+=f'<g transform="rotate({a} {x} {y-110})">'
 body+=lettering(c,x+9,y+15,298,fill=ink,stroke=ink,sw=16,weight=700)
 body+=lettering(c,x,y,298,fill=cream,stroke=ink,sw=11,weight=700)
 body+='</g>'
# Pip's eye and coral beak peek from the B counter, without a separate perched mascot.
body+='<g transform="rotate(-8 328 492)"><ellipse cx="327" cy="467" rx="25" ry="29" fill="'+yellow+'"/><ellipse cx="330" cy="467" rx="15" ry="19" fill="'+cream+'" stroke="'+ink+'" stroke-width="4"/><ellipse cx="335" cy="469" rx="7" ry="10" fill="'+ink+'"/><circle cx="337" cy="465" r="2.7" fill="'+cream+'"/><path d="M342 488l36 10-33 14Z" fill="'+coral+'" stroke="'+ink+'" stroke-width="4" stroke-linejoin="round"/></g>'
body+=star(966,225,28,cream,ink,5)+star(202,613,20,cream,ink,4)
body+='<path d="M424 662l315-15" stroke="'+ink+'" stroke-width="10" stroke-linecap="round"/>'
(P/'logo.svg').write_text(svg(body,coral))
(P/'concept.json').write_text(json.dumps({'id':16,'name':'Comic Pop','rationale':'A staggered, oversized comic wordmark erupts from a yellow halftone blast, with Pip’s eye and beak hidden in the B.','theme':'Comic-book arcade explosion','palette':[ink,cream,coral,yellow]},indent=2))
# Standalone letter icon for small placements.
mark=poly([(65,170),(120,150),(84,70),(175,102),(235,35),(263,116),(355,72),(336,166),(405,212),(343,266),(378,359),(280,328),(233,402),(188,328),(85,367),(112,268),(35,240)],yellow,ink,7)
mark+=lettering('B',229,322,302,cream,stroke=ink,sw=10,weight=700)
mark+='<ellipse cx="239" cy="186" rx="19" ry="25" fill="'+cream+'" stroke="'+ink+'" stroke-width="4"/><ellipse cx="245" cy="188" rx="8" ry="12" fill="'+ink+'"/><path d="M249 210l34 11-31 15Z" fill="'+coral+'" stroke="'+ink+'" stroke-width="4"/>'
(P/'mark.svg').write_text(svg(mark,coral,450,450))
import xml.etree.ElementTree as ET
ET.parse(P/'logo.svg');ET.parse(P/'mark.svg')
