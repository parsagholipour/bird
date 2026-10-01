# Flight voices

During a flight the characters talk. The equipped bird reacts to what
happens to it, in its own voice and in its own words, and each boss speaks
in its own fight. Nothing is shared: Pip, Peaches, Minty and Orbit each
have 267 lines of their own, and each boss 34 (the Pirate Captain 37).
Every line was recorded with ElevenLabs **Eleven v4**, one take each, in
the voice the character has in the story ([story-voices.md](story-voices.md)).
They are bundled in `assets/audio/flight/` and play offline.

**Recording status (2026-10-01):** 1,130 of the 1,241 lines are recorded
and bundled. ElevenLabs' daily generation limit stopped the rest: 21 of
the Pirate Captain's lines, 12 of the Dusk Empress's, 8 of the Spitter
King's, and 70 of the birds' (Orbit's later cargo lines, and some final
stretch, star mark and delivery lines). Until they are recorded those
moments draw on what there is or stay quiet. `prepare_flight_voices.py
pending` lists them.

## When a character speaks

`lib/game/flight_voices.dart` reads the flight after every step and turns
what changed into moments; `lib/game/flight_voice_director.dart` decides
whether one is said and which line.

| Moments | The bird says… |
| --- | --- |
| Setting off | a takeoff line; after a lost flight, a retry line; on a campaign level's first try, a line about its cargo |
| Hearts and shield | a hit (its own line for flames and for the sea), the shield taking a bump, the last heart, the shield coming back, a heart pickup, the knockout |
| Stars and score | a streak multiplier, the star magnet, a new endless record |
| Exercise | every 10 push-ups, squats or jumps |
| Combat | the first bat, beetle or moth of a flight, a knockout, a shot fired at the bird, a deflected shot, an empty Shoot, a broken stone panel, a sprint |
| Set pieces | each rush path's warning (a tip from Bill the first time the player ever meets it), escaping it, a gale's warning and its end |
| Bosses | the boss's arrival, the Dragon's breath, the tide bell, a cannon fuse, Baron's screech, the Empress's shield, the boss at half health, the win, a comeback to a taunt |
| The campaign | a quiet word about the region, the final stretch, the ★★ and ★★★ star marks, the delivery |
| Quiet stretches | small talk; in endless, a word about each new region of the tour |

A boss arrives with a line (in the campaign, the line on its name card),
taunts in quiet moments, calls its signature attack, summons helpers,
yelps when hit, gloats when it hits the bird, snarls at half health and
grumbles as it flies off. A boss's line can draw the bird's answer right
after it: an arrival, a taunt, half health and the defeat are little
exchanges.

## Never the same line

- **Freshness.** A moment draws from the least recently said half of its
  pool. A line comes back only after 12 other lines have been said (24 for
  pools of two or three lines, 48 for a single line), or after 2, 3 or 6
  flights have begun, so a quiet mode never goes silent for good. What was
  said is kept in the phone's preferences (`flightVoices`), so the next
  flight and the next launch carry on from there. A moment with no fresh
  line stays silent.
- **Talkativeness.** The rules below were tuned first; the game then talks
  at 0.39 of that (`FlightVoiceDirector.talkativeness`), halving how much
  is said without removing any moment: every chance is multiplied by 0.39,
  and the gaps, cooldowns, budget and quiet stretches are stretched by the
  same factor. Warnings keep their 0.5 s gap. The figures below are the
  rules before that factor, with what the game uses in brackets.
- **Pacing.** After a line ends, the next waits: 16 s for small talk (41),
  7 s for an ordinary line (18), 2.5 s for one that matters (6.4) and
  0.5 s for a warning. Lines share a budget of 5 a minute (2); warnings and
  once-a-flight lines (takeoff, cargo, last heart, record, a boss's
  arrival, half health and fall, the knockout, the delivery) stand outside
  it. Each kind of line has its own cooldown (a hit at most every 12 s
  (31), a shield bump every 20 s (51), a sprint call every 6 s (15)) and a
  chance of being said at all: every rush and gale warning (39%), most
  hits, 60% of sprints (23%), a third of enemy knockouts (12%).
- **The campaign talks more:** 9 s, 4.5 s and 1.5 s gaps (23, 12, 3.8),
  8 lines a minute (3), higher chances and cooldowns cut by 30%, small
  talk after 13 s of quiet instead of 22 (33 s and 56 s), and lines it
  alone has (cargo, region, star marks, delivery).
