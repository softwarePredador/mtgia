import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// BT-GATE-007: todo integration_test do app tem trilha, e a trilha
/// web_hermetic roda no `quality_gate.sh full` sem tocar a API de produção.
void main() {
  const lanes = {'web_hermetic', 'web_backend', 'device', 'ui_proof', 'triage'};
  final manifest =
      jsonDecode(
            File(
              'config/integration_test_lanes.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final tests = (manifest['tests'] as List).cast<Map<String, dynamic>>();

  group('manifesto de trilhas dos integration_test', () {
    test('cada arquivo tem exatamente uma trilha conhecida e um motivo', () {
      expect(manifest['schema'], 'manaloom.integration_test_lanes.v1');
      expect((manifest['lanes'] as Map).keys.toSet(), lanes);

      final onDisk =
          Directory('../app/integration_test')
              .listSync()
              .whereType<File>()
              .map((file) => file.uri.pathSegments.last)
              .where((name) => name.endsWith('_test.dart'))
              .map((name) => 'app/integration_test/$name')
              .toSet();
      final paths = tests.map((entry) => entry['path'] as String).toList();

      expect(paths.toSet().length, paths.length, reason: 'entrada duplicada');
      expect(paths.toSet(), onDisk);
      for (final entry in tests) {
        expect(lanes, contains(entry['lane']), reason: '${entry['path']}');
        expect(
          (entry['reason'] as String).trim(),
          isNotEmpty,
          reason: '${entry['path']}',
        );
      }
      expect(tests.where((entry) => entry['lane'] == 'web_hermetic'), isNotEmpty);
    });

    test('a prova de UI fica com os arquivos do digest de UI', () {
      final digest =
          File('../scripts/manaloom_ui_source_digest.sh').readAsStringSync();
      for (final entry in tests) {
        final inDigest = digest.contains('"${entry['path']}"');
        expect(
          entry['lane'] == 'ui_proof',
          inDigest,
          reason: '${entry['path']} está no digest de UI: $inDigest',
        );
      }
    });
  });

  group('etapa de integração no gate', () {
    final gate =
        File('../scripts/manaloom_integration_lane_gate.sh').readAsStringSync();

    test('full roda a trilha web_hermetic', () {
      final qualityGate = File('../scripts/quality_gate.sh').readAsStringSync();
      final full = RegExp(
        r'\n    full\)\n(.*?)\n      ;;',
        dotAll: true,
      ).firstMatch(qualityGate);

      expect(full, isNotNull);
      expect(full!.group(1), contains('run_integration_lanes'));
      expect(qualityGate, contains('scripts/manaloom_integration_lane_gate.sh'));
      expect(gate, contains('LANE="web_hermetic"'));
    });

    test('a API fica presa em loopback e não vem do ambiente', () {
      expect(gate, contains('LOOPBACK_API_BASE_URL="http://127.0.0.1:9"'));
      expect(
        gate,
        contains(r'--dart-define=API_BASE_URL="$LOOPBACK_API_BASE_URL"'),
      );
      expect(gate, isNot(contains(r'${API_BASE_URL')));
      expect(gate, isNot(contains(r'$API_BASE_URL')));
    });

    test('falha fechado: manifesto, trilha vazia e teste vermelho', () {
      expect(gate, contains('set -euo pipefail'));
      expect(gate, contains(r'python3 "$LANES_TOOL" check'));
      expect(gate, contains('o gate nao aceita trilha vazia'));
      expect(gate, contains("grep -q 'All tests passed'"));
      expect(gate, contains(r'if [[ "$failures" -gt 0 ]]; then'));
    });
  });
}
