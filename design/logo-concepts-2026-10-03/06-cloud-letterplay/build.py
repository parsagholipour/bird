from pathlib import Path
import sys,json,re
sys.path.insert(0,str(Path(__file__).resolve().parent.parent))
from logo_tools import lettering,svg,star,asset
OUT=Path(__file__).resolve().parent
INK='#203B45'; CREAM='#FFF9ED'; SKY='#BDE9F6'; PINK='#FFAFAC'
# Hand-drawn, editable cloud letterforms; counters remain true vector holes.
B='M42 291 C11 291 -4 269 4 240 L4 62 C-4 29 18 10 45 13 C62 -8 102 -10 127 7 C154 -3 186 5 199 30 C234 39 243 78 224 104 C227 126 213 140 201 147 C233 155 244 179 239 204 C259 237 234 270 205 275 C189 301 151 306 125 290 C100 304 66 305 42 291 Z M81 70 C93 55 135 55 151 67 C178 63 191 80 187 101 C184 121 162 128 144 122 L82 122 Z M81 190 L141 190 C164 181 189 195 188 215 C190 238 167 249 145 240 L81 240 Z'
I='M21 17 C39 -3 63 -4 79 10 C98 -5 126 0 139 20 C162 32 158 69 133 79 L121 79 L121 209 L134 209 C159 222 163 252 142 266 C129 292 100 297 81 280 C61 297 31 293 22 274 C-6 263 -7 228 17 213 L32 209 L32 80 L19 78 C-7 67 -4 31 21 17 Z'
R='M43 293 C15 300 -3 279 4 249 L4 63 C-4 29 17 7 46 14 C65 -7 100 -6 123 9 C151 -6 186 8 198 29 C230 32 247 68 230 96 C242 133 218 165 193 175 L234 225 C258 239 253 273 231 281 C215 307 180 306 165 280 L117 204 L84 204 L84 254 C88 280 69 303 43 293 Z M84 72 L84 129 L137 129 C160 138 187 120 184 99 C187 77 164 64 145 72 Z'
D='M44 293 C16 301 -4 279 4 249 L4 61 C-6 27 18 7 47 15 C69 -6 105 -7 127 10 C159 -3 191 15 199 42 C233 52 248 87 237 114 C253 144 248 176 233 196 C244 234 222 260 196 264 C178 294 147 302 123 289 C96 306 67 304 44 293 Z M85 82 L85 220 L128 220 C164 220 167 190 167 151 C169 108 160 82 128 82 Z'
paths=[(B,160,338),(I,425,349),(R,602,337),(D,871,344)]
# Overall word scales to leave relaxed margins while preserving custom glyphs.
letters=''
for n,(p,x,y) in enumerate(paths):
    letters+=f'<g id="cloud-letter-{n}" transform="translate({x} {y}) scale(.88)"><path d="{p}" transform="translate(0 17)" fill="#78BFD6" stroke="{INK}" stroke-width="8" stroke-linejoin="round" fill-rule="evenodd"/><path d="{p}" fill="{CREAM}" stroke="{INK}" stroke-width="8" stroke-linejoin="round" fill-rule="evenodd"/></g>'
