import 'dart:convert';
import 'dart:math';

/// How much a line matters: how soon after another line it may play, and
/// what it may cut short.
enum VoiceUrgency { chatter, normal, high, urgent }

/// One recorded line.
class VoiceClip {
  const VoiceClip(this.name, this.asset, this.ms, {this.mouth, this.mood});
  final String name, asset;
  final int ms;
  double get seconds => ms / 1000;

  /// A voice pack's own take carries its face (lib/game/voice_packs.dart):
  /// the mouth every 50 ms and the mood (a StoryMood name). Null for the
  /// English takes, whose faces are in the generated tables.
  final String? mouth, mood;
}

/// A line the director chose to say now.
class FlightVoiceLine {
  const FlightVoiceLine(
    this.clip,
    this.urgency, {
    this.delay = 0,
    this.speaker = '',
  });
  final VoiceClip clip;
  final VoiceUrgency urgency;

  /// Who says it, by the name its pools begin with (`pip`, `dragon`).
  final String speaker;

  /// Seconds to wait before saying it, clear of the sound it answers.
  final double delay;
  String get asset => clip.asset;
}

/// What the characters have said, kept across flights and launches, so a
/// flight never opens on the lines the last one ended with.
class FlightVoiceMemory {
  FlightVoiceMemory();

  /// Lines said so far, ever.
  int said = 0;

  /// Flights flown with voices so far, ever.
  int flights = 0;

  /// When each clip was last said, as the count of lines said by then.
  final Map<String, int> last = {};

  /// The flight each clip was last said in.
  final Map<String, int> lastFlight = {};

  /// What the player has already met, for lines said only the first time.
  final Set<String> met = {};

  void remember(String clip) {
    last[clip] = ++said;
    lastFlight[clip] = flights;
  }

  /// Lines said since [clip], or null if it has never been said.
  int? since(String clip) {
    final at = last[clip];
    return at == null ? null : said - at;
  }

  /// Flights begun since [clip] was said, or null if it never was.
  int? flightsSince(String clip) {
    final at = lastFlight[clip];
    return at == null ? null : flights - at;
  }

  String encode() => jsonEncode({
    'said': said,
    'flights': flights,
    'last': last,
    'lastFlight': lastFlight,
    'met': met.toList()..sort(),
  });

  /// A memory from [encode]; anything unreadable starts afresh.
  static FlightVoiceMemory decode(String? source) {
    final memory = FlightVoiceMemory();
    if (source == null || source.isEmpty) return memory;
    try {
      final json = jsonDecode(source) as Map<String, dynamic>;
      memory.said = json['said'] as int;
      memory.flights = json['flights'] as int;
      memory.last.addAll((json['last'] as Map).cast<String, int>());
      memory.lastFlight.addAll((json['lastFlight'] as Map).cast<String, int>());
      memory.met.addAll((json['met'] as List).cast<String>());
    } catch (_) {
      return FlightVoiceMemory();
    }
    return memory;
  }
}

/// Every in-flight line, in pools named `<speaker>-<moment>`: the clip
/// `pip-hit-03` belongs to `pip-hit`.
class FlightVoiceBank {
  FlightVoiceBank(this._pools);

  /// Groups [clips] (name to length in ms) into pools, each clip at
  /// `[folder]/<name>.ogg`.
  factory FlightVoiceBank.of(
    Map<String, int> clips, {
    String folder = 'audio/flight',
    Map<String, List<VoiceClip>> extra = const {},
  }) {
    final pools = <String, List<VoiceClip>>{
      for (final entry in extra.entries) entry.key: [...entry.value],
    };
    for (final MapEntry(key: name, value: ms) in clips.entries) {
      pools
          .putIfAbsent(poolOf(name), () => [])
          .add(VoiceClip(name, '$folder/$name.ogg', ms));
    }
    return FlightVoiceBank(pools);
  }

  /// Groups [clips] into pools by name, after the [extra] pools: a voice
  /// pack's lines, each with its own asset path and face.
  factory FlightVoiceBank.ofClips(
    Iterable<VoiceClip> clips, {
    Map<String, List<VoiceClip>> extra = const {},
  }) {
    final pools = <String, List<VoiceClip>>{
      for (final entry in extra.entries) entry.key: [...entry.value],
    };
    for (final clip in clips) {
      pools.putIfAbsent(poolOf(clip.name), () => []).add(clip);
    }
    return FlightVoiceBank(pools);
  }

  final Map<String, List<VoiceClip>> _pools;
  List<VoiceClip> operator [](String pool) => _pools[pool] ?? const [];
  Iterable<String> get pools => _pools.keys;

  static String poolOf(String clip) => clip.replaceFirst(_number, '');
  static final _number = RegExp(r'-\d+$');
}

