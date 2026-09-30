# Story voices

The campaign's characters speak. Every line of the 23 story scenes, the
thank-you on every level's result and each bird's sprint calls were
recorded with ElevenLabs **Eleven v4**, one take per line, and are bundled in
`assets/audio/story/`. The game plays them offline.

## The cast

| Part | Voice | Why |
| --- | --- | --- |
| Postmaster Bill | GERALD – Exciting Older Voice | An eccentric, warm, colourful old British voice for a pelican who tells bad jokes |
| Pip (courier) | Nelson – Awkward Nerd Character | High, slightly squeaky and earnest: a small bird with a big sky ahead of it. Picked by the game's owner after hearing five high-pitched auditions |
| Peaches (courier) | Cherry Twinkle – Adorable Cartoon Girl | Sweet and bubbly: "all heart" |
| Minty (courier) | Teddy Twinkle – Cute Cartoon Boy | Cheerful and quick: a tiny hummingbird at full speed |
| Orbit (courier) | Lola – Soft, Innocent and Calming | Soft and calm: a dreamy owl |
| Baron Bat | Posh Josh | A smug aristocrat who wants his beauty sleep |
| Spitter King | Dr. Von Fusion | A quirky, excitable mad alchemist |
| Dusk Empress | Enchantress | Velvety and mysterious; she speaks in a hush |
| Pirate Captain | Matthew Schmitz – Old Pirate Captain | A gruff West Country sea dog |
| Ember Dragon | Smoke – The Dragon | Old, grand and weary, for a dragon who only wanted a letter |
| The place line of the prologue | Twinkle – Narration & Acting | A gentle storybook narrator |

The courier's lines are recorded four times, once in each bird's voice, and
the scene plays the equipped bird's take. The letter the Ember Dragon
receives is read aloud in Bill's voice, since Bill wrote it.

The 40 thank-you notes are voiced by the people who sign them, from a wider
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

`lib/game/campaign_voices.dart` maps a scene line, a level or a bird to its
clip. `SkyAudio.speak` and `hush` play them on a dedicated player that runs
at normal speed whatever the flight's rate.

## Remaking the clips

The downloaded takes are kept out of the repository, in
`build/story-voices/source/<name>.mp3`. To master them again:

```sh
python3 tool/prepare_story_voices.py            # every clip
python3 tool/prepare_story_voices.py --only before-1-1-1 thanks-2-4
```

The script trims each take to its speech (40 ms of room before the first
word, 120 ms after the last), brings it to −18 LUFS with a −1.5 dBTP ceiling
in one linear gain, and saves it as mono 44.1 kHz Ogg Vorbis (quality 2). It
writes the clip lengths to `lib/game/campaign_voice_clips.dart` and the
output hashes to `build/story-voices/verification.json`.

To re-record a line, generate a new take with the same voice, model and
prompt from the sources file (Eleven v4, one generation), save it over its
source file and run the script with `--only`. A changed line of the script
needs a new prompt: keep its words identical to the printed line.
