// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_repository.dart';

// ignore_for_file: type=lint
class $RunsTable extends Runs with TableInfo<$RunsTable, Run> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<int> mode = GeneratedColumn<int>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseMeta = const VerificationMeta('course');
  @override
  late final GeneratedColumn<String> course = GeneratedColumn<String>(
    'course',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('classic'),
  );
  static const VerificationMeta _gatesMeta = const VerificationMeta('gates');
  @override
  late final GeneratedColumn<int> gates = GeneratedColumn<int>(
    'gates',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _starsMeta = const VerificationMeta('stars');
  @override
  late final GeneratedColumn<int> stars = GeneratedColumn<int>(
    'stars',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bestComboMeta = const VerificationMeta(
    'bestCombo',
  );
  @override
  late final GeneratedColumn<int> bestCombo = GeneratedColumn<int>(
    'best_combo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _perfectPassesMeta = const VerificationMeta(
    'perfectPasses',
  );
  @override
  late final GeneratedColumn<int> perfectPasses = GeneratedColumn<int>(
    'perfect_passes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _practiceMeta = const VerificationMeta(
    'practice',
  );
  @override
  late final GeneratedColumn<bool> practice = GeneratedColumn<bool>(
    'practice',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("practice" IN (0, 1))',
    ),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    check: () => ComparableExpr(score).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _flapsMeta = const VerificationMeta('flaps');
  @override
  late final GeneratedColumn<int> flaps = GeneratedColumn<int>(
    'flaps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<double> duration = GeneratedColumn<double>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birdMeta = const VerificationMeta('bird');
  @override
  late final GeneratedColumn<int> bird = GeneratedColumn<int>(
    'bird',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mode,
    course,
    gates,
    stars,
    bestCombo,
    perfectPasses,
    practice,
    score,
    repetitions,
    flaps,
    duration,
    reason,
    finishedAt,
    bird,
    level,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Run> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('course')) {
      context.handle(
        _courseMeta,
        course.isAcceptableOrUnknown(data['course']!, _courseMeta),
      );
    }
    if (data.containsKey('gates')) {
      context.handle(
        _gatesMeta,
        gates.isAcceptableOrUnknown(data['gates']!, _gatesMeta),
      );
    }
    if (data.containsKey('stars')) {
      context.handle(
        _starsMeta,
        stars.isAcceptableOrUnknown(data['stars']!, _starsMeta),
      );
    }
    if (data.containsKey('best_combo')) {
      context.handle(
        _bestComboMeta,
        bestCombo.isAcceptableOrUnknown(data['best_combo']!, _bestComboMeta),
      );
    }
    if (data.containsKey('perfect_passes')) {
      context.handle(
        _perfectPassesMeta,
        perfectPasses.isAcceptableOrUnknown(
          data['perfect_passes']!,
          _perfectPassesMeta,
        ),
      );
    }
    if (data.containsKey('practice')) {
      context.handle(
        _practiceMeta,
        practice.isAcceptableOrUnknown(data['practice']!, _practiceMeta),
      );
    } else if (isInserting) {
      context.missing(_practiceMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_repetitionsMeta);
    }
    if (data.containsKey('flaps')) {
      context.handle(
        _flapsMeta,
        flaps.isAcceptableOrUnknown(data['flaps']!, _flapsMeta),
      );
    } else if (isInserting) {
      context.missing(_flapsMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_finishedAtMeta);
    }
    if (data.containsKey('bird')) {
      context.handle(
        _birdMeta,
        bird.isAcceptableOrUnknown(data['bird']!, _birdMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Run map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Run(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mode'],
      )!,
      course: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course'],
      )!,
      gates: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gates'],
      )!,
      stars: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stars'],
      )!,
      bestCombo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}best_combo'],
      )!,
      perfectPasses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}perfect_passes'],
      )!,
      practice: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}practice'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      flaps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}flaps'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}duration'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      )!,
      bird: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bird'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      ),
    );
  }

  @override
  $RunsTable createAlias(String alias) {
    return $RunsTable(attachedDatabase, alias);
  }
}

class Run extends DataClass implements Insertable<Run> {
  final String id;
  final int mode;
  final String course;
  final int gates;
  final int stars;
  final int bestCombo;
  final int perfectPasses;
  final bool practice;
  final int score;
  final int repetitions;
  final int flaps;
  final double duration;
  final String reason;
  final DateTime finishedAt;
  final int bird;

