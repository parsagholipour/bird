import 'dart:math';

import '../domain/campaign.dart';
import '../domain/campaign_story.dart' show StoryMood;
import '../domain/game_rules.dart';
import '../domain/tracking.dart';
import 'campaign_voice_clips.dart';
import 'campaign_voices.dart';
import 'flight_voice_clips.dart';
import 'flight_voice_director.dart';
import 'flight_voice_faces.dart';
import 'regions/world_region.dart';

export 'flight_voice_director.dart'
    show FlightVoiceLine, FlightVoiceMemory, FlightVoiceBank, VoiceClip;

/// The line being said in flight, as the face saying it should look this
/// frame: whose face, its mood, and how far its mouth is open.
class FlightSpeech {
  const FlightSpeech({
    this.boss,
    required this.mood,
    required this.mouth,
    required this.age,
    required this.length,
  });

  /// The boss saying it, or null when the bird is talking.
  final BossKind? boss;
  bool get bird => boss == null;

  /// The line's mood, from its direction tags (docs/flight-voices.md).
  final StoryMood mood;

  /// The mouth this frame, 0 shut to [mouths] wide, following the take's
  /// own loudness every 50 ms. It is 0 in the pauses between words and
  /// once the line has ended.
  final int mouth;
  static const mouths = 3;

  /// Seconds since the line began, and its length. [age] runs a little past
  /// [length] while the face settles after the last word.
  final double age, length;
  bool get talking => age < length;
}

/// The characters' voice-over during a live flight (docs/flight-voices.md):
/// the equipped bird reacts to what happens to it, and a boss speaks in its
/// own fight. Each speaker has lines of its own; nothing is shared.
///
/// [update] reads the flight after every step, turns what changed into
/// moments ([VoiceCue]) and lets a [FlightVoiceDirector] choose what, if
/// anything, is said. Replays never create one, so they stay quiet apart
/// from their sound effects.
class FlightVoices {
  FlightVoices({
    required int bird,
    required this.mode,
    this.level,
    this.best = 0,
    this.retry = false,
    FlightVoiceMemory? memory,
    FlightVoiceBank? bank,
    Random? random,
    double Function()? clock,
    double talk = FlightVoiceDirector.talkativeness,
  }) : bird = CampaignVoices.birds[bird % CampaignVoices.birds.length],
       _random = random ?? Random(),
       _clock = clock ?? _wallClock,
       director = FlightVoiceDirector(
         bank: bank ?? recorded,
         memory: (memory ?? FlightVoiceMemory())..flights += 1,
         campaign: level != null,
         talk: talk,
         random: random,
       );

  /// The bird's name in clip names.
  final String bird;
  final PlayMode mode;

  /// The campaign level flown, or null for endless.
  final CampaignLevel? level;

  /// The endless record to beat; 0 when there is none yet.
  final int best;

  /// The last flight was lost and this one tries again.
  final bool retry;
  final FlightVoiceDirector director;
  final Random _random;

  /// Seconds on a clock that runs with the speech, not the flight: a line
  /// keeps moving the mouth through the knockout, after the flight's clock
  /// has stopped.
  final double Function() _clock;
  static final _watch = Stopwatch()..start();
  static double _wallClock() => _watch.elapsedMicroseconds / 1e6;

  /// The line being said and when it began on [_clock].
  ({FlightVoiceLine line, double start})? _said;

  /// Seconds a face holds its mood after the last word.
  static const _settle = .35;

  /// The face of whoever is talking, this frame, or null in silence.
  FlightSpeech? get speech {
    final said = _said;
    if (said == null) return null;
    final age = _clock() - said.start;
    final clip = said.line.clip;
    if (age < 0 || age > clip.seconds + _settle) return null;
    final curve = flightVoiceMouths[clip.name] ?? '';
    final frame = (age / .05).floor();
    return FlightSpeech(
      boss: _bosses[said.line.speaker],
      mood:
          StoryMood.values.asNameMap()[flightVoiceMoods[clip.name]] ??
          StoryMood.plain,
      mouth: frame < curve.length ? curve.codeUnitAt(frame) - 48 : 0,
      age: age,
      length: clip.seconds,
    );
  }

  static final _bosses = {
    for (final kind in BossKind.values) bossKey(kind): kind,
  };

  /// The line was cut short (a pause, a retry, leaving): the face falls
  /// quiet with it.
  void hush() => _said = null;

  FlightVoiceMemory get memory => director.memory;
  set memory(FlightVoiceMemory value) => director.memory = value;

