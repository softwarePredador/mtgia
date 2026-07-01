import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app surfaces do not define local hardcoded colors', () {
    final offenders = <String>[];
    final forbidden = RegExp(
      r'Color\(0x[0-9A-Fa-f]{8}\)|Colors\.(blue|purple|amber|orange|white|black|green|red|yellow|pink|teal|cyan|lime|indigo|brown|grey|gray)',
    );

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final path = file.path.replaceAll('\\', '/');
      if (_isExcluded(path)) continue;

      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (forbidden.hasMatch(line)) {
          offenders.add('$path:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Use AppTheme tokens for shared app surfaces. Scanner and life-counter '
          'skins are excluded because they have independent visual systems.',
    );
  });
}

bool _isExcluded(String path) {
  return path == 'lib/core/theme/app_theme.dart' ||
      path.startsWith('lib/features/scanner/') ||
      path.startsWith('lib/features/home/life_counter/') ||
      path.startsWith('lib/features/home/lotus/') ||
      path == 'lib/features/home/lotus_life_counter_screen.dart';
}
