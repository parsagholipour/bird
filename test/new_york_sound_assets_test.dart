// Objective checks of New York's 25 synthesised cues (32 files). Nobody can
// audition them while they are built, so this pins what an ear would notice:
// format and length, headroom, no clipping or DC, clean edges, how loud each
// is as played next to the dragon's and the boss roar, and the shape that
// makes each one recognisable (a rising hiss, a crack then a fading jet, a
// whistle that blows twice, a flock that takes off after a beat).
//
// The same measurements, with spectral centroids per slice, are printed by
// `python3 tool/check_sound_effects.py --family new_york`.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/game/sound_bank.dart';

const rate = 44100;

class Wav {
  Wav(this.channels, this.bits, this.rate, this.x);
  final int channels, bits, rate;
  final Float64List x;
  double get seconds => x.length / rate;
  int at(double t) => (t * rate).round().clamp(0, x.length);

  double get peak => x.fold(0.0, (m, v) => math.max(m, v.abs()));
  double get mean => x.fold(0.0, (s, v) => s + v) / x.length;

  /// RMS of [from, to) seconds, in dBFS.
  double rmsDb(double from, double to) {
    final a = at(from), b = math.max(a + 1, at(to));
    var sum = 0.0;
    for (var i = a; i < b && i < x.length; i++) {
      sum += x[i] * x[i];
    }
    return 10 * math.log(sum / (b - a) + 1e-12) / math.ln10;
  }

  /// RMS per [hop] seconds, in dBFS.
  List<double> envelope(double hop) => [
    for (var t = 0.0; t + hop <= seconds + 1e-9; t += hop) rmsDb(t, t + hop),
  ];

  /// The loudest [window] seconds of plain RMS, in dBFS.
  double loudest(double window) {
    final n = at(window);
    var best = 0.0, sum = 0.0;
    for (var i = 0; i < x.length; i++) {
      sum += x[i] * x[i];
      if (i >= n) sum -= x[i - n] * x[i - n];
      if (i >= n - 1) best = math.max(best, sum);
    }
    return 10 * math.log(best / n + 1e-12) / math.ln10;
  }

  /// The mean power spectrum of [from, to) in frames of 2048: bin power.
  List<double> spectrum(double from, double to) {
    const size = 2048;
    final power = List<double>.filled(size ~/ 2 + 1, 0);
    var frames = 0;
    final window = [
      for (var i = 0; i < size; i++)
        .5 - .5 * math.cos(2 * math.pi * i / (size - 1)),
    ];
    final start = at(from), end = math.min(at(to), x.length);
    for (
      var s = start;
      s + size <= math.max(end, start + size);
      s += size ~/ 2
    ) {
      final re = Float64List(size), im = Float64List(size);
      for (var i = 0; i < size; i++) {
        re[i] = s + i < x.length ? x[s + i] * window[i] : 0;
      }
      _fft(re, im);
      for (var k = 0; k <= size ~/ 2; k++) {
        power[k] += re[k] * re[k] + im[k] * im[k];
      }
      frames++;
    }
    return [for (final p in power) p / frames];
  }

  /// IEC 61672 A-weighting as a power ratio (1 at 1 kHz).
  static double aWeight(double f) {
    final f2 = f * f;
    final ra =
        (12194 * 12194 * f2 * f2) /
        ((f2 + 20.6 * 20.6) *
            math.sqrt((f2 + 107.7 * 107.7) * (f2 + 737.9 * 737.9)) *
            (f2 + 12194 * 12194));
    return math.pow(ra / .7943, 2).toDouble();
  }

  /// The A-weighted level of [from, to) in dBFS: what a phone speaker (deaf
  /// below about 250 Hz) lets through, weighted as an ear hears it.
  double awDb(double from, double to) {
    const size = 2048;
    final p = spectrum(from, to);
    var norm = 0.0;
    for (var i = 0; i < size; i++) {
      final w = .5 - .5 * math.cos(2 * math.pi * i / (size - 1));
      norm += w * w;
    }
    var sum = 0.0;
    for (var k = 1; k <= size ~/ 2; k++) {
      sum += 2 * p[k] * aWeight(k * rate / size) / (norm * size);
    }
    return 10 * math.log(sum + 1e-12) / math.ln10;
  }

  /// The loudest A-weighted 100 ms of the cue (every 50 ms), in dBFS.
  double awLoudest() {
    var best = -200.0;
    for (var t = 0.0; t + .1 <= seconds + 1e-9; t += .05) {
      best = math.max(best, awDb(t, t + .1));
    }
    return best;
  }

