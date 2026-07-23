import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final matrix = _loadJson('test/ui/fixtures/ui_state_matrix.json');
  final surfaceInventory = _loadJson(
    'test/ui/fixtures/ui_surface_inventory.json',
  );

  test('every product domain classifies every canonical UI state', () {
    final canonicalStates = (matrix['canonical_states'] as List<dynamic>)
        .cast<String>()
        .toSet();
    final domains = matrix['domains'] as Map<String, dynamic>;
    final inventoryDomains =
        (surfaceInventory['domain_contracts'] as Map<String, dynamic>).keys
            .toSet();
    final findings = <String>[];

    expect(domains.keys.toSet(), inventoryDomains);
    expect(canonicalStates, hasLength(15));

    for (final entry in domains.entries) {
      final domain = entry.key;
      final contract = entry.value as Map<String, dynamic>;
      final covered = (contract['covered'] as List<dynamic>).cast<String>();
      final notApplicable = (contract['not_applicable'] as List<dynamic>)
          .cast<String>();
      final classified = <String>{...covered, ...notApplicable};
      final overlap = covered.toSet().intersection(notApplicable.toSet());

      if (covered.length != covered.toSet().length) {
        findings.add('$domain repeats a covered state');
      }
      if (notApplicable.length != notApplicable.toSet().length) {
        findings.add('$domain repeats a not-applicable state');
      }
      if (overlap.isNotEmpty) {
        findings.add('$domain classifies twice: ${overlap.join(', ')}');
      }
      if (classified.difference(canonicalStates).isNotEmpty) {
        findings.add(
          '$domain has unknown states: '
          '${classified.difference(canonicalStates).join(', ')}',
        );
      }
      if (canonicalStates.difference(classified).isNotEmpty) {
        findings.add(
          '$domain leaves states undecided: '
          '${canonicalStates.difference(classified).join(', ')}',
        );
      }
    }

    expect(
      findings,
      isEmpty,
      reason:
          'Cada domínio deve classificar todos os estados como coberto ou '
          'não aplicável:\n${findings.join('\n')}',
    );
  });

  test('state claims point to executable sources, anchors and tests', () {
    final domains = matrix['domains'] as Map<String, dynamic>;
    final findings = <String>[];

    for (final entry in domains.entries) {
      final domain = entry.key;
      final contract = entry.value as Map<String, dynamic>;
      final sources = (contract['sources'] as List<dynamic>).cast<String>();
      final tests = (contract['tests'] as List<dynamic>).cast<String>();
      final anchors = (contract['anchors'] as List<dynamic>).cast<String>();
      final inputPolicy = contract['input_policy'] as String? ?? '';
      final rawErrorPolicy = contract['raw_error_policy'] as String? ?? '';

      if (sources.isEmpty || tests.isEmpty || anchors.isEmpty) {
        findings.add('$domain needs source, test and anchor evidence');
        continue;
      }

      final sourceBuffer = StringBuffer();
      for (final path in sources) {
        final file = File(path);
        if (!file.existsSync()) {
          findings.add('$domain source is missing: $path');
          continue;
        }
        sourceBuffer.writeln(file.readAsStringSync());
      }
      for (final anchor in anchors) {
        if (!sourceBuffer.toString().contains(anchor)) {
          findings.add('$domain anchor is not in its sources: $anchor');
        }
      }

      for (final path in tests) {
        final file = File(path);
        if (!file.existsSync()) {
          findings.add('$domain test is missing: $path');
          continue;
        }
        final source = file.readAsStringSync();
        if (!source.contains('test(') && !source.contains('testWidgets(')) {
          findings.add('$domain evidence has no executable test: $path');
        }
      }

      if (!inputPolicy.startsWith('tested:') &&
          !inputPolicy.startsWith('not_applicable:')) {
        findings.add('$domain input policy is not decided');
      }
      if (!rawErrorPolicy.startsWith('sanitized:')) {
        findings.add('$domain raw error policy is not sanitized');
      }
    }

    expect(
      findings,
      isEmpty,
      reason: 'Evidência de estado incompleta:\n${findings.join('\n')}',
    );
  });

  test('page loading states use the accessible live-region component', () {
    final requiredAnchors = <String>{
      'battle-replays-loading-state',
      'binder-list-loading-',
      'card-search-loading',
      'community-explore-loading',
      'community-following-loading',
      'community-users-loading',
      'deck-details-loading-state',
      'deck-list-loading-state',
      'messages-inbox-loading',
      'notifications-loading',
      'post-game-loading',
      'set-cards-loading',
      'sets-catalog-loading',
      'trade-detail-loading-state',
      'trade-inbox-loading',
      'user-profile-loading',
      'user-search-loading',
    };
    final findings = <String>[];

    for (final file in _featureDartFiles()) {
      final source = file.readAsStringSync();
      for (final anchor in requiredAnchors.toList()) {
        final anchorOffset = source.indexOf(anchor);
        if (anchorOffset < 0) continue;
        final start = anchorOffset > 240 ? anchorOffset - 240 : 0;
        final end = anchorOffset + 240 < source.length
            ? anchorOffset + 240
            : source.length;
        final neighborhood = source.substring(start, end);
        if (!neighborhood.contains('AppStatePanel.loading(')) {
          findings.add('${file.path}: $anchor is not an accessible loading');
        }
        requiredAnchors.remove(anchor);
      }
    }

    if (requiredAnchors.isNotEmpty) {
      findings.add('loading anchors not found: ${requiredAnchors.join(', ')}');
    }
    expect(
      findings,
      isEmpty,
      reason:
          'Carregamentos de página precisam anunciar estado em região viva:\n'
          '${findings.join('\n')}',
    );
  });

  test('screen/widget code does not render raw exception expressions', () {
    final forbidden = <RegExp>[
      RegExp(r'''Text\s*\(\s*(?:e|error|exception)\.toString\s*\('''),
      RegExp(r'''Text\s*\(\s*['"]\$(?:e|error|exception)['"]'''),
      RegExp(r'''(?:message|title):\s*(?:e|error|exception)\.toString\s*\('''),
      RegExp(
        r'''content:\s*Text\s*\(\s*(?:result|response|payload|data)'''
        r'''\s*\[\s*['"]error['"]\s*\]''',
      ),
    ];
    final findings = <String>[];

    for (final file in _featureDartFiles()) {
      if (!file.path.contains('/screens/') &&
          !file.path.contains('/widgets/')) {
        continue;
      }
      final source = file.readAsStringSync();
      for (final pattern in forbidden) {
        for (final match in pattern.allMatches(source)) {
          final line =
              '\n'.allMatches(source.substring(0, match.start)).length + 1;
          findings.add('${file.path}:$line raw error expression');
        }
      }
    }

    expect(
      findings,
      isEmpty,
      reason:
          'Exception/payload técnico não pode ser renderizado diretamente:\n'
          '${findings.join('\n')}',
    );
  });
}

Map<String, dynamic> _loadJson(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

List<File> _featureDartFiles() {
  return Directory('lib/features')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList(growable: false);
}
