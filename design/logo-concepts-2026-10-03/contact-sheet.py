from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json

ROOT=Path(__file__).resolve().parent
GAME=ROOT.parents[1]
entries=json.loads((ROOT/'manifest.json').read_text())
ink='#203B45';ground='#F2F0E9'
def font(size, family='Fredoka'):
    return ImageFont.truetype(str(GAME/'assets/fonts'/f'{family}.ttf'),size)

def make(selected, out, title, subtitle):
    cols=5;cw=432;ch=324;gap=24;margin=54;label=68;top=190
    rows=(len(selected)+cols-1)//cols
    canvas=Image.new('RGB',(margin*2+cols*cw+(cols-1)*gap,top+rows*(ch+label)+margin),ground)
    draw=ImageDraw.Draw(canvas)
    draw.text((margin,42),title,font=font(51),fill=ink)
    draw.text((margin,110),subtitle,font=font(24,'Nunito'),fill=ink)
    for i,e in enumerate(selected):
        x=margin+(i%cols)*(cw+gap);y=top+(i//cols)*(ch+label)
        im=Image.open(ROOT/e['dir']/'logo.png').convert('RGB').resize((cw,ch),Image.Resampling.LANCZOS)
        canvas.paste(im,(x,y))
        draw.text((x,y+ch+14),f"{e['id']:02}  {e['name']}",font=font(23),fill=ink)
    canvas.save(ROOT/out)

make(entries,'contact-sheet.png','Push-Up Bird / 20 logo concepts','01–10: current model     ·     11–20: GPT-6.1 Sol     ·     One independent agent per concept')
make([e for e in entries if e['id']<=10],'set-a.png','Push-Up Bird / Concepts 01–10','Ten independent agents · Current model')
make([e for e in entries if e['id']>10],'set-b.png','Push-Up Bird / Concepts 11–20','Ten independent agents · GPT-6.1 Sol')
print(f'Contact sheets rendered for {len(entries)} concepts.')
