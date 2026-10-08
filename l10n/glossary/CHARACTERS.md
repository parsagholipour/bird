# Beakbound: character bible for translators

Source: the game snapshot `base @ 480f4c8` (`lib/domain/campaign.dart`,
`lib/domain/campaign_story.dart`, `docs/story-voices.md`,
`docs/story-voices-sources.json`, `docs/flight-voices-sources.json`). Read it
together with `terms.en.json` (names and terms; ids such as `boss.baron-bat`
below point there).

Two voice systems carry the characters:

- **Story** (386 clips, 372 recorded, 14 *pending recording*): scenes on the
  campaign map, the 41 thank-you notes and the four sprint calls. In a scene the
  courier's line is ONE caption shared by all four birds (recorded four times,
  once per bird voice).
- **Flight** (1,273 lines): each bird has its OWN 271 lines; the five endless
  bosses have 34 lines each (the Pirate Captain 37), Neferhoo 16. King Coo and
  the Searchlight Gargoyle are silent in flight.

Every translated line keeps the English ElevenLabs voice of its character (same
voice id), so the voice names below tell you how each line will sound.

## Tone of the game

- **Kid-friendly, warm and silly.** Beakbound is a casual tap-to-fly bird
  courier adventure (push-ups, squats and jumps are side mini games; it is not
  a fitness app). Nothing is ever scary, cruel or violent: enemies are
  "knocked out", bats get "Sweet dreams", fireballs "singe", the knockout
  screen says "Bonk!".
- **Bosses are comic and redeemable.** Each took a mail route for a small,
  silly reason (sleep, ink, lamps, stamps, loneliness) and ends with a job at
  the Sky Club. Their menace is theatrical; keep them funny, never nasty.
- **Puns and running gags everywhere** (see the last section). Recreate the
  effect; do not translate puns literally.