  double centroid(double from, double to) {
    final p = spectrum(from, to);
    var num = 0.0, den = 0.0;
    for (var k = 1; k < p.length; k++) {
      num += k * rate / 2048 * p[k];
      den += p[k];
    }
    return den == 0 ? 0 : num / den;
  }

  /// The frequency of the strongest bin in [lo, hi] Hz over [from, to).
  double peakHz(double from, double to, double lo, double hi) {
    final p = spectrum(from, to);
    var best = lo.ceil() * 2048 ~/ rate;
    for (var k = (lo * 2048 / rate).floor(); k <= hi * 2048 / rate; k++) {
      if (p[k] > p[best]) best = k;
    }
    return best * rate / 2048;
  }

  /// Share of the energy within [lo, hi] Hz.
  double share(double lo, double hi) {
    final p = spectrum(0, seconds);
    var inside = 0.0, all = 0.0;
    for (var k = 1; k < p.length; k++) {
      all += p[k];
      final f = k * rate / 2048;
      if (f >= lo && f <= hi) inside += p[k];
    }
    return inside / all;
  }

  /// Onsets: times where the [hop]-second RMS jumps at least [rise] dB above
  /// the quietest of the previous [back] hops and is within [within] dB of the
  /// cue's loudest hop.
  List<double> onsets({
    double hop = .004,
    double rise = 8,
    double within = 18,
    int back = 4,
    double after = 0,
  }) {
    final env = envelope(hop);
    final top = env.reduce(math.max);
    final found = <double>[];
    for (var i = 0; i < env.length; i++) {
      if (i * hop < after || env[i] < top - within) continue;
      var low = 0.0;
      if (i == 0) {
        low = -120;
      } else {
        low = env.sublist(math.max(0, i - back), i).reduce(math.min);
      }
      if (env[i] - low >= rise &&
          (found.isEmpty || i * hop - found.last > .03)) {
        found.add(i * hop);
      }
    }
    return found;
  }
}

void _fft(Float64List re, Float64List im) {
  final n = re.length;
  for (var i = 1, j = 0; i < n; i++) {
    var bit = n >> 1;
    for (; j & bit != 0; bit >>= 1) {
      j ^= bit;
    }
    j ^= bit;
    if (i < j) {
      final tr = re[i], ti = im[i];
      re[i] = re[j];
      im[i] = im[j];
      re[j] = tr;
      im[j] = ti;
    }
  }
  for (var size = 2; size <= n; size <<= 1) {
    final ang = -2 * math.pi / size;
    final wr = math.cos(ang), wi = math.sin(ang);
    for (var start = 0; start < n; start += size) {
      var cr = 1.0, ci = 0.0;
      for (var k = 0; k < size ~/ 2; k++) {
        final a = start + k, b = a + size ~/ 2;
        final vr = re[b] * cr - im[b] * ci, vi = re[b] * ci + im[b] * cr;
        re[b] = re[a] - vr;
        im[b] = im[a] - vi;
        re[a] += vr;
        im[a] += vi;
        final nr = cr * wr - ci * wi;
        ci = cr * wi + ci * wr;
        cr = nr;
      }
    }
  }
}

Wav wav(String asset) {
  final bytes = File('assets/audio/$asset.wav').readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  if (String.fromCharCodes(bytes.take(4)) != 'RIFF') {
    throw StateError('$asset is not a RIFF file');
  }
  var pos = 12, channels = 0, bits = 0, sampleRate = 0;
  while (pos + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(pos, pos + 4));
    final size = data.getUint32(pos + 4, Endian.little);
    if (id == 'fmt ') {
      channels = data.getUint16(pos + 10, Endian.little);
      sampleRate = data.getUint32(pos + 12, Endian.little);
      bits = data.getUint16(pos + 22, Endian.little);
    } else if (id == 'data') {
      final n = size ~/ 2;
      final x = Float64List(n);
      for (var i = 0; i < n; i++) {
        x[i] = data.getInt16(pos + 8 + 2 * i, Endian.little) / 32768;
      }
      return Wav(channels, bits, sampleRate, x);
    }
    pos += 8 + size + (size.isOdd ? 1 : 0);
  }
  throw StateError('no data chunk in $asset');
}

double db(double gain) => 20 * math.log(gain) / math.ln10;

/// The loudness of a cue as played: its loudest 100 ms of RMS with the sound
/// bank's playback volume applied.
double played(String name, [int variant = 0]) =>
    wav(
      soundAsset(name, variant).replaceAll(RegExp(r'^audio/|\.wav$'), ''),
    ).loudest(.1) +
    db(soundBank[name]!.volume);

