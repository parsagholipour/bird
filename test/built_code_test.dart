import 'dart:convert';
import 'dart:io' show ZLibCodec;

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/domain/built_code.dart';
import 'package:push_up_bird/domain/built_templates.dart';
import 'package:push_up_bird/domain/tracking.dart';

import 'built_pilot.dart';

Matcher fault(BuiltCodeFault fault) =>
    throwsA(isA<BuiltCodeException>().having((e) => e.fault, 'fault', fault));

String pack(Object json, {int version = 1}) {
  final bytes = ZLibCodec(raw: true).encode(utf8.encode(jsonEncode(json)));
  return 'BEAK$version.${base64Url.encode(bytes).replaceAll('=', '')}';
}

void main() {
  test('every level survives its share code', () {
    for (final plan in [
      for (final level in BuiltTemplates.all) level.plan,
      for (final mode in PlayMode.values) sampleLevel(mode),
    ]) {
      final code = BuiltCode.encode(plan);
      expect(code, startsWith('BEAK1.'));
      expect(code, matches(RegExp(r'^BEAK1\.[A-Za-z0-9_-]+$')));
      final read = BuiltCode.decode(code, id: 'u-importedlv');
      expect(read.plan.id, 'u-importedlv');
      expect(read.plan.name, plan.name);
      expect(read.plan.fingerprint, plan.fingerprint);
      expect(read.cleared, isFalse);
    }
    final cleared = BuiltCode.decode(
      BuiltCode.encode(sampleLevel(PlayMode.squat), cleared: true),
      id: 'u-importedlv',
    );
    expect(cleared.cleared, isTrue);
  });

  test('a code is found inside whatever text it was pasted with', () {
    final plan = BuiltTemplates.byId('t-push-1')!.plan;
    final message = BuiltCode.message(plan);
    expect(message, contains('Ten Push-Ups'));
    expect(message, contains('Push-Up Flight'));
    final read = BuiltCode.decode(
      'Hey!\n$message\nsee you',
      id: 'u-fromfriend',
    );
    expect(read.plan.fingerprint, plan.fingerprint);
    // A long level stays a short paste.
    expect(BuiltCode.encode(plan).length, lessThan(1200));
  });

  test('a damaged, newer or missing code is refused politely', () {
    final code = BuiltCode.encode(sampleLevel(PlayMode.touch));
    expect(
      () => BuiltCode.decode('nothing here', id: 'u-x000000000'),
      fault(BuiltCodeFault.missing),
    );
    expect(
      () => BuiltCode.decode(
        code.replaceFirst('BEAK1', 'BEAK2'),
        id: 'u-x000000000',
      ),
      fault(BuiltCodeFault.newer),
    );
    expect(
      () => BuiltCode.decode(
        code.substring(0, code.length - 9),
        id: 'u-x000000000',
      ),
      fault(BuiltCodeFault.damaged),
    );
    expect(
      () => BuiltCode.decode('BEAK1.abcdefghijklmnop', id: 'u-x000000000'),
      fault(BuiltCodeFault.damaged),
    );
    final json = {
      'name': 'Later',
      ...sampleLevel(PlayMode.touch).contentJson(),
    };
    expect(
      () => BuiltCode.decode(pack({...json, 'v': 2}), id: 'u-x000000000'),
      fault(BuiltCodeFault.newer),
    );
    // A plan that cannot be flown is no level at all.
    expect(
      () => BuiltCode.decode(pack({...json, 'finish': 10}), id: 'u-x000000000'),
      fault(BuiltCodeFault.damaged),
    );
    expect(
      () => BuiltCode.decode(
        pack({...json, 'cleared': 'yes'}),
        id: 'u-x000000000',
      ),
      fault(BuiltCodeFault.damaged),
    );
  });

  test('a code that inflates past the cap is refused', () {
    // Half a megabyte of spaces deflates to a few hundred bytes.
    final bomb = ZLibCodec(
      raw: true,
      level: 9,
    ).encode(utf8.encode('{"name":"${' ' * 500000}"}'));
    final code = 'BEAK1.${base64Url.encode(bomb).replaceAll('=', '')}';
    expect(code.length, lessThan(4000));
    expect(
      () => BuiltCode.decode(code, id: 'u-x000000000'),
      fault(BuiltCodeFault.damaged),
    );
  });
}
