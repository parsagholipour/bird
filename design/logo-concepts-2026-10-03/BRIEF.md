# Push-Up Bird logo exploration

Twenty independent concept agents: 01–10 inherit the parent model; 11–20 explicitly use GPT-6.1 Sol. Each agent owns just its numbered directory.

The game is a joyful offline arcade adventure controlled through push-ups, squats, jumping or touch. Existing motifs: Pip (round yellow bird, coral beak, huge eyes, three-feather crest), Minty (mint), Peaches (pink), Orbit (lavender), star trails, floating islands, garden gates, flying around the world, sky passport stamps, wing medals. The app's exact name is **Push-Up Bird**. Do not invent a new brand name or tagline. Concepts should feel like a polished game logo, not a corporate fitness company.

Palette: ink #203B45, cream #FFF9ED, sky #BDE9F6, coral #F47D64, yellow #FFD45B, mint #A8D8B4, lavender #B9AAF2. You may selectively expand it for your concept. Bundled typefaces Fredoka and Nunito.

Deliver `logo.svg` (1200×900 presentation artboard), `concept.json` (id number, name, rationale, theme, palette array), and `build.py` if used in your assigned directory. Optional `mark.svg` (square icon) appreciated. SVG is the primary editable art: use real vector geometry and outlined lettering; no external linked assets and no text nodes. Strong centered visual hierarchy, comfortable margins, accurate title, no concept labels or footnotes inside the artboard. Focus on one distinctive design, not several variations. You may import editable birds from `design/*.svg`. Do not edit game source, existing art, or anyone else's concept.

Shared helper at `design/logo-concepts-2026-10-03/logo_tools.py`: Python3, fontTools available. Add parent directory to sys.path. `lettering(text,x,y,size,fill='#203B45',family='Fredoka',weight=650,anchor='middle',tracking=0,stroke=None,sw=0)` returns outlined paths, with baseline y. `asset(name,x,y,width,prefix='unique')` embeds existing vector art. `svg(body,bg='#FFF9ED',width=1200,height=900)` wraps it. `star(x,y,r=20,fill='#FFD45B',stroke='#203B45',sw=3)` supplies a star. Make your own shapes and arrangements so concepts are genuinely different. Parent will render and inspect; validate your SVG as XML. You can inspect source images with view_image if needed.

Do not ask questions. No subdelegation. Return the directory path and a one-sentence rationale when complete.
