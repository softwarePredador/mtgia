import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../lib/privacy/retention_cleanup.dart';
import 'support/scripted_pool.dart';

/// D-70 (BT-PRIV-002), sem banco: a limpeza por prazo apaga só o que o
/// inventário de retenção manda, não aceita prazo pela linha de comando e só
/// liga com a aprovação explícita.
void main() {
  final inventory =
      jsonDecode(
            File(
              '../docs/privacy/data_retention_inventory.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final section = inventory['retention_cleanup'] as Map<String, dynamic>;
  final tables = (inventory['tables'] as Map).cast<String, Map>();
  final source = File('lib/privacy/retention_cleanup.dart').readAsStringSync();

  group('regras x inventário', () {
    test('a seção retention_cleanup e o código têm as mesmas regras, nos '
        'dois sentidos', () {
      expect(section['job'], retentionCleanupJobName);
      expect(section['contract'], retentionCleanupContract);
      expect(section['decision'], 'D-70');
      final fromInventory = {
        for (final rule in (section['rules'] as List).cast<Map>())
          rule['id'] as String: '${rule['table']}:${rule['max_age_minutes']}',
      };
      final fromCode = {
        for (final rule in retentionCleanupRules)
          rule.id: '${rule.table}:${rule.maxAge.inMinutes}',
      };
      expect(fromCode, fromInventory);
    });

    test('só apaga tabela com prazo (ttl) que o inventário põe neste job', () {
      for (final rule in retentionCleanupRules) {
        final retention = tables[rule.table]!['retention'] as Map;
        expect(retention['class'], 'ttl', reason: rule.table);
        expect(
          '${retention['enforced_by']}',
          allOf(
            contains(retentionCleanupJobName),
            contains(retentionCleanupContract),
          ),
          reason: rule.table,
        );
      }
    });

    test('toda tabela que o inventário põe neste job tem regra', () {
      final ruleTables = {for (final rule in retentionCleanupRules) rule.table};
      for (final MapEntry(key: name, value: entry) in tables.entries) {
        final enforcedBy = '${(entry['retention'] as Map)['enforced_by']}';
        if (!enforcedBy.contains(retentionCleanupJobName)) continue;
        expect(ruleTables, contains(name));
      }
    });

    test('os jobs de IA seguem a D-32 (24 h)', () {
      final d32 = (inventory['decided_retention'] as List)
          .cast<Map>()
          .singleWhere((rule) => rule['decision'] == 'D-32');
      for (final table in (d32['applies_to'] as List).cast<String>()) {
        final rules = retentionCleanupRules.where(
          (rule) => rule.table == table,
        );
        expect(rules, isNotEmpty, reason: table);
        for (final rule in rules) {
          expect(rule.maxAge, const Duration(hours: 24), reason: table);
        }
      }
    });

    test('a reserva de cota só sai depois do TTL do PlanService', () {
      final planService = File('lib/plan_service.dart').readAsStringSync();
      final match = RegExp(
        r'static const _reservationTtl = Duration\(minutes: (\d+)\);',
      ).firstMatch(planService);
      expect(match, isNotNull);
      final serviceTtl = Duration(minutes: int.parse(match!.group(1)!));
      final rule = retentionCleanupRules.singleWhere(
        (rule) => rule.id == 'ai_logs_unconfirmed_plan_reservation_10min',
      );
      expect(rule.maxAge, greaterThanOrEqualTo(serviceTtl));
      expect(rule.filter, contains('success = FALSE'));
    });

    test('o único DELETE do job é o da regra, com tabela e filtro do '
        'código', () {
      expect('DELETE FROM'.allMatches(source), hasLength(1));
      expect(source, contains(r"'DELETE FROM $table WHERE $_where'"));
      for (final rule in retentionCleanupRules) {
        expect(rule.table, matches(RegExp(r'^[a-z_]+$')));
        expect(rule.deleteSql, startsWith('DELETE FROM ${rule.table} WHERE '));
        expect(
          rule.deleteSql,
          endsWith(
            'created_at < CURRENT_TIMESTAMP - '
            'make_interval(mins => ${rule.maxAge.inMinutes})',
          ),
        );
      }
    });
  });

  group('linha de comando', () {
    test('agendado por padrão; modos conhecidos', () {
      expect(parseRetentionCleanupArguments(const []), (
        RetentionCleanupMode.scheduled,
        null,
      ));
      expect(
        parseRetentionCleanupArguments(const ['--mode', 'dry-run'])?.$1,
        RetentionCleanupMode.dryRun,
      );
      expect(
        parseRetentionCleanupArguments(const ['--dry-run'])?.$1,
        RetentionCleanupMode.dryRun,
      );
      expect(
        parseRetentionCleanupArguments(const ['--mode=activate'])?.$1,
        RetentionCleanupMode.activate,
      );
      expect(parseRetentionCleanupArguments(const ['--output-dir', '/tmp/x']), (
        RetentionCleanupMode.scheduled,
        '/tmp/x',
      ));
    });

    test('prazo não entra pela linha de comando', () {
      for (final args in const [
        ['--retention-days=1'],
        ['--ai-log-retention-days=1'],
        ['--job-retention-minutes', '1'],
        ['--reservation-ttl-minutes=1'],
        ['--rate-limit-retention-hours=1'],
        ['--mode', 'apagar-tudo'],
        ['--mode'],
      ]) {
        expect(parseRetentionCleanupArguments(args), isNull, reason: '$args');
      }
    });
  });

  test('ativar e pausar exigem a aprovação explícita, antes de tocar no '
      'banco', () async {
    for (final mode in [
      RetentionCleanupMode.activate,
      RetentionCleanupMode.deactivate,
    ]) {
      final pool = ScriptedPool(const []);
      await expectLater(
        RetentionCleanupRunner(pool).run(
          mode: mode,
          runId: 'teste',
          environment: const {retentionCleanupWriteApprovalEnvironment: 'sim'},
        ),
        throwsA(isA<RetentionCleanupRefused>()),
      );
      expect(pool.executedCount, 0, reason: mode.wireName);
    }
  });

  test('a linha de recibo tem o marcador', () {
    expect(
      retentionCleanupReceiptLine({'status': 'ok'}),
      '$retentionCleanupReceiptMarker {"status":"ok"}',
    );
  });
}
