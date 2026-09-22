# Menu, flight and boss music

The app bundles three ElevenLabs Music v2 instrumentals:

| Scene | Asset | Loop | Style |
| --- | --- | --- | --- |
| Menus | `assets/audio/sky_menu.ogg` | 87.5 s | Relaxed marimba, strings and electric piano |
| Flight | `assets/audio/sky_flight.ogg` | 82 s | Playful orchestral adventure, percussion and acoustic bass |
| Boss | `assets/audio/sky_boss.ogg` | 88.125 s | Scary strings, low brass and pounding drums |

Menu music starts after the saved setting loads and continues across menu pages.
Play, Flight School, replay and camera-lab routes pause it. Backgrounding pauses
it; returning to menus resumes it. The music toggle applies immediately.

`SkyAudio.syncBoss` selects the boss track from arrival through defeat and
departure for all three bosses, then returns to flight music. Per-frame updates
do not restart the track. Music plays at 20%, reduced to 3.5% during boss
cinematics so cues remain audible. Sound effects mix with it.

Track selection, volume, pause and mute share a serialized queue. Silent replay
seeks update the desired track without starting paused audio; resume selects
the right track. Resuming the same track preserves its position. Replay speed
still applies.

All files use stereo 44.1 kHz Ogg Vorbis, included by `assets/audio/` in
`pubspec.yaml`. No runtime downloads, credentials or ElevenLabs calls are needed.

## Source

Generated on 2026-09-22 using the connected account. The
[ElevenLabs flow](https://elevenlabs.io/app/flows/HeHtzmiQYMI1natgMcoI) retains
the variations. The first take of each node is bundled:

| Scene | Node | Generation |
| --- | --- | --- |
| Menu | `I9cKYdUCK8fPa8Gr4j2t` | `r1ExxzjflRIx9xlErKVU` |
| Flight | `BnAn92kRbVuGC41HubpD` | `NcM4NxkBMmN44VbVSliq` |
| Boss | `QadAZ0zyUFEzHGYGw8P7` | `6chjKdSjkmEf0E19Yr13` |

Parameters: 90 seconds, `lyrics_type=instrumental`, `instrumental=true`.
The adventure track replaces the earlier electronic flight take, retained in
the flow and ignored `build/music/sky_flight-electronic-previous.ogg`.

Flight prompt:

> Playful adventurous instrumental orchestral game music at a lively steady 120 BPM in G major: nimble pizzicato and staccato strings, bouncing acoustic bass, syncopated hand percussion and snare, warm woodwind runs and bold but light French-horn phrases. Spirited, mischievous and propulsive with a catchy adventurous motif and space between phrases, crisp natural acoustic production; maintain engaging forward motion for 90 seconds with varied orchestration, no synthesizers, electronic dance beat, sugary marimba, vocals or sound effects. Begin immediately on the rhythmic groove and end on the opening harmony and rhythm for a repeating loop, without a slow introduction, dramatic ending, fade-out or silence.

Boss prompt:

> Dark, frightening instrumental orchestral boss-battle music at a driving 128 BPM in D minor: relentless low-string ostinatos, pounding deep toms and timpani, ominous low brass, tense tremolo strings, dissonant accents and a pulsing sub bass. Menacing and urgent with a strong continuous combat rhythm, clean spacious production and controlled peaks, no voices, singing, screams, jump-scare sound effects or cheerful melodies; maintain tension across 90 seconds with subtle variations. Start immediately in the full rhythmic texture and end on the opening harmony and groove so it can repeat, with no quiet intro, final cadence, fade-out or silence.

Menu prompt:

> Warm whimsical instrumental menu music at a relaxed steady 96 BPM in C major,
> with soft marimba plucks, gentle pizzicato strings, mellow electric piano
> chords, airy pads, rounded bass and very light brushed percussion. A welcoming
> memorable melody with ample space and polished gentle stereo production;
> sustain an even calm upbeat mood for 90 seconds with subtle variations, no
> vocals, speech or sound effects. Begin and end with the same flowing groove
> and chord pattern for a repeating loop, with no dramatic build, intro, final
> flourish, fade-out or silence.

## Preparation

With Python 3 and FFmpeg (`ffprobe` and `libvorbis`) installed:

```sh
python3 tool/prepare_music.py /path/to/sky_adventure-source.mp3 --start 2 --duration 84 --crossfade 2 --output assets/audio/sky_flight.ogg
python3 tool/prepare_music.py /path/to/sky_boss-source.mp3 --crossfade 1.875 --output assets/audio/sky_boss.ogg
python3 tool/prepare_music.py /path/to/sky_menu-source.mp3 --crossfade 2.5 --output assets/audio/sky_menu.ogg
```

The adventure excerpt excludes a quiet source ending. The helper blends the
tail into the head with an equal-power crossfade, puts that blend after the
body, and applies constant gain targeting -16 LUFS with a -2 dBTP ceiling before
Vorbis quality-5 encoding. Source downloads stay in ignored `build/music/`.
`tool/generate_audio.py` does not overwrite these tracks.

Source MP3 SHA-256:

- Flight: `3e780c48aa36d5ade8aa36a57775324f9e502ab39acecf77195bd509ab6aa916`
- Boss: `9c11c577396e1a08272ec1b18f99c29d0d594a00ca2a4dbfff5aa3c813c0e71b`
- Menu: `2a6c198f2c65a550c3ec74fa71d4a647e3f3e95f5523a06917afe1a32335ad7f`

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

## Audio verification

| Asset | Bytes | Loudness | True peak |
| --- | ---: | ---: | ---: |
| Flight | 1,461,579 | -17.71 LUFS | -1.95 dBTP |
| Boss | 1,727,117 | -16.06 LUFS | -3.85 dBTP |
| Menu | 1,573,392 | — | — |

Both new loops decode successfully, with no silence longer than 100 ms at -55 dB.
Prepared SHA-256:

- Flight: `baaaa2516d4aaa32d5934383cf909f1543aa6fdcc4adb92103178b981dd6e72a`
- Boss: `26f4aff5f013057f10bb98235fa38de034cdb6da93732999063c9ec4799ab61d`
- Menu: `a0dee5d50ac3867394e7e416013894f0db585280b3a34bf14bf4a988401266f2`

Regression coverage includes all three boss kinds, one switch per encounter,
cinematic volume, return to flight, mute, paused replay seeks and stop/disposal
while a transition is pending.

Validation on 2026-09-22: all 480 Flutter tests and `flutter analyze --no-pub`
passed. The release APK contains byte-identical copies of all three prepared
tracks and was installed on the connected Android phone. Native player checks
confirmed menu playback and the handoff to active flight music, with exactly
one looping music player active. Boss transitions were verified by automated
tests.
