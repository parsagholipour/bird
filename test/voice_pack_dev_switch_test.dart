// tool/l10n/dev_voice_packs.py: a dev build lists only some voice packs, a
// release lists all of them again, byte for byte. Runs on a copy of
// pubspec.yaml and android/settings.gradle.kts; the real files are not
// touched.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/game/voice_packs.dart';
import 'package:push_up_bird/l10n/app_language.dart';

const _tool = 'tool/l10n/dev_voice_packs.py';

final _localized = [
  for (final language in AppLanguage.values)
    if (language != AppLanguage.en) language,
];

/// The text between a file's `voice-packs:begin` and `voice-packs:end` lines.
String _block(String text) {
  final begin = text.indexOf('\n', text.indexOf('voice-packs:begin')) + 1;
  return text.substring(begin, text.indexOf('voice-packs:end', begin));
}

/// The file with its generated block cut out: what the switch must keep.
String _outside(String text) => text.replaceFirst(_block(text), '');

void main() {
  late Directory root;
  late File pubspec;
  late File settings;
  late String realPubspec;
  late String realSettings;

  setUp(() {
    root = Directory.systemTemp.createTempSync('dev_voice_packs_');
    realPubspec = File('pubspec.yaml').readAsStringSync();
    realSettings = File('android/settings.gradle.kts').readAsStringSync();
    pubspec = File('${root.path}/pubspec.yaml')..writeAsStringSync(realPubspec);
    settings = File('${root.path}/android/settings.gradle.kts')
      ..createSync(recursive: true)
      ..writeAsStringSync(realSettings);
    // The asset folders the real packs fill, one stand-in take each, so the
    // copy lists the same folders as the real tree.
    for (final language in _localized) {
      for (final kind in ['story', 'flight']) {
        final real = Directory('assets/voice/${language.slug}/$kind');
        if (real.existsSync() &&
            real.listSync().any((f) => f.path.endsWith('.ogg'))) {
          File(
            '${root.path}/assets/voice/${language.slug}/$kind/x.ogg',
          ).createSync(recursive: true);
        }
      }
    }
  });

  tearDown(() => root.deleteSync(recursive: true));

  Future<ProcessResult?> run(List<String> args) async {
    try {
      return await Process.run('python3', [
        _tool,
        '--root',
        root.path,
        ...args,
      ], stdoutEncoding: utf8);
    } on ProcessException {
      return null;
    }
  }

  List<String> components() => [
    for (final m in RegExp(
      r'^    - name: (\S+)$',
      multiLine: true,
    ).allMatches(_block(pubspec.readAsStringSync())))
      m[1]!,
  ];

  List<String> includes() => [
    for (final m in RegExp(
      r'^include\(":(\S+)"\)$',
      multiLine: true,
    ).allMatches(_block(settings.readAsStringSync())))
      m[1]!,
  ];

  test('the committed tree is the release state', () async {
    final check = await run(['--check']);
    if (check == null) return markTestSkipped('python3 is not installed');
    expect(check.exitCode, 0, reason: '${check.stdout}${check.stderr}');
    expect(check.stdout, contains('all 11 voice packs listed'));
    expect(components(), [for (final l in _localized) VoicePack.component(l)]);
  });

  test('--only lists just those packs in both files, marked', () async {
    final only = await run(['--only', 'de,es-419']);
    if (only == null) return markTestSkipped('python3 is not installed');
    expect(only.exitCode, 0, reason: '${only.stderr}');
    // Language order, whatever order was asked; tags work like slugs.
    expect(components(), ['voice_es_419', 'voice_de']);
    expect(includes(), ['voice_es_419', 'voice_de']);
    final spec = pubspec.readAsStringSync();
    expect(_block(spec), contains('voice-packs:dev-subset es_419,de'));
    expect(_block(spec), contains('        - assets/voice/de/story/\n'));
    expect(spec, isNot(contains('assets/voice/fr/')));
    expect(
      _block(settings.readAsStringSync()),
      contains('voice-packs:dev-subset es_419,de'),
    );
    // Nothing outside the generated blocks moves.
    expect(_outside(spec), _outside(realPubspec));
    expect(
      _outside(settings.readAsStringSync()),
      _outside(realSettings),
    );

    final check = await run(['--check']);
    expect(check!.exitCode, 1);
    expect(check.stdout, contains('DEV SUBSET: 2 of 11'));
    expect(check.stdout, contains('dev_voice_packs.py --all'));
  });

  test('--none lists no pack and no deferred components at all', () async {
    final none = await run(['--none']);
    if (none == null) return markTestSkipped('python3 is not installed');
    expect(none.exitCode, 0, reason: '${none.stderr}');
    expect(components(), isEmpty);
    expect(includes(), isEmpty);
    expect(pubspec.readAsStringSync(), isNot(contains('deferred-components:')));
    expect(
      _block(pubspec.readAsStringSync()),
      contains('voice-packs:dev-subset none'),
    );
    expect((await run(['--check']))!.exitCode, 1);
  });

  test('--all restores the release files byte for byte', () async {
    final only = await run(['--only', 'ja']);
    if (only == null) return markTestSkipped('python3 is not installed');
    expect(components(), ['voice_ja']);
    await run(['--none']);
    final all = await run(['--all']);
    expect(all!.exitCode, 0, reason: '${all.stderr}');
    expect(pubspec.readAsStringSync(), realPubspec);
    expect(settings.readAsStringSync(), realSettings);
    expect((await run(['--check']))!.exitCode, 0);
  });

  test('an unknown pack changes nothing', () async {
    final bad = await run(['--only', 'es_419,xx']);
    if (bad == null) return markTestSkipped('python3 is not installed');
    expect(bad.exitCode, isNot(0));
    expect(bad.stderr, contains("unknown voice pack 'xx'"));
    expect(pubspec.readAsStringSync(), realPubspec);
    expect(settings.readAsStringSync(), realSettings);
  });
}
