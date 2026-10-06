import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// BT-CAT-02: the catalog is read-only for users (D-35). The app must never
/// ask `/cards`, `/cards/resolve` or `/cards/printings` to sync from Scryfall,
/// so the server can reject `sync=true` without breaking any screen.
void main() {
  test('no app source sends a catalog sync parameter', () {
    final offenders = <String>[];
    final pattern = RegExp(r'''[?&]sync=|['"]sync['"]\s*:''');
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) {
          offenders.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(offenders, isEmpty);
  });
}
