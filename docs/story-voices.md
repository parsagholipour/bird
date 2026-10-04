# Story voices

The campaign's characters speak. Every line of the first 23 story scenes, the
thank-you on every level's result and each bird's sprint calls were
recorded with ElevenLabs **Eleven v4**, one take per line, and are bundled in
`assets/audio/story/`. The game plays them offline.

Six more scenes, the guardians', are written and in the game but **not
recorded yet**: New York's four (47 clips, two voices still to audition: King
Coo and the Searchlight Gargoyle) and Egypt's two with the pyramid caretaker's
thank-you (31 clips; Neferhoo's voice is to be picked from five auditions
already made). Until a clip is recorded the game prints its line and plays
nothing, paced as with Character voices off. They are in
[New York: the guardians](#new-york-the-guardians-pending-recording) and
[Egypt: Neferhoo](#egypt-neferhoo-pending-recording);
[Adding a new character or voice](#adding-a-new-character-or-voice) is the
recipe for recording them, or for any voice after them. The working document
for recording, from nothing to a clip playing in the game, is
[story-voices-recording.md](story-voices-recording.md).

## The cast

| Part | Voice | Voice id | Why |
| --- | --- | --- | --- |
| Postmaster Bill | GERALD – Exciting Older Voice | `fGIZlgPQ75MMlvQ6WxgY` | An eccentric, warm, colourful old British voice for a pelican who tells bad jokes |
| Pip (courier) | Nelson – Awkward Nerd Character | `EaX6rnyDKjJx35tchi80` | High, slightly squeaky and earnest: a small bird with a big sky ahead of it. Picked by the game's owner after hearing five high-pitched auditions |
| Peaches (courier) | Cherry Twinkle – Adorable Cartoon Girl | `XJ2fW4ybq7HouelYYGcL` | Sweet and bubbly: "all heart" |
| Minty (courier) | Teddy Twinkle – Cute Cartoon Boy | `XjGYkUkzth8BPs29fmcV` | Cheerful and quick: a tiny hummingbird at full speed |
| Orbit (courier) | Lola – Soft, Innocent and Calming | `f9imtLc2jfOLXtqe3Ihb` | Soft and calm: a dreamy owl |
| Baron Bat | Posh Josh | `NXaTw4ifg0LAguvKuIwZ` | A smug aristocrat who wants his beauty sleep |
| Spitter King | Dr. Von Fusion – VF | `yjJ45q8TVCrtMhEKurxY` | A quirky, excitable mad alchemist |
| Dusk Empress | Enchantress | `sssn4wp3AspuK2kvy3Ym` | Velvety and mysterious; she speaks in a hush |
| Pirate Captain | Matthew Schmitz – Old Pirate Captain | `4Vl3K2x290GidNvuaLm7` | A gruff West Country sea dog |
| Ember Dragon | Smoke – The Dragon | `xsiB5fGhEtknnqzudCO6` | Old, grand and weary, for a dragon who only wanted a letter |
| King Coo (3-2 guardian) | *to audition*, fallback Rusty Malone – Deep & Raspy | `507tTFX0IPtqFzGd1CAL` (the fallback's) | A plump, pompous pigeon police commissioner with a New York accent: comic, never scary. [Brief](#king-coo) |
| Searchlight Gargoyle (3-4 guardian) | *to audition*, fallback Eldrin – Wise Epic Fantasy Narration Storyteller | `LvmvHEBEmMJBJw9UuhwO` (the fallback's) | A theatrical old stage actor, warm gravel and vibrato: a ham of a statue. [Brief](#searchlight-gargoyle) |
| Neferhoo (2-6 guardian) | *to pick from five auditions*, fallback Grampa Werthers – Old & Cranky | `MKlLqCItoCkvdhrxgtLv` (the fallback's) | A fussy, reedy, precise old royal courier, proper and quick to take offence, warm and silly underneath. [Brief](#neferhoo) |
| The place lines (the prologue, “To be continued…”) | Twinkle – Narration & Acting | `Qz7YNvloEr5RXwYE3NCH` | A gentle storybook narrator |

`python3 tool/prepare_story_voices.py --voices` prints every voice in the sources
file with its id and how many clips it speaks (GERALD 62, each bird 56).

The courier's lines are recorded four times, once in each bird's voice, and
the scene plays the equipped bird's take. The letter the Ember Dragon
receives is read aloud in Bill's voice, since Bill wrote it; the Sphinx's note
that closes Neferhoo's last word (`last-2-6-8`) is read in the Sphinx's.

The 41 thank-you notes are voiced by the people who sign them (40 recorded;
the pyramid caretaker's on 2-6 is pending, in Jessie – Vintage Narrator), from a wider
cast: the toucan twins (Minnie), the sloth stargazer (Kavian R, slow and
sleepy), the drum captain (Freddy Quicksilver), the Sphinx (Matthew
Schmitz – Ancient Sage), the Paris painters and accordion player (Jamie and
Henri, French accents), Unit 7 the robot (Silent Systemus) and more. A
boss's thank-you is in its own voice. Every clip's voice is in
`docs/story-voices-sources.json`.

## How the lines are directed

Each prompt is the printed line with Eleven v4 audio tags in front of the
words they colour: `[whispers]`, `[chuckles]`, `[sighs]`, `[shouting]`,
`[trembling voice]` and so on, chosen from the line's mood and the scene.
For example, Bill's first line is sent as
`[cheerfully] There you are, rookie! [chuckles] Postmaster Bill. Welcome to
the Sky Club post.` The spoken words always match the words on screen; the
build script behind the sources file checks that before anything is
generated. A word whose pronunciation needs pinning is given in IPA between
slashes, as Eleven v4 expects: the Dusk Empress's "lamps" is sent as
`/læmps/`.

### Tags

The 308 recorded takes use 64 different tags (the most used: `[curious]` 43
clips, `[excited]` 39, `[surprised]` 32, `[cheerfully]` 20, `[warmly]` 18,
`[softly]` 15, `[laughs]` 13, `[chuckles]`, `[sighs]` and `[happy]` 11 each).
`python3 tool/prepare_story_voices.py --tags` prints the whole vocabulary. A tag
is **proven** once a recorded take has used it and been heard (or transcribed)
without the tag spoken aloud. Fourteen tags in the New York prompts are unproven:
`pompously, suspiciously, fuming, wistfully, sniffs, quietly, deadpan, delighted
gasp, nervously, theatrically, pleading, softly, voice cracking, happily,
ecstatic`. Record those clips first and transcribe them; the proven stand-ins
are in [story-voices-recording.md](story-voices-recording.md), section 3. When
you write a new prompt, prefer a proven tag.

## Checked by transcription

A sample of 24 clips, chosen for their heaviest direction ([chuckles],
[whispers], [laughs], [crying], [trembling voice], [yawns], [robotic], the
sprint "Wheeee!", the letter read aloud), was transcribed with ElevenLabs
Scribe:

- No audio tag was read out as a word in any of them.
- The penguin choir's thank-you lost "high notes" in two takes, once with a
  `[singing]` tag and once without. It was re-recorded as
  `[happy] Warm heads! High notes! [cheerfully] Thank you!`, and that take
  transcribes in full.
- The Dusk Empress's "You will wake the lamps" transcribes as "lambs" in all
  four takes, including the two sent with IPA. The transcriber gave every
  take the same confidence, which points to it favouring the common phrase
  rather than to a misreading. The IPA take is the one in the game. It is
  worth one listen.
- "night mail" in a whisper transcribes as "nightmare". The words are on
  screen with the voice, so the take stays.

## Recording settings and export

Every existing take: model Eleven v4 (`eleven_v4`), one generation, English,
exported as MP3, mono, 44.1 kHz, 128 kbps (`mp3_44100_128`). All 308 takes in
`build/story-voices/source/` were checked with `ffprobe` and are identical in
format. The **voice settings** (stability preset, similarity, style, speed,
speaker boost) were not written down: assume each voice's defaults on
2026-09-30. To close the gap, open one history item (for example
`before-1-1-1`, generation id `UysfLzHl68MIorRDjpAY`), copy its settings into
the `"voice_settings"` key of `docs/story-voices-sources.json` (it is `null`
now), and use the same for every new take. Never change a setting for one clip
only: it would no longer match the 308 that are recorded.

## In the game

- **Scenes:** each line plays its recording as it starts, and the text is
  written out over 90% of the recording, so the words land with the voice
  and the speaker's mouth moves while it talks. A tap finishes the text and
  lets the voice run on; the next tap cuts it and moves to the next line.
  Skip, the back key or the end of the scene stops the voice.
- **Results:** a finished level's thank-you is read out as its note lands.
- **Sprints:** the equipped bird calls out "Woo-hooo!", "Turbo feathers!",
  "Bye-bye, gravity!" or "Wheeee!" in its own voice, never the same call
  twice in a row.
- **Music** ducks to 35% under a spoken line and comes back when it ends.
- **Settings → Character voices** turns all of it off. The text and pacing
  of the scenes stay the same without it, at 26 ms a character.
- **A line that is not recorded** (a clip still *pending recording*, see
  below) plays nothing and is written out exactly as with voices off: 26 ms
  a character, at least 0.26 s and at most 1.7 s. Nothing else changes: the
  speaker's mouth moves, the tap and Skip behave the same, and the lines
  around it that are recorded still play.

In flight the same cast has 1,241 more lines of its own: see
[flight-voices.md](flight-voices.md). In a live flight the sprint calls
join those lines, so they obey the same pacing and never-repeat rules.

`lib/game/campaign_voices.dart` maps a scene line, a level or a bird to its
clip. `SkyAudio.speak` and `hush` play them on a dedicated player that runs
at normal speed whatever the flight's rate.

## Remaking the clips

The downloaded takes are kept out of the repository, in
`build/story-voices/source/<name>.mp3` (see [Backing up the takes](#backing-up-the-takes)
below: they exist nowhere else). To master them again:

```sh
python3 tool/prepare_story_voices.py            # every recorded clip
python3 tool/prepare_story_voices.py --only before-1-1-1 thanks-2-4
python3 tool/prepare_story_voices.py --status   # recorded, pending, missing; no FFmpeg
python3 tool/prepare_story_voices.py --checklist # refresh the clip list in docs/story-voices-recording.md
python3 tool/prepare_story_voices.py --tags     # audio tags: proven and unproven
python3 tool/prepare_story_voices.py --voices   # every voice, its id and clip count
python3 tool/prepare_story_voices.py --source-dir ~/backups/takes   # takes kept elsewhere
```

The script trims each take to its speech (40 ms of room before the first
word, 120 ms after the last), brings it to −18 LUFS with a −1.5 dBTP ceiling
in one linear gain, and saves it as mono 44.1 kHz Ogg Vorbis (quality 2). It
writes the clip lengths to `lib/game/campaign_voice_clips.dart` and the
output hashes to `build/story-voices/verification.json`. A clip whose entry
says `"status": "pending recording"` is skipped, never an error (the game
shows its text without a voice). It needs FFmpeg; the other options do not.
`--checklist` rewrites only the text between the two `checklist` comments of
`docs/story-voices-recording.md` (`--checklist -` prints it), so the rest of that
document is never erased.

To re-record a line, generate a new take with the same voice, model and
prompt from the sources file (Eleven v4, one generation), save it over its
source file, put the new `generation_id` and `source_sha256` (`sha256sum
build/story-voices/source/<name>.mp3`) in its entry, and run the script with
`--only`. A changed line of the script needs a new prompt: keep its words
identical to the printed line, and change the printed line
(`lib/domain/campaign_story.dart`), the entry's `text` and `prompt` and the
recording together: `test/campaign_voices_test.dart` fails on a recorded clip
that says anything else than the line the game prints.

To take a recorded clip back to pending (its words changed and it is not
re-recorded yet): set its `status` to `pending recording`, set `voice_id`,
`generation_id` and `source_sha256` back to `null`, delete its
`assets/audio/story/<name>.ogg` and run the script with `--only <name>`: it
skips the pending clip and rewrites the clip table without it.

## Backing up the takes

The 308 downloaded takes (23 MB of MP3) live **only** in
`/run/media/parsa/projects/ravanix-other/push-up-bird-game/build/story-voices/source/`
on the development machine (308 files, git-ignored by `/build/`), together with
the Pip auditions in `build/story-voices/pip-auditions/` beside it. `build/` is
git-ignored, and `flutter clean` deletes it. The mastered Ogg files in
`assets/audio/story/` are in git and keep the game working, but without the
takes nobody can change the loudness target or the trimming, or fix one clip,
without re-recording it: a new generation is a different performance. The
`generation_id` in the sources file helps to find a take in your ElevenLabs
history; do not rely on the history as the backup.

Back them up whenever a batch is recorded:

```sh
tar czf story-voice-takes-$(date +%F).tgz -C build story-voices
```

and keep the archive off this machine. Library voices can also be withdrawn by
their authors, and GERALD speaks 57 clips. For every cast voice keep its name, id,
library URL and a 10-second sample (the first take is enough) in
`build/story-voices/voices/`, so a voice that vanishes can be replaced by a close
one and the new lines audited against the sample. If Eleven v4 is retired,
re-record a whole character rather than single lines: a new model's takes will not
match the old ones. Alternatively keep the takes outside
`build/` and tell the script where they are with `--source-dir`. After a
restore, `python3 tool/prepare_story_voices.py --status` checks every take's
SHA-256 against the sources file.

## New York: the guardians (pending recording)

New York's two mini-bosses, King Coo (3-2, Wheels in the Rain) and the
Searchlight Gargoyle (3-4, Storm Warning), each have two scenes: the words at
the lair before the fight (`before-3-2`, `before-3-4`) and their last word after
it (`last-3-2`, `last-3-4`). A guardian is no chapter's boss, so its last word
is a `last-` scene, not an `after-` one: no flame seal, no postcard. The last
scene ends on a caption, "To be continued… Next stop: Paris, the City of
Light." It is a caption like the prologue's place line, so the narrator reads it
and it goes when Paris opens.

The lines are in `lib/domain/campaign_story.dart`. All 47 clips are in
`docs/story-voices-sources.json`, marked `"status": "pending recording"`, with
`voice_id`, `generation_id` and `source_sha256` left `null`:

| Who | Voice | Clips |
| --- | --- | --- |
| King Coo | to audition (fallback Rusty Malone) | 8 |
| Searchlight Gargoyle | to audition (fallback Eldrin) | 6 |
| Postmaster Bill | GERALD (`fGIZlgPQ75MMlvQ6WxgY`) | 8 |
| The courier, 6 lines in every bird's voice | Nelson (`EaX6rnyDKjJx35tchi80`), Cherry Twinkle (`XJ2fW4ybq7HouelYYGcL`), Teddy Twinkle (`XjGYkUkzth8BPs29fmcV`), Lola (`f9imtLc2jfOLXtqe3Ihb`) | 24 |
| The narrator, "To be continued…" | Twinkle – Narration & Acting (`Qz7YNvloEr5RXwYE3NCH`) | 1 |

Bill, the birds and the narrator already have their voices, so those 33 clips
can be recorded at once. The 14 guardian clips wait for an audition.
[story-voices-recording.md](story-voices-recording.md) lists every pending clip
in story order, each with its voice, its exact prompt, the file to save and where
it plays (section 4, rewritten by `--checklist` from the sources file, so it
cannot drift from it).

### Until they are recorded

`CampaignVoices` (`lib/game/campaign_voices.dart`) maps a scene's line to
`assets/audio/story/<clip>.ogg` only when the clip is in the generated table
`lib/game/campaign_voice_clips.dart`. A pending clip is not in the table, so the
mapping gives null, the scene plays no sound for that line, and the line is
written out at the pace of the text. Recording a clip needs no code change:
the script adds it to the table, and the game picks it up.
`test/campaign_voices_test.dart` tolerates a pending clip and **fails** for a
recorded clip that is not in the table (so has no mastered file), for a clip in
the table that the sources still call pending, for a recorded clip with no
voice, generation id or hash, and for any clip, pending or not, whose text or
prompt says other words than the line the game prints.

### King Coo

Who he is: the owner's own premise, a huge grumpy pigeon **Commissioner of the
Curb** in a police cap, who closes the sky because someone moved the bread
cart. He bellows orders, sulks about the crumbs, and deflates the moment he
learns the cart was only keeping dry.

**Voice to audition:** a plump, pompous, raspy old New York police commissioner,
thick Brooklyn accent, mid-low gravelly baritone, a little wheezy, blustering
and easily offended, like a cartoon precinct chief who missed his lunch. Comic,
never menacing. It has to go from a parade-ground bellow ("HALT!") to a
wounded mumble ("Tonight: not a crumb") and back to a delighted "The
Commissioner accepts", so it needs real dynamic range, not a constant growl.

**Why this and not one of the five we have:** the bosses are a smug young
aristocrat (Posh Josh), an excitable mad alchemist (Dr. Von Fusion), a velvety
hush (Enchantress), a West Country pirate and a grand, weary dragon (Smoke).
None is American, urban or a blusterer, and the stop's comedy depends on a
big voice that is easy to deflate.

**Where to look:** a voice description to paste into ElevenLabs Voice Design
("A plump, pompous old New York police commissioner with a thick Brooklyn
accent. Raspy, gravelly mid-low voice, barrel-chested and a little wheezy,
blustering and easily offended, like a cartoon precinct chief who has missed
his lunch. Comic, never menacing. Clear diction, big dynamic range from a bellow
to a wounded mumble.") or the Voice Library (search: Brooklyn, New York, cop,
police chief, gruff, raspy, cartoon, old man, boisterous).

**Audition with three lines**, exactly as they will be recorded, for every
candidate, and pick by ear in the order bellow, mumble, delight: `before-3-2-0`,
`before-3-2-4` and `last-3-2-6`. Their prompts are in
[story-voices-recording.md](story-voices-recording.md), section 2.

Reject a voice that reads as a villain, as a posh Brit (Bill is British and
Baron Bat is posh), or as an old man who is just tired. The accent comes from
the voice; do not add accent tags to the prompts unless an audition needs them,
and then change the prompts in the sources file too. "Coo" is never spoken in
these 8 lines (he is "the Commissioner"); a future line that says it should use
`/kuː/`, as the Empress's "lamps" is pinned.

**Fallbacks from the cast we already have**, in order: **Rusty Malone – Deep &
Raspy** (`507tTFX0IPtqFzGd1CAL`; the fire brigade's thank-you on 2-3, so the player
has heard it once, and in another stop), then **Countdown Casey – Radio DJ**
(`mKoqwDP2laxTdq1gEgU6`; the stage manager at the marquee where the bread cart hides,
on 3-1's result, so the player would hear one voice for both). Scruffy Duck (the
newsstand pigeons, 3-2) and Mister Gruff (the cabbies, 3-3) thank the courier in the
same stop and stay out. Every King Coo clip already carries `fallback_voice_id` and
`fallback_voice`. Audition a fallback before relying on it.

### Searchlight Gargoyle

Who he is: a limestone eagle bolted to the tallest tower in 1931 with two
searchlights for eyes. Ninety-odd years of admired skyline and nobody ever looked
up. He sweeps the sky to catch someone in the light, and is thrilled every time
he does. The storm woke him; the courier brings the tower its weather vane. He
is a ham and he is lonely under it.

**Voice to audition:** a theatrical old stage actor: transatlantic
(mid-Atlantic, old West End or old Hollywood) accent, warm gravel, mid-low
pitch, generous vibrato, every sentence a little too big for the room, calls
everyone "darling". It must be able to crack quietly on "You looked." and puff
up again on "Darling, I was born for this."

**Why this and not one of the five we have:** nobody in the cast is a ham. The
closest, the Dragon (Smoke), is deep, grand and weary: the Gargoyle is warmer,
lighter, more affectionate and funnier, and must not sound like a second
Dragon. He also shares scenes with Bill (GERALD, an older British voice):
audition them back to back (`before-3-4-0`, then `before-3-4-1`), and reject a
candidate who sounds like Bill in a different hat.

**Where to look:** Voice Design ("A theatrical old stage actor with a
transatlantic accent. Warm, gravelly mid-low voice with a generous vibrato, a
ham who speaks every line as if to the back row of a theatre and calls everyone
darling. Lonely and tender underneath. Clear diction, big dynamic range, able
to crack into a whisper.") or the Voice Library (search: theatrical,
Shakespearean, old actor, stage, transatlantic, mid-Atlantic, vintage, classic
Hollywood).

**Audition with three lines**: `before-3-4-1`, `before-3-4-3` and `last-3-4-2`
(prompts in [story-voices-recording.md](story-voices-recording.md), section 2).

**Fallbacks**, in order: **Eldrin – Wise Epic Fantasy Narration Storyteller**
(`LvmvHEBEmMJBJw9UuhwO`; the dawn keeper's thank-you on 1-7, so the player has
heard it once), **Matthew Schmitz – Ancient Sage Dragon Wizard**
(`HAvvFKatz0uu0Fv55Riy`; the Sphinx on 2-4: deep, so it leans towards the
Dragon), **Jessie – Vintage Narrator** (`KgUSWQPFmuiZ5ycRbnty`; the lighthouse
keeper on 4-1). Every Gargoyle clip already carries its fallback. Words worth
a listen in the take: "darling", "Stoneface", "weather vane" (not "vain" or
"vein") and "Gargoyle".

### The Alley Pigeon and the fight bark

The **Alley Pigeon does not speak**: pigeons coo and flap, which is sound-effect
work (`tool/prepare_sound_effects.py`), and King Coo should stay the only bird
in the stop with lines. The squadron's and the flocks' voices are therefore not
in this file.

One **fight bark** is kept, unrecorded, under `optional_clips` in the sources
file: `coo-pop` ("Ooof! My lunch!"). Nothing in the game plays it, so it is not
in `clips` and the script ignores it. The in-flight voice system
(`docs/flight-voices.md`) is the place to play it from: a bark there is a
moment with a pool of lines, silent with Character voices off. Move it into
`clips` only when the hook exists, and then it needs a `wanted` name in
`CampaignVoices` (the test fails for a clip the game never asks for).

### The 47 clips and their prompts

Each prompt is the printed line with Eleven v4 audio tags. The courier's lines are
recorded four times, once per bird; the clip is named `<scene>-<line>-<bird>` with
the bird one of `pip`, `peaches`, `minty`, `orbit`. Every clip with its exact prompt,
voice, file name and place is in
[story-voices-recording.md](story-voices-recording.md), section 4, generated from the
sources file. Bill's lines are the only ones that mention the mechanics (the
star-grabbing gang, the puff and the crumb bombs, the open lane of the squadron,
the lamp, the steam vents): if the rules change, change the line, its sources entry
and its take together.

## Egypt: Neferhoo (pending recording)

Egypt's guardian (rules 50), **Neferhoo, the Mummy Courier**, Keeper of the
Lost Letter, has two scenes on 2-6, Return to Sender: the words at the lair
(`before-2-6`, 9 lines) and his last word (`last-2-6`, 9 lines). They pay off
`before-2-4`'s "lost one letter… The Sphinx won't say": the lost letter was his,
addressed to the Sphinx, and he could not find its door through his mask. The
lines are the owner-approved design script
(`egypt-ws/reports/01-egypt-guardian.md` §7) with one change: the Sphinx's note
reads “Delivered at last. Worth the wait. Signed: the Sphinx.”, signed inside the
quote as the Dragon's letter is (`after-5-4`), because a printed line ends on a
sentence mark. Line 7 of `before-2-6` is his name-card line, so
`before-2-6-7` also plays as he arrives in the fight (the `neferhoo-card` pool).

Two things his last word does differently from New York's guardians, on purpose
(`campaign_story_test` names them): it opens **surprised**, not sad (the mask is
off and he can see: the story's reveal), and its last spoken line is his
acceptance ("…Then I start with this one. Off to the Sphinx!"), after Bill's
offer, before the Sphinx's note.

All 31 clips are in `docs/story-voices-sources.json`, pending recording:

| Who | Voice | Clips |
| --- | --- | --- |
| Neferhoo | `Neferhoo (audition)`: to pick from five takes (fallback Grampa Werthers) | 8 |
| Postmaster Bill | GERALD (`fGIZlgPQ75MMlvQ6WxgY`) | 5 |
| The courier, 4 lines in every bird's voice | Nelson, Cherry Twinkle, Teddy Twinkle, Lola | 16 |
| The Sphinx's note (`last-2-6-8`) | Matthew Schmitz – Ancient Sage Dragon Wizard (`HAvvFKatz0uu0Fv55Riy`, the Sphinx of `thanks-2-4`) | 1 |
| The pyramid caretaker's thank-you (`thanks-2-6`) | Jessie – Vintage Narrator (`KgUSWQPFmuiZ5ycRbnty`) | 1 |

Every tag in these prompts is proven by a recorded take, so none needs a
transcription check first. He also has 16 in-flight lines and his birds 16
(`docs/flight-voices-sources.json`, pending; [flight-voices.md](flight-voices.md)).

### Neferhoo

Who he is: the Sky Club's first Egypt courier, a hoopoe sealed in the Great
Pyramid 4,000 years ago with the last letter of his round, wrapped in linen to
wait, in the golden courier mask of the Pharaoh's Post. Too proud to let another
courier fly "his" route. **The voice**: an elderly royal courier, fussy, precise,
reedy, a little creaky, very proper, quick to take offence, warm and silly
underneath; comic, never scary. Distinct from Bill (raspy eccentric British),
the Sphinx (ancient sage), the Dragon (grand, weary), the Gargoyle (theatrical
ham) and King Coo (Brooklyn). Say the name NEF-er-hoo (`/ˈnɛfərhuː/`).

**The auditions are made** (2026-10-03, Eleven v4, one take each, the line
"[haughtily] Neferhoo, Royal Courier. [clears throat] Four thousand years on this
route. [shouting] Return to sender!"): Beezle Wheezelby (`BBfN7Spa3cqLPH1xAS22`,
the design's first choice), AK – British Posh Well-Spoken Old Man
(`y0SYydk17lMbUIUvSf3N`), Grampa Werthers – Old & Cranky (`MKlLqCItoCkvdhrxgtLv`,
the fallback; he is also the 3-4 tower keeper), Daniel – The Gruff Old British
Wizard (`htZQqY7WtacRNV7s62Iy`) and Cornelius – Wise Sage (`6sFKzaJr574YWVu4UuJF`).
Where the takes are and how to put the winner on his 8 story clips and 16 flight
lines: [story-voices-recording.md](story-voices-recording.md), section 2,
"Neferhoo".

## Adding a new character or voice

The recipe, in the order things go wrong if you skip a step. "Clip name" is the
name the game derives from the scene and line; the sources file lists every one.

1. **Write the part down.** Who is it, which lines, where (a scene line, a
   thank-you, a sprint call, a boss card)? Add a row to the cast table above, with
   the voice type to audition and why none of the existing voices will do, and
   the fallback voices from the cast if the audition fails. Keep the words of every
   line final before recording: the take is the expensive part.
2. **Audition.** In ElevenLabs, design or pick 3 to 5 candidate voices (Voice
   Design from a description, or the Voice Library). Have each say the same three
   lines from the part, *as prompts from the sources file* (same model,
   Eleven v4, same audio tags), and listen next to the characters they share
   scenes with (Bill and the four birds). Choose by ear, then note the **exact
   voice name** and its **voice id** (the voice's menu has *Copy voice ID*). Keep
   the audition takes in `build/story-voices/<part>-auditions/` and include
   them in the backup.
3. **Add the clips to `docs/story-voices-sources.json`**, inside `clips`, in story
   order (the order of the game), one entry per clip:

   ```json
   {
    "name": "before-3-2-0",
    "text": "HALT! By order of the Commissioner, nothing with wheels or wings passes!",
    "prompt": "[shouting] HALT! [pompously] By order of the Commissioner, nothing with wheels or wings passes!",
    "voice_id": null,
    "voice": "Chosen Voice Name",
    "generation_id": null,
    "source_sha256": null,
    "status": "pending recording"
   }
   ```

   `text` is **exactly** what the game prints (curly quotes, the real `…`);
   `prompt` is the same words with audio tags in front of them and nothing
   else (a word whose pronunciation needs pinning goes in IPA between slashes,
   `/læmps/`). `test/campaign_voices_test.dart` compares both with the game's
   line and fails on a difference. Names follow the scheme
   `before-<level>-<line>` (the scene before a level), `after-<chapter>-<line>`
   (a chapter boss's last word), `last-<level>-<line>` (a guardian's last word),
   `thanks-<level>` (a level's thank-you) and `sprint-<bird>-<call>`, with
   `-<bird>` added for the courier's lines. The status stays until the take exists.
   Optional extra fields (`planned_voice_id`, `fallback_voice_id`,
   `fallback_voice`, `plays`) are for whoever records it; the script and the test
   ignore them. Add the line to `lib/domain/campaign_story.dart` in the same
   change: the test fails for an entry the game never asks for and for a line
   with no entry.
4. **The mapping in `lib/game/campaign_voices.dart`.** A new line for an existing
   kind of speaker needs **no code**: the clip name follows from the scene id,
   the line number and the bird (`CampaignVoices.lineName`), a boss speaks as
   the scene's `boss`, Bill as the postmaster and a caption as the narrator. Add
   code only for a new *kind* of clip: a new accessor beside `line`, `thanks` and
   `sprints`, its names in `CampaignVoices.wanted`, and a test. A new boss also
   needs its place in the cast table, its headwear in `CampaignHeadwear` (the
   name tag) and its scenes in `CampaignStory`. A new courier bird is a fifth name
   in `CampaignVoices.birds` and 4 more clips for every courier line. A recurring
   speaker who is **not** a boss needs more: `StorySpeaker` has four values
   (courier, postmaster, boss, caption), so a villager or a statue needs a fifth
   value, a case in `StoryScenePlayer.speakerName` and `speakerColor`, an actor in
   `story_cast_art.dart` and a branch in `CampaignVoices.line`. Without them the
   line can only be given to the boss or to Bill.
5. **Record.** In the Flow linked in the sources file (or the text-to-speech page),
   generate each clip with its voice, the model in the sources file (Eleven v4),
   **one generation**, the voice settings of
   [Recording settings and export](#recording-settings-and-export) and the
   `prompt` pasted exactly. Download the MP3 (`mp3_44100_128`) and save it as
   `build/story-voices/source/<clip name>.mp3`.
   [story-voices-recording.md](story-voices-recording.md) walks through one clip
   from nothing to the game and lists every pending clip.
6. **Fill in the entry**: `voice_id` (the id of the voice that actually spoke it),
   `generation_id` (the take's id in ElevenLabs), `source_sha256`
   (`sha256sum build/story-voices/source/<name>.mp3`), and **delete `status`** and
   the extra fields. A recorded entry needs all three and no status: the test
   rejects anything in between.
7. **Master**: `python3 tool/prepare_story_voices.py --only <clip names>` (FFmpeg
   needed). It writes `assets/audio/story/<name>.ogg` and adds the clip to
   `lib/game/campaign_voice_clips.dart`, which is generated: never edit it by hand.
8. **Test and listen**: `flutter test test/campaign_voices_test.dart
   test/campaign_story_test.dart`, `flutter analyze`, then play the scene in the
   game, with Character voices on and off. Commit the sources file, the table, the
   new Ogg files and any code together.
9. **Back up the takes** (see [Backing up the takes](#backing-up-the-takes)).

To find out what is left at any moment: `python3 tool/prepare_story_voices.py --status`.

### Putting an audition's winner on every clip of a part

The sources file names the part's voice as `King Coo (audition)`,
`Searchlight Gargoyle (audition)` or `Neferhoo (audition)` until the audition is
decided. This sets the
winner on all of that part's clips at once and keeps the file's formatting (run
it from the repository root, with the voice's real name and id):

```sh
python3 - <<'EOF'
import json
path = 'docs/story-voices-sources.json'
data = json.load(open(path))
for clip in data['clips']:
    if clip['voice'] == 'King Coo (audition)':
        clip['voice'] = 'Chosen Voice Name'
        clip['planned_voice_id'] = 'THE_VOICE_ID'
open(path, 'w').write(json.dumps(data, indent=1, ensure_ascii=False) + '\n')
EOF
```

The fallback is the same edit with the fallback's name and id (the entry already
has them in `fallback_voice` and `fallback_voice_id`). Then `--checklist` shows the
chosen voice on every clip. Neferhoo also speaks in flight: put the same voice in
`VOICES['neferhoo']` in `tool/prepare_flight_voices.py` (it is
`(None, 'Neferhoo (audition)')` until then) and run
`python3 tool/prepare_flight_voices.py script`.
