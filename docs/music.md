# Menu, flight and boss music

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
