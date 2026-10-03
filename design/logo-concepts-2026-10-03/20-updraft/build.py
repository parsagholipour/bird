from pathlib import Path
import sys,json
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from logo_tools import lettering,svg
OUT=Path(__file__).parent
ink='#203B45'; sky='#BDE9F6'; yellow='#FFD45B'; coral='#F47D64'
# A single continuous contour circles the title, curls into a heart, and climbs.
trail='''<path d="M 849,305 C 670,215 290,252 192,357 C 116,439 173,562 311,586 C 378,598 424,590 463,585 C 433,565 428,539 449,528 C 471,516 488,533 499,548 C 510,530 532,516 551,529 C 578,549 545,579 499,612 C 633,655 860,624 962,538 C 1023,487 1045,423 1033,351 L 1008,380 L 1033,351 L 1063,377 L 1033,351 C 1019,309 1001,287 977,264" fill="none" stroke="#BDE9F6" stroke-width="19" stroke-linecap="round" stroke-linejoin="round"/>'''
bird='''<g transform="translate(957 256) rotate(-28)"><path d="M -48,15 C -71,3 -76,-8 -87,-23 C -65,-23 -50,-17 -35,-9 C -29,-38 -8,-56 18,-51 C 46,-48 59,-22 50,1 C 42,23 19,37 -8,33 C -29,32 -41,26 -48,15 Z" fill="#FFD45B"/><path d="M -23,5 C -38,-17 -35,-41 -22,-55 C -3,-44 4,-19 -2,0 C -7,15 -16,17 -23,5 Z" fill="#FFE38B"/><path d="M 48,-24 L 75,-13 L 48,-4 Z" fill="#F47D64"/><circle cx="29" cy="-28" r="5.5" fill="#203B45"/><path d="M 8,-52 L 4,-65 M 20,-52 L 22,-64" stroke="#FFD45B" stroke-width="8" stroke-linecap="round"/></g>'''
body=trail+lettering('Push-Up Bird',600,475,105,weight=600,tracking=-1)+bird+'''<path d="M 281,335 L 291,325" stroke="#F47D64" stroke-width="10" stroke-linecap="round"/>'''
(OUT/'logo.svg').write_text(svg(body))
mark='''<path d="M 103,345 C 44,268 91,168 166,165 C 247,161 269,237 225,269 C 177,302 144,253 169,226 C 188,204 204,231 205,242 C 222,222 245,232 243,252 C 239,277 208,301 182,312 C 280,351 365,262 338,171 L 316,194 L 338,171 L 366,192 L 338,171 C 331,153 318,139 308,134" fill="none" stroke="#BDE9F6" stroke-width="18" stroke-linecap="round" stroke-linejoin="round"/>'''
(OUT/'mark.svg').write_text(svg(mark+'<g transform="translate(-649 -122)">'+bird+'</g>',width=450,height=450))
(OUT/'concept.json').write_text(json.dumps({'id':20,'name':'Updraft','rationale':'One airy flight line embraces the name, loops into a heart, and climbs into an ascending yellow bird, making movement feel joyful and effortless.','theme':'Continuous flight path and upward motion','palette':[ink,'#FFF9ED',sky,coral,yellow,'#FFE38B']},indent=2))
