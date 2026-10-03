import 'package:push_up_bird/domain/game_rules.dart';

import 'campaign_flight.dart';

/// Synthetic New York level plans for the rules tests: built by hand so a
/// rules test states exactly the lineup, flocks and steam it needs. (They
/// were the scaffold's stand-ins before the level-data step; the catalog's
/// 3-1 to 3-4 now carry the shipped data, flown in `ny_levels_flight_test`.)
const _wheels = ObstacleKind.sunWheels;
const _road = [
  ObstacleKind.garden,
  ObstacleKind.windLift,
  ObstacleKind.petalGate,
  ObstacleKind.switchback,
  ObstacleKind.lanternDrift,
];

/// A New York plan in the shape of 3-2 (a pigeon lineup, a boss's run-up)
/// unless told otherwise.
LevelPlan nyPlan({
  String id = '3-2',
  double length = 30,
  double start = 85,
  int seed = 3102,
  List<EnemyKind> lineup = const [
    EnemyKind.alleyPigeon,
    EnemyKind.simpleBat,
    EnemyKind.alleyPigeon,
    EnemyKind.duskMoth,
  ],
  List<int> flocks = const [],
  SteamPlan steam = SteamPlan.none,
  BossKind? boss,
  List<SetPiece> pieces = const [],
  StarMarks marks = const StarMarks(20, 30),
}) => LevelPlan(
  id: id,
  region: WorldRegion.newYork,
  length: length,
  start: start,
  seed: seed,
  families: [..._road, _wheels],
  lineup: lineup,
  toughness: 2,
  panels: .25,
  flocks: flocks,
  steam: steam,
  boss: boss,
  pieces: pieces,
  marks: marks,
);

/// A fresh touch Star Trail flight of [plan] at [version]: New York's rules
/// (43) by default, the guardians' short fights as the New York program
/// proved them. Rules 44's staged fights are in `boss_stages_test.dart`.
FlightSimulation nyFlight(
  LevelPlan plan, {
  int version = FlightSimulation.newYorkRulesVersion,
  int weaponDamage = 30,
}) => FlightSimulation(
  rules: TapFlyMode(rulesVersion: version),
  practice: false,
  course: FlightCourse.starTrail,
  rulesVersion: version,
  weaponDamage: weaponDamage,
  plan: plan,
);

/// Flies [plan] with the shared bot until it ends, and returns the flight.
FlightSimulation flyNy(
  LevelPlan plan, {
  int version = FlightSimulation.newYorkRulesVersion,
  double viewportWidth = 2.2,
  void Function(FlightSimulation sim)? watch,
  bool Function(FlightSimulation sim, int frame)? sprintWhen,
  double seconds = 400,
}) {
  final sim = nyFlight(plan, version: version);
  flyLevel(
    sim,
    viewportWidth: viewportWidth,
    watch: watch,
    sprintWhen: sprintWhen,
    seconds: seconds,
  );
  return sim;
}
