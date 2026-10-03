# Menu, flight, region and boss music

The game bundles three violin-led ElevenLabs Music v2 instrumentals. They were
prompted around a repeated five-note idea and a 3+3+2 pulse, with a deliberately
insistent, slightly mischievous feel. The boss track takes the same rhythmic
idea in a darker, more threatening direction.

| Scene | Asset | Loop | Arrangement |
| --- | --- | ---: | --- |
| Menus | `assets/audio/sky_menu.ogg` | 85.38 s | Pizzicato violin, bassoon, upright bass, handclaps and woodblock |
| Flight | `assets/audio/sky_flight.ogg` | 85.71 s | Staccato violin, drums, bass, woodwinds and short brass replies |
| Boss | `assets/audio/sky_boss.ogg` | 85.45 s | Low violin and viola, contrabass, bass clarinet, low brass and timpani |

Menu music starts after the saved setting loads and continues across menu pages.
Play, Flight School, replay and camera-lab routes pause it. Backgrounding pauses
it; returning to menus resumes it. The music toggle applies immediately.

`SkyAudio.syncBoss` selects the boss track from arrival through defeat and
departure for all three bosses, then returns to flight music. Per-frame updates
do not restart the track. Music plays at 70%, reduced to 14% during boss
cinematics so cues remain audible. Sound effects mix with it.

Track selection, volume, pause and mute share a serialized queue. Silent replay
seeks update the desired track without starting paused audio; resume selects
the right track. Resuming the same track preserves its position. Replay speed
still applies.

All files use stereo 44.1 kHz Ogg Vorbis, included by `assets/audio/` in
`pubspec.yaml`. No runtime downloads, credentials or ElevenLabs calls are needed.

## Source

