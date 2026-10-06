import 'dart:convert';
import 'dart:io' show ZLibCodec, ZLibDecoder;

import 'game_rules.dart';

/// Why a pasted share code could not be read.
enum BuiltCodeFault {
  /// No code in the text.
  missing,

  /// A code from a newer Beakbound, which this one cannot fly.
  newer,

  /// A code that is cut short, mistyped or not a level.
  damaged,
}

class BuiltCodeException implements Exception {
  const BuiltCodeException(this.fault);
  final BuiltCodeFault fault;
  @override
  String toString() => 'BuiltCodeException(${fault.name})';
}

/// A level read from a share code: its plan under the id it is given here,
/// and whether its creator had flown it to the finish.
typedef BuiltImport = ({BuiltPlan plan, bool cleared});

/// Share codes: a built level as text to paste anywhere, read back on
/// another phone with no network. `BEAK1.` then the plan's canonical JSON
/// (without its id, which every phone gives anew) deflated and in
/// URL-safe base64. The number is the code's format: a newer one is
/// refused politely rather than misread.
abstract final class BuiltCode {
  static const version = 1;
  static const prefix = 'BEAK';

  /// The most a code may inflate to: far more than the largest level, far
  /// less than a hostile code could ask for.
  static const maxJson = 64 * 1024;
  static final _pattern = RegExp(r'BEAK(\d{1,4})\.([A-Za-z0-9_-]{8,65536})');

  static String encode(BuiltPlan plan, {bool cleared = false}) {
    final json = <String, Object?>{
      'name': plan.name,
      ...plan.contentJson(),
      if (cleared) 'cleared': true,
    };
    final packed = ZLibCodec(
      raw: true,
      level: 9,
    ).encode(utf8.encode(jsonEncode(json)));
    return '$prefix$version.${base64Url.encode(packed).replaceAll('=', '')}';
  }

  /// The text the share key copies: a line a friend can read, ending with
  /// the code itself.
  static String message(BuiltPlan plan, {bool cleared = false}) =>
      'Fly my Beakbound level “${plan.name}” '
      '(${plan.mode.title}): ${encode(plan, cleared: cleared)}';

  /// The first share code in [text], flown under [id]. Throws a
  /// [BuiltCodeException] when there is none or it cannot be flown.
  static BuiltImport decode(String text, {required String id}) {
    final match = _pattern.firstMatch(text);
    if (match == null) {
      throw const BuiltCodeException(BuiltCodeFault.missing);
    }
    final format = int.parse(match.group(1)!);
    if (format > version) throw const BuiltCodeException(BuiltCodeFault.newer);
    if (format < 1) throw const BuiltCodeException(BuiltCodeFault.damaged);
    try {
      final body = match.group(2)!;
      final padded = body.padRight((body.length + 3) ~/ 4 * 4, '=');
      final json = jsonDecode(utf8.decode(_inflate(base64Url.decode(padded))));
      if (json is! Map<String, dynamic>) throw const FormatException();
      final cleared = switch (json.remove('cleared')) {
        null => false,
        true => true,
        _ => throw const FormatException(),
      };
      if (json['v'] is int && (json['v'] as int) > BuiltPlan.formatVersion) {
        throw const BuiltCodeException(BuiltCodeFault.newer);
      }
      final plan = BuiltPlan.fromJson({...json, 'id': id});
      if (plan.minRulesVersion > FlightSimulation.currentRulesVersion) {
        throw const BuiltCodeException(BuiltCodeFault.newer);
      }
      return (plan: plan, cleared: cleared);
    } on BuiltCodeException {
      rethrow;
    } catch (_) {
      throw const BuiltCodeException(BuiltCodeFault.damaged);
    }
  }

  /// Inflates [packed] a kilobyte at a time, refusing anything that grows
  /// past [maxJson] as soon as it does.
  static List<int> _inflate(List<int> packed) {
    final sink = _CappedSink(maxJson);
    final input = ZLibDecoder(raw: true).startChunkedConversion(sink);
    const step = 1024;
    for (var i = 0; i < packed.length; i += step) {
      final end = i + step > packed.length ? packed.length : i + step;
      input.add(packed.sublist(i, end));
    }
    input.close();
    return sink.bytes;
  }
}

class _CappedSink implements Sink<List<int>> {
  _CappedSink(this.limit);
  final int limit;
  final bytes = <int>[];
  @override
  void add(List<int> chunk) {
    bytes.addAll(chunk);
    if (bytes.length > limit) throw const FormatException('Too large');
  }

  @override
  void close() {}
}
