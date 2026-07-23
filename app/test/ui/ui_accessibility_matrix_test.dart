import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';

void main() {
  final matrix = _loadJson('test/ui/fixtures/ui_accessibility_matrix.json');
  final inventory = _loadJson('test/ui/fixtures/ui_surface_inventory.json');

  test('every product domain has executable mobile accessibility evidence', () {
    final evidence = matrix['automated_evidence'] as Map<String, dynamic>;
    final inventoryDomains =
        (inventory['domain_contracts'] as Map<String, dynamic>).keys.toSet();
    expect(evidence.keys.toSet(), inventoryDomains);

    final checks = (matrix['canonical_checks'] as List<dynamic>).cast<String>();
    expect(checks.toSet(), {
      'labels',
      'roles_and_states',
      'live_status',
      'tap_target_48',
      'text_200_percent',
      'wcag_contrast',
      'color_redundancy',
      'reading_order',
    });

    final paths = <String>{
      ...(matrix['shared_evidence'] as List<dynamic>).cast<String>(),
      for (final tests in evidence.values)
        ...(tests as List<dynamic>).cast<String>(),
    };
    for (final path in paths) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'missing $path');
      final source = file.readAsStringSync();
      expect(
        source.contains('test(') || source.contains('testWidgets('),
        isTrue,
        reason: '$path is not executable evidence',
      );
    }
  });

  test('icon-only buttons expose a discoverable tooltip', () {
    final findings = <String>[];
    for (final file in _dartFiles(Directory('lib'))) {
      final source = file.readAsStringSync();
      for (final call in _constructorCalls(source, 'IconButton')) {
        if (call.block.contains('tooltip:')) continue;
        findings.add('${file.path}:${call.line} IconButton missing tooltip');
      }
    }

    expect(
      findings,
      isEmpty,
      reason:
          'Controles apenas por ícone precisam de tooltip/label textual para '
          'tecnologia assistiva:\n${findings.join('\n')}',
    );
  });

  test('canonical text and control pairs meet WCAG AA contrast', () {
    final normalTextPairs =
        <({String name, Color foreground, Color background})>[
          (
            name: 'primary/background',
            foreground: AppTheme.textPrimary,
            background: AppTheme.backgroundAbyss,
          ),
          (
            name: 'primary/surface',
            foreground: AppTheme.textPrimary,
            background: AppTheme.surfaceSlate,
          ),
          (
            name: 'secondary/background',
            foreground: AppTheme.textSecondary,
            background: AppTheme.backgroundAbyss,
          ),
          (
            name: 'secondary/surface',
            foreground: AppTheme.textSecondary,
            background: AppTheme.surfaceSlate,
          ),
          (
            name: 'error/background',
            foreground: AppTheme.error,
            background: AppTheme.backgroundAbyss,
          ),
          (
            name: 'on-error/error-container',
            foreground: AppTheme.onErrorContainer,
            background: AppTheme.errorContainer,
          ),
        ];
    for (final pair in normalTextPairs) {
      expect(
        _contrast(pair.foreground, pair.background),
        greaterThanOrEqualTo(4.5),
        reason: pair.name,
      );
    }

    final controlPairs = <({String name, Color foreground, Color background})>[
      (
        name: 'primary CTA',
        foreground: AppTheme.backgroundAbyss,
        background: AppTheme.brass500,
      ),
      (
        name: 'focus/outline on background',
        foreground: AppTheme.brass400,
        background: AppTheme.backgroundAbyss,
      ),
      (
        name: 'support/control on background',
        foreground: AppTheme.frost400,
        background: AppTheme.backgroundAbyss,
      ),
    ];
    for (final pair in controlPairs) {
      expect(
        _contrast(pair.foreground, pair.background),
        greaterThanOrEqualTo(3),
        reason: pair.name,
      );
    }
  });

  test('physical TalkBack and VoiceOver evidence stays explicit', () {
    final manual = matrix['manual_screen_reader'] as Map<String, dynamic>;
    expect(manual.keys.toSet(), {'android', 'ios'});
    for (final entry in manual.entries) {
      final contract = entry.value as Map<String, dynamic>;
      expect(contract['reader'], isNotEmpty);
      expect(contract['status'], anyOf('pending_physical', 'pass'));
      expect((contract['required_routes'] as List<dynamic>).toSet(), {
        '/login',
        '/home',
        '/decks',
        '/collection',
        '/community',
        '/profile',
        '/battle/replays',
      });
    }
  });
}

Map<String, dynamic> _loadJson(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

Iterable<File> _dartFiles(Directory root) {
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}

Iterable<_ConstructorCall> _constructorCalls(
  String source,
  String constructor,
) sync* {
  var index = 0;
  while (index < source.length) {
    index = source.indexOf(constructor, index);
    if (index < 0) break;
    final before = index == 0 ? '' : source[index - 1];
    final afterIndex = index + constructor.length;
    final after = afterIndex >= source.length ? '' : source[afterIndex];
    if (_isIdentifierCharacter(before) || _isIdentifierCharacter(after)) {
      index += constructor.length;
      continue;
    }

    var cursor = afterIndex;
    while (cursor < source.length && source[cursor].trim().isEmpty) {
      cursor++;
    }
    String? namedConstructor;
    if (cursor < source.length && source[cursor] == '.') {
      final nameStart = ++cursor;
      while (cursor < source.length && _isIdentifierCharacter(source[cursor])) {
        cursor++;
      }
      namedConstructor = source.substring(nameStart, cursor);
      while (cursor < source.length && source[cursor].trim().isEmpty) {
        cursor++;
      }
    }
    if (namedConstructor == 'styleFrom' ||
        cursor >= source.length ||
        source[cursor] != '(') {
      index += constructor.length;
      continue;
    }

    final openParen = cursor;
    final end = _findMatchingParen(source, openParen);
    if (end == null) break;
    yield _ConstructorCall(
      source.substring(index, end + 1),
      '\n'.allMatches(source.substring(0, index)).length + 1,
    );
    index = end + 1;
  }
}

bool _isIdentifierCharacter(String character) {
  return character.isNotEmpty && RegExp(r'[A-Za-z0-9_]').hasMatch(character);
}

int? _findMatchingParen(String source, int openParen) {
  var depth = 0;
  for (var index = openParen; index < source.length; index++) {
    if (source[index] == '(') depth++;
    if (source[index] != ')') continue;
    depth--;
    if (depth == 0) return index;
  }
  return null;
}

double _contrast(Color first, Color second) {
  final lighter = first.computeLuminance() > second.computeLuminance()
      ? first.computeLuminance()
      : second.computeLuminance();
  final darker = first.computeLuminance() > second.computeLuminance()
      ? second.computeLuminance()
      : first.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}

class _ConstructorCall {
  const _ConstructorCall(this.block, this.line);

  final String block;
  final int line;
}
