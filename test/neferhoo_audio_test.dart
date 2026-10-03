// Neferhoo's sound (rules version 50): the design's 13 cues
// (`egypt-ws/reports/01-egypt-guardian.md` section 6) and the edges that
// ring them. Nobody could listen while they were built, so this pins what an
// ear would notice (format, length against the rules' own timings, headroom,
// the phone band, how loud each is next to the other guardians') and that
// every cue sounds exactly once on its edge, never on a seek or a rewind, and
// never with Sound effects off.
//
// The rules (R1) raise the counters these cues read, so every test drives the
// counters, the latches and the boss clock directly, which is exactly what
// the rules do (`test/new_york_audio_cues_test.dart` does the same).
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/data/progress_repository.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/game/audio.dart';
import 'package:push_up_bird/game/boss_audio_cues.dart';
import 'package:push_up_bird/game/neferhoo_audio_cues.dart';
import 'package:push_up_bird/game/sound_bank.dart';
import 'new_york_sound_assets_test.dart' show Wav, db, played, wav;
import 'sky_audio_test.dart' show AndroidAudioHost, drainAudio;

const arrival = 4.6;

/// A staged Neferhoo [age] seconds into his encounter (4.6 s of arrival
/// first), as the staged campaign builds him.
SkyBoss neferhoo({double age = arrival + 1}) => SkyBoss(
  number: 6,
  x: 1.5,
  cinematic: true,
  kind: BossKind.neferhoo,
  staged: true,
  maxHp: Neferhoo.campaignHp,
)..age = age;

/// What the rules do when a mail call locks at this boss's age: latch the
/// lane and deal [letters] letters, the first one second later.
void mailCall(SkyBoss boss, {int letters = 3, bool express = false}) {
  final fight = boss.neferhoo;
  final gap = express ? Neferhoo.furyStreamGap : Neferhoo.streamGap;
  fight
    ..mailLockedAt = boss.age
    ..laneY = .5;
  fight.mailLocks++;
  for (var i = 0; i < letters; i++) {
    fight.letters.add(
      NeferhooLetter(
        cycle: fight.mailLocks - 1,
        index: i,
        lane: .5,
        releaseAt:
            boss.age + (Neferhoo.mailReleaseAt - Neferhoo.mailLockAt) + i * gap,
        speed: express ? Neferhoo.furyLetterSpeed : Neferhoo.letterSpeed,
        express: express,
      ),
    );
  }
}

/// An ankh lock at this boss's age: the loop is latched now, the throw
/// follows [Neferhoo.ankhThrowAt] - [Neferhoo.ankhLockAt] later; fury's
/// second ankh [Neferhoo.furyAnkhDelay] after the first.
void ankhLock(SkyBoss boss, {bool two = false}) {
  final fight = boss.neferhoo;
  fight
    ..ankhLockedAt = boss.age
    ..twoAnkhs = two;
  fight.ankhLocks++;
  final thrown = boss.age + Neferhoo.ankhThrowAt - Neferhoo.ankhLockAt;
  for (var i = 0; i < (two ? 2 : 1); i++) {
    fight.ankhs.add(
      NeferhooAnkh(
        cycle: fight.ankhLocks - 1,
        laneA: .4,
        laneB: .72,
        lockedAt: boss.age,
        thrownAt: thrown + i * Neferhoo.furyAnkhDelay,
        speed: two ? Neferhoo.furyAnkhSpeed : Neferhoo.ankhSpeed,
        second: i == 1,
      ),
    );
  }
}

/// The design's table: (volume, priority, seconds, cooldown ms) per cue.
/// `hoopoe_roar` is .65, not the design's .55 (see sound_bank.dart).
const design = <String, (double, int, double, int)>{
  'hoopoe_roar': (.65, 4, 1.4, 600),
  'sand_devil': (.40, 3, 1.6, 1000),
  'mail_call': (.40, 3, 1.0, 500),
  'letter_flick': (.30, 2, .25, 120),
  'letter_return': (.45, 3, .40, 100),
  'postage_due': (.70, 4, .70, 150),
  'wrap_scuff': (.22, 1, .16, 80),
  'ankh_raise': (.40, 3, 1.4, 1000),
  'ankh_whir': (.35, 2, 2.6, 2000),
  'ankh_catch': (.40, 3, .35, 300),
  'mummy_fury': (.55, 4, 1.3, 1000),
  'mask_pop': (.60, 4, 1.3, 1000),
  'lost_letter': (.45, 3, 1.4, 1000),
};