  /// Every recorded line: the in-flight clips, each bird's sprint calls from
  /// the story recordings, and each boss's name-card line, which the
  /// campaign plays as the boss arrives.
  static final recorded = FlightVoiceBank.of(
    flightVoiceClips,
    extra: {
      for (final bird in CampaignVoices.birds)
        '$bird-sprint': [
          for (final call in const ['woohoo', 'turbo', 'gravity', 'whee'])
            ?_story('sprint-$bird-$call'),
        ],
      for (final chapter in Campaign.chapters)
        '${bossKey(chapter.boss)}-card': [
          ?_story('before-${chapter.number}-8-4'),
        ],
      // New York's two guardians say their name-card line (the 7th and 5th
      // lines of their lair scenes). Those takes are not recorded yet: the
      // pools stay empty and the card is silent until they are.
      '${bossKey(BossKind.kingCoo)}-card': [?_story('before-3-2-6')],
      '${bossKey(BossKind.searchlightGargoyle)}-card': [
        ?_story('before-3-4-4'),
      ],
    },
  );

  static VoiceClip? _story(String name) {
    final ms = campaignVoiceClips[name];
    return ms == null ? null : VoiceClip(name, 'audio/story/$name.ogg', ms);
  }

  /// A boss's name in clip names. King Coo and the Searchlight Gargoyle (New
  /// York's guardians) have their own keys, never another boss's, so they can
  /// never borrow its voice; they have no in-flight lines yet, so every pool
  /// asked for them is empty and they stay silent (see [voicedBosses]).
  static String bossKey(BossKind kind) => switch (kind) {
    BossKind.baronBat => 'baron',
    BossKind.spitterBeetle => 'spitter',
    BossKind.duskMoth => 'empress',
    BossKind.pirate => 'captain',
    BossKind.dragon => 'dragon',
    BossKind.kingCoo => 'coo',
    BossKind.searchlightGargoyle => 'gargoyle',
  };

  /// The bosses that have in-flight lines in `docs/flight-voices-sources.json`
  /// (taunts, hurt cries, their bird's answers). The guardians have none
  /// yet; adding theirs means adding them here and to the script.
  static const voicedBosses = {
    BossKind.baronBat,
    BossKind.spitterBeetle,
    BossKind.duskMoth,
    BossKind.pirate,
    BossKind.dragon,
  };

  /// A region's name in clip names.
  static String regionKey(WorldRegion region) => region.name.replaceAllMapped(
    RegExp('[A-Z]'),
    (m) => '-${m[0]!.toLowerCase()}',
  );

  /// Seconds of quiet before the bird says something to pass the time.
  double get _idleAfter => (level != null ? 13 : 22) / director.talk;

  /// Seconds of quiet before a boss taunts.
  double get _tauntAfter => (level != null ? 7 : 10) / director.talk;

  FlightSimulation? _sim;
  bool _tookOff = false, _ended = false, _record = false, _stretch = false;
  int _hearts = 3, _multiplier = 1, _magnets = 0, _reps = 0, _stars = 1;
  bool _shield = true;
  int _defeated = 0, _enemyShots = 0, _deflected = 0, _dryFires = 0;
  int _doors = 0, _sprints = 0, _rings = 0, _burns = 0, _splashes = 0;
  int _rushWarnings = 0, _rushEscapes = 0, _galeWarnings = 0, _galesOver = 0;
  FlightEvent? _event;
  WorldRegion? _region;
  final _spotted = <String>{};
  double _nextIdle = 0, _nextTaunt = 0;

  int? _bossNumber;
  bool _bossArrived = false, _bossEnraged = false, _bossDown = false;
  bool _bossCharging = false, _bossShielded = false;
  int _breaths = 0, _screeches = 0, _tides = 0, _summons = 0;
  double _bossHit = double.negativeInfinity;

  /// The line to say after this step of [sim], if any. With [mute] the
  /// flight is still followed, so turning voices back on never replays the
  /// past, but nothing is chosen.
  FlightVoiceLine? update(FlightSimulation sim, {bool mute = false}) {
    final fresh = !identical(_sim, sim);
    _sim = sim;
    final cues = _cues(sim, fresh: fresh);
    if (mute) {
      director.forgetHeld();
      return null;
    }
    final now = sim.elapsed;
    var line = director.tick(now);
    for (final cue in cues) {
      final said = director.offer(cue, now);
      if (said != null) line = said;
    }
    if (line != null) {
      _said = (line: line, start: _clock() + line.delay);
      final tip = RegExp(r'-rush-first-(\w+)-\d+$').firstMatch(line.clip.name);
      if (tip != null) memory.met.add('rush-${tip[1]}');
    }
    return line;
  }