/// One way to voice a moment: which kind of line (for its pacing rule) and
/// which pool to draw it from.
class VoiceOption {
  const VoiceOption(this.kind, this.pool);
  final String kind, pool;
}

/// A moment worth a line. The director tries its [options] in order and
/// says the first one its rules allow. [then] is offered right after the
/// line ends, so a boss's taunt can draw the bird's comeback.
class VoiceCue {
  const VoiceCue(this.options, {this.then});
  VoiceCue.of(String kind, String pool, {VoiceCue? then})
    : this([VoiceOption(kind, pool)], then: then);
  final List<VoiceOption> options;
  final VoiceCue? then;
}

/// How one kind of line is paced: its urgency, the chance it is said at all
/// (in endless and in the campaign), the seconds before it may come again
/// and the seconds it waits to be said, clear of the sound it answers.
/// [always] lines (once a flight or once a boss) are outside the per-minute
/// budget.
class VoiceRule {
  const VoiceRule(
    this.urgency, {
    this.chance = 1,
    this.campaign = 1,
    this.cooldown = 0,
    this.delay = 0,
    this.always = false,
  });
  final VoiceUrgency urgency;
  final double chance, campaign, cooldown, delay;
  final bool always;
}

class _Held {
  _Held(
    this.cue, {
    required this.from,
    required this.until,
    this.reply = false,
  });
  final VoiceCue cue;
  final double from, until;

  /// The second half of an exchange: it follows the line before without the
  /// usual gap, and its chance was not rolled yet.
  final bool reply;
}

/// Decides when a character speaks and which line it says, so that lines
/// stay rare enough to matter and never repeat.
///
/// - **Pacing.** After a line ends, the next waits a gap that shrinks with
///   urgency; chatter and ordinary lines also share a per-minute budget.
///   The campaign is chattier than endless: shorter gaps, a larger budget,
///   higher chances and shorter cooldowns. Warnings and once-a-flight lines
///   are outside the budget.
/// - **Urgency.** An urgent warning ("Fire!") may cut short chatter or an
///   ordinary line; a line that matters but finds the voice busy waits
///   briefly, then is dropped rather than said late.
/// - **Freshness.** A pool plays the least recently said half of its lines,
///   and a clip returns only after enough other lines were said ([rest]:
///   12 for pools of four or more, 24 for two or three, 48 for a single
///   line) or enough flights have begun since ([flightRest]), so a quiet
///   mode never falls silent for good. Both counts are kept across flights
///   ([FlightVoiceMemory]). A moment with no fresh line stays silent.
class FlightVoiceDirector {
  FlightVoiceDirector({
    required this.bank,
    required this.memory,
    this.campaign = false,
    this.talk = talkativeness,
    Random? random,
  }) : _random = random ?? Random();

  /// How often the characters talk, against the [rules]' chances: every
  /// kind of line is said this share of the times its rules allow. Halved
  /// from the first tuning on the owner's ask: nothing removed, half as
  /// often.
  static const talkativeness = .39;
  final double talk;

  final FlightVoiceBank bank;
  FlightVoiceMemory memory;
  final bool campaign;
  final Random _random;

