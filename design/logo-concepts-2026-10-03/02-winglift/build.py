from pathlib import Path
import sys, json
import xml.etree.ElementTree as ET
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from logo_tools import svg, lettering
OUT=Path(__file__).resolve().parent
INK='#203B45'; CREAM='#FFF9ED'; GOLD='#FFD45B'; CORAL='#F47D64'
# Two hand-built initials share a rising bird silhouette. Each counter remains editable.
mark=f'''<g id="winglift-monogram">
  <g id="p-wing" transform="rotate(-13 -65 10)">
    <path fill="{INK}" d="M-177 155 L-177 -102 Q-177 -158 -121 -158 L-77 -158 C-10 -158 24 -122 24 -67 C24 -9 -15 30 -77 30 L-105 30 L-105 124 Q-139 137 -177 155Z"/>
    <path fill="{GOLD}" d="M-105 -95 L-77 -95 C-57 -95 -46 -83 -46 -64 C-46 -44 -58 -32 -79 -32 L-105 -32Z"/>
  </g>
  <path id="beak" fill="{CORAL}" d="M150 -98 L232 -48 Q240 -42 231 -37 L155 -12Z"/>
  <path id="b-body" fill="{INK}" d="M22 -128 H99 C155 -128 184 -102 184 -61 C184 -27 169 -8 146 4 C182 14 207 36 207 72 C207 125 169 151 106 151 H22Z"/>
  <path id="upper-counter" fill="{GOLD}" d="M90 -76 H104 C123 -76 134 -66 134 -50 C134 -32 122 -22 104 -22 H90Z"/>
  <circle id="eye" cx="112" cy="-53" r="8" fill="{INK}"/>
  <path id="lower-counter" fill="{CREAM}" d="M90 38 H111 C135 38 147 49 147 69 C147 88 134 98 111 98 H90Z"/>
</g>'''
body='<g id="logo-symbol" transform="translate(593 350) scale(1.12)">'+mark+'</g>'
body+=lettering('Push-Up Bird',600,674,112,fill=INK,weight=620,tracking=-1.5)
# A compact, deliberate coral hyphen is already carried by the outlined name.
(OUT/'logo.svg').write_text(svg(body))
(OUT/'mark.svg').write_text(svg('<g transform="translate(250 248) scale(.9)">'+mark+'</g>',width=512,height=512))
(OUT/'concept.json').write_text(json.dumps({'id':2,'name':'Winglift Monogram','rationale':'A rising P becomes the wing while a rounded B becomes Pip’s profile, joining playful initials with a bright beak and a warm, compact wordmark.','theme':'Minimal bird monogram','palette':[INK,CREAM,GOLD,CORAL]},indent=2)+'\n')
ET.parse(OUT/'logo.svg'); ET.parse(OUT/'mark.svg')