  String _mine(String moment) => '$bird-$moment';
  VoiceOption _bird(String kind, String moment) =>
      VoiceOption(kind, _mine(moment));

  /// [options] in a random order, so neither speaker always gets the word.
  List<VoiceOption> _either(List<VoiceOption> options) =>
      options..shuffle(_random);

  List<VoiceCue> _cues(FlightSimulation sim, {required bool fresh}) {
    final cues = <VoiceCue>[];
    final events = _freshEvents(sim.events);
    if (fresh) {
      _remember(sim);
      _region = WorldTour.at(sim.elapsed, held: sim.region).dominant;
      return cues;
    }
    final now = sim.elapsed;
    final boss = sim.boss;
    final gloat = boss != null && boss.phase == BossPhase.attacking
        ? VoiceOption('gloat', '${bossKey(boss.kind)}-gloat')
        : null;

    if (!_tookOff && sim.phase == RunPhase.playing && sim.elapsed >= .6) {
      _tookOff = true;
      _nextIdle = now;
      final level = this.level;
      cues.add(
        VoiceCue([
          if (retry) _bird('retry', 'retry'),
          if (level != null && !retry) _bird('cargo', 'cargo-${level.id}'),
          _bird('takeoff', 'takeoff'),
        ]),
      );
    }

    // The flight's end.
    if (!_ended && sim.phase == RunPhase.ended) {
      _ended = true;
      if (sim.endReason == EndReason.collision) {
        cues.add(VoiceCue.of('knockout', _mine('knockout')));
      } else if (sim.endReason == EndReason.completed && level != null) {
        cues.add(VoiceCue.of('delivered', _mine('delivered')));
      }
    }

    // Hearts and the shield.
    final burned =
        sim.breathBurns > _burns ||
        events.any((e) => e.kind == FlightEventKind.scorched);
    final splashed = sim.birdSplashes > _splashes;
    if (sim.hearts < _hearts && sim.phase != RunPhase.ended) {
      final hit = [
        if (sim.hearts == 1) _bird('last-heart', 'last-heart'),
        if (burned) _bird('hit', 'hit-fire'),
        if (splashed) _bird('hit', 'hit-water'),
        _bird('hit', 'hit'),
      ];
      cues.add(
        VoiceCue(
          gloat == null || sim.hearts == 1
              ? hit
              : _random.nextBool()
              ? [gloat, ...hit]
              : [...hit, gloat],
        ),
      );
    } else if (_shield && !sim.shield && sim.hearts == _hearts) {
      cues.add(
        VoiceCue([
          if (gloat != null && _random.nextBool()) gloat,
          _bird('shield-pop', 'shield-pop'),
        ]),
      );
    } else if (!_shield && sim.shield) {
      cues.add(VoiceCue.of('shield-back', _mine('shield-back')));
    }
    if (sim.hearts > _hearts) {
      cues.add(VoiceCue.of('heart-pickup', _mine('heart-pickup')));
    }

    // Stars and score.
    if (sim.multiplier > _multiplier) {
      cues.add(VoiceCue.of('streak', _mine('streak')));
    }
    if (sim.magnetActivations > _magnets) {
      cues.add(VoiceCue.of('magnet', _mine('magnet')));
    }
    if (!_record && level == null && best > 0 && sim.score > best) {
      _record = true;
      cues.add(VoiceCue.of('record', _mine('record')));
    }
    final reps = switch (mode) {
      PlayMode.pushUp => 'reps-pushup',
      PlayMode.squat => 'reps-squat',
      PlayMode.jump => 'reps-jump',
      PlayMode.touch => null,
    };
    if (reps != null && sim.repetitions ~/ 10 > _reps ~/ 10) {
      cues.add(VoiceCue.of('reps', _mine(reps)));
    }

    // Enemies and the bird's weapons.
    if (!sim.bossCutscene) {
      for (final enemy in sim.enemies) {
        if (enemy.x > 1.02) continue;
        final kind = switch (enemy.kind) {
          EnemyKind.caveBat || EnemyKind.simpleBat => 'bat',
          EnemyKind.spitterBeetle => 'beetle',
          EnemyKind.duskMoth => 'moth',
          // New York's Alley Pigeon has no in-flight line: it is not spotted
          // aloud (and never borrows a bat's).
          EnemyKind.alleyPigeon => null,
        };
        if (kind != null && _spotted.add(kind)) {
          cues.add(VoiceCue.of('spot', _mine('spot-$kind')));
          break;
        }
      }
    }
    if (sim.enemiesDefeated + sim.swarmSmashed > _defeated) {
      cues.add(VoiceCue.of('enemy-down', _mine('enemy-down')));
    }
    if (sim.enemyShots > _enemyShots) {
      cues.add(VoiceCue.of('incoming', _mine('incoming')));
    }
    if (sim.projectilesDeflected > _deflected) {
      cues.add(VoiceCue.of('deflect', _mine('deflect')));
    }
    if (sim.dryFires > _dryFires) {
      cues.add(VoiceCue.of('no-ammo', _mine('no-ammo')));
    }
    if (sim.doorsDestroyed > _doors) {
      cues.add(VoiceCue.of('panel-break', _mine('panel-break')));
    }
    // A ring chain's first ring sprints like the Sprint key.
    if (sim.sprints > _sprints ||
        (sim.ringSprints > _rings && sim.ringChain == 1)) {
      cues.add(VoiceCue.of('sprint', _mine('sprint')));
    }

    // Set pieces.
    final rush = sim.rushPath?.kind;
    if (sim.rushWarnings > _rushWarnings && rush != null) {
      // The tip is for the first time it is heard, not merely met.
      final first = !memory.met.contains('rush-${rush.name}');
      cues.add(
        VoiceCue([
          if (first) _bird('rush', 'rush-first-${rush.name}'),
          _bird('rush', 'rush-${rush.name}'),
        ]),
      );
    }
    if (sim.rushPathsEscaped > _rushEscapes) {
      cues.add(VoiceCue.of('rush-escaped', _mine('rush-escaped')));
    }
    if (sim.galeWarnings > _galeWarnings) {
      cues.add(VoiceCue.of('gale', _mine('gale')));
    }
    if (sim.galesWeathered > _galesOver) {
      cues.add(VoiceCue.of('gale-over', _mine('gale-over')));
    }

    // A campaign level's route.
    if (level != null) {
      final route = sim.route;
      if (!_stretch &&
          route != null &&
          !route.boss &&
          sim.routeProgress >= .85) {
        _stretch = true;
        cues.add(VoiceCue.of('final-stretch', _mine('final-stretch')));
      }
      final stars = _levelStars(sim);
      if (stars > _stars) {
        cues.add(
          VoiceCue.of('stars', _mine(stars >= 3 ? 'stars-three' : 'stars-two')),
        );
      }
    }

    // The endless tour moving on to its next region.
    final region = WorldTour.at(sim.elapsed, held: sim.region).dominant;
    if (region != _region) {
      if (_region != null && level == null && boss == null) {
        cues.add(VoiceCue.of('region', _mine('region-${regionKey(region)}')));
      }
      _region = region;
    }

    _bossCues(sim, cues);

    // Quiet stretches.
    final quiet = now - max(director.lastEnd, 0.0);
    if (boss != null &&
        boss.phase == BossPhase.attacking &&
        now >= _nextTaunt &&
        quiet >= _tauntAfter) {
      _nextTaunt = now + 3;
      cues.add(
        VoiceCue.of(
          'taunt',
          '${bossKey(boss.kind)}-taunt',
          then: VoiceCue.of('retort', _mine('retort')),
        ),
      );
    }
    final calm =
        boss == null &&
        sim.phase == RunPhase.playing &&
        sim.rushPath == null &&
        sim.gale == null;
    if (calm && _tookOff && now >= _nextIdle && quiet >= _idleAfter) {
      _nextIdle = now + 6;
      final idle = _bird('idle', 'idle');
      final held = sim.region;
      final home = level == null || held == null
          ? null
          : _bird('region', 'region-${regionKey(held)}');
      cues.add(VoiceCue(home == null ? [idle] : _either([idle, home])));
    }

    _remember(sim);
    // The most urgent first: it takes the voice, the rest wait or pass.
    cues.sort((a, b) => _urgency(b).index.compareTo(_urgency(a).index));
    return cues;
  }

