import 'dart:io';

import 'package:test/test.dart';

import '../bin/sync_rules.dart' as rules;

const _fixture = '''
Magic: The Gathering Comprehensive Rules
These rules are effective as of June 19, 2026.

1. Game Concepts
100. General
100.1 These Magic rules apply to any Magic game with two or more players.
100.2 To play, each player needs their own deck of traditional Magic cards.
''';

void main() {
  group('Comprehensive Rules sync safety', () {
    test('write and failure-injection approvals require exact phrases', () {
      expect(rules.hasRulesWriteApproval(const {}), isFalse);
      expect(
        rules.hasRulesWriteApproval(const {
          rules.rulesWriteApprovalEnvironment: 'yes',
        }),
        isFalse,
      );
      expect(
        rules.hasRulesWriteApproval(const {
          rules.rulesWriteApprovalEnvironment: rules.rulesWriteApprovalPhrase,
        }),
        isTrue,
      );

      expect(rules.hasRulesFailureInjectionApproval(const {}), isFalse);
      expect(
        rules.hasRulesFailureInjectionApproval(const {
          rules.rulesFailureInjectionEnvironment:
              rules.rulesFailureInjectionPhrase,
        }),
        isTrue,
      );
    });

    test('arguments and official file lineage fail closed', () {
      expect(
        () => rules.validateRulesSyncArguments(const ['--chek']),
        throwsArgumentError,
      );
      expect(
        () => rules.validateRulesSyncArguments(const ['--from-file=']),
        throwsArgumentError,
      );
      expect(
        rules.isOfficialRulesSourceUrl(
          'https://media.wizards.com/2026/downloads/'
          'MagicCompRules%2020260619.txt',
        ),
        isTrue,
      );
      expect(
        rules.isOfficialRulesSourceUrl(
          'https://example.invalid/MagicCompRules 20260619.txt',
        ),
        isFalse,
      );
    });

    test('parses effective date, rows and deterministic row digest', () {
      expect(rules.extractRulesVersionDateFromText(_fixture), '20260619');
      final parsed = rules.parseComprehensiveRules(_fixture);
      expect(parsed, hasLength(2));
      expect(parsed.first.title, '100.1');
      expect(parsed.first.category, 'General');

      final reversed = parsed.reversed.toList();
      expect(
        rules.comprehensiveRulesRowsSha256(parsed),
        rules.comprehensiveRulesRowsSha256(reversed),
      );

      final snapshot = rules.RulesSnapshot(
        rulesText: _fixture,
        sourceReference:
            'https://media.wizards.com/2026/downloads/'
            'MagicCompRules 20260619.txt',
        versionDate: '20260619',
      );
      expect(
        () => rules.validateComprehensiveRulesSnapshot(
          snapshot,
          parsedRuleCount: parsed.length,
          minimumRuleRows: 2,
        ),
        returnsNormally,
      );
      expect(
        () => rules.validateComprehensiveRulesSnapshot(
          snapshot,
          parsedRuleCount: 1,
          minimumRuleRows: 2,
        ),
        throwsStateError,
      );
    });

    test('normalizes the cache to LF without changing the source digest', () {
      final crlfFixture = _fixture.replaceAll('\n', '\r\n');
      final legacyCarriageReturnFixture = _fixture.replaceAll('\n', '\r');
      final lfSnapshot = rules.RulesSnapshot(
        rulesText: _fixture,
        sourceReference:
            'https://media.wizards.com/2026/downloads/'
            'MagicCompRules 20260619.txt',
        versionDate: '20260619',
      );
      final crlfSnapshot = rules.RulesSnapshot(
        rulesText: crlfFixture,
        sourceReference: lfSnapshot.sourceReference,
        versionDate: lfSnapshot.versionDate,
      );

      expect(crlfSnapshot.rulesText, lfSnapshot.rulesText);
      expect(crlfSnapshot.rulesText, isNot(contains('\r')));
      expect(crlfSnapshot.contentSha256, lfSnapshot.contentSha256);
      expect(
        rules.comprehensiveRulesContentSha256(legacyCarriageReturnFixture),
        lfSnapshot.contentSha256,
      );
    });

    test('freshness requires version, raw hash, row hash, count and cache', () {
      final snapshot = rules.RulesSnapshot(
        rulesText: _fixture,
        sourceReference:
            'https://media.wizards.com/2026/downloads/'
            'MagicCompRules 20260619.txt',
        versionDate: '20260619',
      );
      final parsed = rules.parseComprehensiveRules(_fixture);
      final rowsSha = rules.comprehensiveRulesRowsSha256(parsed);
      final alignedDatabase = rules.RulesDatabaseState(
        rulesTableExists: true,
        syncStateTableExists: true,
        ruleCount: parsed.length,
        sourceReference: snapshot.sourceReference,
        versionDate: snapshot.versionDate,
        contentSha256: snapshot.contentSha256,
        rowsSha256: rowsSha,
        persistedRowsSha256: rowsSha,
        lastSyncAt: '2026-07-16T00:00:00Z',
      );
      final alignedCache = rules.RulesCacheState(
        exists: true,
        versionDate: snapshot.versionDate,
        contentSha256: snapshot.contentSha256,
      );

      final passing = rules.evaluateRulesFreshness(
        snapshot: snapshot,
        parsedRuleCount: parsed.length,
        parsedRowsSha256: rowsSha,
        databaseState: alignedDatabase,
        cacheState: alignedCache,
      );
      expect(passing.isFresh, isTrue);
      expect(passing.toJson(), containsPair('mutations_performed', false));

      final failing = rules.evaluateRulesFreshness(
        snapshot: snapshot,
        parsedRuleCount: parsed.length,
        parsedRowsSha256: rowsSha,
        databaseState: const rules.RulesDatabaseState(
          rulesTableExists: true,
          syncStateTableExists: true,
          ruleCount: 1,
          versionDate: '20260227',
          contentSha256: 'old-content',
          rowsSha256: 'old-rows',
          persistedRowsSha256: null,
        ),
        cacheState: const rules.RulesCacheState(
          exists: true,
          versionDate: '20260417',
          contentSha256: 'old-cache',
        ),
      );
      expect(failing.isFresh, isFalse);
      expect(
        failing.failureReasons,
        containsAll(const [
          'database_version_mismatch',
          'database_content_hash_mismatch',
          'database_rows_hash_mismatch',
          'database_persisted_rows_hash_mismatch',
          'database_rule_count_mismatch',
          'local_cache_version_mismatch',
          'local_cache_content_hash_mismatch',
        ]),
      );
    });

    test(
      'failure injection aborts before metadata and supports rollback',
      () async {
        final events = <String>[];
        await rules.executeRulesSnapshotMutation(
          replaceRules: () async => events.add('rules'),
          writeMetadata: () async => events.add('metadata'),
        );
        expect(events, ['rules', 'metadata']);

        var state = <String, String>{'rules': 'old', 'metadata': 'old'};
        final before = Map<String, String>.from(state);

        Future<void> simulatedTransaction(
          Future<void> Function() action,
        ) async {
          final snapshot = Map<String, String>.from(state);
          try {
            await action();
          } catch (_) {
            state = snapshot;
            rethrow;
          }
        }

        await expectLater(
          simulatedTransaction(
            () => rules.executeRulesSnapshotMutation(
              replaceRules: () async => state['rules'] = 'new',
              writeMetadata: () async => state['metadata'] = 'new',
              injectFailureAfterRules: true,
            ),
          ),
          throwsStateError,
        );
        expect(state, before);
      },
    );

    test(
      'source keeps check read-only and mutation inside one transaction',
      () {
        final source = File('bin/sync_rules.dart').readAsStringSync();
        final gate = source.indexOf(
          'if (!checkOnly && !hasRulesWriteApproval(Platform.environment))',
        );
        final snapshotLoad = source.indexOf(
          'final snapshot = await _loadRulesSnapshot',
        );
        final connect = source.indexOf('await db.connect()');
        final transaction = source.indexOf('pool.runTx<bool>');
        final replacement = source.indexOf(
          'replaceRules: () => _replaceRules(session, parsed)',
        );
        final metadata = source.indexOf("'rules_source_url'");
        final cacheWrite = source.indexOf(
          'await _writeRulesCacheAtomically(snapshot.rulesText)',
        );

        expect(source, contains('--check'));
        expect(source, contains('[CHECK READ-ONLY]'));
        expect(source, contains('pg_advisory_xact_lock'));
        expect(
          source,
          contains('LOCK TABLE rules IN SHARE ROW EXCLUSIVE MODE'),
        );
        expect(
          source,
          contains('LOCK TABLE sync_state IN SHARE ROW EXCLUSIVE MODE'),
        );
        expect(source, contains('rules_content_sha256'));
        expect(source, contains('rules_rows_sha256'));
        expect(source, contains('--test-fail-after-rules'));
        expect(source, isNot(contains('_setSyncState(pool')));
        expect(gate, greaterThanOrEqualTo(0));
        expect(gate, lessThan(snapshotLoad));
        expect(gate, lessThan(connect));
        expect(transaction, lessThan(replacement));
        expect(replacement, lessThan(metadata));
        expect(transaction, lessThan(cacheWrite));
      },
    );

    test('CLI refuses mutation before reading a file or connecting', () async {
      final environment =
          Map<String, String>.from(Platform.environment)
            ..[rules.rulesWriteApprovalEnvironment] = ''
            ..[rules.rulesFailureInjectionEnvironment] = '';
      final result = await Process.run(Platform.resolvedExecutable, const [
        'run',
        'bin/sync_rules.dart',
        '--from-file=/definitely/missing/rules.txt',
        '--source-url=https://media.wizards.com/2026/downloads/'
            'MagicCompRules%2020260619.txt',
      ], environment: environment);
      expect(result.exitCode, isNot(0));
      expect(result.stderr.toString(), contains('PostgreSQL write refused'));
      expect(
        result.stderr.toString(),
        isNot(contains('Arquivo não encontrado')),
      );
    });
  });
}
