import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  final repoRoot = _findRepoRoot();

  test('app and server Dart surfaces are valid UTF-8 without mojibake', () {
    final failures = <String>[];

    for (final relativeRoot in const [
      'server/lib',
      'server/routes',
      'app/lib',
    ]) {
      final root = Directory('${repoRoot.path}/$relativeRoot');
      for (final entity in root.listSync(recursive: true, followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }

        final relativePath = entity.path.substring(repoRoot.path.length + 1);
        late final String source;
        try {
          source = utf8.decode(entity.readAsBytesSync(), allowMalformed: false);
        } on FormatException catch (error) {
          failures.add('$relativePath: UTF-8 inválido ($error)');
          continue;
        }

        for (final marker in _mojibakeMarkers) {
          if (source.contains(marker)) {
            failures.add('$relativePath: marcador corrompido "$marker"');
          }
        }
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('optimize app-facing progress and warning literals stay readable', () {
    final asyncSource = File(
      '${repoRoot.path}/server/lib/ai/optimize_route_internal.dart',
    ).readAsStringSync(encoding: utf8);
    final syncSource = File(
      '${repoRoot.path}/server/routes/ai/optimize/index.dart',
    ).readAsStringSync(encoding: utf8);

    for (final literal in const [
      'Preparando referências do commander...',
      'Consultando IA para sugestões...',
      'Pulando IA (modo determinístico)...',
      'Preenchendo com cartas sinérgicas...',
      'Complete mode não atingiu qualidade mínima.',
    ]) {
      expect(asyncSource, contains(literal));
    }

    for (final literal in const [
      'A execução da otimização falhou; o deck original foi preservado em estado saudável.',
      'Complete mode não atingiu qualidade mínima para montagem competitiva.',
      '🔒 Gate de qualidade removeu',
      '🔒 Escopo aggressive limitado a',
    ]) {
      expect(syncSource, contains(literal));
    }
  });
}

const _mojibakeMarkers = <String>[
  'Ãƒ',
  'Ã£',
  'Ã©',
  'Ãª',
  'Ãµ',
  'Ã¡',
  'Ã­',
  'Ã³',
  'Ãº',
  'Ã§',
  'ðŸ',
  'â€',
  'â€”',
  'â€œ',
  'â€',
  'â†',
  'âœ',
  'âš',
  'â„',
  'â•',
  'ï¸',
  'Â ',
  '�',
];

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (current.parent.path != current.path) {
    if (Directory('${current.path}/server').existsSync() &&
        Directory('${current.path}/app').existsSync()) {
      return current;
    }
    current = current.parent;
  }
  throw StateError('Não foi possível localizar a raiz do repositório.');
}