  /// The campaign level flown, such as "1-3". Null for endless flights and
  /// every flight saved before the campaign; only those make records.
  final String? level;
  const Run({
    required this.id,
    required this.mode,
    required this.course,
    required this.gates,
    required this.stars,
    required this.bestCombo,
    required this.perfectPasses,
    required this.practice,
    required this.score,
    required this.repetitions,
    required this.flaps,
    required this.duration,
    required this.reason,
    required this.finishedAt,
    required this.bird,
    this.level,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['mode'] = Variable<int>(mode);
    map['course'] = Variable<String>(course);
    map['gates'] = Variable<int>(gates);
    map['stars'] = Variable<int>(stars);
    map['best_combo'] = Variable<int>(bestCombo);
    map['perfect_passes'] = Variable<int>(perfectPasses);
    map['practice'] = Variable<bool>(practice);
    map['score'] = Variable<int>(score);
    map['repetitions'] = Variable<int>(repetitions);
    map['flaps'] = Variable<int>(flaps);
    map['duration'] = Variable<double>(duration);
    map['reason'] = Variable<String>(reason);
    map['finished_at'] = Variable<DateTime>(finishedAt);
    map['bird'] = Variable<int>(bird);
    if (!nullToAbsent || level != null) {
      map['level'] = Variable<String>(level);
    }
    return map;
  }

  RunsCompanion toCompanion(bool nullToAbsent) {
    return RunsCompanion(
      id: Value(id),
      mode: Value(mode),
      course: Value(course),
      gates: Value(gates),
      stars: Value(stars),
      bestCombo: Value(bestCombo),
      perfectPasses: Value(perfectPasses),
      practice: Value(practice),
      score: Value(score),
      repetitions: Value(repetitions),
      flaps: Value(flaps),
      duration: Value(duration),
      reason: Value(reason),
      finishedAt: Value(finishedAt),
      bird: Value(bird),
      level: level == null && nullToAbsent
          ? const Value.absent()
          : Value(level),
    );
  }

  factory Run.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Run(
      id: serializer.fromJson<String>(json['id']),
      mode: serializer.fromJson<int>(json['mode']),
      course: serializer.fromJson<String>(json['course']),
      gates: serializer.fromJson<int>(json['gates']),
      stars: serializer.fromJson<int>(json['stars']),
      bestCombo: serializer.fromJson<int>(json['bestCombo']),
      perfectPasses: serializer.fromJson<int>(json['perfectPasses']),
      practice: serializer.fromJson<bool>(json['practice']),
      score: serializer.fromJson<int>(json['score']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      flaps: serializer.fromJson<int>(json['flaps']),
      duration: serializer.fromJson<double>(json['duration']),
      reason: serializer.fromJson<String>(json['reason']),
      finishedAt: serializer.fromJson<DateTime>(json['finishedAt']),
      bird: serializer.fromJson<int>(json['bird']),
      level: serializer.fromJson<String?>(json['level']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mode': serializer.toJson<int>(mode),
      'course': serializer.toJson<String>(course),
      'gates': serializer.toJson<int>(gates),
      'stars': serializer.toJson<int>(stars),
      'bestCombo': serializer.toJson<int>(bestCombo),
      'perfectPasses': serializer.toJson<int>(perfectPasses),
      'practice': serializer.toJson<bool>(practice),
      'score': serializer.toJson<int>(score),
      'repetitions': serializer.toJson<int>(repetitions),
      'flaps': serializer.toJson<int>(flaps),
      'duration': serializer.toJson<double>(duration),
      'reason': serializer.toJson<String>(reason),
      'finishedAt': serializer.toJson<DateTime>(finishedAt),
      'bird': serializer.toJson<int>(bird),
      'level': serializer.toJson<String?>(level),
    };
  }

  Run copyWith({
    String? id,
    int? mode,
    String? course,
    int? gates,
    int? stars,
    int? bestCombo,
    int? perfectPasses,
    bool? practice,
    int? score,
    int? repetitions,
    int? flaps,
    double? duration,
    String? reason,
    DateTime? finishedAt,
    int? bird,
    Value<String?> level = const Value.absent(),
  }) => Run(
    id: id ?? this.id,
    mode: mode ?? this.mode,
    course: course ?? this.course,
    gates: gates ?? this.gates,
    stars: stars ?? this.stars,
    bestCombo: bestCombo ?? this.bestCombo,
    perfectPasses: perfectPasses ?? this.perfectPasses,
    practice: practice ?? this.practice,
    score: score ?? this.score,
    repetitions: repetitions ?? this.repetitions,
    flaps: flaps ?? this.flaps,
    duration: duration ?? this.duration,
    reason: reason ?? this.reason,
    finishedAt: finishedAt ?? this.finishedAt,
    bird: bird ?? this.bird,
    level: level.present ? level.value : this.level,
  );
  Run copyWithCompanion(RunsCompanion data) {
    return Run(
      id: data.id.present ? data.id.value : this.id,
      mode: data.mode.present ? data.mode.value : this.mode,
      course: data.course.present ? data.course.value : this.course,
      gates: data.gates.present ? data.gates.value : this.gates,
      stars: data.stars.present ? data.stars.value : this.stars,
      bestCombo: data.bestCombo.present ? data.bestCombo.value : this.bestCombo,
      perfectPasses: data.perfectPasses.present
          ? data.perfectPasses.value
          : this.perfectPasses,
      practice: data.practice.present ? data.practice.value : this.practice,
      score: data.score.present ? data.score.value : this.score,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      flaps: data.flaps.present ? data.flaps.value : this.flaps,
      duration: data.duration.present ? data.duration.value : this.duration,
      reason: data.reason.present ? data.reason.value : this.reason,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      bird: data.bird.present ? data.bird.value : this.bird,
      level: data.level.present ? data.level.value : this.level,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Run(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('course: $course, ')
          ..write('gates: $gates, ')
          ..write('stars: $stars, ')
          ..write('bestCombo: $bestCombo, ')
          ..write('perfectPasses: $perfectPasses, ')
          ..write('practice: $practice, ')
          ..write('score: $score, ')
          ..write('repetitions: $repetitions, ')
          ..write('flaps: $flaps, ')
          ..write('duration: $duration, ')
          ..write('reason: $reason, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('bird: $bird, ')
          ..write('level: $level')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mode,
    course,
    gates,
    stars,
    bestCombo,
    perfectPasses,
    practice,
    score,
    repetitions,
    flaps,
    duration,
    reason,
    finishedAt,
    bird,
    level,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Run &&
          other.id == this.id &&
          other.mode == this.mode &&
          other.course == this.course &&
          other.gates == this.gates &&
          other.stars == this.stars &&
          other.bestCombo == this.bestCombo &&
          other.perfectPasses == this.perfectPasses &&
          other.practice == this.practice &&
          other.score == this.score &&
          other.repetitions == this.repetitions &&
          other.flaps == this.flaps &&
          other.duration == this.duration &&
          other.reason == this.reason &&
          other.finishedAt == this.finishedAt &&
          other.bird == this.bird &&
          other.level == this.level);
}

class RunsCompanion extends UpdateCompanion<Run> {
  final Value<String> id;
  final Value<int> mode;
  final Value<String> course;
  final Value<int> gates;
  final Value<int> stars;
  final Value<int> bestCombo;
  final Value<int> perfectPasses;
  final Value<bool> practice;
  final Value<int> score;
  final Value<int> repetitions;
  final Value<int> flaps;
  final Value<double> duration;
  final Value<String> reason;
  final Value<DateTime> finishedAt;
  final Value<int> bird;
  final Value<String?> level;
  final Value<int> rowid;
  const RunsCompanion({
    this.id = const Value.absent(),
    this.mode = const Value.absent(),
    this.course = const Value.absent(),
    this.gates = const Value.absent(),
    this.stars = const Value.absent(),
    this.bestCombo = const Value.absent(),
    this.perfectPasses = const Value.absent(),
    this.practice = const Value.absent(),
    this.score = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.flaps = const Value.absent(),
    this.duration = const Value.absent(),
    this.reason = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.bird = const Value.absent(),
    this.level = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RunsCompanion.insert({
    required String id,
    required int mode,
    this.course = const Value.absent(),
    this.gates = const Value.absent(),
    this.stars = const Value.absent(),
    this.bestCombo = const Value.absent(),
    this.perfectPasses = const Value.absent(),
    required bool practice,
    required int score,
    required int repetitions,
    required int flaps,
    required double duration,
    required String reason,
    required DateTime finishedAt,
    this.bird = const Value.absent(),
    this.level = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mode = Value(mode),
       practice = Value(practice),
       score = Value(score),
       repetitions = Value(repetitions),
       flaps = Value(flaps),
       duration = Value(duration),
       reason = Value(reason),
       finishedAt = Value(finishedAt);
  static Insertable<Run> custom({
    Expression<String>? id,
    Expression<int>? mode,
    Expression<String>? course,
    Expression<int>? gates,
    Expression<int>? stars,
    Expression<int>? bestCombo,
    Expression<int>? perfectPasses,
    Expression<bool>? practice,
    Expression<int>? score,
    Expression<int>? repetitions,
    Expression<int>? flaps,
    Expression<double>? duration,
    Expression<String>? reason,
    Expression<DateTime>? finishedAt,
    Expression<int>? bird,
    Expression<String>? level,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mode != null) 'mode': mode,
      if (course != null) 'course': course,
      if (gates != null) 'gates': gates,
      if (stars != null) 'stars': stars,
      if (bestCombo != null) 'best_combo': bestCombo,
      if (perfectPasses != null) 'perfect_passes': perfectPasses,
      if (practice != null) 'practice': practice,
      if (score != null) 'score': score,
      if (repetitions != null) 'repetitions': repetitions,
      if (flaps != null) 'flaps': flaps,
      if (duration != null) 'duration': duration,
      if (reason != null) 'reason': reason,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (bird != null) 'bird': bird,
      if (level != null) 'level': level,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RunsCompanion copyWith({
    Value<String>? id,
    Value<int>? mode,
    Value<String>? course,
    Value<int>? gates,
    Value<int>? stars,
    Value<int>? bestCombo,
    Value<int>? perfectPasses,
    Value<bool>? practice,
    Value<int>? score,
    Value<int>? repetitions,
    Value<int>? flaps,
    Value<double>? duration,
    Value<String>? reason,
    Value<DateTime>? finishedAt,
    Value<int>? bird,
    Value<String?>? level,
    Value<int>? rowid,
  }) {
    return RunsCompanion(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      course: course ?? this.course,
      gates: gates ?? this.gates,
      stars: stars ?? this.stars,
      bestCombo: bestCombo ?? this.bestCombo,
      perfectPasses: perfectPasses ?? this.perfectPasses,
      practice: practice ?? this.practice,
      score: score ?? this.score,
      repetitions: repetitions ?? this.repetitions,
      flaps: flaps ?? this.flaps,
      duration: duration ?? this.duration,
      reason: reason ?? this.reason,
      finishedAt: finishedAt ?? this.finishedAt,
      bird: bird ?? this.bird,
      level: level ?? this.level,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mode.present) {
      map['mode'] = Variable<int>(mode.value);
    }
    if (course.present) {
      map['course'] = Variable<String>(course.value);
    }
    if (gates.present) {
      map['gates'] = Variable<int>(gates.value);
    }
    if (stars.present) {
      map['stars'] = Variable<int>(stars.value);
    }
    if (bestCombo.present) {
      map['best_combo'] = Variable<int>(bestCombo.value);
    }
    if (perfectPasses.present) {
      map['perfect_passes'] = Variable<int>(perfectPasses.value);
    }
    if (practice.present) {
      map['practice'] = Variable<bool>(practice.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (flaps.present) {
      map['flaps'] = Variable<int>(flaps.value);
    }
    if (duration.present) {
      map['duration'] = Variable<double>(duration.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (bird.present) {
      map['bird'] = Variable<int>(bird.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunsCompanion(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('course: $course, ')
          ..write('gates: $gates, ')
          ..write('stars: $stars, ')
          ..write('bestCombo: $bestCombo, ')
          ..write('perfectPasses: $perfectPasses, ')
          ..write('practice: $practice, ')
          ..write('score: $score, ')
          ..write('repetitions: $repetitions, ')
          ..write('flaps: $flaps, ')
          ..write('duration: $duration, ')
          ..write('reason: $reason, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('bird: $bird, ')
          ..write('level: $level, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreferencesTable extends Preferences
    with TableInfo<$PreferencesTable, Preference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Preference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Preference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Preference(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $PreferencesTable createAlias(String alias) {
    return $PreferencesTable(attachedDatabase, alias);
  }
}

class Preference extends DataClass implements Insertable<Preference> {
  final String key;
  final String value;
  const Preference({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(key: Value(key), value: Value(value));
  }

  factory Preference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Preference(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Preference copyWith({String? key, String? value}) =>
      Preference(key: key ?? this.key, value: value ?? this.value);
  Preference copyWithCompanion(PreferencesCompanion data) {
    return Preference(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Preference(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Preference &&
          other.key == this.key &&
          other.value == this.value);
}

class PreferencesCompanion extends UpdateCompanion<Preference> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferencesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Preference> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PreferencesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LevelProgressTable extends LevelProgress
    with TableInfo<$LevelProgressTable, LevelProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LevelProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bestStarsMeta = const VerificationMeta(
    'bestStars',
  );
  @override
  late final GeneratedColumn<int> bestStars = GeneratedColumn<int>(
    'best_stars',
    aliasedName,
    false,
    check: () => ComparableExpr(bestStars).isBetweenValues(0, 3),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bestCollectedMeta = const VerificationMeta(
    'bestCollected',
  );
  @override
  late final GeneratedColumn<int> bestCollected = GeneratedColumn<int>(
    'best_collected',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bestScoreMeta = const VerificationMeta(
    'bestScore',
  );
  @override
  late final GeneratedColumn<int> bestScore = GeneratedColumn<int>(
    'best_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _playsMeta = const VerificationMeta('plays');
  @override
  late final GeneratedColumn<int> plays = GeneratedColumn<int>(
    'plays',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _firstClearedAtMeta = const VerificationMeta(
    'firstClearedAt',
  );
  @override
  late final GeneratedColumn<DateTime> firstClearedAt =
      GeneratedColumn<DateTime>(
        'first_cleared_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
    'last_played_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _postcardSeenMeta = const VerificationMeta(
    'postcardSeen',
  );
  @override
  late final GeneratedColumn<bool> postcardSeen = GeneratedColumn<bool>(
    'postcard_seen',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("postcard_seen" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    level,
    bestStars,
    bestCollected,
    bestScore,
    plays,
    firstClearedAt,
    lastPlayedAt,
    postcardSeen,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'level_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<LevelProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('best_stars')) {
      context.handle(
        _bestStarsMeta,
        bestStars.isAcceptableOrUnknown(data['best_stars']!, _bestStarsMeta),
      );
    }
    if (data.containsKey('best_collected')) {
      context.handle(
        _bestCollectedMeta,
        bestCollected.isAcceptableOrUnknown(
          data['best_collected']!,
          _bestCollectedMeta,
        ),
      );
    }
    if (data.containsKey('best_score')) {
      context.handle(
        _bestScoreMeta,
        bestScore.isAcceptableOrUnknown(data['best_score']!, _bestScoreMeta),
      );
    }
    if (data.containsKey('plays')) {
      context.handle(
        _playsMeta,
        plays.isAcceptableOrUnknown(data['plays']!, _playsMeta),
      );
    }
    if (data.containsKey('first_cleared_at')) {
      context.handle(
        _firstClearedAtMeta,
        firstClearedAt.isAcceptableOrUnknown(
          data['first_cleared_at']!,
          _firstClearedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    if (data.containsKey('postcard_seen')) {
      context.handle(
        _postcardSeenMeta,
        postcardSeen.isAcceptableOrUnknown(
          data['postcard_seen']!,
          _postcardSeenMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {level};
  @override
  LevelProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LevelProgressRow(
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      bestStars: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}best_stars'],
      )!,
      bestCollected: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}best_collected'],
      )!,
      bestScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}best_score'],
      )!,
      plays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plays'],
      )!,
      firstClearedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_cleared_at'],
      ),
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_at'],
      ),
      postcardSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}postcard_seen'],
      )!,
    );
  }

  @override
  $LevelProgressTable createAlias(String alias) {
    return $LevelProgressTable(attachedDatabase, alias);
  }
}

class LevelProgressRow extends DataClass
    implements Insertable<LevelProgressRow> {
  final String level;
  final int bestStars;
  final int bestCollected;
  final int bestScore;
  final int plays;
  final DateTime? firstClearedAt;
  final DateTime? lastPlayedAt;
  final bool postcardSeen;
  const LevelProgressRow({
    required this.level,
    required this.bestStars,
    required this.bestCollected,
    required this.bestScore,
    required this.plays,
    this.firstClearedAt,
    this.lastPlayedAt,
    required this.postcardSeen,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['level'] = Variable<String>(level);
    map['best_stars'] = Variable<int>(bestStars);
    map['best_collected'] = Variable<int>(bestCollected);
    map['best_score'] = Variable<int>(bestScore);
    map['plays'] = Variable<int>(plays);
    if (!nullToAbsent || firstClearedAt != null) {
      map['first_cleared_at'] = Variable<DateTime>(firstClearedAt);
    }
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    map['postcard_seen'] = Variable<bool>(postcardSeen);
    return map;
  }

  LevelProgressCompanion toCompanion(bool nullToAbsent) {
    return LevelProgressCompanion(
      level: Value(level),
      bestStars: Value(bestStars),
      bestCollected: Value(bestCollected),
      bestScore: Value(bestScore),
      plays: Value(plays),
      firstClearedAt: firstClearedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(firstClearedAt),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
      postcardSeen: Value(postcardSeen),
    );
  }

  factory LevelProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LevelProgressRow(
      level: serializer.fromJson<String>(json['level']),
      bestStars: serializer.fromJson<int>(json['bestStars']),
      bestCollected: serializer.fromJson<int>(json['bestCollected']),
      bestScore: serializer.fromJson<int>(json['bestScore']),
      plays: serializer.fromJson<int>(json['plays']),
      firstClearedAt: serializer.fromJson<DateTime?>(json['firstClearedAt']),
      lastPlayedAt: serializer.fromJson<DateTime?>(json['lastPlayedAt']),
      postcardSeen: serializer.fromJson<bool>(json['postcardSeen']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'level': serializer.toJson<String>(level),
      'bestStars': serializer.toJson<int>(bestStars),
      'bestCollected': serializer.toJson<int>(bestCollected),
      'bestScore': serializer.toJson<int>(bestScore),
      'plays': serializer.toJson<int>(plays),
      'firstClearedAt': serializer.toJson<DateTime?>(firstClearedAt),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
      'postcardSeen': serializer.toJson<bool>(postcardSeen),
    };
  }

  LevelProgressRow copyWith({
    String? level,
    int? bestStars,
    int? bestCollected,
    int? bestScore,
    int? plays,
    Value<DateTime?> firstClearedAt = const Value.absent(),
    Value<DateTime?> lastPlayedAt = const Value.absent(),
    bool? postcardSeen,
  }) => LevelProgressRow(
    level: level ?? this.level,
    bestStars: bestStars ?? this.bestStars,
    bestCollected: bestCollected ?? this.bestCollected,
    bestScore: bestScore ?? this.bestScore,
    plays: plays ?? this.plays,
    firstClearedAt: firstClearedAt.present
        ? firstClearedAt.value
        : this.firstClearedAt,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
    postcardSeen: postcardSeen ?? this.postcardSeen,
  );
  LevelProgressRow copyWithCompanion(LevelProgressCompanion data) {
    return LevelProgressRow(
      level: data.level.present ? data.level.value : this.level,
      bestStars: data.bestStars.present ? data.bestStars.value : this.bestStars,
      bestCollected: data.bestCollected.present
          ? data.bestCollected.value
          : this.bestCollected,
      bestScore: data.bestScore.present ? data.bestScore.value : this.bestScore,
      plays: data.plays.present ? data.plays.value : this.plays,
      firstClearedAt: data.firstClearedAt.present
          ? data.firstClearedAt.value
          : this.firstClearedAt,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      postcardSeen: data.postcardSeen.present
          ? data.postcardSeen.value
          : this.postcardSeen,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LevelProgressRow(')
          ..write('level: $level, ')
          ..write('bestStars: $bestStars, ')
          ..write('bestCollected: $bestCollected, ')
          ..write('bestScore: $bestScore, ')
          ..write('plays: $plays, ')
          ..write('firstClearedAt: $firstClearedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('postcardSeen: $postcardSeen')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    level,
    bestStars,
    bestCollected,
    bestScore,
    plays,
    firstClearedAt,
    lastPlayedAt,
    postcardSeen,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LevelProgressRow &&
          other.level == this.level &&
          other.bestStars == this.bestStars &&
          other.bestCollected == this.bestCollected &&
          other.bestScore == this.bestScore &&
          other.plays == this.plays &&
          other.firstClearedAt == this.firstClearedAt &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.postcardSeen == this.postcardSeen);
}

class LevelProgressCompanion extends UpdateCompanion<LevelProgressRow> {
  final Value<String> level;
  final Value<int> bestStars;
  final Value<int> bestCollected;
  final Value<int> bestScore;
  final Value<int> plays;
  final Value<DateTime?> firstClearedAt;
  final Value<DateTime?> lastPlayedAt;
  final Value<bool> postcardSeen;
  final Value<int> rowid;
  const LevelProgressCompanion({
    this.level = const Value.absent(),
    this.bestStars = const Value.absent(),
    this.bestCollected = const Value.absent(),
    this.bestScore = const Value.absent(),
    this.plays = const Value.absent(),
    this.firstClearedAt = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.postcardSeen = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LevelProgressCompanion.insert({
    required String level,
    this.bestStars = const Value.absent(),
    this.bestCollected = const Value.absent(),
    this.bestScore = const Value.absent(),
    this.plays = const Value.absent(),
    this.firstClearedAt = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.postcardSeen = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : level = Value(level);
  static Insertable<LevelProgressRow> custom({
    Expression<String>? level,
    Expression<int>? bestStars,
    Expression<int>? bestCollected,
    Expression<int>? bestScore,
    Expression<int>? plays,
    Expression<DateTime>? firstClearedAt,
    Expression<DateTime>? lastPlayedAt,
    Expression<bool>? postcardSeen,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (level != null) 'level': level,
      if (bestStars != null) 'best_stars': bestStars,
      if (bestCollected != null) 'best_collected': bestCollected,
      if (bestScore != null) 'best_score': bestScore,
      if (plays != null) 'plays': plays,
      if (firstClearedAt != null) 'first_cleared_at': firstClearedAt,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (postcardSeen != null) 'postcard_seen': postcardSeen,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LevelProgressCompanion copyWith({
    Value<String>? level,
    Value<int>? bestStars,
    Value<int>? bestCollected,
    Value<int>? bestScore,
    Value<int>? plays,
    Value<DateTime?>? firstClearedAt,
    Value<DateTime?>? lastPlayedAt,
    Value<bool>? postcardSeen,
    Value<int>? rowid,
  }) {
    return LevelProgressCompanion(
      level: level ?? this.level,
      bestStars: bestStars ?? this.bestStars,
      bestCollected: bestCollected ?? this.bestCollected,
      bestScore: bestScore ?? this.bestScore,
      plays: plays ?? this.plays,
      firstClearedAt: firstClearedAt ?? this.firstClearedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      postcardSeen: postcardSeen ?? this.postcardSeen,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (bestStars.present) {
      map['best_stars'] = Variable<int>(bestStars.value);
    }
    if (bestCollected.present) {
      map['best_collected'] = Variable<int>(bestCollected.value);
    }
    if (bestScore.present) {
      map['best_score'] = Variable<int>(bestScore.value);
    }
    if (plays.present) {
      map['plays'] = Variable<int>(plays.value);
    }
    if (firstClearedAt.present) {
      map['first_cleared_at'] = Variable<DateTime>(firstClearedAt.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    if (postcardSeen.present) {
      map['postcard_seen'] = Variable<bool>(postcardSeen.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LevelProgressCompanion(')
          ..write('level: $level, ')
          ..write('bestStars: $bestStars, ')
          ..write('bestCollected: $bestCollected, ')
          ..write('bestScore: $bestScore, ')
          ..write('plays: $plays, ')
          ..write('firstClearedAt: $firstClearedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('postcardSeen: $postcardSeen, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BuiltLevelsTable extends BuiltLevels
    with TableInfo<$BuiltLevelsTable, BuiltLevelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BuiltLevelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<int> mode = GeneratedColumn<int>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('created'),
  );
  static const VerificationMeta _remixOfMeta = const VerificationMeta(
    'remixOf',
  );
  @override
  late final GeneratedColumn<String> remixOf = GeneratedColumn<String>(
    'remix_of',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clearedRevisionMeta = const VerificationMeta(
    'clearedRevision',
  );
  @override
  late final GeneratedColumn<int> clearedRevision = GeneratedColumn<int>(
    'cleared_revision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _importedClearedMeta = const VerificationMeta(
    'importedCleared',
  );
  @override
  late final GeneratedColumn<bool> importedCleared = GeneratedColumn<bool>(
    'imported_cleared',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("imported_cleared" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    mode,
    json,
    fingerprint,
    revision,
    origin,
    remixOf,
    clearedRevision,
    importedCleared,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'built_levels';
  @override
  VerificationContext validateIntegrity(
    Insertable<BuiltLevelRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('remix_of')) {
      context.handle(
        _remixOfMeta,
        remixOf.isAcceptableOrUnknown(data['remix_of']!, _remixOfMeta),
      );
    }
    if (data.containsKey('cleared_revision')) {
      context.handle(
        _clearedRevisionMeta,
        clearedRevision.isAcceptableOrUnknown(
          data['cleared_revision']!,
          _clearedRevisionMeta,
        ),
      );
    }
    if (data.containsKey('imported_cleared')) {
      context.handle(
        _importedClearedMeta,
        importedCleared.isAcceptableOrUnknown(
          data['imported_cleared']!,
          _importedClearedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BuiltLevelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BuiltLevelRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mode'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      remixOf: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remix_of'],
      ),
      clearedRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cleared_revision'],
      ),
      importedCleared: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}imported_cleared'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BuiltLevelsTable createAlias(String alias) {
    return $BuiltLevelsTable(attachedDatabase, alias);
  }
}

class BuiltLevelRow extends DataClass implements Insertable<BuiltLevelRow> {
  final String id;
  final String name;
  final int mode;
  final String json;
  final String fingerprint;
  final int revision;

  /// 'created', 'remixed' or 'imported' ([BuiltOrigin]).
  final String origin;

  /// The template a remix was made from.
  final String? remixOf;
  final int? clearedRevision;
  final bool importedCleared;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BuiltLevelRow({
    required this.id,
    required this.name,
    required this.mode,
    required this.json,
    required this.fingerprint,
    required this.revision,
    required this.origin,
    this.remixOf,
    this.clearedRevision,
    required this.importedCleared,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['mode'] = Variable<int>(mode);
    map['json'] = Variable<String>(json);
    map['fingerprint'] = Variable<String>(fingerprint);
    map['revision'] = Variable<int>(revision);
    map['origin'] = Variable<String>(origin);
    if (!nullToAbsent || remixOf != null) {
      map['remix_of'] = Variable<String>(remixOf);
    }
    if (!nullToAbsent || clearedRevision != null) {
      map['cleared_revision'] = Variable<int>(clearedRevision);
    }
    map['imported_cleared'] = Variable<bool>(importedCleared);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BuiltLevelsCompanion toCompanion(bool nullToAbsent) {
    return BuiltLevelsCompanion(
      id: Value(id),
      name: Value(name),
      mode: Value(mode),
      json: Value(json),
      fingerprint: Value(fingerprint),
      revision: Value(revision),
      origin: Value(origin),
      remixOf: remixOf == null && nullToAbsent
          ? const Value.absent()
          : Value(remixOf),
      clearedRevision: clearedRevision == null && nullToAbsent
          ? const Value.absent()
          : Value(clearedRevision),
      importedCleared: Value(importedCleared),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BuiltLevelRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BuiltLevelRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      mode: serializer.fromJson<int>(json['mode']),
      json: serializer.fromJson<String>(json['json']),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      revision: serializer.fromJson<int>(json['revision']),
      origin: serializer.fromJson<String>(json['origin']),
      remixOf: serializer.fromJson<String?>(json['remixOf']),
      clearedRevision: serializer.fromJson<int?>(json['clearedRevision']),
      importedCleared: serializer.fromJson<bool>(json['importedCleared']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'mode': serializer.toJson<int>(mode),
      'json': serializer.toJson<String>(json),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'revision': serializer.toJson<int>(revision),
      'origin': serializer.toJson<String>(origin),
      'remixOf': serializer.toJson<String?>(remixOf),
      'clearedRevision': serializer.toJson<int?>(clearedRevision),
      'importedCleared': serializer.toJson<bool>(importedCleared),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BuiltLevelRow copyWith({
    String? id,
    String? name,
    int? mode,
    String? json,
    String? fingerprint,
    int? revision,
    String? origin,
    Value<String?> remixOf = const Value.absent(),
    Value<int?> clearedRevision = const Value.absent(),
    bool? importedCleared,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BuiltLevelRow(
    id: id ?? this.id,
    name: name ?? this.name,
    mode: mode ?? this.mode,
    json: json ?? this.json,
    fingerprint: fingerprint ?? this.fingerprint,
    revision: revision ?? this.revision,
    origin: origin ?? this.origin,
    remixOf: remixOf.present ? remixOf.value : this.remixOf,
    clearedRevision: clearedRevision.present
        ? clearedRevision.value
        : this.clearedRevision,
    importedCleared: importedCleared ?? this.importedCleared,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BuiltLevelRow copyWithCompanion(BuiltLevelsCompanion data) {
    return BuiltLevelRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      mode: data.mode.present ? data.mode.value : this.mode,
      json: data.json.present ? data.json.value : this.json,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      revision: data.revision.present ? data.revision.value : this.revision,
      origin: data.origin.present ? data.origin.value : this.origin,
      remixOf: data.remixOf.present ? data.remixOf.value : this.remixOf,
      clearedRevision: data.clearedRevision.present
          ? data.clearedRevision.value
          : this.clearedRevision,
      importedCleared: data.importedCleared.present
          ? data.importedCleared.value
          : this.importedCleared,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BuiltLevelRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mode: $mode, ')
          ..write('json: $json, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('revision: $revision, ')
          ..write('origin: $origin, ')
          ..write('remixOf: $remixOf, ')
          ..write('clearedRevision: $clearedRevision, ')
          ..write('importedCleared: $importedCleared, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    mode,
    json,
    fingerprint,
    revision,
    origin,
    remixOf,
    clearedRevision,
    importedCleared,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BuiltLevelRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.mode == this.mode &&
          other.json == this.json &&
          other.fingerprint == this.fingerprint &&
          other.revision == this.revision &&
          other.origin == this.origin &&
          other.remixOf == this.remixOf &&
          other.clearedRevision == this.clearedRevision &&
          other.importedCleared == this.importedCleared &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BuiltLevelsCompanion extends UpdateCompanion<BuiltLevelRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> mode;
  final Value<String> json;
  final Value<String> fingerprint;
  final Value<int> revision;
  final Value<String> origin;
  final Value<String?> remixOf;
  final Value<int?> clearedRevision;
  final Value<bool> importedCleared;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BuiltLevelsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.mode = const Value.absent(),
    this.json = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.revision = const Value.absent(),
    this.origin = const Value.absent(),
    this.remixOf = const Value.absent(),
    this.clearedRevision = const Value.absent(),
    this.importedCleared = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BuiltLevelsCompanion.insert({
    required String id,
    required String name,
    required int mode,
    required String json,
    required String fingerprint,
    this.revision = const Value.absent(),
    this.origin = const Value.absent(),
    this.remixOf = const Value.absent(),
    this.clearedRevision = const Value.absent(),
    this.importedCleared = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       mode = Value(mode),
       json = Value(json),
       fingerprint = Value(fingerprint),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BuiltLevelRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? mode,
    Expression<String>? json,
    Expression<String>? fingerprint,
    Expression<int>? revision,
    Expression<String>? origin,
    Expression<String>? remixOf,
    Expression<int>? clearedRevision,
    Expression<bool>? importedCleared,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (mode != null) 'mode': mode,
      if (json != null) 'json': json,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (revision != null) 'revision': revision,
      if (origin != null) 'origin': origin,
      if (remixOf != null) 'remix_of': remixOf,
      if (clearedRevision != null) 'cleared_revision': clearedRevision,
      if (importedCleared != null) 'imported_cleared': importedCleared,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BuiltLevelsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? mode,
    Value<String>? json,
    Value<String>? fingerprint,
    Value<int>? revision,
    Value<String>? origin,
    Value<String?>? remixOf,
    Value<int?>? clearedRevision,
    Value<bool>? importedCleared,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BuiltLevelsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      json: json ?? this.json,
      fingerprint: fingerprint ?? this.fingerprint,
      revision: revision ?? this.revision,
      origin: origin ?? this.origin,
      remixOf: remixOf ?? this.remixOf,
      clearedRevision: clearedRevision ?? this.clearedRevision,
      importedCleared: importedCleared ?? this.importedCleared,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (mode.present) {
      map['mode'] = Variable<int>(mode.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (remixOf.present) {
      map['remix_of'] = Variable<String>(remixOf.value);
    }
    if (clearedRevision.present) {
      map['cleared_revision'] = Variable<int>(clearedRevision.value);
    }
    if (importedCleared.present) {
      map['imported_cleared'] = Variable<bool>(importedCleared.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BuiltLevelsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mode: $mode, ')
          ..write('json: $json, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('revision: $revision, ')
          ..write('origin: $origin, ')
          ..write('remixOf: $remixOf, ')
          ..write('clearedRevision: $clearedRevision, ')
          ..write('importedCleared: $importedCleared, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BuiltFlightsTable extends BuiltFlights
    with TableInfo<$BuiltFlightsTable, BuiltFlightRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BuiltFlightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<int> mode = GeneratedColumn<int>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    check: () => ComparableExpr(rating).isBetweenValues(0, 3),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _starsMeta = const VerificationMeta('stars');
  @override
  late final GeneratedColumn<int> stars = GeneratedColumn<int>(
    'stars',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _flapsMeta = const VerificationMeta('flaps');
  @override
  late final GeneratedColumn<int> flaps = GeneratedColumn<int>(
    'flaps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<double> duration = GeneratedColumn<double>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    level,
    revision,
    mode,
    rating,
    stars,
    score,
    repetitions,
    flaps,
    duration,
    reason,
    finishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'built_flights';
  @override
  VerificationContext validateIntegrity(
    Insertable<BuiltFlightRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('stars')) {
      context.handle(
        _starsMeta,
        stars.isAcceptableOrUnknown(data['stars']!, _starsMeta),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    }
    if (data.containsKey('flaps')) {
      context.handle(
        _flapsMeta,
        flaps.isAcceptableOrUnknown(data['flaps']!, _flapsMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_finishedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BuiltFlightRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BuiltFlightRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mode'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      stars: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stars'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      flaps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}flaps'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}duration'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      )!,
    );
  }

  @override
  $BuiltFlightsTable createAlias(String alias) {
    return $BuiltFlightsTable(attachedDatabase, alias);
  }
}

class BuiltFlightRow extends DataClass implements Insertable<BuiltFlightRow> {
  final String id;
  final String level;
  final int revision;
  final int mode;
  final int rating;
  final int stars;
  final int score;
  final int repetitions;
  final int flaps;
  final double duration;
  final String reason;
  final DateTime finishedAt;
  const BuiltFlightRow({
    required this.id,
    required this.level,
    required this.revision,
    required this.mode,
    required this.rating,
    required this.stars,
    required this.score,
    required this.repetitions,
    required this.flaps,
    required this.duration,
    required this.reason,
    required this.finishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['level'] = Variable<String>(level);
    map['revision'] = Variable<int>(revision);
    map['mode'] = Variable<int>(mode);
    map['rating'] = Variable<int>(rating);
    map['stars'] = Variable<int>(stars);
    map['score'] = Variable<int>(score);
    map['repetitions'] = Variable<int>(repetitions);
    map['flaps'] = Variable<int>(flaps);
    map['duration'] = Variable<double>(duration);
    map['reason'] = Variable<String>(reason);
    map['finished_at'] = Variable<DateTime>(finishedAt);
    return map;
  }

  BuiltFlightsCompanion toCompanion(bool nullToAbsent) {
    return BuiltFlightsCompanion(
      id: Value(id),
      level: Value(level),
      revision: Value(revision),
      mode: Value(mode),
      rating: Value(rating),
      stars: Value(stars),
      score: Value(score),
      repetitions: Value(repetitions),
      flaps: Value(flaps),
      duration: Value(duration),
      reason: Value(reason),
      finishedAt: Value(finishedAt),
    );
  }

  factory BuiltFlightRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BuiltFlightRow(
      id: serializer.fromJson<String>(json['id']),
      level: serializer.fromJson<String>(json['level']),
      revision: serializer.fromJson<int>(json['revision']),
      mode: serializer.fromJson<int>(json['mode']),
      rating: serializer.fromJson<int>(json['rating']),
      stars: serializer.fromJson<int>(json['stars']),
      score: serializer.fromJson<int>(json['score']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      flaps: serializer.fromJson<int>(json['flaps']),
      duration: serializer.fromJson<double>(json['duration']),
      reason: serializer.fromJson<String>(json['reason']),
      finishedAt: serializer.fromJson<DateTime>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'level': serializer.toJson<String>(level),
      'revision': serializer.toJson<int>(revision),
      'mode': serializer.toJson<int>(mode),
      'rating': serializer.toJson<int>(rating),
      'stars': serializer.toJson<int>(stars),
      'score': serializer.toJson<int>(score),
      'repetitions': serializer.toJson<int>(repetitions),
      'flaps': serializer.toJson<int>(flaps),
      'duration': serializer.toJson<double>(duration),
      'reason': serializer.toJson<String>(reason),
      'finishedAt': serializer.toJson<DateTime>(finishedAt),
    };
  }

  BuiltFlightRow copyWith({
    String? id,
    String? level,
    int? revision,
    int? mode,
    int? rating,
    int? stars,
    int? score,
    int? repetitions,
    int? flaps,
    double? duration,
    String? reason,
    DateTime? finishedAt,
  }) => BuiltFlightRow(
    id: id ?? this.id,
    level: level ?? this.level,
    revision: revision ?? this.revision,
    mode: mode ?? this.mode,
    rating: rating ?? this.rating,
    stars: stars ?? this.stars,
    score: score ?? this.score,
    repetitions: repetitions ?? this.repetitions,
    flaps: flaps ?? this.flaps,
    duration: duration ?? this.duration,
    reason: reason ?? this.reason,
    finishedAt: finishedAt ?? this.finishedAt,
  );
  BuiltFlightRow copyWithCompanion(BuiltFlightsCompanion data) {
    return BuiltFlightRow(
      id: data.id.present ? data.id.value : this.id,
      level: data.level.present ? data.level.value : this.level,
      revision: data.revision.present ? data.revision.value : this.revision,
      mode: data.mode.present ? data.mode.value : this.mode,
      rating: data.rating.present ? data.rating.value : this.rating,
      stars: data.stars.present ? data.stars.value : this.stars,
      score: data.score.present ? data.score.value : this.score,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      flaps: data.flaps.present ? data.flaps.value : this.flaps,
      duration: data.duration.present ? data.duration.value : this.duration,
      reason: data.reason.present ? data.reason.value : this.reason,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BuiltFlightRow(')
          ..write('id: $id, ')
          ..write('level: $level, ')
          ..write('revision: $revision, ')
          ..write('mode: $mode, ')
          ..write('rating: $rating, ')
          ..write('stars: $stars, ')
          ..write('score: $score, ')
          ..write('repetitions: $repetitions, ')
          ..write('flaps: $flaps, ')
          ..write('duration: $duration, ')
          ..write('reason: $reason, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    level,
    revision,
    mode,
    rating,
    stars,
    score,
    repetitions,
    flaps,
    duration,
    reason,
    finishedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BuiltFlightRow &&
          other.id == this.id &&
          other.level == this.level &&
          other.revision == this.revision &&
          other.mode == this.mode &&
          other.rating == this.rating &&
          other.stars == this.stars &&
          other.score == this.score &&
          other.repetitions == this.repetitions &&
          other.flaps == this.flaps &&
          other.duration == this.duration &&
          other.reason == this.reason &&
          other.finishedAt == this.finishedAt);
}

class BuiltFlightsCompanion extends UpdateCompanion<BuiltFlightRow> {
  final Value<String> id;
  final Value<String> level;
  final Value<int> revision;
  final Value<int> mode;
  final Value<int> rating;
  final Value<int> stars;
  final Value<int> score;
  final Value<int> repetitions;
  final Value<int> flaps;
  final Value<double> duration;
  final Value<String> reason;
  final Value<DateTime> finishedAt;
  final Value<int> rowid;
  const BuiltFlightsCompanion({
    this.id = const Value.absent(),
    this.level = const Value.absent(),
    this.revision = const Value.absent(),
    this.mode = const Value.absent(),
    this.rating = const Value.absent(),
    this.stars = const Value.absent(),
    this.score = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.flaps = const Value.absent(),
    this.duration = const Value.absent(),
    this.reason = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BuiltFlightsCompanion.insert({
    required String id,
    required String level,
    required int revision,
    required int mode,
    this.rating = const Value.absent(),
    this.stars = const Value.absent(),
    this.score = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.flaps = const Value.absent(),
    required double duration,
    required String reason,
    required DateTime finishedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       level = Value(level),
       revision = Value(revision),
       mode = Value(mode),
       duration = Value(duration),
       reason = Value(reason),
       finishedAt = Value(finishedAt);
  static Insertable<BuiltFlightRow> custom({
    Expression<String>? id,
    Expression<String>? level,
    Expression<int>? revision,
    Expression<int>? mode,
    Expression<int>? rating,
    Expression<int>? stars,
    Expression<int>? score,
    Expression<int>? repetitions,
    Expression<int>? flaps,
    Expression<double>? duration,
    Expression<String>? reason,
    Expression<DateTime>? finishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (level != null) 'level': level,
      if (revision != null) 'revision': revision,
      if (mode != null) 'mode': mode,
      if (rating != null) 'rating': rating,
      if (stars != null) 'stars': stars,
      if (score != null) 'score': score,
      if (repetitions != null) 'repetitions': repetitions,
      if (flaps != null) 'flaps': flaps,
      if (duration != null) 'duration': duration,
      if (reason != null) 'reason': reason,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BuiltFlightsCompanion copyWith({
    Value<String>? id,
    Value<String>? level,
    Value<int>? revision,
    Value<int>? mode,
    Value<int>? rating,
    Value<int>? stars,
    Value<int>? score,
    Value<int>? repetitions,
    Value<int>? flaps,
    Value<double>? duration,
    Value<String>? reason,
    Value<DateTime>? finishedAt,
    Value<int>? rowid,
  }) {
    return BuiltFlightsCompanion(
      id: id ?? this.id,
      level: level ?? this.level,
      revision: revision ?? this.revision,
      mode: mode ?? this.mode,
      rating: rating ?? this.rating,
      stars: stars ?? this.stars,
      score: score ?? this.score,
      repetitions: repetitions ?? this.repetitions,
      flaps: flaps ?? this.flaps,
      duration: duration ?? this.duration,
      reason: reason ?? this.reason,
      finishedAt: finishedAt ?? this.finishedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (mode.present) {
      map['mode'] = Variable<int>(mode.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (stars.present) {
      map['stars'] = Variable<int>(stars.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (flaps.present) {
      map['flaps'] = Variable<int>(flaps.value);
    }
    if (duration.present) {
      map['duration'] = Variable<double>(duration.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BuiltFlightsCompanion(')
          ..write('id: $id, ')
          ..write('level: $level, ')
          ..write('revision: $revision, ')
          ..write('mode: $mode, ')
          ..write('rating: $rating, ')
          ..write('stars: $stars, ')
          ..write('score: $score, ')
          ..write('repetitions: $repetitions, ')
          ..write('flaps: $flaps, ')
          ..write('duration: $duration, ')
          ..write('reason: $reason, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ProgressDatabase extends GeneratedDatabase {
  _$ProgressDatabase(QueryExecutor e) : super(e);
  $ProgressDatabaseManager get managers => $ProgressDatabaseManager(this);
  late final $RunsTable runs = $RunsTable(this);
  late final $PreferencesTable preferences = $PreferencesTable(this);
  late final $LevelProgressTable levelProgress = $LevelProgressTable(this);
  late final $BuiltLevelsTable builtLevels = $BuiltLevelsTable(this);
  late final $BuiltFlightsTable builtFlights = $BuiltFlightsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    runs,
    preferences,
    levelProgress,
    builtLevels,
    builtFlights,
  ];
}

typedef $$RunsTableCreateCompanionBuilder =
    RunsCompanion Function({
      required String id,
      required int mode,
      Value<String> course,
      Value<int> gates,
      Value<int> stars,
      Value<int> bestCombo,
      Value<int> perfectPasses,
      required bool practice,
      required int score,
      required int repetitions,
      required int flaps,
      required double duration,
      required String reason,
      required DateTime finishedAt,
      Value<int> bird,
      Value<String?> level,
      Value<int> rowid,
    });
typedef $$RunsTableUpdateCompanionBuilder =
    RunsCompanion Function({
      Value<String> id,
      Value<int> mode,
      Value<String> course,
      Value<int> gates,
      Value<int> stars,
      Value<int> bestCombo,
      Value<int> perfectPasses,
      Value<bool> practice,
      Value<int> score,
      Value<int> repetitions,
      Value<int> flaps,
      Value<double> duration,
      Value<String> reason,
      Value<DateTime> finishedAt,
      Value<int> bird,
      Value<String?> level,
      Value<int> rowid,
    });

class $$RunsTableFilterComposer
    extends Composer<_$ProgressDatabase, $RunsTable> {
  $$RunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get course => $composableBuilder(
    column: $table.course,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gates => $composableBuilder(
    column: $table.gates,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bestCombo => $composableBuilder(
    column: $table.bestCombo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get perfectPasses => $composableBuilder(
    column: $table.perfectPasses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get practice => $composableBuilder(
    column: $table.practice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get flaps => $composableBuilder(
    column: $table.flaps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bird => $composableBuilder(
    column: $table.bird,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RunsTableOrderingComposer
    extends Composer<_$ProgressDatabase, $RunsTable> {
  $$RunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get course => $composableBuilder(
    column: $table.course,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gates => $composableBuilder(
    column: $table.gates,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bestCombo => $composableBuilder(
    column: $table.bestCombo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get perfectPasses => $composableBuilder(
    column: $table.perfectPasses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get practice => $composableBuilder(
    column: $table.practice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get flaps => $composableBuilder(
    column: $table.flaps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bird => $composableBuilder(
    column: $table.bird,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RunsTableAnnotationComposer
    extends Composer<_$ProgressDatabase, $RunsTable> {
  $$RunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get course =>
      $composableBuilder(column: $table.course, builder: (column) => column);

  GeneratedColumn<int> get gates =>
      $composableBuilder(column: $table.gates, builder: (column) => column);

  GeneratedColumn<int> get stars =>
      $composableBuilder(column: $table.stars, builder: (column) => column);

  GeneratedColumn<int> get bestCombo =>
      $composableBuilder(column: $table.bestCombo, builder: (column) => column);

  GeneratedColumn<int> get perfectPasses => $composableBuilder(
    column: $table.perfectPasses,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get practice =>
      $composableBuilder(column: $table.practice, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get flaps =>
      $composableBuilder(column: $table.flaps, builder: (column) => column);

  GeneratedColumn<double> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bird =>
      $composableBuilder(column: $table.bird, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);
}

class $$RunsTableTableManager
    extends
        RootTableManager<
          _$ProgressDatabase,
          $RunsTable,
          Run,
          $$RunsTableFilterComposer,
          $$RunsTableOrderingComposer,
          $$RunsTableAnnotationComposer,
          $$RunsTableCreateCompanionBuilder,
          $$RunsTableUpdateCompanionBuilder,
          (Run, BaseReferences<_$ProgressDatabase, $RunsTable, Run>),
          Run,
          PrefetchHooks Function()
        > {
  $$RunsTableTableManager(_$ProgressDatabase db, $RunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> mode = const Value.absent(),
                Value<String> course = const Value.absent(),
                Value<int> gates = const Value.absent(),
                Value<int> stars = const Value.absent(),
                Value<int> bestCombo = const Value.absent(),
                Value<int> perfectPasses = const Value.absent(),
                Value<bool> practice = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<int> flaps = const Value.absent(),
                Value<double> duration = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<DateTime> finishedAt = const Value.absent(),
                Value<int> bird = const Value.absent(),
                Value<String?> level = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RunsCompanion(
                id: id,
                mode: mode,
                course: course,
                gates: gates,
                stars: stars,
                bestCombo: bestCombo,
                perfectPasses: perfectPasses,
                practice: practice,
                score: score,
                repetitions: repetitions,
                flaps: flaps,
                duration: duration,
                reason: reason,
                finishedAt: finishedAt,
                bird: bird,
                level: level,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int mode,
                Value<String> course = const Value.absent(),
                Value<int> gates = const Value.absent(),
                Value<int> stars = const Value.absent(),
                Value<int> bestCombo = const Value.absent(),
                Value<int> perfectPasses = const Value.absent(),
                required bool practice,
                required int score,
                required int repetitions,
                required int flaps,
                required double duration,
                required String reason,
                required DateTime finishedAt,
                Value<int> bird = const Value.absent(),
                Value<String?> level = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RunsCompanion.insert(
                id: id,
                mode: mode,
                course: course,
                gates: gates,
                stars: stars,
                bestCombo: bestCombo,
                perfectPasses: perfectPasses,
                practice: practice,
                score: score,
                repetitions: repetitions,
                flaps: flaps,
                duration: duration,
                reason: reason,
                finishedAt: finishedAt,
                bird: bird,
                level: level,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RunsTable, Run>(table),
                  BaseReferences<_$ProgressDatabase, $RunsTable, Run>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RunsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProgressDatabase,
      $RunsTable,
      Run,
      $$RunsTableFilterComposer,
      $$RunsTableOrderingComposer,
      $$RunsTableAnnotationComposer,
      $$RunsTableCreateCompanionBuilder,
      $$RunsTableUpdateCompanionBuilder,
      (Run, BaseReferences<_$ProgressDatabase, $RunsTable, Run>),
      Run,
      PrefetchHooks Function()
    >;
typedef $$PreferencesTableCreateCompanionBuilder =
    PreferencesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$PreferencesTableUpdateCompanionBuilder =
    PreferencesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$PreferencesTableFilterComposer
    extends Composer<_$ProgressDatabase, $PreferencesTable> {
  $$PreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferencesTableOrderingComposer
    extends Composer<_$ProgressDatabase, $PreferencesTable> {
  $$PreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferencesTableAnnotationComposer
    extends Composer<_$ProgressDatabase, $PreferencesTable> {
  $$PreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PreferencesTableTableManager
    extends
        RootTableManager<
          _$ProgressDatabase,
          $PreferencesTable,
          Preference,
          $$PreferencesTableFilterComposer,
          $$PreferencesTableOrderingComposer,
          $$PreferencesTableAnnotationComposer,
          $$PreferencesTableCreateCompanionBuilder,
          $$PreferencesTableUpdateCompanionBuilder,
          (
            Preference,
            BaseReferences<_$ProgressDatabase, $PreferencesTable, Preference>,
          ),
          Preference,
          PrefetchHooks Function()
        > {
  $$PreferencesTableTableManager(_$ProgressDatabase db, $PreferencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PreferencesTable, Preference>(table),
                  BaseReferences<
                    _$ProgressDatabase,
                    $PreferencesTable,
                    Preference
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProgressDatabase,
      $PreferencesTable,
      Preference,
      $$PreferencesTableFilterComposer,
      $$PreferencesTableOrderingComposer,
      $$PreferencesTableAnnotationComposer,
      $$PreferencesTableCreateCompanionBuilder,
      $$PreferencesTableUpdateCompanionBuilder,
      (
        Preference,
        BaseReferences<_$ProgressDatabase, $PreferencesTable, Preference>,
      ),
      Preference,
      PrefetchHooks Function()
    >;
typedef $$LevelProgressTableCreateCompanionBuilder =
    LevelProgressCompanion Function({
      required String level,
      Value<int> bestStars,
      Value<int> bestCollected,
      Value<int> bestScore,
      Value<int> plays,
      Value<DateTime?> firstClearedAt,
      Value<DateTime?> lastPlayedAt,
      Value<bool> postcardSeen,
      Value<int> rowid,
    });
typedef $$LevelProgressTableUpdateCompanionBuilder =
    LevelProgressCompanion Function({
      Value<String> level,
      Value<int> bestStars,
      Value<int> bestCollected,
      Value<int> bestScore,
      Value<int> plays,
      Value<DateTime?> firstClearedAt,
      Value<DateTime?> lastPlayedAt,
      Value<bool> postcardSeen,
      Value<int> rowid,
    });

class $$LevelProgressTableFilterComposer
    extends Composer<_$ProgressDatabase, $LevelProgressTable> {
  $$LevelProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bestStars => $composableBuilder(
    column: $table.bestStars,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bestCollected => $composableBuilder(
    column: $table.bestCollected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bestScore => $composableBuilder(
    column: $table.bestScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plays => $composableBuilder(
    column: $table.plays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstClearedAt => $composableBuilder(
    column: $table.firstClearedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get postcardSeen => $composableBuilder(
    column: $table.postcardSeen,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LevelProgressTableOrderingComposer
    extends Composer<_$ProgressDatabase, $LevelProgressTable> {
  $$LevelProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bestStars => $composableBuilder(
    column: $table.bestStars,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bestCollected => $composableBuilder(
    column: $table.bestCollected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bestScore => $composableBuilder(
    column: $table.bestScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plays => $composableBuilder(
    column: $table.plays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstClearedAt => $composableBuilder(
    column: $table.firstClearedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get postcardSeen => $composableBuilder(
    column: $table.postcardSeen,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LevelProgressTableAnnotationComposer
    extends Composer<_$ProgressDatabase, $LevelProgressTable> {
  $$LevelProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get bestStars =>
      $composableBuilder(column: $table.bestStars, builder: (column) => column);

  GeneratedColumn<int> get bestCollected => $composableBuilder(
    column: $table.bestCollected,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bestScore =>
      $composableBuilder(column: $table.bestScore, builder: (column) => column);

  GeneratedColumn<int> get plays =>
      $composableBuilder(column: $table.plays, builder: (column) => column);

  GeneratedColumn<DateTime> get firstClearedAt => $composableBuilder(
    column: $table.firstClearedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get postcardSeen => $composableBuilder(
    column: $table.postcardSeen,
    builder: (column) => column,
  );
}

class $$LevelProgressTableTableManager
    extends
        RootTableManager<
          _$ProgressDatabase,
          $LevelProgressTable,
          LevelProgressRow,
          $$LevelProgressTableFilterComposer,
          $$LevelProgressTableOrderingComposer,
          $$LevelProgressTableAnnotationComposer,
          $$LevelProgressTableCreateCompanionBuilder,
          $$LevelProgressTableUpdateCompanionBuilder,
          (
            LevelProgressRow,
            BaseReferences<
              _$ProgressDatabase,
              $LevelProgressTable,
              LevelProgressRow
            >,
          ),
          LevelProgressRow,
          PrefetchHooks Function()
        > {
  $$LevelProgressTableTableManager(
    _$ProgressDatabase db,
    $LevelProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LevelProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LevelProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LevelProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> level = const Value.absent(),
                Value<int> bestStars = const Value.absent(),
                Value<int> bestCollected = const Value.absent(),
                Value<int> bestScore = const Value.absent(),
                Value<int> plays = const Value.absent(),
                Value<DateTime?> firstClearedAt = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<bool> postcardSeen = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LevelProgressCompanion(
                level: level,
                bestStars: bestStars,
                bestCollected: bestCollected,
                bestScore: bestScore,
                plays: plays,
                firstClearedAt: firstClearedAt,
                lastPlayedAt: lastPlayedAt,
                postcardSeen: postcardSeen,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String level,
                Value<int> bestStars = const Value.absent(),
                Value<int> bestCollected = const Value.absent(),
                Value<int> bestScore = const Value.absent(),
                Value<int> plays = const Value.absent(),
                Value<DateTime?> firstClearedAt = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<bool> postcardSeen = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LevelProgressCompanion.insert(
                level: level,
                bestStars: bestStars,
                bestCollected: bestCollected,
                bestScore: bestScore,
                plays: plays,
                firstClearedAt: firstClearedAt,
                lastPlayedAt: lastPlayedAt,
                postcardSeen: postcardSeen,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LevelProgressTable, LevelProgressRow>(table),
                  BaseReferences<
                    _$ProgressDatabase,
                    $LevelProgressTable,
                    LevelProgressRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LevelProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$ProgressDatabase,
      $LevelProgressTable,
      LevelProgressRow,
      $$LevelProgressTableFilterComposer,
      $$LevelProgressTableOrderingComposer,
      $$LevelProgressTableAnnotationComposer,
      $$LevelProgressTableCreateCompanionBuilder,
      $$LevelProgressTableUpdateCompanionBuilder,
      (
        LevelProgressRow,
        BaseReferences<
          _$ProgressDatabase,
          $LevelProgressTable,
          LevelProgressRow
        >,
      ),
      LevelProgressRow,
      PrefetchHooks Function()
    >;
typedef $$BuiltLevelsTableCreateCompanionBuilder =
    BuiltLevelsCompanion Function({
      required String id,
      required String name,
      required int mode,
      required String json,
      required String fingerprint,
      Value<int> revision,
      Value<String> origin,
      Value<String?> remixOf,
      Value<int?> clearedRevision,
      Value<bool> importedCleared,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$BuiltLevelsTableUpdateCompanionBuilder =
    BuiltLevelsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> mode,
      Value<String> json,
      Value<String> fingerprint,
      Value<int> revision,
      Value<String> origin,
      Value<String?> remixOf,
      Value<int?> clearedRevision,
      Value<bool> importedCleared,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$BuiltLevelsTableFilterComposer
    extends Composer<_$ProgressDatabase, $BuiltLevelsTable> {
  $$BuiltLevelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remixOf => $composableBuilder(
    column: $table.remixOf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clearedRevision => $composableBuilder(
    column: $table.clearedRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get importedCleared => $composableBuilder(
    column: $table.importedCleared,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BuiltLevelsTableOrderingComposer
    extends Composer<_$ProgressDatabase, $BuiltLevelsTable> {
  $$BuiltLevelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remixOf => $composableBuilder(
    column: $table.remixOf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clearedRevision => $composableBuilder(
    column: $table.clearedRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get importedCleared => $composableBuilder(
    column: $table.importedCleared,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BuiltLevelsTableAnnotationComposer
    extends Composer<_$ProgressDatabase, $BuiltLevelsTable> {
  $$BuiltLevelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get remixOf =>
      $composableBuilder(column: $table.remixOf, builder: (column) => column);

  GeneratedColumn<int> get clearedRevision => $composableBuilder(
    column: $table.clearedRevision,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get importedCleared => $composableBuilder(
    column: $table.importedCleared,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BuiltLevelsTableTableManager
    extends
        RootTableManager<
          _$ProgressDatabase,
          $BuiltLevelsTable,
          BuiltLevelRow,
          $$BuiltLevelsTableFilterComposer,
          $$BuiltLevelsTableOrderingComposer,
          $$BuiltLevelsTableAnnotationComposer,
          $$BuiltLevelsTableCreateCompanionBuilder,
          $$BuiltLevelsTableUpdateCompanionBuilder,
          (
            BuiltLevelRow,
            BaseReferences<
              _$ProgressDatabase,
              $BuiltLevelsTable,
              BuiltLevelRow
            >,
          ),
          BuiltLevelRow,
          PrefetchHooks Function()
        > {
  $$BuiltLevelsTableTableManager(_$ProgressDatabase db, $BuiltLevelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BuiltLevelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BuiltLevelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BuiltLevelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> mode = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String> fingerprint = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String?> remixOf = const Value.absent(),
                Value<int?> clearedRevision = const Value.absent(),
                Value<bool> importedCleared = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BuiltLevelsCompanion(
                id: id,
                name: name,
                mode: mode,
                json: json,
                fingerprint: fingerprint,
                revision: revision,
                origin: origin,
                remixOf: remixOf,
                clearedRevision: clearedRevision,
                importedCleared: importedCleared,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int mode,
                required String json,
                required String fingerprint,
                Value<int> revision = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String?> remixOf = const Value.absent(),
                Value<int?> clearedRevision = const Value.absent(),
                Value<bool> importedCleared = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BuiltLevelsCompanion.insert(
                id: id,
                name: name,
                mode: mode,
                json: json,
                fingerprint: fingerprint,
                revision: revision,
                origin: origin,
                remixOf: remixOf,
                clearedRevision: clearedRevision,
                importedCleared: importedCleared,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BuiltLevelsTable, BuiltLevelRow>(table),
                  BaseReferences<
                    _$ProgressDatabase,
                    $BuiltLevelsTable,
                    BuiltLevelRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BuiltLevelsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProgressDatabase,
      $BuiltLevelsTable,
      BuiltLevelRow,
      $$BuiltLevelsTableFilterComposer,
      $$BuiltLevelsTableOrderingComposer,
      $$BuiltLevelsTableAnnotationComposer,
      $$BuiltLevelsTableCreateCompanionBuilder,
      $$BuiltLevelsTableUpdateCompanionBuilder,
      (
        BuiltLevelRow,
        BaseReferences<_$ProgressDatabase, $BuiltLevelsTable, BuiltLevelRow>,
      ),
      BuiltLevelRow,
      PrefetchHooks Function()
    >;
typedef $$BuiltFlightsTableCreateCompanionBuilder =
    BuiltFlightsCompanion Function({
      required String id,
      required String level,
      required int revision,
      required int mode,
      Value<int> rating,
      Value<int> stars,
      Value<int> score,
      Value<int> repetitions,
      Value<int> flaps,
      required double duration,
      required String reason,
      required DateTime finishedAt,
      Value<int> rowid,
    });
typedef $$BuiltFlightsTableUpdateCompanionBuilder =
    BuiltFlightsCompanion Function({
      Value<String> id,
      Value<String> level,
      Value<int> revision,
      Value<int> mode,
      Value<int> rating,
      Value<int> stars,
      Value<int> score,
      Value<int> repetitions,
      Value<int> flaps,
      Value<double> duration,
      Value<String> reason,
      Value<DateTime> finishedAt,
      Value<int> rowid,
    });

class $$BuiltFlightsTableFilterComposer
    extends Composer<_$ProgressDatabase, $BuiltFlightsTable> {
  $$BuiltFlightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get flaps => $composableBuilder(
    column: $table.flaps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BuiltFlightsTableOrderingComposer
    extends Composer<_$ProgressDatabase, $BuiltFlightsTable> {
  $$BuiltFlightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get flaps => $composableBuilder(
    column: $table.flaps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BuiltFlightsTableAnnotationComposer
    extends Composer<_$ProgressDatabase, $BuiltFlightsTable> {
  $$BuiltFlightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get stars =>
      $composableBuilder(column: $table.stars, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get flaps =>
      $composableBuilder(column: $table.flaps, builder: (column) => column);

  GeneratedColumn<double> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );
}

class $$BuiltFlightsTableTableManager
    extends
        RootTableManager<
          _$ProgressDatabase,
          $BuiltFlightsTable,
          BuiltFlightRow,
          $$BuiltFlightsTableFilterComposer,
          $$BuiltFlightsTableOrderingComposer,
          $$BuiltFlightsTableAnnotationComposer,
          $$BuiltFlightsTableCreateCompanionBuilder,
          $$BuiltFlightsTableUpdateCompanionBuilder,
          (
            BuiltFlightRow,
            BaseReferences<
              _$ProgressDatabase,
              $BuiltFlightsTable,
              BuiltFlightRow
            >,
          ),
          BuiltFlightRow,
          PrefetchHooks Function()
        > {
  $$BuiltFlightsTableTableManager(
    _$ProgressDatabase db,
    $BuiltFlightsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BuiltFlightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BuiltFlightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BuiltFlightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> mode = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<int> stars = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<int> flaps = const Value.absent(),
                Value<double> duration = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<DateTime> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BuiltFlightsCompanion(
                id: id,
                level: level,
                revision: revision,
                mode: mode,
                rating: rating,
                stars: stars,
                score: score,
                repetitions: repetitions,
                flaps: flaps,
                duration: duration,
                reason: reason,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String level,
                required int revision,
                required int mode,
                Value<int> rating = const Value.absent(),
                Value<int> stars = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<int> flaps = const Value.absent(),
                required double duration,
                required String reason,
                required DateTime finishedAt,
                Value<int> rowid = const Value.absent(),
              }) => BuiltFlightsCompanion.insert(
                id: id,
                level: level,
                revision: revision,
                mode: mode,
                rating: rating,
                stars: stars,
                score: score,
                repetitions: repetitions,
                flaps: flaps,
                duration: duration,
                reason: reason,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BuiltFlightsTable, BuiltFlightRow>(table),
                  BaseReferences<
                    _$ProgressDatabase,
                    $BuiltFlightsTable,
                    BuiltFlightRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BuiltFlightsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProgressDatabase,
      $BuiltFlightsTable,
      BuiltFlightRow,
      $$BuiltFlightsTableFilterComposer,
      $$BuiltFlightsTableOrderingComposer,
      $$BuiltFlightsTableAnnotationComposer,
      $$BuiltFlightsTableCreateCompanionBuilder,
      $$BuiltFlightsTableUpdateCompanionBuilder,
      (
        BuiltFlightRow,
        BaseReferences<_$ProgressDatabase, $BuiltFlightsTable, BuiltFlightRow>,
      ),
      BuiltFlightRow,
      PrefetchHooks Function()
    >;

class $ProgressDatabaseManager {
  final _$ProgressDatabase _db;
  $ProgressDatabaseManager(this._db);
  $$RunsTableTableManager get runs => $$RunsTableTableManager(_db, _db.runs);
  $$PreferencesTableTableManager get preferences =>
      $$PreferencesTableTableManager(_db, _db.preferences);
  $$LevelProgressTableTableManager get levelProgress =>
      $$LevelProgressTableTableManager(_db, _db.levelProgress);
  $$BuiltLevelsTableTableManager get builtLevels =>
      $$BuiltLevelsTableTableManager(_db, _db.builtLevels);
  $$BuiltFlightsTableTableManager get builtFlights =>
      $$BuiltFlightsTableTableManager(_db, _db.builtFlights);
}
