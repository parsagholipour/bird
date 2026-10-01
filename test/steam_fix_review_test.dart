@Timeout(Duration(minutes: 8))
library;


import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/campaign.dart';
import 'package:push_up_bird/domain/game_rules.dart';

import 'campaign_flight.dart' show flyLevel, levelFlight;
import 'ny_arena.dart' as arena;
import 'steam_geyser_scenes.dart' show mountGame, narrow, savePng, shoot, wide;

/// Review frames of the Steam Geysers in a REAL level 3-3 flight (the
/// catalog's own plan and route, flown by the shared bot through the real
/// simulation, painted by the real renderer), at 800 and 640:
///
///   flutter test test/steam_fix_review_test.dart \
///     --dart-define=CAPTURE_STEAM_FIX=before   (or `after`)
///
/// writes `build/visual-review/steam-fix/<tag>/`.
const _tag = String.fromEnvironment('CAPTURE_STEAM_FIX');
const _dir = 'build/visual-review/steam-fix';

/// A fresh 3-3 flight flown until [until] holds.
FlightSimulation _flyTo(
  bool Function(FlightSimulation sim) until,
  double width,
) {
  final sim = levelFlight(Campaign.level('3-3')!);
  flyLevel(sim, viewportWidth: width, until: until, seconds: 120);
  return sim;
}

/// The nearest hop (or [ride]) vent ahead of the bird in [phase], with its
/// cycle time inside [from, to] and its x within [ahead].
bool Function(FlightSimulation) _vent(
  SteamPhase phase,
  double from,
  double to, {
  SteamKind kind = SteamKind.hop,
  (double, double) ahead = (.3, 1.2),
  bool tall = false,
}) => (sim) {
  for (final v in sim.steamVents) {
    if (v.kind != kind || v.phaseAt(sim.routeSeconds) != phase) continue;
    if (tall && v.top >= SteamCycle.stackBelow) continue;
    final t = SteamCycle.cycleTime(sim.routeSeconds, v.geyser.burstAt);
    final dx = v.x - FlightSimulation.birdX;
    if (t >= from && t <= to && dx >= ahead.$1 && dx <= ahead.$2) return true;
  }
  return false;
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final capture = _tag.isNotEmpty;

  testWidgets('real 3-3 flight frames', skip: !capture, (tester) async {
    for (final (size, px) in [(wide, '800'), (narrow, '640')]) {
      final width = size.width / size.height;
      final moments = <String, bool Function(FlightSimulation)>{
        'hiss-early': _vent(SteamPhase.hiss, -1.1, -.9, ahead: (.4, 1.0)),
        'hiss-late': _vent(SteamPhase.hiss, -.35, -.25, ahead: (.05, .5)),
        'burst': _vent(SteamPhase.burst, .26, .30, ahead: (-.4, .4)),
        'stack-hiss': _vent(
          SteamPhase.hiss,
          -.9,
          -.7,
          ahead: (.2, 1.0),
          tall: true,
        ),
        'stack-burst': _vent(
          SteamPhase.burst,
          .26,
          .30,
          ahead: (-.4, .4),
          tall: true,
        ),
        'billow-hop': _vent(SteamPhase.billow, .85, .9, ahead: (-.9, .1)),
        'ride-billow': _vent(
          SteamPhase.billow,
          .95,
          1.0,
          kind: SteamKind.ride,
          ahead: (-.1, .7),
        ),
      };
      for (final MapEntry(:key, :value) in moments.entries) {
        final sim = _flyTo(value, width);
        final game = await mountGame(tester, sim, size);
        await tester.runAsync(() async {
          await savePng(await shoot(game, size), '$_dir/$_tag/$px-$key.png');
        });
      }
      // The burst handing over to the billow, every 1/30 s, from +0.36 s.
      final sim = _flyTo(
        _vent(SteamPhase.burst, .34, .36, ahead: (-.5, .4)),
        width,
      );
      final game = await mountGame(tester, sim, size);
      for (var i = 0; i < 12; i++) {
        await tester.runAsync(() async {
          await savePng(
            await shoot(game, size),
            '$_dir/$_tag/$px-seq-${i.toString().padLeft(2, '0')}.png',
          );
        });
        sim.invulnerableUntil = 1e9;
        arena.frame(sim, dt: 1 / 30, width: width);
      }
    }
  });
}