  static VoiceUrgency _urgency(VoiceCue cue) => cue.options
      .map((o) => FlightVoiceDirector.rules[o.kind]?.urgency)
      .nonNulls
      .fold(VoiceUrgency.chatter, (a, b) => a.index >= b.index ? a : b);

  void _bossCues(FlightSimulation sim, List<VoiceCue> cues) {
    final boss = sim.boss;
    if (boss == null) {
      _bossNumber = null;
      return;
    }
    final key = bossKey(boss.kind);
    if (_bossNumber != boss.number) {
      _bossNumber = boss.number;
      _bossArrived = false;
      _rememberBoss(boss);
      _nextTaunt = 0;
    }
    final arrival = boss.cinematic ? SkyBoss.roarAt + .8 : .8;
    if (!_bossArrived && boss.age >= arrival && boss.defeatedAt == null) {
      _bossArrived = true;
      final again = sim.bossesDefeated > 0 && level == null;
      final reaction = again
          ? _either([
              _bird('boss-arrive', 'boss-again'),
              _bird('boss-arrive', 'boss-$key'),
            ])
          : [_bird('boss-arrive', 'boss-$key')];
      // The bird answers the boss, or speaks first if the boss has nothing
      // fresh to say.
      cues.add(
        VoiceCue([
          if (level != null) VoiceOption('arrive', '$key-card'),
          VoiceOption('arrive', '$key-arrive'),
          ...reaction,
        ], then: VoiceCue(reaction)),
      );
    }
    if (boss.phase == BossPhase.attacking) {
      if (boss.enraged && !_bossEnraged) {
        cues.add(
          VoiceCue.of(
            'mad',
            '$key-mad',
            then: VoiceCue.of('boss-mad', _mine('boss-mad')),
          ),
        );
      }
      VoiceCue pair(String kind, String pool, String warning) => VoiceCue(
        _either([VoiceOption(kind, pool), _bird('boss-attack', warning)]),
      );
      final charging = boss.charge > 0;
      switch (boss.kind) {
        case BossKind.dragon when boss.breaths > _breaths:
          cues.add(pair('attack', '$key-attack', 'dragon-fire'));
        case BossKind.baronBat when boss.screechWarnings > _screeches:
          cues.add(pair('attack', '$key-attack', 'screech'));
        case BossKind.pirate when boss.tideSurges > _tides:
          cues.add(pair('tide', '$key-tide', 'tide-bell'));
        case BossKind.pirate when charging && !_bossCharging:
          cues.add(pair('attack', '$key-attack', 'cannon'));
        case BossKind.spitterBeetle || BossKind.duskMoth
            when charging && !_bossCharging:
          cues.add(VoiceCue.of('attack', '$key-attack'));
        default:
          break;
      }
      if (boss.shielded && !_bossShielded) {
        cues.add(VoiceCue.of('moth-shield', _mine('moth-shield')));
      }
      if (boss.summons > _summons) {
        cues.add(VoiceCue.of('summon', '$key-summon'));
      }
      if (boss.lastHitAt > _bossHit) {
        cues.add(VoiceCue.of('hurt', '$key-hurt'));
      }
    }
    if (!_bossDown && boss.defeatedAt != null) {
      final cheer = _either([
        _bird('boss-down', 'boss-down-$key'),
        _bird('boss-down', 'boss-down'),
      ]);
      cues.add(
        VoiceCue([
          VoiceOption('defeated', '$key-defeated'),
          ...cheer,
        ], then: VoiceCue(cheer)),
      );
    }
    _rememberBoss(boss);
  }

