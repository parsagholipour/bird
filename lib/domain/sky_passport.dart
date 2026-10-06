/// The three medals of a stamp, earned in order.
enum StampMedal {
  bronze('Bronze'),
  silver('Silver'),
  gold('Gold');

  const StampMedal(this.label);
  final String label;
}

/// A stamp is one durable, measurable goal with a bronze, silver and gold
/// target: bronze a first real goal, silver a few weeks of flying, gold a
/// long-term mastery goal (the reasons are in docs/arcade-expansion.md).
/// Progress is derived from saved scored flights, so retrying a save cannot
/// award anything twice.
enum SkyStamp {
  // Counted targets are pinned Play step counts: see publishedPlaySteps.
  frequentFlyer('Frequent flyer', [10, 100, 500]),
  onTheDot('On the dot', [25, 200, 1000]),
  starChaser('Star chaser', [50, 500, 5000]),
  constellation('Constellation', [15, 40, 80]),
  skyCaptain('Sky captain', [100, 500, 2000]),
  trailblazer('Trailblazer', [5, 50, 250]),

  /// Bronze and silver count birds flown; gold the flights of the least
  /// flown of the four.
  flockTogether('Flock together', [2, 4, 25]),

  /// Bronze and silver count camera mini games tried; gold the flights of
  /// the least flown of the three. The mini games are a side to the
  /// tap-to-fly adventure, so gold stays light.
  allRounder('All-rounder', [1, 3, 10]);

  const SkyStamp(this.title, this.targets);
  final String title;

  /// The bronze, silver and gold targets.
  final List<int> targets;
  int target(StampMedal medal) => targets[medal.index];

  /// What [medal] asks for, as the passport and results show it.
  String goal(StampMedal medal) {
    final n = groupedCount(target(medal));
    return switch (this) {
      frequentFlyer => 'Finish $n scored flights.',
      onTheDot => 'Fly $n perfect passes along the aiming marks.',
      starChaser => 'Collect $n stars.',
      constellation => 'Collect $n stars in one unbroken streak.',
      skyCaptain => 'Score $n points in one endless flight.',
      trailblazer => 'Fly at least 60 seconds in $n endless flights.',
      flockTogether => switch (medal) {
        StampMedal.bronze => 'Take two different birds on scored flights.',
        StampMedal.silver => 'Take all four birds on scored flights.',
        StampMedal.gold => 'Fly $n scored flights with every bird.',
      },
      allRounder => switch (medal) {
        StampMedal.bronze => 'Fly a push-up, squat or jump mini game.',
        StampMedal.silver => 'Fly all three mini games: push-up, squat, jump.',
        StampMedal.gold => 'Fly $n scored flights in each mini game.',
      },
    };
  }
}

/// [n] with its thousands grouped: 5,000.
String groupedCount(int n) {
  final digits = '$n';
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0 && digits[i - 1] != '-') {
      out.write(',');
    }
    out.write(digits[i]);
  }
  return out.toString();
}

/// How far a stamp has come: the medal it holds and the count toward the
/// next one.
class StampProgress {
  /// One [count] measures every medal of [stamp].
  StampProgress(this.stamp, int count) : counts = List.filled(3, count);

  /// [counts] holds the bronze, silver and gold measures of a stamp whose
  /// medals count different things.
  StampProgress.medals(this.stamp, this.counts) : assert(counts.length == 3);

  final SkyStamp stamp;
  final List<int> counts;

  /// The best medal held, earned in order; null before bronze.
  StampMedal? get medal {
    StampMedal? held;
    for (final m in StampMedal.values) {
      if (counts[m.index] < stamp.target(m)) break;
      held = m;
    }
    return held;
  }

  /// Whether the stamp holds at least bronze.
  bool get earned => medal != null;
  bool get complete => medal == StampMedal.gold;

  /// The medal still to earn; null once gold is held.
  StampMedal? get nextMedal {
    final held = medal;
    if (held == null) return StampMedal.bronze;
    return held == StampMedal.gold ? null : StampMedal.values[held.index + 1];
  }

  /// The medal the progress below measures: the next one, or gold.
  StampMedal get aim => nextMedal ?? StampMedal.gold;
  int get current => counts[aim.index];
  int get target => stamp.target(aim);
  String get goal => stamp.goal(aim);
  double get fraction => (current / target).clamp(0.0, 1.0);
  int get remaining => (target - current).clamp(0, target);

  /// "120/500", toward [aim].
  String get tally => '${groupedCount(current)}/${groupedCount(target)}';

  /// "Star chaser: Silver" for the medal held.
  String get medalTitle => '${stamp.title}: ${medal?.label ?? 'none yet'}';

  /// "Star chaser · Silver" for the medal still to earn.
  String get nextTitle => '${stamp.title} · ${aim.label}';
}