- **First times.** Bill's tip for a rush the player has never heard is
  kept until it has been said, so a skipped chance never loses it.
- **Urgency.** A warning ("Fire!") may cut short small talk or an ordinary
  line. A line that matters and finds the voice busy waits up to 2 s, then
  is dropped: a late line is worse than none.
- **Measured:** 24 seeded autopilot flights (five minutes of endless Tap &
  Fly with five bosses, five rushes and a gale, and five campaign levels,
  four birds, sprinting whenever ready) said 305 lines at the first
  tuning and 148 now, 49%; another 24 flights, 312 and 152.
  `test/flight_voices_flight_test.dart` holds it near half.

## Checked by transcription

Fifteen takes chosen for their heaviest direction (one each for
`[giggles]`, `[laughs]`, `[yawns]`, `[gasps]`, `[whispers]`, `[squeaky]`,
`[groans]`, `[sighs]`, `[chuckles]`, `[deep voice]`, `[menacing]`,
`[breathless]`, `[shouting]`, `[panicked]` and `[dreamily]`, across all
four birds, Baron Bat and the Dragon) were joined with gaps and transcribed
with ElevenLabs Scribe. Every line came back word for word, with no tag
read out; the only differences were spellings ("whiz", "Youch").

## In the game

- Lines play on the story's speech player at normal speed, and the music
  ducks to 60% under them (35% under a story line).
- In a live flight the sprint calls join the bird's other lines: the four
  story calls ("Woo-hooo!", "Turbo feathers!", "Bye-bye, gravity!",
  "Wheeee!") and four more of its own, now said on most sprints rather than
  every one.
- The knockout's line waits 0.9 s, under the game-over jingle rather than
  on its first beat, and the delivery's 0.4 s.
- Pausing, retrying and leaving the flight stop the line being
  said. Replays and Flight School stay quiet (their sprints keep the story
  calls).
- The speaker's face follows the line (`FlightSpeech`, read once a frame by
  `BirdGame`). The mouth opens to the take's own loudness curve, 50 ms a
  step, and the face shows the line's mood: a plain line keeps the face the
  flight gave it; glad, startled, angry and sorry lines set the eyes, brows
  and (for the bosses) the mouth's shape, and hold them 0.35 s past the
  last word. The bird's beak parts about a hinge in its art
  (`design/*.svg`, `Beak hinge`), into four cached frames per mood; it keeps
  talking through a knockout's tumble with its dizzy eyes. A boss's face
  moves only for its own lines, and its attacks (a windup, the shot, a
  roar, the dragon's breath) keep their mouth over the words; a beaten boss
  plays its defeat. Under Reduced Motion the mouth stays shut and the mood
  still shows. Review sheets: `flutter test --no-pub
  --dart-define=CAPTURE_TALKING_FACES=true test/talking_faces_art_test.dart`
  writes build/visual-review/talking-faces/.
- **Settings → Character voices** turns them off with the story's voices.

## Remaking the clips

`docs/flight-voices-sources.json` is the script: every line's speaker,
moment, words, v4 prompt, voice and generation. (The writers' first drafts
were per speaker in `build/flight-voices/script/`, outside the repository;
with none there, `script` checks the sources file in place.) The downloaded
takes are kept in `build/flight-voices/source/<name>.mp3`.

```sh
python3 tool/prepare_flight_voices.py script   # check the lines, write the sources
python3 tool/prepare_flight_voices.py pending  # lines with no take yet
python3 tool/prepare_flight_voices.py          # master new takes
python3 tool/prepare_flight_voices.py --all    # master every take again
python3 tool/prepare_flight_voices.py --only pip-hit-01
```

`script` refuses lines that break the brief: a spoken text that differs from
its prompt without the tags, a warning over 6 words (12 for most lines, 14
for cargo), a repeated line, two lines in one pool opening on the same
word, or the wrong number of lines for a moment. Mastering matches the
story's (trimmed to speech, one linear gain, mono Ogg Vorbis, quality 2)
at −16 LUFS, 2 dB over the story, to sit above the flight's music and
effects, and at 24 kHz rather than 44.1: a third smaller, with the whole
of the voice's range.

To change a line, edit its `text` and `prompt` in the sources file and run
`script`: a changed prompt loses its old generation. Then generate a new
take with its voice, model and prompt (Eleven v4, one generation), save it
over its source, log it in `build/flight-voices/generations/` (name to
`generation_id` and `prompt`), and run `script` and then `--only <name>`.
