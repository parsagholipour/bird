import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/game_rules.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'built_pilot.dart';

/// A Tap & Fly level with every kind of item and every optional key.
BuiltPlan everything() => BuiltPlan(
  id: 'u-everything',
  name: 'Everything',
  mode: PlayMode.touch,
  region: WorldRegion.china,
  pace: BuiltPace.brisk,
  finish: 9000,
  marks: const StarMarks(3, 4),
  boss: BossKind.duskMoth,
  sprint: false,
  items: const [
    BuiltGate(x: 3000, y: 500, gap: 400, door: true),
    BuiltGate(
      x: 4200,
      y: 400,
      gap: 420,
      kind: ObstacleKind.petalGate,
      amp: 60,
      cycle: 3000,
      phase: 90,
      look: 2,
    ),
    BuiltStar(x: 3600, y: 450),
    BuiltTrio(x: 5200, y: 600),
    BuiltHeart(x: 6000, y: 300),
    BuiltEnemy(x: 6600, y: 500, kind: EnemyKind.spitterBeetle),
  ],
);

BuiltPlan reload(BuiltPlan plan) => BuiltPlan.fromJson(
  jsonDecode(jsonEncode(plan.toJson())) as Map<String, dynamic>,
);

void main() {
  test('a built plan round-trips through canonical JSON', () {
    for (final plan in [
      everything(),
      for (final mode in PlayMode.values) sampleLevel(mode),
    ]) {
      expect(plan.problem, isNull, reason: plan.name);
      final again = reload(plan);
      expect(again.toJson(), plan.toJson(), reason: plan.name);
      expect(again.fingerprint, plan.fingerprint, reason: plan.name);
      expect(jsonEncode(again.toJson()), jsonEncode(plan.toJson()));
    }
    final json = everything().toJson();
    expect(json['v'], BuiltPlan.formatVersion);
    expect(json['sprint'], isFalse);
    expect(json.containsKey('shoot'), isFalse);
    expect(json['boss'], 'duskMoth');
    // Defaults are left out: a still garden gate is five keys and a tag.
    final items = json['items'] as List;
    expect(items.first, {
      't': 'g',
      'x': 3000,
      'y': 500,
      'gap': 400,
      'k': 'garden',
      'door': true,
    });
  });

  test('items are kept in route order, whatever order they came in', () {
    final plan = everything();
    final shuffled = plan.copyWith(
      items: plan.items.reversed.toList()..shuffle(math.Random(4)),
    );
    expect(jsonEncode(shuffled.toJson()), jsonEncode(plan.toJson()));
    final xs = [for (final item in plan.items) item.x];
    expect(xs, [...xs]..sort());
    // At one x a gate comes before a star, a star before a trio.
    final tied = plan.copyWith(
      items: const [
        BuiltTrio(x: 3000, y: 500),
        BuiltStar(x: 3000, y: 600),
        BuiltStar(x: 3000, y: 400),
      ],
      marks: const StarMarks(1, 2),
      boss: () => null,
    );
    expect(
      [for (final item in tied.items) '${item.tag}${item.y}'],
      ['s400', 's600', '3500'],
    );
  });

  test('the fingerprint is the route, not its id or name', () {
    final plan = sampleLevel(PlayMode.pushUp);
    expect(plan.fingerprint, hasLength(8));
    expect(
      plan.copyWith(id: 'u-otherlevel', name: 'Mine').fingerprint,
      plan.fingerprint,
    );
    final moved = plan.copyWith(
      items: [
        plan.items.first.movedTo(x: plan.items.first.x + 10),
        ...plan.items.skip(1),
      ],
    );
    expect(moved.fingerprint, isNot(plan.fingerprint));
    expect(
      plan.copyWith(region: WorldRegion.egypt).fingerprint,
      isNot(plan.fingerprint),
    );
  });

  test('malformed JSON is refused', () {
    Map<String, dynamic> base() =>
        jsonDecode(jsonEncode(everything().toJson())) as Map<String, dynamic>;
    final broken = <String, void Function(Map<String, dynamic>)>{
      'newer format': (j) => j['v'] = 2,
      'no format': (j) => j.remove('v'),
      'float finish': (j) => j['finish'] = 9000.5,
      'unknown mode': (j) => j['mode'] = 'smile',
      'unknown region': (j) => j['region'] = 'mars',
      'unknown pace': (j) => j['pace'] = 'zoom',
      'three marks': (j) => j['marks'] = [1, 2, 3],
      'explicit shoot': (j) => j['shoot'] = true,
      'unknown tag': (j) =>
          (j['items'] as List).add({'t': 'q', 'x': 5000, 'y': 1}),
      'float x': (j) => ((j['items'] as List).first as Map)['x'] = 3000.0,
      'string y': (j) => ((j['items'] as List).first as Map)['y'] = '500',
      'unknown family': (j) =>
          ((j['items'] as List).first as Map)['k'] = 'wall',
      'door not a flag': (j) => ((j['items'] as List).first as Map)['door'] = 1,
      'not an item': (j) => (j['items'] as List).add(7),
      'unknown enemy': (j) => ((j['items'] as List).last as Map)['k'] = 'owl',
      'bad id': (j) => j['id'] = '1-1',
      'blank name': (j) => j['name'] = ' ',
    };
    expect(BuiltPlan.fromJson(base()).name, 'Everything');
    for (final MapEntry(:key, :value) in broken.entries) {
      final json = base();
      value(json);
      expect(
        () => BuiltPlan.fromJson(json),
        throwsFormatException,
        reason: key,
      );
    }
  });

  test('problem names what makes a plan unflyable', () {
    final tap = sampleLevel(PlayMode.touch);
    final push = sampleLevel(PlayMode.pushUp);
    BuiltPlan withItem(BuiltPlan plan, BuiltItem item) =>
        plan.copyWith(items: [...plan.items, item]);
    final last = tap.gates.last;
    final cases = <String, BuiltPlan>{
      'id': tap.copyWith(id: 'u-short'),
      'name': tap.copyWith(name: 'x' * 25),
      'finish': tap.copyWith(finish: 5000),
      'start': withItem(tap, const BuiltStar(x: 2300, y: 500)),
      'overlap': withItem(tap, BuiltGate(x: last.x + 60, y: 500, gap: 420)),
      'height': withItem(push, const BuiltGate(x: 3500, y: 500, gap: 460)),
      'motion': withItem(
        tap,
        const BuiltGate(x: 3500, y: 500, gap: 420, amp: 40),
      ),
      'gap': withItem(
        tap,
        const BuiltGate(
          x: 3500,
          y: 500,
          gap: 300,
          kind: ObstacleKind.windLift,
          amp: 100,
        ),
      ),
      'door': withItem(
        push,
        const BuiltGate(x: 3500, y: 250, gap: 460, door: true),
      ),
      'enemy': withItem(
        push,
        const BuiltEnemy(x: 4000, y: 500, kind: EnemyKind.caveBat),
      ),
      'boss': push.copyWith(boss: () => BossKind.baronBat),
      'marks': tap.copyWith(marks: StarMarks(1, tap.totalStars + 1)),
      'place': withItem(tap, BuiltStar(x: tap.finish, y: 500)),
    };
    for (final MapEntry(:key, :value) in cases.entries) {
      expect(value.problem, key, reason: key);
    }
    expect(
      tap.copyWith(boss: () => BossKind.kingCoo).problem,
      'boss',
      reason: 'guardians stay in the campaign',
    );
    expect(
      withItem(
        tap,
        const BuiltEnemy(x: 4000, y: 500, kind: EnemyKind.alleyPigeon),
      ).problem,
      'enemy',
    );
    expect(
      tap
          .copyWith(
            shoot: false,
            items: [
              ...tap.items,
              const BuiltGate(x: 3500, y: 500, gap: 420, door: true),
            ],
          )
          .problem,
      'door',
    );
    // The safe lane is the simulation's own: a still height-lane gate needs
    // room from its centre to the calibrated endpoint.
    expect(BuiltPlan.safeGap(PlayMode.pushUp, 250, 0), 326);
    expect(BuiltPlan.safeGap(PlayMode.touch, 500, 0), 126);
    expect(BuiltPlan.safeGap(PlayMode.touch, 500, 100), 326);
  });

  test('a test flight from here drops what lies before it', () {
    final plan = sampleLevel(PlayMode.touch);
    final from = plan.gates.elementAt(4).x - 300;
    final slice = plan.startingAt(from);
    final shift = BuiltPlan.firstX - from;
    expect(slice.items, isNotEmpty);
    expect(slice.items.first.left, greaterThanOrEqualTo(BuiltPlan.firstX));
    expect(slice.finish, plan.finish + shift);
    expect(slice.gates.length, 4);
    expect(slice.marks.three, lessThanOrEqualTo(slice.totalStars));
    expect(slice.problem, isNull);
  });

  test('ids, names, marks and modes', () {
    final random = math.Random(1);
    for (var i = 0; i < 20; i++) {
      final id = BuiltPlan.newId(random);
      expect(id, hasLength(12));
      expect(BuiltPlan.isBuiltId(id), isTrue);
    }
    expect(BuiltPlan.isBuiltId('t-push-1'), isTrue);
    expect(BuiltPlan.isBuiltId('1-1'), isFalse);
    expect(BuiltPlan.validName('Morning Pump'), isTrue);
    expect(BuiltPlan.validName(' Pump'), isFalse);
    expect(BuiltPlan.validName('Pump\n'), isFalse);
    String marks(StarMarks m) => '${m.two}/${m.three}';
    expect(marks(BuiltPlan.suggestMarks(30)), '17/24');
    expect(marks(BuiltPlan.suggestMarks(1)), '1/1');
    final push = sampleLevel(PlayMode.pushUp);
    expect(push.minRulesVersion, FlightSimulation.builtLevelsRulesVersion);
    expect(FlightSimulation.builtLevelsRulesVersion, 64);
    expect(push.flies(PlayMode.pushUp), isTrue);
    expect(push.flies(PlayMode.touch), isFalse);
    expect(push.shoot || push.sprint, isFalse);
    expect(sampleLevel(PlayMode.touch).shoot, isTrue);
    expect(push.levelId, push.id);
    expect(push.route(baseSpeed: .3, interval: 2).passages, isEmpty);
    expect(push.route(baseSpeed: .3, interval: 2).goal, push.finishX);
  });
}