/// The share of [x]'s energy between 250 Hz and 8 kHz with two 12 dB/octave
/// filters on each side: the New York review's phone check, as the design
/// measured it (`proof/mummy_cues_prototype.py`'s `band_share`).
double phoneBand(Wav w) {
  List<double> biquad(List<double> data, bool highPass, double f0) {
    final w0 = 2 * math.pi * f0 / w.rate;
    final alpha = math.sin(w0) / (2 * .7071);
    final cw = math.cos(w0);
    final b0 = highPass ? (1 + cw) / 2 : (1 - cw) / 2;
    final b1 = highPass ? -(1 + cw) : 1 - cw;
    final b2 = b0;
    final a0 = 1 + alpha, a1 = -2 * cw, a2 = 1 - alpha;
    var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0;
    final out = List<double>.filled(data.length, 0);
    for (var i = 0; i < data.length; i++) {
      final x = data[i];
      final y = (b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2) / a0;
      x2 = x1;
      x1 = x;
      y2 = y1;
      y1 = y;
      out[i] = y;
    }
    return out;
  }

  final band = biquad(
    biquad(biquad(biquad(w.x, true, 250), true, 250), false, 8000),
    false,
    8000,
  );
  double energy(List<double> v) => v.fold(0.0, (s, e) => s + e * e);
  return energy(band) / math.max(energy(w.x), 1e-12);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the bank and the files', () {
    test('the 13 cues are the design\'s table (one volume re-measured)', () {
      for (final MapEntry(key: name, value: spec) in design.entries) {
        final got = soundBank[name];
        expect(got, isNotNull, reason: name);
        expect(
          (got!.volume, got.priority, got.seconds, got.cooldownMs),
          spec,
          reason: name,
        );
        expect(got.variants, 1, reason: name);
        expect(got.file, isNull, reason: name);
      }
    });

    test('every cue he plays is in the bank, with a file on disk', () {
      for (final name in NeferhooAudioCues.all) {
        final spec = soundBank[name];
        expect(spec, isNotNull, reason: name);
        expect(
          File('assets/${soundAsset(name, 0)}').existsSync(),
          isTrue,
          reason: name,
        );
      }
      // (15 with M1's ducked postage due, played under his roar or cry)
      expect(NeferhooAudioCues.all, hasLength(15));
      expect(NeferhooAudioCues.all.toSet(), hasLength(15));
      expect(soundBank['postage_due_duck']!.file, 'postage_due');
      expect(soundBank['postage_due_duck']!.volume, lessThan(soundBank['postage_due']!.volume * .45));
      // The shared roar, fury and burst cues are replaced by his own.
      expect(NeferhooAudioCues.roarCue, 'hoopoe_roar');
      expect(NeferhooAudioCues.furyCue, 'mummy_fury');
      expect(NeferhooAudioCues.burstCue, 'mask_pop');
    });

    test('the lengths are the rules\' own timings', () {
      // The mail call rings from the lock to the first letter; the ankh rises
      // from its lock to its throw; the roar fills the stage-up's roar.
      expect(
        soundBank['mail_call']!.seconds,
        closeTo(Neferhoo.mailReleaseAt - Neferhoo.mailLockAt, 1e-9),
      );
      expect(
        soundBank['ankh_raise']!.seconds,
        closeTo(Neferhoo.ankhThrowAt - Neferhoo.ankhLockAt, 1e-9),
      );
      expect(soundBank['hoopoe_roar']!.seconds, SkyBoss.stageRoar);
      // Fury's two ankhs are thrown this far apart: one whir covers both.
      expect(
        soundBank['ankh_whir']!.cooldownMs / 1000,
        greaterThan(Neferhoo.furyAnkhDelay),
      );
      // A letter flick never swallows the next (they are .32 s apart).
      expect(
        soundBank['letter_flick']!.cooldownMs / 1000,
        lessThan(Neferhoo.furyStreamGap),
      );
    });

    test('a scuff under a postage due is the same file, 6 dB lower', () {
      final duck = soundBank['wrap_scuff_duck']!,
          base = soundBank['wrap_scuff']!;
      expect(duck.file, 'wrap_scuff');
      expect(soundAsset('wrap_scuff_duck', 0), soundAsset('wrap_scuff', 0));
      expect(duck.seconds, base.seconds);
      expect(duck.priority, base.priority);
      expect(db(duck.volume / base.volume), closeTo(-6, .3));
    });

    for (final name in design.keys) {
      test('$name is clean, mastered PCM', () {
        final w = wav(name);
        final spec = soundBank[name]!;
        expect([w.channels, w.bits, w.rate], [1, 16, 44100]);
        expect(
          (w.x.length - spec.seconds * w.rate).abs(),
          lessThanOrEqualTo(2),
          reason: 'as long as the ${spec.seconds} s the bank reserves',
        );
        // Mastered to -3.10 dBFS: headroom and no sample at full scale.
        expect(db(w.peak), inInclusiveRange(-3.25, -2.95));
        expect(w.x.where((v) => v >= 32767 / 32768 || v <= -1), isEmpty);
        expect(w.mean.abs(), lessThan(5e-4), reason: 'DC offset');
        expect(w.x.first.abs(), lessThan(.02), reason: 'a click at the start');
        expect(w.x.last.abs(), lessThan(.005), reason: 'a click at the end');
        expect(w.rmsDb(0, w.seconds), greaterThan(-26));
        // The decoded-buffer limit (the packaged-asset test uses 1 MB).
        expect(File('assets/audio/$name.wav').lengthSync(), lessThan(400000));
      });
    }
  });

  group('a phone can play them', () {
    // The design's rule: every cue keeps at least 40 % of its energy in
    // 250 Hz-8 kHz (two 12 dB/octave filters each side). Measured when the
    // WAVs were rendered (tool/check_sound_effects.py's sharp FFT band reads
    // 63-100 %): 49 % the roar (a deep call over a gong), 59-66 % the mail
    // call, return, postage due, mask pop and ankh raise, the rest 72-96 %.
    const measured = {
      'hoopoe_roar': .49,
      'sand_devil': .91,
      'mail_call': .59,
      'letter_flick': .93,
      'letter_return': .65,
      'postage_due': .65,
      'wrap_scuff': .96,
      'ankh_raise': .64,
      'ankh_whir': .78,
      'ankh_catch': .72,
      'mummy_fury': .77,
      'mask_pop': .66,
      'lost_letter': .96,
    };
    for (final name in design.keys) {
      test('$name keeps at least 40 % of its energy in 250 Hz-8 kHz', () {
        final share = phoneBand(wav(name));
        expect(share, greaterThanOrEqualTo(.40));
        // A re-render that changes the sound moves this (a guard on the
        // measurement and on the files, not on taste).
        expect(share, closeTo(measured[name]!, .03));
        // The sharp FFT band is never lower than the filtered one's 40 %.
        expect(wav(name).share(250, 8000), greaterThanOrEqualTo(.40));
      });
    }
  });

  group('as loud as their neighbours', () {
    // The references: the boss roar and reveal (the strongest cues of the
    // bank), the dragon's breath (a telegraph), measured from their assets.
    final roar = played('boss_roar');
    final reveal = played('boss_reveal');
    final breath = played('dragon_breath');

    test('the arrival roar stands with the other guardians\' roars', () {
      expect(
        played('hoopoe_roar'),
        inInclusiveRange(roar - 4, reveal + 1),
        reason: 'the window the New York roars are held to',
      );
    });

    test('the jackpot is the loudest thing he does, and not painful', () {
      final jackpot = played('postage_due');
      for (final name in design.keys) {
        if (name == 'postage_due' || name == 'mask_pop') continue;
        expect(played(name), lessThan(jackpot), reason: name);
      }
      expect(jackpot, lessThanOrEqualTo(reveal + 1.5));
    });

    test('nothing of his is louder than the boss reveal', () {
      for (final name in design.keys) {
        expect(played(name), lessThanOrEqualTo(reveal + 1.5), reason: name);
      }
    });

    test('telegraphs and cries sit within 6 dB of the dragon', () {
      for (final name in [
        'mummy_fury',
        'ankh_raise',
        'mail_call',
        'letter_return',
        'ankh_catch',
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
        'letter_flick',
        'wrap_scuff',
        'ankh_whir',
        'sand_devil',
      ]) {
        expect(played(name), inInclusiveRange(-31, breath - 1), reason: name);
      }
    });

    test('the scuff is the smallest thing he does, ducked smaller still', () {
      final scuff = played('wrap_scuff');
      for (final name in design.keys) {
        if (name == 'wrap_scuff') continue;
        expect(played(name), greaterThan(scuff - 1.5), reason: name);
      }
      expect(
        wav('wrap_scuff').loudest(.1) +
            db(soundBank['wrap_scuff_duck']!.volume),
        closeTo(scuff - 6, .3),
      );
    });
  });

  group('the shape that makes each one recognisable', () {
    test('the roar is three hoots in the first half second, then a gong', () {
      final w = wav('hoopoe_roar');
      // The call's body: a bright voice near 300 Hz while his beak pulses
      // (the picture opens it at 0, .15 and .30 s of the roar for .15 s each).
      expect(w.peakHz(.02, .5, 200, 420), inInclusiveRange(230, 380));
      expect(w.rmsDb(0, .5), greaterThan(w.rmsDb(.9, 1.4) + 15));
    });

    test('the postage due is a thud then a bell, the loudest at the start', () {
      final w = wav('postage_due');
      expect(w.rmsDb(0, .1), greaterThan(w.rmsDb(.4, .7) + 8));
      // The counter bell: G6 (1568 Hz) rings after the thump.
      expect(w.peakHz(.14, .4, 1200, 2400), closeTo(1568, 60));
    });

    test('the ankh whir is chopped, level, and as long as a throw', () {
      final w = wav('ankh_whir');
      final env = w.envelope(.1);
      // A steady beat: nothing in the body drops far below its neighbours.
      final body = env.sublist(2, env.length - 2);
      expect(
        body.reduce(math.max) - body.reduce(math.min),
        lessThan(8),
        reason: 'a drone or a gap would show here',
      );
      expect(w.centroid(0, w.seconds), greaterThan(2000));
    });

    test('the lost letter is four warm notes climbing, and ends quiet', () {
      final w = wav('lost_letter');
      final starts = w.onsets(hop: .01, rise: 5, within: 30);
      expect(starts.length, inInclusiveRange(3, 5));
      expect(w.rmsDb(0, .5), greaterThan(w.rmsDb(1.0, 1.4) + 12));
    });
  });

  group('his cues sound once, on their edge', () {
    test('the arrival: warning, sand devil, reveal, roar', () {
      final boss = neferhoo(age: 0);
      final cues = BossAudioCues();
      expect(cues.advance(boss), ['boss_warning']);
      boss.age = .05;
      expect(cues.advance(boss), isEmpty);
      boss.age = NeferhooAudioCues.devilAt + .01;
      expect(cues.advance(boss), ['sand_devil']);
      boss.age = .3;
      expect(cues.advance(boss), isEmpty);
      // The generic reveal at the picture's flash, then his own roar.
      boss.age = SkyBoss.revealAt + .01;
      expect(cues.advance(boss), ['boss_reveal']);
      boss.age = SkyBoss.roarAt + .01;
      expect(cues.advance(boss), ['hoopoe_roar']);
      expect(cues.advance(boss), isEmpty);
      boss.age = arrival + .1;
      expect(cues.advance(boss), isEmpty);
    });

    test('a first frame a little late still hears the devil once', () {
      final boss = neferhoo(age: .3);
      final cues = BossAudioCues();
      expect(cues.advance(boss), ['boss_warning', 'sand_devil']);
      boss.age = .4;
      expect(cues.advance(boss), isEmpty);
      // But a boss met mid-fight (a resumed or scrubbed flight) is silent.
      expect(BossAudioCues().advance(neferhoo(age: arrival + 5)), isEmpty);
    });

    test('the stage-up roars, fury cries, and each once', () {
      final boss = neferhoo(age: arrival + 5);
      final cues = BossAudioCues()..advance(boss, silent: true);
      // A third of his health gone: the full fight, and the hoopoe's roar.
      boss
        ..hp = 180
        ..stageReached = 1
        ..stageUpAt = boss.age;
      expect(cues.advance(boss), ['hoopoe_roar']);
      expect(cues.advance(boss), isEmpty);
      // Fury: his cry, not a second roar with it.
      boss
        ..hp = 90
        ..stageReached = 2
        ..stageUpAt = boss.age
        ..enragedAt = boss.age;
      expect(boss.enraged, isTrue);
      expect(cues.advance(boss), ['mummy_fury']);
      expect(cues.advance(boss), isEmpty);
    });

    test('the mail call, each letter as it leaves, a return, the payoff', () {
      final boss = neferhoo();
      final cues = BossAudioCues()..advance(boss, silent: true);
      final lock = boss.age;
      mailCall(boss);
      expect(cues.advance(boss), ['mail_call']);
      expect(cues.advance(boss), isEmpty, reason: 'the letters are not out');
      // The first letter leaves one second after the lock, then .4 s apart.
      for (var i = 0; i < 3; i++) {
        boss.age = lock + 1.0 + i * Neferhoo.streamGap - .01;
        expect(cues.advance(boss), isEmpty, reason: 'before letter $i');
        boss.age += .02;
        expect(cues.advance(boss), ['letter_flick'], reason: 'letter $i');
        expect(cues.advance(boss), isEmpty);
      }
      // A rock sends one home; it lands for 25 a moment later.
      boss.age += .3;
      boss.neferhoo.lettersReturned++;
      expect(cues.advance(boss), ['letter_return']);
      boss.age += .5;
      boss.neferhoo.returnsLanded++;
      expect(cues.advance(boss), ['postage_due']);
      expect(cues.advance(boss), isEmpty);
    });

    test('the express post flicks five, and a bulk return sounds once', () {
      final boss = neferhoo();
      final cues = BossAudioCues()..advance(boss, silent: true);
      final lock = boss.age;
      mailCall(boss, letters: 5, express: true);
      expect(cues.advance(boss), ['mail_call']);
      var flicks = 0;
      for (var i = 0; i < 5; i++) {
        boss.age = lock + 1.0 + i * Neferhoo.furyStreamGap + .01;
        flicks += cues.advance(boss).where((c) => c == 'letter_flick').length;
      }
      expect(flicks, 5);
      // One charged rock returns three letters in one step: one cue.
      boss.neferhoo.lettersReturned += 3;
      expect(cues.advance(boss), ['letter_return']);
      // A frame that releases two letters at once still flicks once (the
      // bank's cooldown would drop a second anyway).
      final late = neferhoo();
      final lateCues = BossAudioCues()..advance(late, silent: true);
      final start = late.age;
      mailCall(late);
      lateCues.advance(late);
      late.age = start + 1.5;
      expect(lateCues.advance(late), ['letter_flick']);
    });

    test('a rock on the wraps scuffs; under a postage due it is ducked', () {
      final boss = neferhoo();
      final cues = BossAudioCues()..advance(boss, silent: true);
      boss.neferhoo.wrapScuffs++;
      expect(cues.advance(boss), ['wrap_scuff']);
      boss.neferhoo.wrapScuffs += 2;
      expect(cues.advance(boss), ['wrap_scuff']);
      // The same frame as the landing: the jackpot first, the scuff ducked.
      boss.neferhoo.returnsLanded++;
      boss.neferhoo.wrapScuffs++;
      expect(cues.advance(boss), ['postage_due', 'wrap_scuff_duck']);
      // 0.2 s after: still ducked. 0.3 s after: at full level again.
      boss.age += .2;
      boss.neferhoo.wrapScuffs++;
      expect(cues.advance(boss), ['wrap_scuff_duck']);
      boss.age += .1;
      boss.neferhoo.wrapScuffs++;
      expect(cues.advance(boss), ['wrap_scuff']);
    });

    test('the ankh: raised at its lock, whirs at the throw, caught home', () {
      final boss = neferhoo();
      final cues = BossAudioCues()..advance(boss, silent: true);
      final lock = boss.age;
      ankhLock(boss);
      expect(cues.advance(boss), ['ankh_raise']);
      expect(cues.advance(boss), isEmpty, reason: 'not thrown yet');
      boss.age = lock + Neferhoo.ankhThrowAt - Neferhoo.ankhLockAt - .01;
      expect(cues.advance(boss), isEmpty);
      boss.age += .02;
      expect(cues.advance(boss), ['ankh_whir']);
      expect(cues.advance(boss), isEmpty);
      boss.age += 3;
      boss.neferhoo.ankhCatches++;
      expect(cues.advance(boss), ['ankh_catch']);
      expect(cues.advance(boss), isEmpty);
    });

    test('fury: one raise, a whir at each throw, a catch for each ankh', () {
      final boss = neferhoo();
      final cues = BossAudioCues()..advance(boss, silent: true);
      final lock = boss.age;
      ankhLock(boss, two: true);
      expect(cues.advance(boss), ['ankh_raise']);
      boss.age = lock + 1.41;
      expect(cues.advance(boss), ['ankh_whir']);
      boss.age = lock + 1.41 + Neferhoo.furyAnkhDelay;
      expect(cues.advance(boss), ['ankh_whir'], reason: 'the bank merges them');
      boss.age += 3;
      boss.neferhoo.ankhCatches++;
      expect(cues.advance(boss), ['ankh_catch']);
      boss.age += .5;
      boss.neferhoo.ankhCatches++;
      expect(cues.advance(boss), ['ankh_catch']);
    });

    test('the warm-up\'s skipped ankh lock makes no sound', () {
      // The rules advance their lock cursor through a cycle whose ankh the
      // stage holds back, but latch nothing: the cue is the lock, not the
      // cycle (the stages' lesson: never key a cue on a hazard existing).
      final boss = neferhoo();
      final cues = BossAudioCues()..advance(boss, silent: true);
      boss.neferhoo.ankhLocks++;
      boss.age += 6;
      expect(boss.neferhoo.ankhLockedAt, isNegative);
      expect(cues.advance(boss), isEmpty);
    });

    test('the mask pops at the burst, the lost letter glows at 1.6 s', () {
      final boss = neferhoo(age: arrival + 20);
      final cues = BossAudioCues()..advance(boss, silent: true);
      boss.hp = 0;
      boss.defeatedAt = boss.age;
      expect(cues.advance(boss), ['boss_break']);
      boss.age = boss.defeatedAt! + SkyBoss.burstAt + .01;
      expect(cues.advance(boss), ['mask_pop']);
      expect(cues.advance(boss), isEmpty);
      // His victory card, then the found letter's chime once the victory
      // stinger has rung out (M1: they used to start .05 s apart).
      boss.age = boss.defeatedAt! + 1.56;
      expect(cues.advance(boss), ['boss_victory']);
      expect(NeferhooAudioCues.lostLetterAt, greaterThanOrEqualTo(1.55 + soundBank['boss_victory']!.seconds - 1e-9));
      boss.age = boss.defeatedAt! + NeferhooAudioCues.lostLetterAt + .01;
      expect(cues.advance(boss), ['lost_letter']);
      boss.age += .5;
      expect(cues.advance(boss), isEmpty);
    });

    test('a defeat that leaves a letter and an ankh unreleased is silent', () {
      final boss = neferhoo();
      final cues = BossAudioCues()..advance(boss, silent: true);
      mailCall(boss);
      ankhLock(boss);
      cues.advance(boss);
      // He falls before either leaves his hand.
      boss.age += .3;
      boss.hp = 0;
      boss.defeatedAt = boss.age;
      expect(cues.advance(boss), ['boss_break']);
      boss.age += 3.3;
      final heard = cues.advance(boss);
      expect(heard, ['mask_pop', 'boss_victory', 'lost_letter']);
      expect(cues.advance(boss), isEmpty);
    });
  });

  group('fix round (M1, after the W4 reviews)', () {
    test('a letter landing as fury rings is ducked under his cry, and no roar follows a step later', () {
      final boss = neferhoo(age: arrival + 30)
        ..hp = Neferhoo.campaignHp ~/ 3 + 10
        ..stageReached = 1;
      final cues = BossAudioCues()..advance(boss, silent: true);
      // the landing takes him to a third: fury now (the rules raise the
      // stage a step later)
      boss.age += 1 / 60;
      boss.takeDamage(Neferhoo.returnDamage);
      boss.neferhoo
        ..returnsLanded += 1
        ..lastLandAt = boss.age;
      expect(boss.enraged, isTrue);
      final first = cues.advance(boss);
      expect(first, containsAll(['mummy_fury', 'postage_due_duck']));
      expect(first, isNot(contains('postage_due')));
      expect(first, isNot(contains('boss_hit')));
      boss
        ..age += 1 / 60
        ..stageReached = 2
        ..stageUpAt = boss.age;
      expect(cues.advance(boss), isNot(contains('hoopoe_roar')), reason: 'fury cried already: no second roar');
    });

    test('the full fight\'s stage-up still roars, and a landing in its frame is ducked', () {
      final boss = neferhoo(age: arrival + 10);
      final cues = BossAudioCues()..advance(boss, silent: true);
      boss.age += 1 / 60;
      boss
        ..stageReached = 1
        ..stageUpAt = boss.age;
      boss.neferhoo.returnsLanded += 1;
      final heard = cues.advance(boss);
      expect(heard, containsAll(['hoopoe_roar', 'postage_due_duck']));
      // an ordinary landing is the full payoff
      boss.age += 1;
      boss.neferhoo.returnsLanded += 1;
      expect(cues.advance(boss), ['postage_due']);
    });

    test('his hits never ring the generic boss_hit: a scuff is only the cloth thud, a landing the payoff', () {
      final boss = neferhoo(age: arrival + 10);
      final cues = BossAudioCues()..advance(boss, silent: true);
      boss.age += .1;
      boss.takeDamage(3);
      boss.neferhoo
        ..wrapScuffs += 1
        ..lastScuffAt = boss.age;
      expect(cues.advance(boss), ['wrap_scuff']);
      boss.age += 1;
      boss.takeDamage(Neferhoo.returnDamage);
      boss.neferhoo
        ..returnsLanded += 1
        ..lastLandAt = boss.age;
      expect(cues.advance(boss), ['postage_due']);
      // (every other boss keeps it)
      final baron = SkyBoss(number: 1, x: 1.2, cinematic: true, kind: BossKind.baronBat)..age = arrival + 10;
      final other = BossAudioCues()..advance(baron, silent: true);
      baron.age += .1;
      baron.takeDamage(3);
      expect(other.advance(baron), contains('boss_hit'));
    });

    test('the defeat\'s stingers are sequenced: the lost letter chimes after the victory has rung out', () {
      final boss = neferhoo(age: arrival + 20);
      final cues = BossAudioCues()..advance(boss, silent: true);
      boss
        ..hp = 0
        ..defeatedAt = boss.age;
      final at = <String, double>{};
      for (var t = 0.0; t < 5; t += 1 / 60) {
        boss.age = boss.defeatedAt! + t;
        for (final cue in cues.advance(boss)) {
          at[cue] = t;
        }
      }
      final victoryEnds = at['boss_victory']! + soundBank['boss_victory']!.seconds;
      expect(at['lost_letter']!, greaterThanOrEqualTo(victoryEnds - 1 / 60));
      expect(at['lost_letter']! + soundBank['lost_letter']!.seconds, lessThan(SkyBoss(number: 1, x: 1, cinematic: true, kind: BossKind.neferhoo).departureDuration + 1.5),
          reason: 'it rings out before the level ends (about 7 s after the blow)');
    });
  });

  group('seeks, rewinds and new fights are silent', () {
    SkyBoss midFight() {
      final boss = neferhoo(age: arrival + 30);
      mailCall(boss);
      ankhLock(boss, two: true);
      boss.neferhoo.lettersReturned = 2;
      boss.neferhoo.returnsLanded = 1;
      boss.neferhoo.wrapScuffs = 5;
      boss.neferhoo.ankhCatches = 1;
      boss.age += 8; // the letters and both ankhs are long out
      return boss;
    }

    test('a silent seek into a fight plays nothing, now or after', () {
      final boss = midFight();
      final cues = BossAudioCues();
      expect(cues.advance(boss, silent: true), isEmpty);
      expect(cues.advance(boss), isEmpty);
      boss.age += .05;
      expect(cues.advance(boss), isEmpty);
      // And what comes next is heard as usual.
      boss.neferhoo.returnsLanded++;
      expect(cues.advance(boss), ['postage_due']);
    });

    test('a seek forward past letters and a throw leaves them unsounded', () {
      final boss = neferhoo();
      final cues = BossAudioCues()..advance(boss, silent: true);
      final lock = boss.age;
      mailCall(boss);
      ankhLock(boss);
      expect(cues.advance(boss), ['mail_call', 'ankh_raise']);
      boss.age = lock + 12;
      boss.neferhoo.ankhCatches++;
      expect(cues.advance(boss, silent: true), isEmpty);
      boss.age += .1;
      expect(cues.advance(boss), isEmpty, reason: 'the flicks are past');
    });

    test('a rewind is silent, and the edges it passes again are heard', () {
      final boss = neferhoo();
      final cues = BossAudioCues()..advance(boss, silent: true);
      final lock = boss.age;
      mailCall(boss);
      expect(cues.advance(boss), ['mail_call']);
      boss.age = lock + 1.5;
      expect(cues.advance(boss), ['letter_flick']);
      boss.neferhoo.lettersReturned++;
      expect(cues.advance(boss), ['letter_return']);
      // The player scrubs back to before the lock (the replay re-simulates
      // to there): a state with nothing latched yet.
      boss.age = lock - .5;
      boss.neferhoo.mailLockedAt = double.negativeInfinity;
      boss.neferhoo.mailLocks = 0;
      boss.neferhoo.letters.clear();
      boss.neferhoo.lettersReturned = 0;
      expect(cues.advance(boss), isEmpty, reason: 'the rewind itself');
      // Playing on from there sounds the lock and the letters again, once.
      boss.age = lock;
      mailCall(boss);
      expect(cues.advance(boss), ['mail_call']);
      boss.age = lock + 1.01;
      expect(cues.advance(boss), ['letter_flick']);
    });

    test('a rewind to before the defeat does not replay its cues', () {
      final boss = neferhoo(age: arrival + 20);
      final cues = BossAudioCues()..advance(boss, silent: true);
      boss.hp = 0;
      boss.defeatedAt = boss.age;
      cues.advance(boss);
      boss.age = boss.defeatedAt! + 2;
      cues.advance(boss, silent: true);
      boss.age = boss.defeatedAt! + .5;
      expect(cues.advance(boss), isEmpty);
      boss.age = boss.defeatedAt! + 1;
      expect(cues.advance(boss), ['mask_pop'], reason: 'crossed again');
      boss.age = boss.defeatedAt! + 3.3;
      expect(cues.advance(boss), ['boss_victory', 'lost_letter']);
    });

    test('a new fight starts from nothing, and the boss going forgets', () {
      final cues = BossAudioCues();
      final first = midFight();
      cues.advance(first, silent: true);
      expect(cues.advance(null), isEmpty);
      // The same cues on a later boss: its counters are its own.
      final next = neferhoo(age: arrival + 1);
      expect(cues.advance(next, silent: true), isEmpty);
      mailCall(next);
      expect(cues.advance(next), ['mail_call']);
    });
  });

  group('through SkyAudio', () {
    test(
      'his fight plays his files, in order, over the generic cues',
      () async {
        final host = AndroidAudioHost()..install();
        var now = 0;
        final audio = SkyAudio(effectClock: () => now);
        addTearDown(audio.dispose);
        await audio.configure(const GameSettings(music: false));
        final boss = neferhoo(age: arrival + 1);
        audio.syncBoss(boss, silent: true);
        mailCall(boss);
        audio.syncBoss(boss);
        await drainAudio();
        expect(host.loads.last, endsWith('mail_call.wav'));
        now += 3000;
        boss.neferhoo.returnsLanded++;
        boss.neferhoo.lettersReturned++;
        audio.syncBoss(boss);
        await drainAudio();
        expect(host.loads.reversed.take(2), [
          anyOf(endsWith('letter_return.wav'), endsWith('postage_due.wav')),
          anyOf(endsWith('letter_return.wav'), endsWith('postage_due.wav')),
        ]);
        expect(
          host.loads.where((u) => u.endsWith('postage_due.wav')),
          hasLength(1),
        );
        // A ducked scuff plays the scuff's own file.
        boss.neferhoo.returnsLanded++;
        boss.neferhoo.wrapScuffs++;
        now += 3000;
        audio.syncBoss(boss);
        await drainAudio();
        expect(
          host.loads.reversed.take(2),
          contains(endsWith('wrap_scuff.wav')),
          reason: 'the ducked scuff plays the scuff\'s own file',
        );
      },
    );

    test(
      'fury\'s two ankhs share one whir (the bank\'s 2 s cooldown)',
      () async {
        final host = AndroidAudioHost()..install();
        var now = 0;
        final audio = SkyAudio(effectClock: () => now);
        addTearDown(audio.dispose);
        await audio.configure(const GameSettings(music: false));
        final boss = neferhoo();
        audio.syncBoss(boss, silent: true);
        final lock = boss.age;
        ankhLock(boss, two: true);
        audio.syncBoss(boss);
        boss.age = lock + 1.41;
        now += 1410;
        audio.syncBoss(boss);
        boss.age += Neferhoo.furyAnkhDelay;
        now += 500;
        audio.syncBoss(boss);
        await drainAudio();
        expect(
          host.loads.where((u) => u.endsWith('ankh_whir.wav')),
          hasLength(1),
        );
        expect(
          host.loads.where((u) => u.endsWith('ankh_raise.wav')),
          hasLength(1),
        );
      },
    );

    test(
      'with Sound effects off nothing of his sounds, and nothing waits',
      () async {
        final host = AndroidAudioHost()..install();
        var now = 0;
        final audio = SkyAudio(effectClock: () => now);
        addTearDown(audio.dispose);
        await audio.configure(const GameSettings(music: false, effects: false));
        final boss = neferhoo();
        audio.syncBoss(boss, silent: true);
        final before = host.loads.length;
        mailCall(boss);
        ankhLock(boss);
        boss.neferhoo.returnsLanded++;
        boss.neferhoo.lettersReturned++;
        boss.neferhoo.wrapScuffs++;
        boss.neferhoo.ankhCatches++;
        boss.age += 8;
        audio.syncBoss(boss);
        boss.hp = 0;
        boss.defeatedAt = boss.age;
        audio.syncBoss(boss);
        boss.age += 2;
        audio.syncBoss(boss);
        await drainAudio();
        expect(host.loads, hasLength(before));
        expect(host.starts, isEmpty);
        // Turned back on, the edges that passed are not played late.
        await audio.configure(const GameSettings(music: false));
        now += 5000;
        audio.syncBoss(boss);
        await drainAudio();
        expect(host.loads, hasLength(before));
      },
    );

    test(
      'Character voices off silences voices, not his sound effects',
      () async {
        final host = AndroidAudioHost()..install();
        final audio = SkyAudio(effectClock: () => 0);
        addTearDown(audio.dispose);
        await audio.configure(const GameSettings(music: false, voices: false));
        final boss = neferhoo();
        audio.syncBoss(boss, silent: true);
        mailCall(boss);
        audio.syncBoss(boss);
        await drainAudio();
        expect(host.loads.last, endsWith('mail_call.wav'));
        expect(host.loads, isNot(contains(contains('audio/story/'))));
        expect(host.loads, isNot(contains(contains('audio/flight/'))));
      },
    );

    test('a replay scrub through his fight makes no sound', () async {
      final host = AndroidAudioHost()..install();
      final audio = SkyAudio(effectClock: () => 0);
      addTearDown(audio.dispose);
      await audio.configure(const GameSettings(music: false));
      final boss = neferhoo();
      audio.syncBoss(boss, silent: true);
      final loads = host.loads.length;
      final lock = boss.age;
      mailCall(boss);
      ankhLock(boss);
      boss.neferhoo.returnsLanded = 1;
      boss.neferhoo.lettersReturned = 1;
      boss.neferhoo.wrapScuffs = 3;
      boss.neferhoo.ankhCatches = 1;
      boss.age = lock + 11;
      audio.syncBoss(boss, silent: true);
      boss.age = lock + .2;
      audio.syncBoss(boss, silent: true);
      await drainAudio();
      expect(host.loads, hasLength(loads));
    });
  });

  group('the tool and its documentation', () {
    final tool = File('tool/prepare_sound_effects.py').readAsStringSync();

    test(
      'every cue has its own synth() branch (a misspelt one is a whoosh)',
      () {
        for (final name in design.keys) {
          expect(tool, contains("if name == '$name':"), reason: name);
        }
        final list = RegExp(
          r'EGYPT_CUES = \[(.*?)\]',
          dotAll: true,
        ).firstMatch(tool)!.group(1)!;
        expect(
          RegExp(r"'([a-z_]+)'").allMatches(list).map((m) => m[1]).toList(),
          design.keys.toList(),
        );
      },
    );

    test('the seeds stay in 501-619', () {
      final from = tool.indexOf('# ---- Egypt: Neferhoo');
      final to = tool.indexOf("if name == 'rush_clear':");
      expect(from, greaterThan(0));
      expect(to, greaterThan(from));
      final seeds = RegExp(
        r'seed=(\d+)|\b(?:updraft|crackle|crinkle|whistle|whir|band_noise)\(data, (\d+)',
      ).allMatches(tool.substring(from, to));
      expect(seeds, isNotEmpty);
      for (final m in seeds) {
        expect(int.parse((m[1] ?? m[2])!), inInclusiveRange(501, 619));
      }
    });

    test('docs/sound-effects.md documents each cue with its --only line', () {
      final doc = File('docs/sound-effects.md').readAsStringSync();
      expect(
        doc,
        contains(
          'python3 tool/prepare_sound_effects.py --only '
          '${design.keys.join(' ')}',
        ),
      );
      for (final name in [...design.keys, 'wrap_scuff_duck']) {
        expect(doc, contains('`$name`'), reason: name);
      }
    });
  });
}
