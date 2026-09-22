#!/usr/bin/env python3
"""Prepare a generated music take for offline looping (requires FFmpeg).

Example: python3 tool/prepare_music.py /path/to/elevenlabs-take.mp3
The default 90-second excerpt becomes an 88-second loop with a two-second
crossfade. Keep the source download outside assets/ so only the loop is bundled.
"""

import argparse
import json
import math
import pathlib
import subprocess


def main():
    root = pathlib.Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=pathlib.Path)
    parser.add_argument("--start", type=float, default=0)
    parser.add_argument("--duration", type=float, default=90)
    parser.add_argument("--crossfade", type=float, default=2)
    parser.add_argument(
        "--output", type=pathlib.Path,
        default=root / "assets/audio/sky_flight.ogg",
    )
    args = parser.parse_args()
    if not args.source.is_file():
        parser.error("source must be an existing audio file")
    if not all(math.isfinite(x) for x in (args.start, args.duration, args.crossfade)):
        parser.error("timing values must be finite")
    if args.start < 0 or not 0 < args.crossfade < args.duration / 2:
        parser.error("start must be nonnegative and duration must exceed two crossfades")
    if args.source.resolve() == args.output.resolve():
        parser.error("source and output must be different files")

    probe = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "json", str(args.source)],
        check=True, capture_output=True, text=True,
    )
    source_duration = float(json.loads(probe.stdout)["format"]["duration"])
    if args.start + args.duration > source_duration + .001:
        parser.error("the requested excerpt extends past the source audio")

    fade = args.crossfade
    tail = args.duration - fade
    # Put the tail/head crossfade at the end. Its final sample flows into the
    # first sample of the body on repeat; there is no fade to silence.
    graph = (
        f"[0:a]atrim=start={args.start}:duration={args.duration},"
        "asetpts=PTS-STARTPTS,aresample=44100,asplit=3[h][b][t];"
        f"[h]atrim=0:{fade},asetpts=PTS-STARTPTS[head];"
        f"[b]atrim={fade}:{tail},asetpts=PTS-STARTPTS[body];"
        f"[t]atrim={tail}:{args.duration},asetpts=PTS-STARTPTS[tail];"
        f"[tail][head]acrossfade=d={fade}:c1=qsin:c2=qsin[seam];"
        "[body][seam]concat=n=2:v=0:a=1"
    )
    analysis = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostdin", "-i", str(args.source),
         "-filter_complex", graph + ",loudnorm=I=-16:TP=-2:print_format=json[out]",
         "-map", "[out]", "-f", "null", "-"],
        check=True, capture_output=True, text=True,
    )
    levels, _ = json.JSONDecoder().raw_decode(
        analysis.stderr[analysis.stderr.rfind("{"):]
    )
    integrated = float(levels["input_i"])
    peak = float(levels["input_tp"])
    if not all(math.isfinite(x) for x in (integrated, peak)):
        parser.error("source must contain audible music")
    # Constant gain preserves dynamics and the seam, unlike an adaptive limiter.
    gain = min(-16 - integrated, -2 - peak)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-nostdin", "-y",
         "-i", str(args.source), "-filter_complex", graph + f",volume={gain}dB[out]",
         "-map", "[out]", "-map_metadata", "-1", "-ar", "44100", "-ac", "2",
         "-c:a", "libvorbis", "-q:a", "5", str(args.output)],
        check=True,
    )
    print(json.dumps({
        "output": str(args.output),
        "duration_seconds": args.duration - fade,
        "crossfade_seconds": fade,
        "gain_db": round(gain, 2),
        "estimated_lufs": round(integrated + gain, 2),
        "bytes": args.output.stat().st_size,
    }, indent=2))


if __name__ == "__main__":
    main()
