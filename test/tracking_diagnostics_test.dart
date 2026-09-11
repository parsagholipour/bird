import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_up_bird/tracking/tracking_diagnostics.dart';

void main() {
  test(
    'a long camera session retains the newest trace after rotation',
    () async {
      final folder = await Directory.systemTemp.createTemp('bird-trace-roll-');
      addTearDown(() => folder.delete(recursive: true));
      final log = TrackingDiagnostics(folder, byteLimit: 20);
      await log.start();
      for (final line in ['before', 'more', 'next chunk', 'newest']) {
        log.write(line);
      }
      await log.close();
      expect(
        await File('${folder.path}/latest.log').readAsString(),
        'next chunk\nnewest\n',
      );
      expect(
        await File('${folder.path}/previous.log').readAsString(),
        'before\nmore\n',
      );
      expect(await folder.list().length, 2);
    },
  );
  test(
    'latest and previous session traces survive closing and remain bounded',
    () async {
      final folder = await Directory.systemTemp.createTemp('bird-trace-');
      addTearDown(() => folder.delete(recursive: true));
      final log = TrackingDiagnostics(folder, byteLimit: 40);
      await log.start();
      log.write('first run');
      await log.close();
      await log.start();
      log.write('second run');
      log.write('x' * 100);
      await log.flush();
      expect(
        await File('${folder.path}/latest.log').readAsString(),
        'second run\n',
      );
      expect(
        await File('${folder.path}/previous.log').readAsString(),
        'first run\n',
      );
      await log.close();
      final reopened = TrackingDiagnostics(folder);
      await reopened.start();
      reopened.write('third run');
      await reopened.close();
      expect(
        await File('${folder.path}/previous.log').readAsString(),
        'second run\n',
      );
      expect(await folder.list().length, 2);
    },
  );
}
