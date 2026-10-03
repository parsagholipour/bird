from pathlib import Path
import sys, json
import xml.etree.ElementTree as ET
sys.path.insert(0,str(Path(__file__).resolve().parent.parent))
from logo_tools import lettering, svg
OUT=Path(__file__).resolve().parent
cream='#FFF9ED'; ink='#203B45'; mint='#A8D8B4'; deep='#75BA99'; coral='#F47D64'
# Two soft aerodynamic lobes make a single rising bird. The arrow is a true knockout.
mark=f'''<defs><mask id="lift-cutout"><rect width="480" height="440" fill="white"/><path d="M226 343 V239 H190 Q181 239 187 232 L242 175 Q247 170 252 175 L307 232 Q313 239 304 239 H268 V343 Z" fill="black"/></mask></defs>
<g id="interlocking-wings" mask="url(#lift-cutout)">
<path id="left-wing" d="M247 367 C173 356 97 300 63 224 C44 183 32 122 52 103 C67 88 87 102 105 126 L202 243 C238 286 276 309 292 325 C307 343 280 371 247 367Z" fill="{deep}"/>
<path id="right-wing" d="M214 340 C188 311 189 263 214 221 C245 168 266 142 286 112 C310 77 351 73 381 97 C406 119 408 155 393 181 C382 202 364 213 350 223 C338 289 295 355 247 367 C227 372 214 356 214 340Z" fill="{mint}"/>
</g>
<path id="beak" d="M399 129 L432 145 Q441 150 431 156 L398 171Z" fill="{coral}"/>
<circle id="eye" cx="369" cy="129" r="8" fill="{ink}"/>
<path id="crest" d="M324 83 C313 64 316 50 325 51 C335 53 337 66 337 78 M339 79 C343 57 355 48 361 57 C367 66 355 77 353 82" fill="{mint}"/>
'''
body=f'<g id="bird-emblem" transform="translate(366 129)">{mark}</g>'
body+=lettering('push-up bird',600,665,126,fill=ink,weight=560,tracking=-1)
# Small mint lozenge repeats the upward gesture below the wordmark.
body+=f'<rect x="558" y="710" width="84" height="10" rx="5" fill="{mint}"/>'
(OUT/'logo.svg').write_text(svg(body))
(OUT/'mark.svg').write_text(svg(f'<g transform="translate(16 24)">{mark}</g>',width=512,height=512))
meta={'id':13,'name':'Minty Lift','rationale':'Two interlocking mint wings form an uplifting little bird, with an upward arrow cut through their meeting point and a warm rounded lowercase wordmark.','theme':'Scandinavian toy brand / geometric arcade bird','palette':[cream,ink,mint,deep,coral]}
(OUT/'concept.json').write_text(json.dumps(meta,indent=2)+'\n')
for name in ['logo.svg','mark.svg']: ET.parse(OUT/name)
print(OUT)