# Pink presence is visible through the B counter; wing rests over the cloud rim.
head='''<g id="peaches-in-the-B">
<path d="M236 440 C218 422 224 393 250 385 C250 369 270 365 278 377 C297 362 314 378 311 390 C338 393 348 413 340 442 Z" fill="#FFAFAC" stroke="#203B45" stroke-width="4.5"/>
<path d="M258 388 C243 374 251 364 260 369 M272 382 C263 363 277 352 287 360 C295 368 284 374 279 368" fill="none" stroke="#FF8198" stroke-width="7" stroke-linecap="round"/>
<ellipse cx="287" cy="408" rx="17" ry="22" fill="#FFF9ED" stroke="#203B45" stroke-width="3.5"/>
<ellipse cx="316" cy="409" rx="12" ry="18" fill="#FFF9ED" stroke="#203B45" stroke-width="3.5"/>
<ellipse cx="292" cy="412" rx="7" ry="11" fill="#203B45"/><ellipse cx="320" cy="412" rx="5" ry="8" fill="#203B45"/>
<circle cx="290" cy="407" r="2.5" fill="white"/><circle cx="318" cy="408" r="2" fill="white"/>
<path d="M306 427 C317 418 337 425 338 437 L308 439 Q299 434 306 427" fill="#FFD45B" stroke="#203B45" stroke-width="3.5" stroke-linejoin="round"/>
<path d="M276 390 L270 384 M324 393 L330 388" stroke="#203B45" stroke-width="3" stroke-linecap="round"/>
<circle cx="275" cy="432" r="6" fill="#FF8198"/>
</g>'''
# Face confined exactly to the upper counter, so the cloud-B stays legible.
clip=f'<defs><clipPath id="b-window"><path d="M81 70 C93 55 135 55 151 67 C178 63 191 80 187 101 C184 121 162 128 144 122 L82 122 Z" transform="translate(160 338) scale(.88)"/></clipPath></defs>'
face=f'<g clip-path="url(#b-window)">{head}</g>'
wing='<path id="peaches-wing-on-rim" d="M229 449 C218 437 200 440 195 451 C187 468 202 482 215 477 C224 480 233 470 229 449 Z" fill="#FF8198" stroke="#203B45" stroke-width="4"/><path d="M201 457 Q207 465 218 461" fill="none" stroke="#FFCBC6" stroke-width="4" stroke-linecap="round"/>'
# Tuck the small name capsule into the typography's negative space.
capsule='<g id="push-up-capsule" transform="rotate(-4 681 285)"><rect x="495" y="246" width="355" height="91" rx="45.5" fill="#78BFD6"/><rect x="495" y="236" width="355" height="91" rx="45.5" fill="#F47D64" stroke="#203B45" stroke-width="6"/>'+lettering('Push-Up',672.5,302,66,weight=650)+'</g>'
# A restrained set of airy marks gives the bespoke word room to float.
accents='''<path d="M112 349 C132 335 143 334 164 338 M1055 628 C1074 632 1089 629 1104 618" fill="none" stroke="#70B6D0" stroke-width="7" stroke-linecap="round"/>
<path d="M339 677 Q597 710 901 672" fill="none" stroke="#89CBDE" stroke-width="11" stroke-linecap="round"/>
<circle cx="954" cy="278" r="8" fill="#FFF9ED"/><circle cx="139" cy="579" r="7" fill="#FFF9ED"/>'''+star(1004,313,23,'#FFD45B',INK,4)+star(212,290,18,'#FFF9ED',INK,3)
body=clip+accents+letters+face+wing+capsule
(OUT/'logo.svg').write_text(svg(body,SKY))
mark=clip+f'<g transform="translate(-149 -425.2) scale(1.4)"><g transform="translate(160 338) scale(.88)"><path d="{B}" fill="{CREAM}" stroke="{INK}" stroke-width="8" stroke-linejoin="round" fill-rule="evenodd"/></g>'+face+wing+'</g>'
(OUT/'mark.svg').write_text(svg(mark,SKY,512,512))
(OUT/'concept.json').write_text(json.dumps({'id':6,'name':'Cloud Letterplay','rationale':'Bespoke cloud-shaped BIRD lettering becomes the emblem itself, with Peaches peeking through the B and a coral Push-Up capsule floating in the sky.','theme':'Soft toy lettering, cloud cruise, Peaches','palette':[SKY,CREAM,INK,'#F47D64','#FFAFAC','#FF8198','#78BFD6','#FFD45B']},indent=2))
import xml.etree.ElementTree as ET
ET.parse(OUT/'logo.svg'); ET.parse(OUT/'mark.svg')