  static const rules = <String, VoiceRule>{
    // The bird's lines.
    'takeoff': VoiceRule(always: true, VoiceUrgency.normal),
    'cargo': VoiceRule(always: true, VoiceUrgency.normal),
    'retry': VoiceRule(always: true, VoiceUrgency.normal),
    'hit': VoiceRule(VoiceUrgency.high, chance: .6, campaign: .8, cooldown: 12),
    'shield-pop': VoiceRule(
      VoiceUrgency.high,
      chance: .5,
      campaign: .7,
      cooldown: 20,
    ),
    'last-heart': VoiceRule(always: true, VoiceUrgency.high),
    'shield-back': VoiceRule(
      VoiceUrgency.normal,
      chance: .5,
      campaign: .7,
      cooldown: 30,
    ),
    'streak': VoiceRule(
      VoiceUrgency.normal,
      chance: .45,
      campaign: .6,
      cooldown: 30,
    ),
    'magnet': VoiceRule(
      VoiceUrgency.normal,
      chance: .6,
      campaign: .8,
      cooldown: 25,
    ),
    'heart-pickup': VoiceRule(
      VoiceUrgency.normal,
      chance: .6,
      campaign: .8,
      cooldown: 20,
    ),
    // After the bump, and under the game-over jingle rather than on it.
    'knockout': VoiceRule(VoiceUrgency.high, delay: .9, always: true),
    'record': VoiceRule(always: true, VoiceUrgency.high),
    'idle': VoiceRule(
      VoiceUrgency.chatter,
      chance: .7,
      campaign: .9,
      cooldown: 30,
    ),
    'region': VoiceRule(
      VoiceUrgency.chatter,
      chance: .5,
      campaign: .9,
      cooldown: 20,
    ),
    'reps': VoiceRule(
      VoiceUrgency.normal,
      chance: .7,
      campaign: .9,
      cooldown: 20,
    ),
    'spot': VoiceRule(VoiceUrgency.normal, chance: .9),
    'enemy-down': VoiceRule(
      VoiceUrgency.normal,
      chance: .3,
      campaign: .45,
      cooldown: 18,
    ),
    'incoming': VoiceRule(
      VoiceUrgency.urgent,
      chance: .35,
      campaign: .5,
      cooldown: 15,
    ),
    'deflect': VoiceRule(
      VoiceUrgency.normal,
      chance: .45,
      campaign: .6,
      cooldown: 20,
    ),
    'no-ammo': VoiceRule(
      VoiceUrgency.normal,
      chance: .6,
      campaign: .8,
      cooldown: 30,
    ),
    'panel-break': VoiceRule(
      VoiceUrgency.normal,
      chance: .6,
      campaign: .8,
      cooldown: 20,
    ),
    'rush': VoiceRule(VoiceUrgency.urgent),
    'rush-escaped': VoiceRule(VoiceUrgency.high, chance: .8),
    'gale': VoiceRule(VoiceUrgency.urgent),
    'gale-over': VoiceRule(VoiceUrgency.high, chance: .8),
    'sprint': VoiceRule(
      VoiceUrgency.high,
      chance: .6,
      campaign: .8,
      cooldown: 6,
    ),
    'boss-arrive': VoiceRule(always: true, VoiceUrgency.high),
    'boss-attack': VoiceRule(
      VoiceUrgency.urgent,
      chance: .7,
      campaign: .85,
      cooldown: 12,
    ),
    'moth-shield': VoiceRule(
      VoiceUrgency.normal,
      chance: .7,
      campaign: .85,
      cooldown: 20,
    ),
    'boss-mad': VoiceRule(VoiceUrgency.high, chance: .5, campaign: .7),
    'boss-down': VoiceRule(always: true, VoiceUrgency.high),
    'retort': VoiceRule(
      VoiceUrgency.normal,
      chance: .4,
      campaign: .55,
      cooldown: 15,
    ),
    'final-stretch': VoiceRule(always: true, VoiceUrgency.normal),
    'stars': VoiceRule(always: true, VoiceUrgency.normal),
    'delivered': VoiceRule(VoiceUrgency.high, delay: .4, always: true),
    // The boss's lines.
    'arrive': VoiceRule(always: true, VoiceUrgency.high),
    'taunt': VoiceRule(
      VoiceUrgency.normal,
      chance: .6,
      campaign: .8,
      cooldown: 12,
    ),
    'attack': VoiceRule(
      VoiceUrgency.urgent,
      chance: .7,
      campaign: .85,
      cooldown: 12,
    ),
    'tide': VoiceRule(
      VoiceUrgency.urgent,
      chance: .7,
      campaign: .85,
      cooldown: 12,
    ),
    'summon': VoiceRule(
      VoiceUrgency.normal,
      chance: .6,
      campaign: .8,
      cooldown: 20,
    ),
    'hurt': VoiceRule(
      VoiceUrgency.normal,
      chance: .25,
      campaign: .35,
      cooldown: 10,
    ),
    'gloat': VoiceRule(
      VoiceUrgency.high,
      chance: .6,
      campaign: .75,
      cooldown: 10,
    ),
    'mad': VoiceRule(always: true, VoiceUrgency.high),
    'defeated': VoiceRule(always: true, VoiceUrgency.high),
  };

  /// Seconds of quiet a line needs after the last one ended, stretched as
  /// [talk] falls. Warnings keep theirs.
  double _gap(VoiceUrgency urgency) => switch (urgency) {
    VoiceUrgency.chatter => (campaign ? 9 : 16) / talk,
    VoiceUrgency.normal => (campaign ? 4.5 : 7) / talk,
    VoiceUrgency.high => (campaign ? 1.5 : 2.5) / talk,
    VoiceUrgency.urgent => .5,
  };

  /// Lines allowed in any minute, warnings and [VoiceRule.always] lines
  /// aside.
  double get _budget => (campaign ? 8 : 5) * talk;

  /// Seconds a line that matters waits for the voice to come free, and the
  /// breath it leaves after the line it waited for.
  static const _patience = 2.0, _heldGap = .8;

  /// Lines that must be said before a clip from a pool of [size] returns.
  static int rest(int size) => size >= 4
      ? 12
      : size >= 2
      ? 24
      : 48;

  /// Flights that must begin before a clip from a pool of [size] returns
  /// however little was said since.
  static int flightRest(int size) => size >= 4
      ? 2
      : size >= 2
      ? 3
      : 6;

  double _speakingUntil = double.negativeInfinity;
  VoiceUrgency _speaking = VoiceUrgency.chatter;
  final _said = <double>[];
  final _lastKind = <String, double>{};
  _Held? _held;