const pigeon = [
  'pigeon_coo',
  'pigeon_flap',
  'pigeon_snatch',
  'pigeon_defeat',
  'star_rescue',
];
const steam = ['steam_hiss', 'steam_burst', 'pipe_clang', 'steam_ride'];
const gargoyle = [
  'gargoyle_strike',
  'gargoyle_awaken',
  'beam_warning',
  'beam_sweep',
  'beam_spot',
  'lamp_vent',
  'lamp_glance',
  'feather_drop',
];
const coo = [
  'coo_roar',
  'coo_whistle',
  'crumb_throw',
  'crumb_splat',
  'squad_flutter',
  'coo_puff',
  'coo_pop',
  'coo_defeat',
];
// The audio fix round's four new cues.
const fix = ['coo_shout', 'gargoyle_fury', 'gargoyle_shatter', 'coo_inflate'];
const all = [...pigeon, ...steam, ...gargoyle, ...coo, ...fix];

String stem(String name, int variant) =>
    name + (variant == 0 ? '' : '_${variant + 1}');

void main() {
  group('every file', () {
    for (final name in all) {
      final spec = soundBank[name]!;
      for (var variant = 0; variant < spec.variants; variant++) {
        test('${stem(name, variant)} is clean, mastered PCM', () {
          final w = wav(stem(name, variant));
          expect([w.channels, w.bits, w.rate], [1, 16, rate]);
          expect(
            (w.x.length - spec.seconds * rate).abs(),
            lessThanOrEqualTo(2),
            reason: 'as long as the ${spec.seconds} s the sound bank reserves',
          );
          // Mastered to -3.10 dBFS: headroom, and no sample at full scale.
          expect(db(w.peak), inInclusiveRange(-3.25, -2.95));
          expect(
            w.x.where((v) => v >= 32767 / 32768 || v <= -1).length,
            0,
            reason: 'clipped samples',
          );
          expect(w.mean.abs(), lessThan(5e-4), reason: 'DC offset');
          expect(
            w.x.first.abs(),
            lessThan(.02),
            reason: 'a click at the start',
          );
          expect(w.x.last.abs(), lessThan(.005), reason: 'a click at the end');
          expect(w.rmsDb(0, w.seconds), greaterThan(-26));
          // The decoded-buffer limit (the packaged-asset test uses 1 MB).
          expect(
            File('assets/audio/${stem(name, variant)}.wav').lengthSync(),
            lessThan(400000),
          );
        });
      }
    }
  });

  group('as loud as their neighbours', () {
    // The reference figures: the dragon's two cues (docs/validation.md) and
    // the boss roar, measured here from their own assets.
    final breath = played('dragon_breath');
    final inhale = played('dragon_inhale');
    final roar = played('boss_roar');
    final reveal = played('boss_reveal');

    test('the references are what the docs say', () {
      // tool/check_sound_effects.py steps by 50 ms, this by one sample.
      expect(breath, closeTo(-17.9, .8));
      expect(inhale, closeTo(-18.1, .8));
      expect(roar, closeTo(-10.4, .8));
      expect(reveal, closeTo(-9.4, .8));
    });

    test('the two roars and the strike stand with the boss roar', () {
      for (final name in ['gargoyle_strike', 'gargoyle_awaken', 'coo_roar']) {
        expect(
          played(name),
          inInclusiveRange(roar - 4, reveal + 1),
          reason: name,
        );
      }
    });

    test('telegraphs and boss attacks sit within 6 dB of the dragon', () {
      for (final name in [
        'beam_warning',
        'lamp_vent',
        'coo_puff',
        'coo_whistle',
        'steam_hiss',
        'steam_burst',
        'crumb_throw',
        'crumb_splat',
        'coo_defeat',
        'coo_pop',
        'coo_inflate',
        'gargoyle_fury',
      ]) {
        expect(
          played(name),
          inInclusiveRange(breath - 6, breath + 6),
          reason: name,
        );
      }
    });

    test('incidental cues stay well under the boss cues', () {
      for (final name in [
        'pigeon_coo',
        'pigeon_flap',
        'pipe_clang',
        'lamp_glance',
        'feather_drop',
        'squad_flutter',
        'beam_sweep',
      ]) {
        expect(played(name), inInclusiveRange(-31, breath - 1), reason: name);
      }
    });

    test('nothing is louder than the boss reveal', () {
      for (final name in all) {
        for (var v = 0; v < soundBank[name]!.variants; v++) {
          expect(
            played(name, v),
            lessThanOrEqualTo(reveal + 1.5),
            reason: stem(name, v),
          );
        }
      }
    });

    test('a phone can play them: most energy is above 250 Hz', () {
      // Cues built on a low voice or thump keep a formant or crack up high.
      for (final name in all) {
        final w = wav(name);
        final minShare =
            {
              'gargoyle_strike': .25,
              'gargoyle_awaken': .30,
              'coo_roar': .60,
              'coo_defeat': .55,
              // The crumb bombs were 26-31% in the band and the quietest
              // cues on a phone; now crinkle grains in the mids.
              'crumb_throw': .60,
              'crumb_splat': .60,
              'gargoyle_shatter': .45,
              'coo_shout': .55,
              'squad_flutter': .6,
              'beam_sweep': .5,
            }[name] ??
            .6;
        expect(w.share(250, 12000), greaterThan(minShare), reason: name);
      }
    });
  });

  group('the beats a phone used to lose', () {
    // A phone speaker plays almost nothing under 250 Hz, so the A-weighted
    // level is what the player hears. The generic boss_enrage and boss_break
    // were quieter than a rock hit (boss_hit); the crumb bombs, King Coo's
    // main attack, were the quietest cues in the bank.
    final shot = wav('shoot').awLoudest() + db(soundBank['shoot']!.volume);
    final hit = wav('boss_hit').awLoudest() + db(soundBank['boss_hit']!.volume);
    final oldFury =
        wav('boss_enrage').awLoudest() + db(soundBank['boss_enrage']!.volume);

    double phone(String name) =>
        wav(name).awLoudest() + db(soundBank[name]!.volume);

    test('the references: the old fury roar was under a rock hit', () {
      expect(oldFury, lessThan(hit - 2));
    });

    test('the Gargoyle\'s fury is well over a rock hit and the old roar', () {
      final w = wav('gargoyle_fury');
      expect(phone('gargoyle_fury'), greaterThan(hit + 8));
      expect(phone('gargoyle_fury'), greaterThan(oldFury + 8));
      // At +0.12 s, when the pose throws its roar, it is already at -20 dB
      // A-weighted or louder.
      expect(
        w.awDb(.12, .22) + db(soundBank['gargoyle_fury']!.volume),
        greaterThan(-20),
      );
      expect(w.share(250, 8000), greaterThan(.4));
    });

    test('the crumb bombs are no longer the quietest cues', () {
      for (final name in ['crumb_throw', 'crumb_splat']) {
        expect(phone(name), greaterThan(hit + 4), reason: name);
        expect(phone(name), greaterThan(-21.5), reason: name);
        expect(wav(name).share(250, 8000), greaterThan(.6), reason: name);
      }
      // The report's numbers: -29.6 and -28.2 A-weighted as played.
      expect(phone('crumb_throw'), greaterThan(-29.6 + 6));
      expect(phone('crumb_splat'), greaterThan(-28.2 + 6));
      expect(shot, greaterThan(hit));
    });

    test('the Gargoyle\'s shattering and King Coo\'s inflate are audible', () {
      expect(phone('gargoyle_shatter'), greaterThan(hit + 6));
      expect(phone('coo_inflate'), greaterThan(hit + 4));
      expect(phone('coo_shout'), greaterThan(shot + 4));
    });
  });

  group('Alley Pigeon', () {
    test('coo: three round glides around 300-450 Hz with gaps between', () {
      final w = wav('pigeon_coo');
      expect(w.peakHz(.02, .13, 200, 700), inInclusiveRange(350, 450));
      expect(w.peakHz(.16, .34, 200, 700), inInclusiveRange(380, 460));
      expect(w.peakHz(.40, .53, 200, 700), inInclusiveRange(280, 400));
      expect(w.centroid(.02, .53), inInclusiveRange(380, 620));
      // The breaths between the three notes are much quieter.
      final loud = w.rmsDb(.17, .33);
      expect(w.rmsDb(.131, .149), lessThan(loud - 10));
      expect(w.rmsDb(.361, .379), lessThan(loud - 10));
    });

    test('the second coo take is a whole tone higher', () {
      final a = wav('pigeon_coo'), b = wav('pigeon_coo_2');
      final ratio = b.peakHz(.16, .34, 200, 700) / a.peakHz(.16, .34, 200, 700);
      expect(ratio, closeTo(math.pow(2, 2 / 12), .07));
    });

    test('flap: four claps at 0, 75, 145 and 210 ms, fading', () {
      for (final name in ['pigeon_flap', 'pigeon_flap_2']) {
        final w = wav(name);
        final hits = w.onsets(hop: .003, rise: 6, within: 14);
        expect(hits.length, 4, reason: '$name onsets $hits');
        for (final (i, want) in [0.0, .075, .145, .21].indexed) {
          expect(hits[i], closeTo(want, .02), reason: name);
        }
        // Dry, not hissy: the energy is in the mids.
        expect(w.centroid(0, .3), inInclusiveRange(1500, 4500));
      }
    });

    test('snatch: a bright clap, then two falling bells E6 and B5', () {
      final w = wav('pigeon_snatch');
      expect(w.centroid(0, .03), greaterThan(w.centroid(.2, .4)));
      expect(w.peakHz(.06, .13, 1000, 2000), closeTo(1318, 30));
      expect(w.peakHz(.2, .4, 800, 2000), closeTo(988, 30));
      expect(w.rmsDb(.35, .42), lessThan(w.rmsDb(0, .07) - 18));
    });

    test('defeat: squeaks first, the tiny falling coo after', () {
      final w = wav('pigeon_defeat');
      expect(w.centroid(0, .15), greaterThan(700));
      expect(w.peakHz(.24, .44, 150, 500), inInclusiveRange(200, 340));
      final twist = wav('pigeon_defeat_2');
      expect(
        twist.peakHz(.24, .44, 150, 500),
        greaterThan(w.peakHz(.24, .44, 150, 500)),
      );
    });

    test('star rescue: three rising bells over a lift of air', () {
      final w = wav('star_rescue');
      expect(w.peakHz(.0, .05, 1200, 3200), closeTo(1568, 60));
      expect(w.peakHz(.13, .2, 1800, 3200), closeTo(2637, 120));
      expect(w.rmsDb(.35, .45), lessThan(w.rmsDb(0, .1) - 15));
    });
  });

  group('Steam Geysers', () {
    test('hiss swells from near silence for its whole 1.5 s', () {
      final w = wav('steam_hiss');
      // It runs the vent's whole 1.5 s warning, to the burst (it stopped
      // 0.1 s short, at 1.4 s).
      expect(w.seconds, closeTo(1.5, .001));
      final env = w.envelope(.1875);
      expect(env.first, lessThan(env.last - 14));
      // Monotone within a few dB from the second slice on.
      for (var i = 2; i < env.length; i++) {
        expect(env[i], greaterThan(env[i - 1] - 3), reason: 'slice $i');
      }
      expect(w.centroid(.5, 1.5), greaterThan(2500), reason: 'a bright hiss');
    });

    test('hiss: iron knocks tick ever quicker under it', () {
      // The knocks raise the 150-1500 Hz band above the hiss's own, so the
      // band holds more of the late frames than a pure hiss would.
      final w = wav('steam_hiss');
      expect(w.share(150, 1500), greaterThan(.15));
    });

    test('burst: a crack first, then a jet that darkens and fades', () {
      for (final name in ['steam_burst', 'steam_burst_2']) {
        final w = wav(name);
        final env = w.envelope(.01);
        final top = env.reduce(math.max);
        expect(env.indexOf(top) * .01, lessThan(.06), reason: name);
        expect(w.rmsDb(.6, .8), lessThan(w.rmsDb(0, .1) - 15), reason: name);
        expect(
          w.centroid(0, .2),
          greaterThan(w.centroid(.5, .75) + 300),
          reason: '$name darkens',
        );
      }
    });

    test('clang: inharmonic iron ringing, a lower clunk after the strike', () {
      for (final name in ['pipe_clang', 'pipe_clang_2']) {
        final w = wav(name);
        expect(
          w.peakHz(.0, .1, 250, 500),
          inInclusiveRange(380, 440),
          reason: name,
        );
        expect(w.rmsDb(.35, .45), lessThan(w.rmsDb(0, .1) - 18), reason: name);
      }
      expect(
        wav('pipe_clang_2').peakHz(.0, .1, 250, 500),
        greaterThan(wav('pipe_clang').peakHz(.0, .1, 250, 500)),
      );
    });

    test('ride: a soft updraft that rises in colour, swells then fades', () {
      final w = wav('steam_ride');
      expect(w.centroid(.4, .6), greaterThan(w.centroid(0, .2) * 2));
      final env = w.envelope(.075);
      final top = env.indexOf(env.reduce(math.max));
      expect(top, inInclusiveRange(2, 5), reason: 'the swell peaks inside');
      expect(w.rmsDb(0, .05), lessThan(w.rmsDb(.2, .4) - 10));
      expect(w.rmsDb(.56, .6), lessThan(w.rmsDb(.2, .4) - 15));
    });
  });

  group('Searchlight Gargoyle', () {
    test('strike: the crack lands first, thunder rolls away', () {
      final w = wav('gargoyle_strike');
      final env = w.envelope(.01);
      expect(env.indexOf(env.reduce(math.max)) * .01, lessThan(.05));
      expect(w.centroid(0, .05), greaterThan(600), reason: 'a bright crack');
      expect(w.rmsDb(.9, 1.1), lessThan(w.rmsDb(0, .1) - 25));
      // Snaps of arcing electricity keep crackling after the crack.
      expect(
        w.onsets(hop: .002, rise: 6, within: 40, after: .1).length,
        greaterThan(3),
      );
    });

    test('awaken: peaks early, fades over two seconds, bells ring on', () {
      final w = wav('gargoyle_awaken');
      final env = w.envelope(.25);
      expect(env.indexOf(env.reduce(math.max)), lessThanOrEqualTo(2));
      expect(w.rmsDb(1.75, 2.0), lessThan(w.rmsDb(.25, .75) - 12));
      // Steel: partials near 466 x (1, 2.76, 5.4) stand out late in the cue.
      expect(w.peakHz(1.3, 1.9, 2200, 2800), closeTo(2517, 120));
    });

    test('warning: shutter slam, then a hum and ticks that build', () {
      final w = wav('beam_warning');
      expect(w.rmsDb(0, .03), greaterThan(w.rmsDb(.2, .4)), reason: 'the slam');
      expect(w.rmsDb(1.1, 1.5), greaterThan(w.rmsDb(.3, .7) + 3));
      // Relay ticks: short chirps between 1.0 and 2.4 kHz, ever closer.
      final ticks = w.onsets(hop: .003, rise: 5, within: 30, after: .15);
      expect(ticks.length, greaterThanOrEqualTo(5));
      // They quicken: more of them land in the last 0.7 s than the first.
      expect(
        ticks.where((t) => t >= .8).length,
        greaterThan(ticks.where((t) => t < .8).length),
      );
    });

    test('sweep: a steady 2.9 s buzz that glides up, then holds', () {
      final w = wav('beam_sweep');
      final env = w.envelope(.3).sublist(0, 8);
      final hi = env.reduce(math.max), lo = env.reduce(math.min);
      expect(hi - lo, lessThan(3), reason: 'sustained, not pumping');
      // The saw (100 Hz rising to 128 Hz) puts its harmonics on a comb that
      // rises: compare the comb pitch early and late.
      expect(w.peakHz(.1, .4, 300, 1500), isNot(w.peakHz(2.2, 2.7, 300, 1500)));
      expect(w.centroid(.3, 2.6), inInclusiveRange(400, 1500));
      expect(w.rmsDb(2.85, 2.9), lessThan(w.rmsDb(1, 2) - 10));
    });

    test('spot: a pop and a bright G6 bell', () {
      final w = wav('beam_spot');
      expect(w.peakHz(.15, .35, 1000, 2500), closeTo(1568, 40));
      expect(w.rmsDb(.3, .4), lessThan(w.rmsDb(0, .05) - 12));
    });

    test('vent: eleven ratchet ticks, then steam hissing brighter', () {
      final w = wav('lamp_vent');
      final ticks = w
          .onsets(hop: .002, rise: 6, within: 14)
          .where((t) => t < .4)
          .toList();
      expect(ticks.length, inInclusiveRange(9, 13), reason: '$ticks');
      expect(w.centroid(.9, 1.15), greaterThan(w.centroid(.4, .6)));
      expect(w.rmsDb(1.2, 1.3), lessThan(w.rmsDb(.4, .8) - 15));
    });

    test('glance: a short clink at 1320 or 1440 Hz', () {
      final a = wav('lamp_glance'), b = wav('lamp_glance_2');
      expect(a.peakHz(.03, .2, 1000, 1700), closeTo(1320, 40));
      expect(b.peakHz(.03, .2, 1000, 1800), closeTo(1439, 40));
      expect(a.rmsDb(.2, .25), lessThan(a.rmsDb(0, .03) - 20));
    });

    test('feather: a 3 kHz rustle and a tick, then a thin fall', () {
      for (final name in ['feather_drop', 'feather_drop_2']) {
        final w = wav(name);
        expect(w.centroid(.05, .3), inInclusiveRange(2500, 5500), reason: name);
        expect(w.rmsDb(.45, .55), lessThan(w.rmsDb(0, .2) - 18), reason: name);
      }
    });
  });

  group('audio fix round: the new cues', () {
    test('shout: one swell that rides the beak, thump with the shock ring', () {
      final w = wav('coo_shout');
      expect(w.seconds, closeTo(.85, .001));
      // The pose opens the beak as sin(pi t / 0.8): shut, widest at 0.4 s,
      // shut. The voiced part follows that pulse (from 0.1 s: the first
      // 0.1 s is the thump of the shock ring).
      final beak = <double>[], voice = <double>[];
      for (var i = 2; i < 16; i++) {
        final t = i * .05;
        beak.add(math.sin(math.pi * (t + .025) / .8));
        voice.add(math.pow(10, w.rmsDb(t, t + .05) / 20).toDouble());
      }
      final mb = beak.reduce((a, b) => a + b) / beak.length;
      final mv = voice.reduce((a, b) => a + b) / voice.length;
      var cov = 0.0, vb = 0.0, vv = 0.0;
      for (var i = 0; i < beak.length; i++) {
        cov += (beak[i] - mb) * (voice[i] - mv);
        vb += math.pow(beak[i] - mb, 2);
        vv += math.pow(voice[i] - mv, 2);
      }
      expect(
        cov / math.sqrt(vb * vv),
        greaterThan(.85),
        reason: 'the notes land with the beak (the 1.6 s roar: about -0.1)',
      );
      // Nothing is voiced once the beak has shut at 0.8 s.
      expect(w.rmsDb(.79, .85), lessThan(w.rmsDb(.3, .5) - 15));
      // The thump at 0, then a peak while the beak is widest.
      final env = w.envelope(.05);
      expect(
        env.indexOf(env.reduce(math.max)) * .05,
        inInclusiveRange(.25, .55),
      );
      expect(w.peakHz(.2, .6, 100, 400), inInclusiveRange(110, 230));
    });

    test('the long roar is not the arrival shout any more', () {
      expect(soundBank['coo_roar']!.seconds, 1.6);
      expect(soundBank['coo_shout']!.seconds, lessThan(.9));
    });

    test('Gargoyle fury: crack, grind and arc surge, steel ringing out', () {
      final w = wav('gargoyle_fury');
      final env = w.envelope(.05);
      expect(env.indexOf(env.reduce(math.max)) * .05, lessThan(.4));
      expect(w.centroid(0, .05), greaterThan(1500), reason: 'a bright crack');
      expect(
        w.rmsDb(.1, .6),
        greaterThan(w.rmsDb(0, .05) - 8),
        reason: 'full while the pose throws its roar (0.12-0.6 s)',
      );
      expect(w.rmsDb(1.1, 1.2), lessThan(w.rmsDb(.1, .5) - 25));
      expect(
        w.peakHz(.5, 1.0, 2200, 2800),
        closeTo(2517, 150),
        reason: 'steel partials ring on',
      );
    });

    test('Gargoyle shatter: a crack, glass and chips, rubble and wings', () {
      final w = wav('gargoyle_shatter');
      final env = w.envelope(.01);
      expect(env.indexOf(env.reduce(math.max)) * .01, lessThan(.06));
      expect(w.centroid(.1, .5), greaterThan(2500), reason: 'glass and chips');
      expect(w.rmsDb(1.1, 1.2), lessThan(w.rmsDb(0, .1) - 30));
      // Pigeons break out of the dust: claps still sound after 0.5 s.
      expect(
        w.onsets(hop: .004, rise: 5, within: 40, after: .5).length,
        greaterThan(1),
      );
    });

    test('inflate: rising air and squeak, creaks closing up, to the pop', () {
      final w = wav('coo_inflate');
      expect(w.seconds, closeTo(.75, .001));
      expect(w.centroid(.5, .7), greaterThan(w.centroid(0, .2) * 2));
      expect(w.rmsDb(.3, .55), greaterThan(w.rmsDb(0, .1) + 10));
      expect(w.rmsDb(.7, .75), lessThan(w.rmsDb(.3, .55) - 12));
    });

    test(
      'the ducked and lifted cues are the same audio as their originals',
      () {
        for (final name in ['steam_burst', 'pipe_clang', 'pigeon_snatch']) {
          for (var v = 0; v < soundBank[name]!.variants; v++) {
            final alias = {
              'steam_burst': 'steam_burst_duck',
              'pipe_clang': 'pipe_clang_duck',
              'pigeon_snatch': 'pigeon_snatch_lift',
            }[name]!;
            expect(soundAsset(alias, v), soundAsset(name, v));
          }
        }
      },
    );
  });

  group('King Coo', () {
    test('roar: COO-ROO-COOOO, three voiced glides with breaths between', () {
      final w = wav('coo_roar');
      final env = w.envelope(.01);
      final voiced = [
        for (var i = 0; i < env.length; i++)
          if (env[i] > env.reduce(math.max) - 16) i * .01,
      ];
      expect(voiced.first, lessThan(.1));
      // Gaps near .42 and .85 s.
      expect(w.rmsDb(.41, .45), lessThan(w.rmsDb(.5, .78) - 12));
      expect(w.rmsDb(.79, .85), lessThan(w.rmsDb(.5, .78) - 12));
      expect(w.peakHz(.1, .4, 100, 400), inInclusiveRange(140, 210));
      expect(w.peakHz(1.2, 1.5, 80, 300), inInclusiveRange(95, 170));
    });

    test('whistle: a short and a long pea blast, both at about 3 kHz', () {
      final w = wav('coo_whistle');
      // The blast pose lasts 0.4 s from the whistle: the long trill starts at
      // 0.12 s (it began at 0.30 s, after the picture's blast peaked).
      expect(w.seconds, closeTo(.85, .001));
      expect(w.peakHz(.01, .1, 2000, 4000), closeTo(2900, 100));
      expect(w.peakHz(.2, .7, 2000, 4000), closeTo(3000, 100));
      final full = w.rmsDb(.2, .7);
      expect(w.rmsDb(.13, .2), greaterThan(full - 6), reason: 'on by 0.13 s');
      expect(w.rmsDb(.2, .45), closeTo(w.rmsDb(.45, .7), 3), reason: 'steady');
      expect(w.rmsDb(.79, .85), lessThan(full - 12), reason: 'done by 0.8 s');
      // Steady pitch, not a screech's glide: the peak does not wander.
      expect(
        (w.peakHz(.2, .4, 2000, 4000) - w.peakHz(.5, .7, 2000, 4000)).abs(),
        lessThan(60),
      );
    });

    test('throw and splat: a swish, a thwup, a patter of crumbs', () {
      final t = wav('crumb_throw'), s = wav('crumb_splat');
      // Mids, not bass: a 1.7 kHz swish and 1-3.5 kHz crinkle grains.
      expect(t.centroid(.0, .3), inInclusiveRange(1200, 3500));
      expect(s.centroid(.0, .5), inInclusiveRange(1200, 4000));
      expect(t.rmsDb(.3, .36), lessThan(t.rmsDb(0, .2) - 10));
      final env = s.envelope(.01);
      expect(env.indexOf(env.reduce(math.max)) * .01, lessThan(.05));
      expect(s.rmsDb(.3, .4), lessThan(s.rmsDb(0, .1) - 12));
      // The crumbs patter on after the pop: grains are still heard late.
      expect(
        s.onsets(hop: .004, rise: 6, within: 40, after: .2).length,
        greaterThan(0),
      );
      expect(
        t.onsets(hop: .004, rise: 6, within: 30, after: .1).length,
        greaterThan(1),
        reason: 'grains after the thwup',
      );
    });

    test('flutter: a beat of silence, then a flock takes off', () {
      final w = wav('squad_flutter');
      expect(w.rmsDb(0, .08), lessThan(w.rmsDb(.15, .4) - 18));
      final claps = w.onsets(hop: .004, rise: 6, within: 26, after: .09);
      expect(claps.length, greaterThan(6), reason: 'many wings');
    });

    test('puff: rising air and squeak, then a creak at the top', () {
      final w = wav('coo_puff');
      expect(w.centroid(1.0, 1.25), greaterThan(w.centroid(0.1, .4)));
      expect(w.peakHz(1.3, 1.45, 500, 1000), closeTo(740, 40));
      expect(w.rmsDb(1.45, 1.5), lessThan(w.rmsDb(.3, 1.0) - 18));
    });

    test('pop: a sharp pop, a falling squeal, a dizzy little coo', () {
      final w = wav('coo_pop');
      final env = w.envelope(.01);
      expect(env.indexOf(env.reduce(math.max)) * .01, lessThan(.05));
      expect(
        w.peakHz(.0, .15, 600, 1800),
        greaterThan(w.peakHz(.45, .55, 250, 1800) - 1),
      );
      expect(w.peakHz(.5, .72, 200, 450), inInclusiveRange(240, 340));
    });

    test('defeat: a whump, a deflating flutter, two sad falling coos', () {
      final w = wav('coo_defeat');
      expect(
        w.rmsDb(.55, .95),
        greaterThan(w.rmsDb(.1, .5) - 8),
        reason: 'the first coo',
      );
      expect(
        w.rmsDb(.985, 1.015),
        lessThan(w.rmsDb(.6, .95) - 12),
        reason: 'a breath between the coos',
      );
      expect(
        w.peakHz(1.05, 1.5, 80, 300),
        lessThan(w.peakHz(.6, .95, 80, 300)),
      );
    });
  });
}