- **The motto "Every letter lands."** is the club's rule and the game's
  catchphrase. It opens and closes the story, sits under the logo on Home and
  recurs in the birds' and Bill's lines ("Every letter lands!",
  "Every letter lands, and mine lands FAST!", the Dragon's "Does every letter
  really land?"). **Translate it once and reuse it verbatim**, including in
  the variants that build on it.
- **Short lines.** The whole app is a fixed 792×360 frame; story lines are at
  most 100 characters, in-flight warnings 6 words or fewer, most flight lines
  12 words or fewer (cargo lines 14). Stay as short as the English.

## Address and register

| Who → whom | Register | fr / de / es-419 / pt-BR / ru / tr | ja | ko |
|---|---|---|---|---|
| Bill → courier ("rookie") | warm, informal mentor | tu / du / tú / você / ты / sen | casual (plain form) | 반말 |
| Courier → Bill | friendly, first-name club | tu / du / tú / você / ты / sen | light polite (です/ます) | 해요체 |
| Courier → bosses and guardians (story and flight) | polite postal worker, even when teasing | vous / Sie / usted / o senhor, a senhora / вы / siz | polite (です/ます) | 해요체 |
| Baron Bat → courier | posh, condescending-polite | vous / Sie / usted / o senhor / вы / siz | haughty polite | 하오체 or haughty 해요체 |
| Neferhoo → courier | fussy, proper old official | vous / Sie / usted / o senhor / вы / siz | stiff polite | 하오체 |
| King Coo → courier | blustering police chief | vous / Sie / usted / o senhor / вы / siz | pompous | 하오체/반말 mix as fits |
| Spitter King, Dusk Empress, Pirate Captain, Ember Dragon, Searchlight Gargoyle → courier | condescending, theatrical or ancient | tu / du / tú / você / ты / sen | casual / archaic as fits | 반말 |
| Birds → the player (mini game rep cheers) | cheerful buddy | tu / du / tú / você / ты / sen | casual | 반말 |
| Thank-you notes → courier | grateful | as fits each signer (default informal) | as fits | 해요체 default |

**Traditional Chinese (zh-Hant):** use 你 throughout; use 您 only where Baron
Bat and Neferhoo address the courier (ironically polite).

**Arabic (ar):** matching the courier's grammatical gender is impossible in
the shared courier lines (one text for four birds), so every line that
addresses the courier (Bill's "rookie", the bosses, the narrator's "Your first
day.") uses the masculine generic or, better where it reads naturally, a
neutral construction (a verbal noun, an impersonal or plural phrasing). Use the
same rule for the courier's own shared lines. Bird-specific flight lines may
follow each bird's gender (below).

**Indonesian (id):** *kamu* (informal) where the table says tu/du, *Anda*
(formal) where it says vous/Sie; same split.

Additional rows for minor speakers (suggestions, not part of the fixed table):

| Who → whom | Register | fr / de / es-419 / pt-BR / ru / tr | ja | ko |
|---|---|---|---|---|
| Narrator → player ("Your first day.") | gentle storybook | tu / du / tú / você / ты / sen | soft plain narration | 해요체 |
| Bill → bosses and guardians ("Tell you what, Baron", "Neferhoo, the club needs…", "Stoneface…", "Route six, Dragon") | warm, courteous club manager offering a job | vous / Sie / usted / o senhor / вы / siz | polite (です/ます) | 해요체 |
| Birds → the player (all other flight lines: "partner", Peaches's pet names, "When this is over, I'll name a star after you.") | cheerful buddy | tu / du / tú / você / ты / sen | casual | 반말 |
| Birds → small enemies ("Hello, batty!", "Sorry, sweet pea!") | playful | tu / du / tú / você / ты / sen | casual | 반말 |
| Bosses → their own helpers ("Cousins!", "my lovelies", "Assistants!", "All hands!") | commanding, theatrical | plural: vous / ihr / ustedes / vocês / вы / siz | commanding plain | 반말 |
| Pirate Captain → the Parrot | gruff, fond | tu / du / tú / você / ты / sen | plain | 반말 |
| The club's letter → the Ember Dragon ("Dear Dragon… Come and keep our beacon.") | warm invitation from friends | tu / du / tú / você / ты / sen | warm です/ます letter style | 해요체 |
| Postcards → courier ("Dear courier, …") | warm, proud | tu / du / tú / você / ты / sen | です/ます letter style | 해요체 |
| Game UI → player (buttons, hints) | friendly, short (UI architect decides) | tu / du / tú / você / ты / sen | です/ます in sentences, plain in labels | 해요체 |

## Grammatical gender and self-reference

The game never states the birds' genders. The recommendations below come from
their voices and are **flagged: owner to confirm**.

| Character | Gender for self-reference and agreement | Notes |
|---|---|---|
| Pip | masculine (owner to confirm) | ja first person suggestion: 僕 |
| Peaches | feminine (owner to confirm) | ja: あたし |
| Minty | masculine (owner to confirm) | ja: オレ (cocky) or 僕 |
| Orbit | feminine (owner to confirm) | ja: わたし |
| The courier in story scenes (shared caption) | **gender-neutral** | ja: omit the pronoun (or 私); see below |
| Postmaster Bill | masculine | ja: わし or 私 |
| The narrator | no self-reference | |
| Baron Bat | masculine | posh "one" ("One's beauty sleep"); ja: 私(わたくし) or 吾輩 |
| Spitter King | masculine | mad scientist; ja: 我輩 |
| Dusk Empress | feminine | uses the royal "we" ("We shall not speak of this."); ja: わらわ; zh-Hant: 本宮 fits |
| Pirate Captain | masculine | calls himself "the Captain"; ja: わし / 俺様 |
| The Parrot | masculine ("He says hello") | never speaks |
| Ember Dragon | masculine | ancient; ja: 我(われ) |
| Neferhoo | masculine | ja: 私(わたくし) |
| King Coo | masculine | calls himself "the Commissioner" in the third person; ja: 本官 is the police officer's own word |
| Searchlight Gargoyle | masculine | calls himself "the Gargoyle" once ("The Gargoyle accepts.") |
| The Sphinx | masculine ("Mister Sphinx") | |
| Thank-you signers | see the table at the end | many are plural groups speaking as "we" |

Bosses address the courier with ONE line whichever bird is flying: phrase
everything they say to or about the courier so it fits any bird (no gendered
adjective agreement, no "lad"; see `address.lad`).

## The courier in the story: one caption for four birds

In every scene the courier is the equipped bird, under its own name tag, but the
**text is one caption** (52 lines, each recorded four times: Nelson, Cherry
Twinkle, Teddy Twinkle, Lola). Write it so it is correct for a masculine and a
feminine speaker:

- avoid first-person adjectives and participles that agree in gender
  ("Ready to fly!": fr *Prêt(e)*, es *Listo/a*, pt *Pronto/a*, ru *Готов(а)*,
  ar *مستعد/ة*). Rephrase: "C'est parti ! Où va le courrier ?";
- Russian: avoid first-person past tense ("Sorry! I couldn't look away." →
  a present or impersonal form);
- Japanese: avoid gendered first-person pronouns (僕/あたし); omit the subject;
- Arabic: first-person verbs are not gendered, adjectives are: prefer verbs.

The courier is curious, brave and polite: short questions ("Who would steal a
mail route?", "Pirates?"), plucky resolve ("Not on my route."), kind solutions
("We could just add lampshades…", "It still counts. Every letter lands!"). It
greets every door with "Sky Club post!" and calls bosses "sir", "Baron",
"Empress", "Commissioner", "Captain" politely.

## The four birds

Each bird is the courier in the story (shared caption) and has 271 lines of its
own in flight, plus the four shared sprint calls ("Woo-hooo!", "Turbo
feathers!", "Bye-bye, gravity!", "Wheeee!", same text for all four). Their
flight lines are written in each bird's own voice: keep the personalities
distinct. The birds talk to the player as a teammate (informal), to bosses
politely (see the table), and quote Bill's tips word for word (see "Callbacks").

### Pip

- **Who:** a small, earnest, studious rookie (species not stated; sunshine
  colours, trail "Sunshine bubbles"). Tagline: "Small bird. Big sky."
- **Age feel:** a keen kid; the class swot.
- **Voice:** Nelson – Awkward Nerd Character (high, slightly squeaky, earnest).
- **Speech style:** counts, measures, makes notes and charts, quotes rules
  and fun facts; nervous but determined; science words ("Trajectory",
  "Recalculating!", "Statistically, we're amazing now!").
- **Pet phrases:** "Small bird, big sky", "Noted!", "logbook", "In pen!",
  "Bill's tip, word for word", "Rookie Pip".
- **Lines:** "Rookie courier Pip, reporting for duty! Ahem. Flying now." ·
  "One heart left. One is still a whole number!" · "Fun fact: the first stamp
  cost one penny. I have two." · "Top notch lit! Literally top notch!" ·
  "Royal Courier? I'm just Courier. Courier Pip."
- **Addresses the player:** "partner". Bosses: "Your Lordship", "His
  Majesty the beetle", "Her Highness".
- **Gender:** masculine recommended (owner to confirm).

### Peaches

- **Who:** a pink bird with rosy cheeks and a curly crest, sweet and bubbly,
  "all heart" (trail "Peach hearts"). Tagline: "Rosy cheeks, curly crest, all
  heart."
- **Age feel:** a cheerful little girl who wants to hug everyone.
- **Voice:** Cherry Twinkle – Adorable Cartoon Girl (sweet, bubbly).
- **Speech style:** hearts, hugs, cuddles, sparkles; cute words ("Ouchie!",
  "Owie!", "Boop!"); kind to enemies and bosses ("Sending you a get-well hug!",
  "I kind of want to hug them"); jokes on her own name ("Toasted peach!").
- **Pet names (never the same twice):** sweetie, sugar, cupcake, lovebug,
  gumdrop, buttercup, jellybean, sweet pea, honey, honeybun, sweetheart,
  darling, sugarplum, pumpkin, poppet, cutie, lovely: use a varied set of
  sweet, gender-neutral endearments in your language.
- **Lines:** "Wings out, heart open. Let's go make somebody smile!" · "I think
  every letter is a hug that learned to fly." · "Hi, Mister Sphinx! Big smile?
  No? Maybe tomorrow, then." · "Everybody deserves a letter, Dragon. Even you.
  Especially you."
- **Gender:** feminine recommended (owner to confirm).

### Minty

- **Who:** a tiny mint-green hummingbird, the **default first bird** a new
  player flies with (trail "Mint leaves"). Tagline: "Tiny hummer. Fresh sprig.
  Full speed."
- **Age feel:** a cocky, quick little boy.
- **Voice:** Teddy Twinkle – Cute Cartoon Boy (cheerful, quick).
- **Speech style:** speed-mad and bragging, racing slang ("lap time",
  "overtake", "photo finish", "express lane"); short punchy lines; nectar and
  snacks.
- **Pet phrases:** "zero brakes", "Minty express!", "Hummingbird hyperdrive!",
  "Signed, sealed, zoomed!"
- **Lines:** "Big sky, tiny bird, zero brakes!" · "Ha! Too slow, pal!" ·
  "Brew's done, Your Majesty! Try mint tea. Named after me, basically." ·
  "Hey, Dragon... for you, I'll even slow down. Somebody wrote to you."
- **Addresses:** the player "partner"; enemies "buddy", "pal"; a boss "bossy".
- **Gender:** masculine recommended (owner to confirm).

### Orbit

- **Who:** a dreamy little owl who flies by starlight (trail "Stardust
  sparkles"). Tagline: "A dreamy owl who flies by starlight."
- **Age feel:** a sleepy, gentle child at bedtime.
- **Voice:** Lola – Soft, Innocent and Calming (soft, calm).
- **Speech style:** soft, slow, poetic images of moon, stars, pillows,
  lullabies, naps; ellipses; understated even in danger ("A shot. Let's not.").
- **Lines:** "Wings open. Clouds ahead, soft as pillows." · "Letters are like
  stars. Small, and full of far away." · "Return to sender, softly." · "Sleep
  well, old courier. Your letter landed." · "That was very scary. I nearly
  woke up."
- **Gender:** feminine recommended (owner to confirm).

## Postmaster Bill

- **Who:** the old pelican who runs the Sky Club post (`char.postmaster-bill`).
  His bill pouch was the club's first mailbag. He briefs every route, gives the
  fight tips and makes the (bad) jokes. Story only (62 clips); the birds quote
  him in flight.
- **Age feel:** a jolly old postmaster, eccentric, colourful, British.
- **Voice:** GERALD – Exciting Older Voice.
- **Speech style:** warm, brisk, wry; one-liners and dad jokes; postal
  metaphors; ends briefings on a tip ("Shoot the seeds down, rookie. And don't
  drink anything!").
- **Catchphrases:** "rookie" (every scene), "Club rule: every letter lands.",
  "Keep your beak up.", "He's all screech", "No flame seal on this guardian."
- **Jokes to recreate:** "It's carnival week, so half the mail is confetti." ·
  "He says the morning post wakes him. His bedtime is our rush hour." ·
  "We've delivered here for four thousand years and lost one letter." ·
  "A wire can't carry a parcel, rookie. Or a hug. Or noodles." · "Our
  pigeonholes have never had a pigeon. Commissioner wanted. Pay: a hot bagel a
  day." · "Stay in the dark, rookie… Don't mention pigeons."
- **Reads the club's letter to the Dragon** (two captions, `after-5-3/4`, in
  his voice: "Dear Dragon. The Sky Club has a new route, and no one to light
  the way." / "Come and keep our beacon. Signed: everyone. Even the Baron.").
- **Gender:** masculine. Register: see the table (informal to the courier).

## The narrator

- **Who:** an unseen storybook narrator who reads the place captions: the
  prologue plate "The Sky Club post. Sunrise. Your first day." and the end card
  "To be continued… Next stop: Paris, the City of Light."
- **Voice:** Twinkle – Narration & Acting (gentle storybook).
- **Style:** short, calm phrases; addresses the player directly, gender-neutral.
  The "To be continued…" caption is detected by the game from its text: tell
  the UI architect your exact wording.

## Bosses

### Baron Bat (chapter 1, lair 1-8)

- **Who:** a smug aristocrat bat with a crown who roosts on the Aztec temple
  top. The morning post wakes him at sunrise, so he took the Canopy Route; he
  gets his canopy delivered at dusk instead. Epithet: LORD OF THE STORM (THE
  STORM RETURNS when he comes back louder in endless).
- **Age feel:** a vain young-ish posh aristocrat.
- **Voice:** Posh Josh.
- **Style:** posh British understatement ("Frightfully", "Do keep going",
  "Marvellous"), vanity ("I bruise like a peach", "Not the face!"), sleepiness;
  speaks of himself as "one". Twists idioms: "at your disservice", "No more
  Mister Nice Bat!", "Mind the gap".
- **Addresses the courier:** "little courier", "darling" (posh, polite form).
  His bats: "Cousins!", "Relatives!", "my little ones".
- **Lines:** "WHO is flapping on my doorstep at sunrise?" · "This route is my
  roost now, little courier!" · "Every dawn: flap, thump, “POST!” A bat needs
  his beauty sleep." · "Dusk! How civilised. …You may go." · Thank-you:
  "Fine. FINE. Take your noisy route."

### Spitter King (chapter 2, lair 2-9)

- **Who:** king of the spitter beetles and a mad alchemist with a flask for a
  crown, boiling letters for an ink that never fades. His brew turns to mint
  tea; he becomes the club's (Royal) ink-maker. Epithet: BREWER OF THE SWARM.
- **Age feel:** an excitable middle-aged mad professor.
- **Voice:** Dr. Von Fusion – VF.
- **Style:** lab jargon and glee ("Hypothesis:", "Data noted. Painful data.",
  "EUREKA!", "Science!"), recipes made of letter phrases ("One “Dear
  Grandma”, two “Wish you were here”, stir…"), self-aware ("They called me
  mad! Well... they had a point.").
- **Addresses the courier:** "courier" (informal); helpers: "Assistants!",
  "my little scarabs", "Beetles!".
- **Lines:** "A courier! Splendid. Is that fresh mail I smell?" · "Every
  letter on my road goes in the brew!" · "My brew! It has gone all… minty." ·
  "Acid one, courier nil!" · Thank-you: "Bah. It was very nearly ink."

### Dusk Empress (chapter 3, lair 3-8)

- **Who:** a velvety dusk-moth empress in a diadem who put the city lamps to
  bed because her moths kept bumping into them. She ends lighting the lamps
  herself each dusk, with lampshades. Epithet: KEEPER OF THE TWILIGHT VEIL.
- **Age feel:** an elegant, mysterious lady; a lullaby voice.
- **Voice:** Enchantress (velvety, mysterious, in a hush).
- **Style:** hushed, slow, soothing-menacing; bedtime vocabulary ("Sweet
  dreams", "lullabies", "rest a while"); royal "we" ("We shall not speak of
  this."). "Bonk. Bonk." is her imitation of moths on lamps.
- **Addresses the courier:** "little one", "little wanderer", "night bird",
  "courier" (informal, gently condescending); her moths: "my lovelies",
  "my pretties", "my sweets".
- **Lines:** "Shh. You will wake the lamps." · "Hush now. The night mail is
  sleeping." · "Tiptoe, little one. You flap like a marching band." · "Shades…
  Yes. And I shall light the lamps myself, each dusk." · Thank-you: "Very
  well. Let them have their lamps."
- **Note:** English TTS heard "lamps" as "lambs" (the English prompt pins
  /læmps/). Check your word for lamp is clear in the take.

### Pirate Captain (chapter 4, lair 4-8), and his Parrot

- **Who:** a gruff old West Country sea dog with a ship, a cannon and a parrot,
  who raids mailbags for the STAMPS (a stamp collector who keeps the envelopes
  and throws the letters back). The club sends him a stamp from every route.
  Epithet: TERROR OF THE HIGH TIDE.
- **Age feel:** an old salt, loud and hearty.
- **Voice:** Matthew Schmitz – Old Pirate Captain.
- **Style:** stage pirate (West Country): "Arr!", "Ahoy!", "Avast!", "Shiver
  me timbers!", "me ship", "ye/yer", "be" for "is/are", "me handsome", "Proper
  job"; philately words ("Perforations! Postmarks!", "a penny black").
  Recreate with your language's pirate idiom, readable for kids.
- **Addresses the courier:** "postie", "sprat", "skylubber", "matey",
  "feathers", "me handsome", and in the story "lad" (**gender trap**: use a
  neutral pirate word). Calls himself "the Captain"; crew: "All hands!",
  "me hearties".
- **The Parrot** (`npc.parrot`): his silent first mate ("Log it, Parrot!",
  "Parrot, strike the colours."); masculine; stays at the club ("The parrot
  stayed. He says hello.").
- **Lines:** "Not the mail, lad. The STAMPS. Tiny paper treasure from every
  port!" · "Arr! Every mailbag on these waves be mine!" · "Me hat! Me ship! Me
  stamp album… it’s soggy." · Thank-you: "Arr. Ye fly well, for a postie."

### Ember Dragon (chapter 5, lair 5-8)

- **Who:** an ancient, grand, weary and lonely dragon at the edge of the map.
  Nobody ever wrote to him, so he wrote four warm letters with flame seals
  giving the routes away. The last delivery is the first letter ever addressed
  to him; he becomes keeper of the beacon on route six. Epithet: SOVEREIGN OF
  THE BURNING SKY.
- **Age feel:** very old, slow, majestic, melancholic.
- **Voice:** Smoke – The Dragon.
- **Style:** grand, archaic-leaning, slow; fire imagery ("kindling",
  "embers"); loneliness under the threat ("It is quiet at the edge of the map.
  Always quiet.").
- **Addresses the courier:** "little spark", "hatchling", "small one",
  "messenger", "little bird", "courier" (informal, ancient).
- **Lines:** "No route ever reached ME. If the mail can’t find me, let it find
  no one!" · "The sky is mine. Your letters are kindling." · "Tell me,
  courier. Does every letter really land?" · "I wrote four letters, to feel
  part of the mail. This is the first one back." · Thank-you: "I have read it
  nine times already."

## Guardians

Campaign mini-bosses before a chapter's boss; always called **GUARDIAN**.
They sent no letter and carry no flame seal; each ends with a club job.

### Neferhoo (Egypt, 2-6 "Return to Sender")

- **Who:** the Mummy Courier: a 4,000-year-old hoopoe in linen wraps and the
  golden mask of the Pharaoh's post, the club's first Egypt courier, sealed in
  the pyramid with the last letter of his round. Through his mask he could not
  find its door; it was for the Sphinx, right outside. He becomes Keeper of
  Lost Letters. Epithet: KEEPER OF THE LOST LETTER.
- **Age feel:** a very old, fussy, precise royal official; warm and silly
  underneath.
- **Voice:** Herbie (Old Man with a Lisp and whistle S sounds) for his 8 story
  and 16 flight lines (the lisp is in the voice; do not write it).
  Pronounce the name NEF-er-hoo.
- **Style:** proper, quick to take offence ("My own letter?! How rude."),
  postal battle cries ("Mail call!", "Special delivery!", "Signed, sealed,
  delivered!", "Enough! EXPRESS POST!"), catchphrase "Return to sender!".
- **Addresses the courier:** "fledgling" (polite form, see the table). The
  courier calls him "sir"; Peaches "Mister Neferhoo"; Orbit "old courier".
- **Lines:** "HALT! No courier flies the Pharaoh’s post but me!" ·
  "Neferhoo, Royal Courier. Four thousand years on this route." · "One letter
  left in my bag… and I cannot find its door." · "My mask! …Oh. Oh my. I can
  see!" · "Lost letters? …Then I start with this one. Off to the Sphinx!"

### King Coo (New York, 3-2 "Wheels in the Rain")

- **Who:** a huge, plump, grumpy pouter pigeon in a police cap, Commissioner
  of the Curb, who grounds the whole sky because someone moved his bread cart
  (it was sheltering from the rain under the theatre marquee of 3-1). He
  becomes Commissioner of the club's pigeonholes for a hot bagel a day.
- **Age feel:** a blustering old police chief who missed his lunch.
- **Voice:** *to audition* (fallback Rusty Malone – Deep & Raspy; a Brooklyn
  police commissioner). **His 8 story clips are pending recording** in English
  too; their captions show. He is silent in flight; his card shouts "COO!".
- **Style:** parade-ground bellow ("HALT!", "By order of the Commissioner"),
  wounded mumble ("Tonight: not a crumb, only wheel tracks."), sudden
  deflation ("…I may have overreacted."), third-person self-reference ("The
  Commissioner accepts."). The accent comes from the voice: do not write
  dialect.
- **Addresses the courier:** see the table (pompous polite). The courier and
  Bill call him "Commissioner".
- **Lines:** "HALT! By order of the Commissioner, nothing with wheels or wings
  passes!" · "Umbrellas? A likely story! You’re the one who moved my bread
  cart!" · "Nobody flies till the bread cart is found!" · "My cap! …It was the
  only thing that made them listen." · "A bagel a day? …The Commissioner
  accepts."

### Searchlight Gargoyle (New York, 3-4 "Storm Warning")

- **Who:** a limestone eagle bolted to the tallest tower in 1931, searchlights
  for eyes, a lamp in his chest; a lonely old ham. Ninety-odd years of people
  admiring the skyline and nobody looking up. He becomes the night mail's
  landing light. Bill nicknames him "Stoneface". Epithet: WATCHMAN OF THE
  TALLEST TOWER.
- **Age feel:** an old theatrical stage actor.
- **Voice:** *to audition* (fallback Eldrin – Wise Epic Fantasy Narration
  Storyteller; a transatlantic ham with vibrato). **His 6 story clips are
  pending recording**; captions show. Silent in flight.
- **Style:** grand theatre vocabulary ("the curtain falls", "a nightly
  audience", "my best feature"), calls everyone "darling", cracks into
  sincerity ("You looked. That’s all I ever wanted."), third person once ("The
  Gargoyle accepts.").
- **Lines:** "A visitor! Step into the light, darling, let me look at you!" ·
  "Ninety-odd years on this ledge. Everyone admires the skyline. Nobody looks
  up." · "Hold still! Nobody ever stays in the light." · "A nightly audience!
  …Darling, I was born for this. The Gargoyle accepts."

## The Sphinx

- **Who:** the Great Sphinx of Giza: receives new riddles on 2-4 ("Finally,
  some fresh material.") and, 4,000 years late, Neferhoo's lost letter; "too
  polite to complain". Its note closes Neferhoo's last scene, read in its own
  voice: "“Delivered at last. Worth the wait. Signed: the Sphinx.”"
- **Voice:** Matthew Schmitz – Ancient Sage Dragon Wizard (dry, slow, deep).
- **Gender:** masculine (Peaches: "Hi, Mister Sphinx!").

## Thank-you signers (41 levels)

Each finished level shows a note "“…” — signer" and plays it in the signer's
voice. Most signers are groups speaking as one ("we"); in gendered languages,
pick the group's agreement from the voice and the description. Boss levels'
notes are the beaten boss grumbling (masculine except the Empress). All 41 are
recorded in English (the pyramid caretaker's, 2-6, included).

| Level | Signer | Voice | Tone (audio tags) | Grammar and character | Line |
|---|---|---|---|---|---|
| 1-1 | The toucan twins | Minnie – high pitch cartoon character | [excited] [giggles] | Plural ("We squawked for an hour"); giggly children. | “Best birthday ever! We squawked for an hour.” |
| 1-2 | The sloth stargazer | Kavian R – Chill, Relaxed Character | [slowly] [sleepy] [yawns] | Singular; slow and sleepy, dry humour ("No rush, I said. You rushed."). | “No rush, I said. You rushed. Thank you.” |
| 1-3 | The firefly nursery | Kiran – Very Young Adorable Storyteller | [softly] [happy] | A place/group speaking as one; soft and sweet. "Nursery" = a place where small children are looked after, not a plant nursery. | “Now even the shy ones are glowing.” |
| 1-4 | The samba macaws | Candy – Girly and Sweet | [excited] | Plural, excited. | “The parade starts now. You made it!” |
| 1-5 | The drum captain | Freddy Quicksilver – Flamboyant & Queer | [laughs] [excited] | Singular, flamboyant ("Marvellous!"). Not the Pirate Captain: use a band-leader word, not the ship captain's. | “So fast my hat blew off. Marvellous!” |
| 1-6 | The temple cooks | Jerry B. – Santa Claus | [jolly] [laughs] | Plural, jolly. | “Hot chocolate for the whole temple!” |
| 1-7 | The dawn keeper | Eldrin – Wise Epic Fantasy Narration Storyteller | [calmly] [warmly] | Singular, calm and wise. | “Sunrise is back on schedule.” |
| 1-8 | Baron Bat | Posh Josh | [grumpy] [shouting] [sighs] | Baron Bat himself; masculine; grumpy, posh. | “Fine. FINE. Take your noisy route.” |
| 2-1 | The chariot racers | VALF – Child, Young, Playful & Sarcastic | [excited] | Plural, proud and excited ("We shall wear them at every race!"). | “We shall wear them at every race!” |
| 2-2 | The statue carver | Potato – Earthy & Rooted | [relieved] | Singular; relieved. "his nose" in the thank-you is the STATUE's nose. | “At last I can finish his nose.” |
| 2-3 | The fire brigade | Rusty Malone – Deep & Raspy | [breathless] | A group speaking as one; breathless. | “Just in time. Truly, JUST in time.” |
| 2-4 | The Sphinx | Matthew Schmitz – Ancient Sage Dragon Wizard | [dryly] [slowly] | The Sphinx; masculine ("Mister Sphinx"); dry and slow. | “Finally, some fresh material.” |
| 2-5 | The pyramid astronomer | The Doc | [excited] | Singular, excited. | “Now I can see the meteors coming!” |
| 2-6 | The pyramid caretaker | Jessie – Vintage Narrator | [delighted] [laughs] | Singular, FEMININE ("She says the dust talks back"); delighted. | “Four thousand years of dust, gone by lunch!” |
| 2-7 | The lantern sellers | Emily – Bright & Energetic | [happy] | Plural, happy ("A thousand thanks!"). | “The bazaar glows again. A thousand thanks!” |
| 2-8 | The caravan leader | Matthew Schmitz – Old Outlaw Cowboy | [dryly] [pause] | Singular, dry ("Forty camels. Forty thank-yous."). | “Forty camels. Forty thank-yous.” |
| 2-9 | Spitter King | Dr. Von Fusion – VF | [grumbling] [sighs] | The Spitter King himself; masculine; grumbling. | “Bah. It was very nearly ink.” |
| 3-1 | The stage manager | Countdown Casey – Radio DJ | [excited] | Singular, showbiz-excited. | “The show goes on! Front row for you.” |
| 3-2 | The newsstand pigeons | Scruffy Duck – Energetic & Raspy | [relieved] | Plural, relieved. | “Dry feathers at last. You’re a hero.” |
| 3-3 | The night cabbies | Mister Gruff – Miserable old neighbor | [surprised] | Plural, gruffly surprised. Cargo says "night-shift cabbies", the signer "the night cabbies": same people. | “Still warm! How fast do you fly?” |
| 3-4 | The tower keeper | Grampa Werthers – Old & Cranky | [delighted] | Singular, delighted old man. | “It spins! It points! It’s perfect.” |
| 3-5 | The rooftop painters | Jamie – French Accent \| Charismatic | [delighted] | Plural; their thank-you uses the French word "Magnifique" for flavour (French translators: keep it natural, the foreign-flavour joke does not apply). | “Magnifique. Not one crumb lost.” |
| 3-6 | The accordion player | Henri – French-American Narrator | [happy] | Singular, happy. | “The pages blew in right on the beat.” |
| 3-7 | The baker | Ayla – Bubbly, Cute & Expressive | [excited] [giggles] | Singular, FEMININE (voice and "I said yes!"), giddy. | “I said yes! I mean… thank you.” |
| 3-8 | Dusk Empress | Enchantress – mysterious, witchy, villain character | [softly] [sighs] | The Dusk Empress herself; feminine; soft, resigned. | “Very well. Let them have their lamps.” |
| 4-1 | The lighthouse keeper | Jessie – Vintage Narrator | [warmly] | Singular, warm. | “Now the ships can find us again.” |
| 4-2 | The volcano baker | Milly – Cheerful Aussie Character Voice | [cheerfully] | Singular, cheerful, feminine voice. | “My lava cakes thank you.” |
| 4-3 | The kite flyers | Cassidy Cartoon – Comical & expressive | [excited] | Plural, excited. | “Best wind we’ve had all year!” |
| 4-4 | The island hermit | Grimey | [overjoyed] | Singular, masculine ("He's waited ages"), overjoyed. | “Forty years I waited for a reply!” |
| 4-5 | The ferry crew | Gravel Midnight – Deep Character Voice | [cheerfully] | A group speaking as one, cheerful. | “High water at noon. Good to know!” |
| 4-6 | The gull colony | Candy – Girly and Sweet | [excited] | A group speaking as one ("Dinner for nine hundred"). | “Dinner for nine hundred. Thanks!” |
| 4-7 | The storm watch | David – Deep, Southern, Cowboy | [relieved] | A group speaking as one; relieved. Cargo says "storm-watch sailors": same people. | “Warm toes at last. Bless the post.” |
| 4-8 | Pirate Captain | Matthew Schmitz – Old Pirate Captain | [grudgingly] | The Pirate Captain himself; masculine; grudging pirate-speak. | “Arr. Ye fly well, for a postie.” |
| 5-1 | The penguin choir | Lulu Lollipop – Sweet & Bubbly Girl | [happy] [cheerfully] | Plural, happy ("Warm heads, high notes."). | “Warm heads, high notes. Thank you!” |
| 5-2 | The polar station | celine – cuddly, thin and soft. | [relieved] [softly] | A place speaking for its crew; soft and relieved. | “First warm drink since winter began.” |
| 5-3 | The noodle chef | DEVILL – English Speaking Korean Male Streamer | [excited] | Singular, masculine, excited ("OPEN again" quotes the sign). | “OPEN again. Noodles on the house!” |
| 5-4 | Unit 7 | Silent Systemus – Sovereign Protocol | [robotic] | Unit 7, a robot; neutral (masculine voice); ALL CAPS, formal. | “PAPER. MARVELLOUS. I SHALL FRAME IT.” |
| 5-5 | The rooftop runners | Gigi – Cute, Peppy, Energetic | [breathless] | Plural, breathless. | “You beat our lap record delivering them.” |
| 5-6 | The lantern makers | Aurelia – High Quality Realistic Princess | [warmly] | Plural, warm. | “A thousand lights, thanks to you.” |
| 5-7 | The mountain monks | Mossbeard \| The God of the Wild | [calmly] [slowly] | Plural, calm and slow ("Sit. Rest."). | “Sit. Rest. The last climb is steep.” |
| 5-8 | Ember Dragon | Smoke – The Dragon | [softly] [happy] | The Ember Dragon himself; masculine; soft, happy. | “I have read it nine times already.” |

## Running gags and callbacks

Keep each gag consistent across the story, the flight lines, the UI and the
achievements: one translation, reused.

- **"Every letter lands."** The motto (see Tone). It closes the prologue
  (courier: "Every letter lands. Got it!"), Neferhoo's and King Coo's last
  scenes and the whole story (after-5), and the birds use it when delivering.
  The Dragon turns it into a doubt: "Tell me, courier. Does every letter
  really land?"
- **Bill's bad jokes and "rookie".** Every Bill scene has "rookie" and usually
  a wry joke (confetti, rush hour, pigeonholes, "a wire can't carry… noodles").
  The birds quote him: "Start small, Bill told me.", "Bill's orders: don't
  drink anything!", "Did you know Bill's pouch was the club's first mailbag?"
- **Bill's tips are quoted word for word.** Level-card hints and Bill's scene
  tips come back in the birds' lines the first time a hazard appears; match
  them exactly: "Fly through the gold rings to outrun the fire!" (2-3) → "I
  memorized this: fly through the gold rings!"; "Ring sprints smash meteors."
  (2-5) → "Bill's tip, word for word: ring sprints smash meteors!"; "Sprint
  through the flocks." (3-7) → "The tip said: sprint through the flocks!";
  "Hop over the lava plumes." (4-2) → "My flash card says hop over them!";
  "Beetles spit seeds. Shoot the seeds down." → "Bill's rule: shoot the seeds
  down."; "Moths fire fans of three. Slip between them." → "Fans of three.
  Slip between them, Pip."; "Chain stars for 3×; three perfect gates earn a
  magnet." → "Just like the tip: chain the stars!", "Three perfect gates, one
  magnet!"; "Get through the fire first, rookie!" → "Get through the fire
  first. That's the plan."; "He's all screech" → "He's all screech, Bill
  says."; "half the mail is confetti" → "Bill says half the mail is confetti."
- **The Baron's beauty sleep and the dusk delivery.** The morning post wakes
  him ("Flap, thump, POST!"); he wants his beauty sleep; the canopy is
  delivered at dusk ("Dusk! How civilised."); the birds wish him "Sweet
  dreams" and promise to "tiptoe past at sunrise". He signs the Dragon's
  letter: "He dotted his “i” with a tiny bat." / "Signed: everyone. Even the
  Baron." His crown ends on the club's mantelpiece (postcard 1).
- **The Spitter King's ink, brew and tea.** He boils letters for an ink that
  never fades ("boils the words right off the page"); his recipe is made of
  letter phrases; the brew turns "all… minty"; "Tea is allowed."; he becomes
  Royal ink-maker; his flask crown is kept "as a vase" (postcard 2); thank-you
  "Bah. It was very nearly ink."; the birds: "Maybe try mint tea instead?",
  Minty: "Named after me, basically." Achievement "Mint Tea Again".
- **The Empress's lamps, "Bonk", lampshades.** Moths bumped into the lamps
  ("Bonk. Bonk. All night long."), so she put the lamps to bed ("Shh. You will
  wake the lamps."); the courier suggests lampshades; "Shades… Yes."; she
  lights them herself each dusk; "Do leave a light on." The chapter is "The
  Lamplight Line", the achievement "Lamplighter". English TTS misheard "lamps"
  as "lambs" (pinned with IPA in English only) and a whispered "night mail" as
  "nightmare": listen for near-homophones in your language.
- **The Captain's stamps (penny black).** He wants the stamps, not the mail
  ("Just the corners with the pictures!"), keeps the envelopes, dreams of a
  penny black, his stamp album gets soggy, and the club sends him a stamp from
  every route; the birds: "Stamps go ON letters, not in your album!", "I'll
  send you a heart stamp!" Pip's fact: "the first stamp cost one penny".
  Postage stamps are not the passport's ink stamps.
- **The Dragon who never got a letter.** The trail of flame seals ("Two routes,
  two seals." → "Three seals now. And every one posted from the edge of the
  map." → the Captain's "a little dragon" stamp → "A dragon! At the edge of the
  map…"); Bill "checked the books twice"; everybody signs the first letter ever
  sent to him; "I have read it nine times already."; "Then I had better learn
  to write back." The birds' farewells: "Nobody ever wrote to you? I've
  already started a draft!", "Everybody deserves a letter, Dragon."
- **Neferhoo's "Return to sender".** Bill's "lost one letter… The Sphinx won't
  say" (2-4) is paid off on 2-6: the lost letter was Neferhoo's, for the Sphinx.
  "Return to sender!" is his catchphrase, his card line, level 2-6's name, the
  achievement, a fight tag, and others borrow it (Baron: "Return to sender,
  darling."; Orbit: "Return to sender, softly."). His hurt line twists it:
  "Oof! Return to... me?" Keep one official postal formula. Bill's job offer
  "Keeper of Lost Letters" echoes his epithet "Keeper of the Lost Letter".
- **King Coo's bread cart and bagel.** The cart is missing ("same corner, same
  crumbs… only wheel tracks"); the courier's umbrellas are "A likely story!";
  the cart was under the 3-1 theatre marquee all night; "Our pigeonholes have
  never had a pigeon"; "A bagel a day? …The Commissioner accepts." The level is
  "Wheels in the Rain"; his arrival line "Somebody is very cross about the bread
  cart…"; his attacks are crumb bombs and stale crusts; achievement "Crumbs
  Cleared". The optional bark "Ooof! My lunch!" is not in the game yet.
- **The Gargoyle's "darling" and "Nobody looks up".** He calls everyone
  "darling" and laments "Nobody looks up."; Bill's answer is "Every courier
  will look up!"; Bill also warns "Don't mention pigeons." and ends "And yes,
  the pigeons may stay." (pigeons perch on statues). Achievement "Out of the
  Spotlight". His arrival headline "STORM WARNING" is the same phrase as level
  3-4's name.
- **Postal idioms as battle cries.** "Return to sender!", "Signed, sealed,
  delivered!" (Minty: "Signed, sealed, zoomed!"), "Special delivery!" (also the
  level card heading and an achievement), "Mail call!", "EXPRESS POST!" (also
  level 1-5's name), "Postmarked by cannonball!", "Sky Club post!" at every
  door.
- **Postcard P.S. teasers chain the chapters.** "The ancient road smells like
  something is bubbling." → chapter 2's brew; "The city lamps went dark last
  night. Bring a light." → chapter 3; "The harbour bells have stopped ringing."
  → chapter 4; "They say the sky at the edge of the map is on fire." → chapter
  5; "The endless sky is still out there, whenever you are." → Endless mode.
- **Numbers that repeat:** "four thousand years" (Egypt: Bill, Neferhoo, the
  caretaker, Pip), "five routes", "four letters" (the Dragon), "ninety-odd
  years" (the Gargoyle, since 1931), "forty" (camels; years of waiting).
- **Small recurring jokes:** the birds' "Sticks and stones? I brought the
  stones!" and "Rock beats shot!"; "Bonk!" (the knockout card) and the
  Empress's "Bonk. Bonk."; Pip's counting and "logbook"; Minty's speed
  bragging; Orbit's naps; Peaches's pet names; the toucans "say thank you
  (very loudly)" (postcard 1) after "We squawked for an hour."

## Voice script rules (story.json / flight.json)

- `text` is exactly the caption the game prints; `prompt` is the same words
  with the English audio tags (`[excited]`, `[sighs]`, `[whispers]`…) kept in
  English and in the same places. Never translate a tag or add words to the
  prompt that are not in the text.
- Keep the speaker's voice in mind: the line is spoken by the English voice
  named above, in your language.
- Use the glossary's single translation for every name and term; the bosses'
  card lines must equal their scene lines.
- Clips that are *pending recording* in English (King Coo 8, the Searchlight
  Gargoyle 6) still need translated captions; they stay pending.
- The four sprint calls are shared by all birds and must be gender-neutral.
- Pin a hard word's pronunciation only if a take needs it (IPA between
  slashes, as the English prompt does for /læmps/).

## Open questions for the owner

1. Confirm the bird genders used for agreement and Japanese pronouns: Pip
   masculine, Peaches feminine, Minty masculine, Orbit feminine.
2. Keep the bird names as they are (recommended) although Peaches, Minty and
   Orbit are meaningful words whose puns ("Toasted peach!", "Named after me,
   basically") will be adapted rather than kept?
3. King Coo: localize the pun with each language's pigeon coo, or keep "King
   Coo" everywhere?
4. "Sky Club": translate per language (recommended) or keep as an English
   brand like "Beakbound"?
5. Passport "stamps" (ink stamps) and the Captain's "stamps" (postage stamps)
   become two different words in most languages: accepted?
6. "STORM WARNING" is both the Gargoyle's arrival headline and level 3-4's
   name: keep them identical (assumed)?
