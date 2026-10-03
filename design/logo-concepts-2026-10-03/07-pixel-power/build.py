from pathlib import Path
import json
import xml.etree.ElementTree as ET

OUT = Path(__file__).resolve().parent
C = {'navy':'#182D43','ink':'#0C1D30','cream':'#FFF9ED','sky':'#BDE9F6','coral':'#F47D64','yellow':'#FFD45B','ochre':'#EBAE42'}

FONT = {
 'P':['11110','10001','10001','11110','10000','10000','10000'],
 'U':['10001','10001','10001','10001','10001','10001','01110'],
 'S':['01111','10000','10000','01110','00001','00001','11110'],
 'H':['10001','10001','10001','11111','10001','10001','10001'],
 '-':['00000','00000','00000','11111','00000','00000','00000'],
 'B':['11110','10001','10001','11110','10001','10001','11110'],
 'I':['11111','00100','00100','00100','00100','00100','11111'],
 'R':['11110','10001','10001','11110','10100','10010','10001'],
 'D':['11110','10001','10001','10001','10001','10001','11110']
}

def rect(x,y,w,h,c):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{c}"/>'

def label(word,y,unit,fill):
    x=(1200-(len(word)*6-1)*unit)/2
    cells=[(x+(i*6+xx)*unit,y+yy*unit) for i,ch in enumerate(word) for yy,row in enumerate(FONT[ch]) for xx,v in enumerate(row) if v=='1']
    s=f'<g aria-label="{word}" id="lettering-{word.lower()}">'
    # Shared layers preserve the unbroken square counters and true pixel edges.
    s+='<g id="extrusion-'+word.lower()+'">'+''.join(rect(a+10,b+14,unit+2,unit+2,C['coral']) for a,b in cells)+'</g>'
    s+='<g id="keyline-'+word.lower()+'">'+''.join(rect(a-4,b-4,unit+8,unit+8,C['ink']) for a,b in cells)+'</g>'
    s+='<g id="face-'+word.lower()+'">'+''.join(rect(a,b,unit,unit,fill) for a,b in cells)+'</g></g>'
    return s

def bird(x,y,u=16):
    p={}
    def box(x0,y0,x1,y1,color):
        for yy in range(y0,y1):
            for xx in range(x0,x1):p[xx,yy]=color
    # Three pixel plumes, stepped round belly, and upturned wings.
    box(12,1,14,6,'yellow');box(16,0,18,5,'yellow');box(20,2,22,6,'yellow')
    spans={4:(12,22),5:(10,24),6:(9,25),7:(8,26),8:(8,26),9:(7,27),10:(7,27),11:(7,27),12:(7,27),13:(7,27),14:(8,26),15:(8,26),16:(9,25),17:(10,24),18:(12,22)}
    for yy,(a,b) in spans.items(): box(a,yy,b,yy+1,'yellow')
    box(3,7,5,11,'yellow');box(4,9,7,13,'yellow');box(6,11,10,15,'yellow')
    box(26,7,28,12,'yellow');box(25,10,29,13,'yellow')
    # Feet make Pip feel alive, with one foot lifted.
    box(12,19,14,21,'coral');box(10,20,14,21,'coral')
    box(20,19,22,20,'coral');box(21,19,24,20,'coral')
    # Warm shadow follows the lower stepped contour.
    box(9,14,10,16,'ochre');box(10,16,13,17,'ochre');box(12,17,22,18,'ochre');box(14,18,20,19,'ochre')
    # Large, square eyes with dark pupils facing the viewer.
    box(12,6,16,7,'ink');box(11,7,17,11,'cream');box(12,11,16,12,'cream')
    box(20,6,23,7,'ink');box(19,7,25,11,'cream');box(20,11,24,12,'cream')
    box(14,8,16,11,'ink');box(21,8,23,11,'ink')
    box(14,8,15,9,'cream');box(21,8,22,9,'cream')
    # Coral beak, with a stepped smile and a bright cheek.
    box(17,11,21,12,'coral');box(16,12,23,13,'coral');box(17,13,22,14,'coral')
    box(18,13,22,14,'ink');box(18,14,21,15,'coral');box(10,12,12,13,'coral')
    outline={}
    for xx,yy in p:
        for dx,dy in [(0,-1),(0,1),(-1,0),(1,0)]:
            if (xx+dx,yy+dy) not in p:outline[xx+dx,yy+dy]='ink'
    # Merge horizontal runs to keep the editable vector compact.
    allp={**outline,**p}
    parts=[]
    for yy in sorted({v[1] for v in allp}):
        xx=min(v[0] for v in allp if v[1]==yy)
        last=max(v[0] for v in allp if v[1]==yy)
        while xx<=last:
            if (xx,yy) not in allp:xx+=1;continue
            color=allp[xx,yy];end=xx+1
            while (end,yy) in allp and allp[end,yy]==color:end+=1
            parts.append(rect(x+xx*u,y+yy*u,(end-xx)*u,u,C[color]));xx=end
    return '<g id="pip-pixel-mascot">'+''.join(parts)+'</g>'

def star(x,y,u=10):
    rows=['00100','00100','11111','01110','01010']
    return '<g>'+''.join(rect(x+i*u,y+j*u,u,u,C['yellow']) for j,row in enumerate(rows) for i,v in enumerate(row) if v=='1')+'</g>'

def cloud(x,y,u=10):
    return '<g fill="'+C['sky']+'" opacity="0.28">'+f'<path d="M{x} {y+2*u}h{2*u}v{-u}h{u}v{-u}h{3*u}v{u}h{2*u}v{u}h{2*u}v{2*u}h{-10*u}Z"/></g>'

def wrap(body,w=1200,h=900):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" shape-rendering="crispEdges"><title>Push-Up Bird — Pixel Power</title>{rect(0,0,w,h,C["navy"])}{body}</svg>'

body='<g id="pixel-world">'+cloud(175,159,12)+cloud(851,227,11)+cloud(277,346,7)+star(272,263,10)+star(845,106,12)+star(905,363,8)
body+=rect(216,292,8,8,C['coral'])+rect(973,143,8,8,C['coral'])+rect(810,333,8,8,C['sky'])+'</g>'
body+=rect(426,437,350,16,C['ink'])
body+=bird(320,80,16)
body+=label('PUSH-UP',490,20,C['cream'])
body+=label('BIRD',663,24,C['yellow'])
body+='<g id="arcade-spark-bars">'+rect(235,730,70,12,C['sky'])+rect(895,730,70,12,C['sky'])+rect(253,760,52,12,C['coral'])+rect(895,760,52,12,C['coral'])+'</g>'
(OUT/'logo.svg').write_text(wrap(body))
(OUT/'mark.svg').write_text(wrap(bird(23,98,16),512,512))
(OUT/'concept.json').write_text(json.dumps({'id':7,'name':'Pixel Power','rationale':'A true grid-built arcade wordmark and cheerful pixel Pip turn the movement game into a collectible 8-bit adventure.','theme':'8-bit arcade / pixel mascot','palette':[C[k] for k in ('navy','cream','yellow','coral','sky')],'typography':'Hand-drawn 5×7 pixel glyphs, fully editable vector geometry'},indent=2)+'\n')
ET.parse(OUT/'logo.svg');ET.parse(OUT/'mark.svg')
print(OUT)