  /// When the last line ends (or ended); -infinity before the first.
  double get lastEnd => _speakingUntil;
  bool speaking(double now) => now < _speakingUntil;

  /// Says [cue] now if the rules allow, holds it briefly if it matters and
  /// the voice is busy, or lets it pass.
  FlightVoiceLine? offer(VoiceCue cue, double now) => _try(
    cue,
    now,
    rolled: false,
    reply: false,
    held: false,
    until: now + _patience,
  );

  /// Says a held line or a reply once its time comes.
  FlightVoiceLine? tick(double now) {
    final held = _held;
    if (held == null || now < held.from) return null;
    if (now > held.until) {
      _held = null;
      return null;
    }
    _held = null;
    return _try(
      held.cue,
      now,
      rolled: !held.reply,
      reply: held.reply,
      held: !held.reply,
      until: held.reply ? now + _patience : held.until,
    );
  }

  /// The chosen line was not said after all (voices muted mid-flight).
  void forgetHeld() => _held = null;

  FlightVoiceLine? _try(
    VoiceCue cue,
    double now, {
    required bool rolled,
    required bool reply,
    required bool held,
    required double until,
  }) {
    for (final option in cue.options) {
      final rule = rules[option.kind];
      if (rule == null) continue;
      final cooldown = rule.cooldown * (campaign ? .7 : 1) / talk;
      final last = _lastKind[option.kind];
      if (last != null && now - last < cooldown) continue;
      if (!rolled &&
          _random.nextDouble() >=
              (campaign ? rule.campaign : rule.chance) * talk) {
        continue;
      }
      final clip = _pick(option.pool);
      if (clip == null) continue;
      if (!_free(rule, now, reply: reply, held: held)) {
        if (rule.urgency.index >= VoiceUrgency.high.index) {
          _hold(
            _Held(
              VoiceCue([option], then: cue.then),
              from: now,
              until: until,
            ),
          );
        }
        return null;
      }
      // A reply that spoke first, in place of its lead, is not said twice.
      final then = cue.then;
      final replied =
          then != null && then.options.any((o) => o.pool == option.pool);
      return _say(clip, option, rule, now, replied ? null : then);
    }
    return null;
  }

  bool _free(
    VoiceRule rule,
    double now, {
    required bool reply,
    required bool held,
  }) {
    final urgency = rule.urgency;
    if (now < _speakingUntil) {
      return urgency == VoiceUrgency.urgent &&
          _speaking.index <= VoiceUrgency.normal.index;
    }
    if (reply) return true;
    // A held line already waited: a breath after the voice frees is enough.
    final gap = held ? min(_gap(urgency), _heldGap) : _gap(urgency);
    if (now - _speakingUntil < gap) return false;
    if (_budgeted(rule)) {
      _said.removeWhere((at) => now - at >= 60);
      if (_said.length >= _budget) return false;
    }
    return true;
  }

  static bool _budgeted(VoiceRule rule) =>
      !rule.always && rule.urgency != VoiceUrgency.urgent;

  void _hold(_Held held) {
    final current = _held;
    if (current != null && current.reply && current.until >= held.from) return;
    _held = held;
  }

  /// The least recently said half of the fresh lines in [pool], at random.
  VoiceClip? _pick(String pool) {
    final clips = bank[pool];
    if (clips.isEmpty) return null;
    final rest = FlightVoiceDirector.rest(clips.length);
    final flights = flightRest(clips.length);
    final fresh = [
      for (final clip in clips)
        if ((memory.since(clip.name) ?? rest) >= rest ||
            (memory.flightsSince(clip.name) ?? flights) >= flights)
          clip,
    ];
    if (fresh.isEmpty) return null;
    fresh.sort(
      (a, b) =>
          (memory.last[a.name] ?? -1).compareTo(memory.last[b.name] ?? -1),
    );
    return fresh[_random.nextInt((fresh.length + 1) ~/ 2)];
  }

  FlightVoiceLine _say(
    VoiceClip clip,
    VoiceOption option,
    VoiceRule rule,
    double now,
    VoiceCue? then,
  ) {
    final urgency = rule.urgency;
    memory.remember(clip.name);
    _lastKind[option.kind] = now;
    if (_budgeted(rule)) _said.add(now);
    _speaking = urgency;
    _speakingUntil = now + rule.delay + clip.seconds;
    if (then != null) {
      _held = _Held(
        then,
        from: _speakingUntil + .35,
        until: _speakingUntil + 2.5,
        reply: true,
      );
    } else if (_held?.reply != true) {
      _held = null;
    }
    return FlightVoiceLine(
      clip,
      urgency,
      delay: rule.delay,
      speaker: option.pool.substring(0, option.pool.indexOf('-')),
    );
  }
}
