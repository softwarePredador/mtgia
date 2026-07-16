import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'interactive fields keep stable keys, labels, and validation contracts',
    () {
      final findings = <_FieldFinding>[];
      final root = Directory('lib');

      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        for (final constructor in _constructors) {
          findings.addAll(_scanConstructor(entity.path, source, constructor));
        }
      }

      expect(
        findings,
        isEmpty,
        reason:
            'Campos interativos precisam de key estável, texto de orientação e '
            'validação/semântica quando aplicável:\n${findings.join('\n')}',
      );
    },
  );
}

const _constructors = <String>[
  'TextFormField',
  'TextField',
  'DropdownButtonFormField',
  'Slider',
  'SwitchListTile',
];

Iterable<_FieldFinding> _scanConstructor(
  String path,
  String source,
  String constructor,
) sync* {
  var index = 0;
  while (index < source.length) {
    index = source.indexOf(constructor, index);
    if (index < 0) break;

    final openParen = source.indexOf('(', index);
    if (openParen < 0) break;

    final semicolon = source.indexOf(';', index);
    if (semicolon >= 0 && semicolon < openParen) {
      index += constructor.length;
      continue;
    }

    final end = _findMatchingParen(source, openParen);
    if (end == null) {
      index += constructor.length;
      continue;
    }

    final block = source.substring(index, end + 1);
    final line = '\n'.allMatches(source.substring(0, index)).length + 1;
    final missing = _missingContract(constructor, block);
    if (missing.isNotEmpty) {
      yield _FieldFinding(path, line, constructor, missing);
    }
    index = end + 1;
  }
}

int? _findMatchingParen(String source, int openParen) {
  var depth = 0;
  for (var i = openParen; i < source.length; i++) {
    final char = source[i];
    if (char == '(') depth++;
    if (char == ')') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return null;
}

List<String> _missingContract(String constructor, String block) {
  final missing = <String>[];
  if (constructor != 'Slider' && !block.contains('key:')) {
    missing.add('key');
  }
  if (constructor == 'TextFormField' && !block.contains('validator:')) {
    missing.add('validator');
  }
  if (constructor == 'Slider' &&
      !block.contains('semanticFormatterCallback:')) {
    missing.add('semanticFormatterCallback');
  }
  if ((constructor == 'TextField' || constructor == 'TextFormField') &&
      !block.contains('decoration:')) {
    missing.add('decoration');
  }
  if ((constructor == 'TextField' || constructor == 'TextFormField') &&
      !block.contains('labelText:') &&
      !block.contains('hintText:') &&
      !block.contains('semanticLabel:')) {
    missing.add('labelText/hintText');
  }
  return missing;
}

class _FieldFinding {
  const _FieldFinding(this.path, this.line, this.constructor, this.missing);

  final String path;
  final int line;
  final String constructor;
  final List<String> missing;

  @override
  String toString() {
    return '$path:$line $constructor missing ${missing.join(', ')}';
  }
}
