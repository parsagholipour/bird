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
          ..write('finishedAt: $finishedAt')
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
          other.finishedAt == this.finishedAt);
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

class $BirdUnlocksTable extends BirdUnlocks
    with TableInfo<$BirdUnlocksTable, BirdUnlock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BirdUnlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _birdMeta = const VerificationMeta('bird');
  @override
  late final GeneratedColumn<int> bird = GeneratedColumn<int>(
    'bird',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unlockedAtMeta = const VerificationMeta(
    'unlockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> unlockedAt = GeneratedColumn<DateTime>(
    'unlocked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [bird, unlockedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bird_unlocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<BirdUnlock> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bird')) {
      context.handle(
        _birdMeta,
        bird.isAcceptableOrUnknown(data['bird']!, _birdMeta),
      );
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(
        _unlockedAtMeta,
        unlockedAt.isAcceptableOrUnknown(data['unlocked_at']!, _unlockedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_unlockedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bird};
  @override
  BirdUnlock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BirdUnlock(
      bird: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bird'],
      )!,
      unlockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}unlocked_at'],
      )!,
    );
  }

  @override
  $BirdUnlocksTable createAlias(String alias) {
    return $BirdUnlocksTable(attachedDatabase, alias);
  }
}

class BirdUnlock extends DataClass implements Insertable<BirdUnlock> {
  final int bird;
  final DateTime unlockedAt;
  const BirdUnlock({required this.bird, required this.unlockedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bird'] = Variable<int>(bird);
    map['unlocked_at'] = Variable<DateTime>(unlockedAt);
    return map;
  }

  BirdUnlocksCompanion toCompanion(bool nullToAbsent) {
    return BirdUnlocksCompanion(
      bird: Value(bird),
      unlockedAt: Value(unlockedAt),
    );
  }

  factory BirdUnlock.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BirdUnlock(
      bird: serializer.fromJson<int>(json['bird']),
      unlockedAt: serializer.fromJson<DateTime>(json['unlockedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bird': serializer.toJson<int>(bird),
      'unlockedAt': serializer.toJson<DateTime>(unlockedAt),
    };
  }

  BirdUnlock copyWith({int? bird, DateTime? unlockedAt}) => BirdUnlock(
    bird: bird ?? this.bird,
    unlockedAt: unlockedAt ?? this.unlockedAt,
  );
  BirdUnlock copyWithCompanion(BirdUnlocksCompanion data) {
    return BirdUnlock(
      bird: data.bird.present ? data.bird.value : this.bird,
      unlockedAt: data.unlockedAt.present
          ? data.unlockedAt.value
          : this.unlockedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BirdUnlock(')
          ..write('bird: $bird, ')
          ..write('unlockedAt: $unlockedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(bird, unlockedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BirdUnlock &&
          other.bird == this.bird &&
          other.unlockedAt == this.unlockedAt);
}

class BirdUnlocksCompanion extends UpdateCompanion<BirdUnlock> {
  final Value<int> bird;
  final Value<DateTime> unlockedAt;
  const BirdUnlocksCompanion({
    this.bird = const Value.absent(),
    this.unlockedAt = const Value.absent(),
  });
  BirdUnlocksCompanion.insert({
    this.bird = const Value.absent(),
    required DateTime unlockedAt,
  }) : unlockedAt = Value(unlockedAt);
  static Insertable<BirdUnlock> custom({
    Expression<int>? bird,
    Expression<DateTime>? unlockedAt,
  }) {
    return RawValuesInsertable({
      if (bird != null) 'bird': bird,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
    });
  }

  BirdUnlocksCompanion copyWith({
    Value<int>? bird,
    Value<DateTime>? unlockedAt,
  }) {
    return BirdUnlocksCompanion(
      bird: bird ?? this.bird,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bird.present) {
      map['bird'] = Variable<int>(bird.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BirdUnlocksCompanion(')
          ..write('bird: $bird, ')
          ..write('unlockedAt: $unlockedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$ProgressDatabase extends GeneratedDatabase {
  _$ProgressDatabase(QueryExecutor e) : super(e);
  $ProgressDatabaseManager get managers => $ProgressDatabaseManager(this);
  late final $RunsTable runs = $RunsTable(this);
  late final $PreferencesTable preferences = $PreferencesTable(this);
  late final $BirdUnlocksTable birdUnlocks = $BirdUnlocksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    runs,
    preferences,
    birdUnlocks,
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
typedef $$BirdUnlocksTableCreateCompanionBuilder =
    BirdUnlocksCompanion Function({
      Value<int> bird,
      required DateTime unlockedAt,
    });
typedef $$BirdUnlocksTableUpdateCompanionBuilder =
    BirdUnlocksCompanion Function({
      Value<int> bird,
      Value<DateTime> unlockedAt,
    });

class $$BirdUnlocksTableFilterComposer
    extends Composer<_$ProgressDatabase, $BirdUnlocksTable> {
  $$BirdUnlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get bird => $composableBuilder(
    column: $table.bird,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BirdUnlocksTableOrderingComposer
    extends Composer<_$ProgressDatabase, $BirdUnlocksTable> {
  $$BirdUnlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get bird => $composableBuilder(
    column: $table.bird,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BirdUnlocksTableAnnotationComposer
    extends Composer<_$ProgressDatabase, $BirdUnlocksTable> {
  $$BirdUnlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get bird =>
      $composableBuilder(column: $table.bird, builder: (column) => column);

  GeneratedColumn<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => column,
  );
}

class $$BirdUnlocksTableTableManager
    extends
        RootTableManager<
          _$ProgressDatabase,
          $BirdUnlocksTable,
          BirdUnlock,
          $$BirdUnlocksTableFilterComposer,
          $$BirdUnlocksTableOrderingComposer,
          $$BirdUnlocksTableAnnotationComposer,
          $$BirdUnlocksTableCreateCompanionBuilder,
          $$BirdUnlocksTableUpdateCompanionBuilder,
          (
            BirdUnlock,
            BaseReferences<_$ProgressDatabase, $BirdUnlocksTable, BirdUnlock>,
          ),
          BirdUnlock,
          PrefetchHooks Function()
        > {
  $$BirdUnlocksTableTableManager(_$ProgressDatabase db, $BirdUnlocksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BirdUnlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BirdUnlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BirdUnlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> bird = const Value.absent(),
                Value<DateTime> unlockedAt = const Value.absent(),
              }) => BirdUnlocksCompanion(bird: bird, unlockedAt: unlockedAt),
          createCompanionCallback:
              ({
                Value<int> bird = const Value.absent(),
                required DateTime unlockedAt,
              }) => BirdUnlocksCompanion.insert(
                bird: bird,
                unlockedAt: unlockedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BirdUnlocksTable, BirdUnlock>(table),
                  BaseReferences<
                    _$ProgressDatabase,
                    $BirdUnlocksTable,
                    BirdUnlock
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BirdUnlocksTableProcessedTableManager =
    ProcessedTableManager<
      _$ProgressDatabase,
      $BirdUnlocksTable,
      BirdUnlock,
      $$BirdUnlocksTableFilterComposer,
      $$BirdUnlocksTableOrderingComposer,
      $$BirdUnlocksTableAnnotationComposer,
      $$BirdUnlocksTableCreateCompanionBuilder,
      $$BirdUnlocksTableUpdateCompanionBuilder,
      (
        BirdUnlock,
        BaseReferences<_$ProgressDatabase, $BirdUnlocksTable, BirdUnlock>,
      ),
      BirdUnlock,
      PrefetchHooks Function()
    >;

class $ProgressDatabaseManager {
  final _$ProgressDatabase _db;
  $ProgressDatabaseManager(this._db);
  $$RunsTableTableManager get runs => $$RunsTableTableManager(_db, _db.runs);
  $$PreferencesTableTableManager get preferences =>
      $$PreferencesTableTableManager(_db, _db.preferences);
  $$BirdUnlocksTableTableManager get birdUnlocks =>
      $$BirdUnlocksTableTableManager(_db, _db.birdUnlocks);
}