Generated on 2026-09-24 using the connected ElevenLabs account. The
[ElevenLabs flow](https://elevenlabs.io/app/flows/HeHtzmiQYMI1natgMcoI) retains
all four variations for each scene. The bundled selections are:

| Scene | Node | Take | Generation | Source SHA-256 |
| --- | --- | ---: | --- | --- |
| Menu | `iqGb4oRmWsns9QSF5Ewx` | 2 | `cV9kod1czfEMP8BHzOPR` | `c2c542110f7bf739d3be1c8514a94e1a565f3674eb8b127c04bea41e941a2299` |
| Flight | `64u42SU0d9949mLOP39S` | 2 | `XPAxw3OG3Q29pNfGrv8n` | `43e85bf36860ff677c59f946592660476b1c97553c57d6114d670c77cef3b80f` |
| Boss | `YQ5UM0mnqKiq8ec3azCS` | 1 | `RY2JmPN28wwdZVVCh3uv` | `605093d4c1daef6b08c45e64f71a95ed781ff5c6af7328493abe1c4aacecf9c2` |

Parameters: 90 seconds, `lyrics_type=instrumental`, `instrumental=true`.
Source MP3s and the prior Ogg files are retained under ignored
`build/music/violin-earworm/` in this workspace.

Menu prompt:

> Quirky chamber-pop instrumental at 104 BPM with close, slightly scratchy pizzicato violin, bassoon, plucked upright bass, handclaps and a dry woodblock. Repeat a cheeky five-note hook over a 3+3+2 rhythm until it becomes an earworm, with tiny offbeat interruptions and playful violin answers; bright and gently mischievous, crisp and light. Start on the groove and keep the same pulse and harmony at the end for a clean game loop, with no vocals, intro, fade or sound effects.

Flight prompt:

> Playful, mildly irritating-in-a-fun-way orchestral adventure instrumental at 126 BPM, driven by a prominent staccato violin five-note hook over a relentlessly catchy 3+3+2 hand-drum and snare pattern, bouncing acoustic bass, woodwinds and brief cheeky brass replies. Keep the tune short and repeated with small variations, urgent but buoyant, punchy and spacious enough for game sound effects; no vocals, synth dance beat or cinematic build. Begin immediately in the groove and return to the same harmony and rhythm for seamless looping.

Boss prompt:

> Unsettling orchestral boss instrumental at 132 BPM in a dark minor mode: sawed low violin and viola repeat the same five-note 3+3+2 hook as an obsessive sinister ostinato, backed by contrabass, bass clarinet, low brass, timpani and dry pounding toms. Make the rhythm insistently memorable and slightly nerve-grating while remaining frightening and forceful, with dissonant accents and controlled dynamics; no vocals, screams or sound effects. Start at full pulse and end on its starting harmony and rhythm for a seamless game loop.

## Preparation

With Python 3 and FFmpeg (`ffprobe` and `libvorbis`) installed:

```sh
python3 tool/prepare_music.py build/music/violin-earworm/menu-2.mp3 --duration 87.6923077 --crossfade 2.3076923 --output assets/audio/sky_menu.ogg
python3 tool/prepare_music.py build/music/violin-earworm/flight-2.mp3 --duration 87.6190476 --crossfade 1.9047619 --output assets/audio/sky_flight.ogg
python3 tool/prepare_music.py build/music/violin-earworm/boss-1.mp3 --duration 87.2727273 --crossfade 1.8181818 --output assets/audio/sky_boss.ogg
```

The helper blends the source tail into its head with an equal-power crossfade,
puts that blend after the body, and applies constant gain targeting -16 LUFS
with a -2 dBTP ceiling before Vorbis quality-5 encoding. The prepared loops
have no long silence and cross the repeat boundary without a large sample jump.
`tool/generate_audio.py` does not overwrite these tracks.

| Asset | Bytes | Prepared SHA-256 |
| --- | ---: | --- |
| Menu | 1,485,508 | `2e4248ce16646b400cebe4dd4fcd08b17abc3534a5786086010f0cc247221c65` |
| Flight | 1,784,012 | `ecdae5e66476e2b240b468f5ba06a4d7ed58ad921016b278145993e5a1760a39` |
| Boss | 1,671,004 | `87ae485b0f1eb627e78d82316c605aa5ab6381eb71645b54b82c7449b1cd1103` |

## Campaign region music

Every campaign region except the jungle has its own flight song. A campaign
level plays `SkyMusic.flightOver(level.region)`; the jungle keeps
`sky_flight.ogg`. Bosses and their vanguards still switch to `sky_boss.ogg`
and hand back to the region's song when they leave.

Endless flights (and co-op, whose flights tour the world too) start on
`sky_flight.ogg`. Once a boss has been beaten and flown off, the music comes
back as the song of the region showing behind the bird at that moment, and it
stays until the next boss arrives; over the jungle that is `sky_flight.ogg`
again. The simulation records the moment as `FlightSimulation.bossLeftAt` and
`SkyAudio.tourSong` maps it through `WorldTour.at`, so replays and seeks pick
the same song as the live flight. A replay of a campaign flight plays its
level's song. The region songs share the menu and
flight tracks' loudness and loop treatment, and add about 20 MB to the bundle.

| Region | Asset | BPM | Loop | Take | Generation | Arrangement |
| --- | --- | ---: | ---: | ---: | --- | --- |
| Brazil | `assets/audio/sky_brazil.ogg` | 124 | 87.10 s (45 bars) | 1 | `MoNmGflKBDCVYEpjBKjz` | Samba: cavaquinho, nylon guitar, batucada, flute and trombone |
| Aztec | `assets/audio/sky_aztec.ogg` | 120 | 80.00 s (40 bars) | 3 | `5PJbcak57LQp7urdGgcE` | Ocarina and wooden flute over log drums, rattles and marimba |
| Ancient Rome | `assets/audio/sky_rome.ogg` | 116 | 78.62 s (38 bars) | 1 | `w422tMADLOU52SxCrvnl` | Golden march: trumpets, horns, harp, snare and timpani |
| Egypt | `assets/audio/sky_egypt.ogg` | 118 | 87.46 s (43 bars) | 3 | `WnPttuBOTHky2ac0KzMu` | Hijaz: oud, ney, darbuka, riq and qanun |
| Ancient Arabia | `assets/audio/sky_arabia.ogg` | 104 | 80.77 s (35 bars) | 3 | `50qsGbkdwmyLwul2Odo8` | Bayati 6/8: legato violins, qanun, santur, daf and hand drums |
| New York | `assets/audio/sky_new_york.ogg` | 138 | 86.96 s (50 bars) | 2 | `SkVIukbGvvH9DGA40IUJ` | Big-band swing: walking bass, saxes, muted trumpet, stride piano |
| Paris | `assets/audio/sky_paris.ogg` | 132 | 76.36 s (42 bars) | 3 | `iHadyMg4Lu1RQ7AMOvgh` | Jazz manouche: musette accordion, pompe guitar, clarinet |
| Mexico | `assets/audio/sky_mexico.ogg` | 128 | 76.88 s (41 bars) | 1 | `pN1lXLN1Y8Wlz13tdDRL` | Mariachi: trumpets, violins, vihuela, guitarrón |
| Open Sea | `assets/audio/sky_sea.ogg` | 120 | 82.00 s (41 bars) | 2 | `u4F4D4tcmRjFvjkB6orc` | 6/8 shanty: fiddle, tin whistle, concertina, bodhrán |
| Antarctica | `assets/audio/sky_antarctica.ogg` | 120 | 82.00 s (41 bars) | 2 | `25GgdPQaQDDT2lJuPyyj` | Celesta, glockenspiel, pizzicato strings, harp, vibraphone |
| Cyberpunk City | `assets/audio/sky_cyberpunk.ogg` | 128 | 78.75 s (42 bars) | 3 | `loznqmQsXqM1LZHGRM14` | Synthwave: arpeggiated analog bass, gated drums, neon lead |
| China | `assets/audio/sky_china.ogg` | 112 | 85.71 s (40 bars) | 2 | `PYFcXdTLPJ3IqkczYhpx` | Pentatonic: erhu, dizi, guzheng, pipa, gongs and tanggu |

Generated on 2026-10-03 with ElevenLabs Music v2.5 (`eleven_music_v2_5`), 90
seconds, `lyrics_type=instrumental`, `instrumental=true`, four takes per
region. The [region music flow](https://elevenlabs.io/app/flows/EyHPKlieX9y27wJx7rR6)
keeps every take on a node per region. `docs/region-music-sources.json`
records each prompt, every take's generation id and SHA-256, and the chosen
take's loop and asset hash. All 48 source MP3s are kept under the ignored
`build/music/regions/source/<region>-<take>.mp3`.

Each prompt names the region's genre, instruments and exact tempo, asks for a
short repeated hook with room for sound effects, and ends with: "No vocals,
crowd noise, intro or fade: start immediately in the groove and end on the
opening harmony and rhythm for a seamless game loop."

### How the takes were chosen

Nobody has listened to these yet; takes were picked on measurements alone.
Every take came back at its prompted tempo, so loops are whole bars with a
one-bar crossfade. For each take the bar count was chosen where the music
after the loop point best matches the opening (onset correlation 0.87–0.99,
chroma similarity 0.85–0.99, level within 2 dB). Takes with a dropout in the
body, a quiet intro or a weak seam were passed over. Many takes fade out in
their last few seconds despite the prompt, so each loop ends before the
fade. Each prepared loop wraps as cleanly as `sky_flight.ogg`: there is no
onset spike or level step at the seam.

To try another take, re-run its line below with the other take's file and a
bar count that fits within 90 s (a loop of `n` bars needs `--duration` of
`(n + 1) × 240 / BPM` and `--crossfade` of `240 / BPM`), then update the
region's `selected` entry in `docs/region-music-sources.json`.

```sh
python3 tool/prepare_music.py build/music/regions/source/brazil-1.mp3 --duration 89.0322581 --crossfade 1.9354839 --output assets/audio/sky_brazil.ogg
python3 tool/prepare_music.py build/music/regions/source/aztec-3.mp3 --duration 82.0 --crossfade 2.0 --output assets/audio/sky_aztec.ogg
python3 tool/prepare_music.py build/music/regions/source/rome-1.mp3 --duration 80.6896552 --crossfade 2.0689655 --output assets/audio/sky_rome.ogg
python3 tool/prepare_music.py build/music/regions/source/egypt-3.mp3 --duration 89.4915254 --crossfade 2.0338983 --output assets/audio/sky_egypt.ogg
python3 tool/prepare_music.py build/music/regions/source/arabia-3.mp3 --duration 83.0769231 --crossfade 2.3076923 --output assets/audio/sky_arabia.ogg
python3 tool/prepare_music.py build/music/regions/source/newYork-2.mp3 --duration 88.6956522 --crossfade 1.7391304 --output assets/audio/sky_new_york.ogg
python3 tool/prepare_music.py build/music/regions/source/paris-3.mp3 --duration 78.1818182 --crossfade 1.8181818 --output assets/audio/sky_paris.ogg
python3 tool/prepare_music.py build/music/regions/source/mexico-1.mp3 --duration 78.75 --crossfade 1.875 --output assets/audio/sky_mexico.ogg
python3 tool/prepare_music.py build/music/regions/source/sea-2.mp3 --duration 84.0 --crossfade 2.0 --output assets/audio/sky_sea.ogg
python3 tool/prepare_music.py build/music/regions/source/antarctica-2.mp3 --duration 84.0 --crossfade 2.0 --output assets/audio/sky_antarctica.ogg
python3 tool/prepare_music.py build/music/regions/source/cyberpunk-3.mp3 --duration 80.625 --crossfade 1.875 --output assets/audio/sky_cyberpunk.ogg
python3 tool/prepare_music.py build/music/regions/source/china-2.mp3 --duration 87.8571429 --crossfade 2.1428571 --output assets/audio/sky_china.ogg
```

## Android audio focus

The first implementation became silent because effects used `AUDIOFOCUS_GAIN`
and permanently paused music. Effects now use `AndroidAudioFocus.none` with
game/sonification attributes; music remains the focus owner. Tests exercise
real `SkyAudio` and `AudioPlayer` against a channel fake reproducing Android
focus behavior.

Check the actual native player while the menu or flight is open:

```sh
python3 tool/check_music_playback.py --serial DEVICE
```

It expects one active looping Vorbis player. Use `--silent` when muted or
backgrounded. This catches native pauses that cached Dart state can miss.

Regression coverage includes all three boss kinds, one switch per encounter,
cinematic volume, return to flight, mute, paused replay seeks and stop/disposal
while a transition is pending.
