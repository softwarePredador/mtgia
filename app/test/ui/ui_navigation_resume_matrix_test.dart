import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final file = File('test/ui/fixtures/ui_navigation_resume_matrix.json');
  final matrix = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  test(
    'navigation/resume matrix covers every required scenario exactly once',
    () {
      expect(matrix['schema_version'], 1);
      final required = (matrix['required_scenarios'] as List).cast<String>();
      final scenarios = (matrix['scenarios'] as List)
          .cast<Map<String, dynamic>>();
      final ids = scenarios
          .map((scenario) => scenario['id'] as String)
          .toList();

      expect(ids.toSet().length, ids.length);
      expect(ids.toSet(), required.toSet());
    },
  );

  test(
    'every scenario points to executable evidence and live source anchors',
    () {
      final scenarios = (matrix['scenarios'] as List)
          .cast<Map<String, dynamic>>();
      final findings = <String>[];

      for (final scenario in scenarios) {
        final id = scenario['id'] as String;
        final expectation = scenario['expectation']?.toString().trim() ?? '';
        if (expectation.isEmpty) findings.add('$id has no expectation');

        final sources = (scenario['sources'] as Map<String, dynamic>).map(
          (path, anchors) => MapEntry(path, (anchors as List).cast<String>()),
        );
        for (final source in sources.entries) {
          final sourceFile = File(source.key);
          if (!sourceFile.existsSync()) {
            findings.add('$id missing source ${source.key}');
            continue;
          }
          final contents = sourceFile.readAsStringSync();
          for (final anchor in source.value) {
            if (!contents.contains(anchor)) {
              findings.add('$id missing anchor "$anchor" in ${source.key}');
            }
          }
        }

        for (final testPath in (scenario['tests'] as List).cast<String>()) {
          if (!File(testPath).existsSync()) {
            findings.add('$id missing test $testPath');
          }
        }
      }

      expect(
        findings,
        isEmpty,
        reason:
            'A matriz deve apontar somente para código e testes atuais:\n'
            '${findings.join('\n')}',
      );
    },
  );

  test(
    'manual browser proof records passed and remaining release evidence',
    () {
      final manual = matrix['manual_web'] as Map<String, dynamic>;
      expect(manual['status'], 'partial');
      expect(manual['build_sha256'], matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(
        (manual['required'] as List).cast<String>(),
        containsAll(<String>[
          'authenticated_refresh',
          'collection_back_forward',
          'battle_direct_url',
          'card_detail_direct_url',
          'session_expiry_redirect',
          'draft_restore',
        ]),
      );
      expect(
        (manual['passed'] as List).cast<String>(),
        containsAll(<String>[
          'authenticated_refresh',
          'collection_back_forward',
          'battle_direct_url',
          'card_detail_route_and_safe_reload_state',
          'draft_restore',
          'disposable_account_and_deck_cleanup',
        ]),
      );
      expect(
        (manual['remaining'] as List).cast<String>(),
        containsAll(<String>[
          'card_detail_data_reload_after_backend_publish',
          'live_runtime_401_interception',
        ]),
      );
      expect(
        (manual['automated_evidence'] as List).cast<String>(),
        containsAll(<String>[
          'session_expiry_redirect',
          'card_detail_exact_id_contract',
        ]),
      );
    },
  );
}