  void _rememberBoss(SkyBoss boss) {
    _bossEnraged = boss.enraged;
    _bossDown = boss.defeatedAt != null;
    _bossCharging = boss.charge > 0;
    _bossShielded = boss.shielded;
    _breaths = boss.breaths;
    _screeches = boss.screechWarnings;
    _tides = boss.tideSurges;
    _summons = boss.summons;
    _bossHit = boss.lastHitAt;
  }

  /// Events added since the last step. The list only grows at its end and
  /// drops from its front, so everything after the last one seen is new.
  List<FlightEvent> _freshEvents(List<FlightEvent> events) {
    final seen = _event;
    final start = seen == null
        ? 0
        : events.lastIndexWhere((e) => identical(e, seen)) + 1;
    if (events.isNotEmpty) _event = events.last;
    return events.sublist(start);
  }

  int _levelStars(FlightSimulation sim) =>
      sim.plan.rate(finished: true, stars: sim.collectedStars);

  void _remember(FlightSimulation sim) {
    if (level != null) _stars = _levelStars(sim);
    _hearts = sim.hearts;
    _shield = sim.shield;
    _multiplier = sim.multiplier;
    _magnets = sim.magnetActivations;
    _reps = sim.repetitions;
    _defeated = sim.enemiesDefeated + sim.swarmSmashed;
    _enemyShots = sim.enemyShots;
    _deflected = sim.projectilesDeflected;
    _dryFires = sim.dryFires;
    _doors = sim.doorsDestroyed;
    _sprints = sim.sprints;
    _rings = sim.ringSprints;
    _burns = sim.breathBurns;
    _splashes = sim.birdSplashes;
    _rushWarnings = sim.rushWarnings;
    _rushEscapes = sim.rushPathsEscaped;
    _galeWarnings = sim.galeWarnings;
    _galesOver = sim.galesWeathered;
  }
}
