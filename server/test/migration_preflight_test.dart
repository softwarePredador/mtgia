import 'dart:io';

import 'package:server/migration_preflight.dart';
import 'package:test/test.dart';

/// BT-DB-002 e BT-DB-003: o preflight classifica o banco pelo ledger antes de
/// qualquer DDL; o perfil misto para o runner sem escrever.
void main() {
  const code = <MigrationIdentity>[
    (version: '057', name: 'x057'),
    (version: '058', name: 'snapshot_trade_item_identity'),
    (version: '059', name: 'align_trade_items_owner_fk'),
    (version: '060', name: 'account_deletion_outbox'),
    (version: '063', name: 'commander_learning_snapshot_in_full'),
  ];

  MigrationPreflightResult classify(
    List<MigrationIdentity>? ledger, {
    int? accounts = 0,
  }) => classifyMigrationSource(
    code: code,
    state: MigrationLedgerState(ledger: ledger, userAccounts: accounts),
  );

  test('banco novo do bootstrap: sem ledger e sem contas', () {
    final result = classify(null);
    expect(result.profile, MigrationSourceProfile.semLedger);
    expect(result.accepted, isTrue);
    expect(result.pending, ['057', '058', '059', '060', '063']);
    final empty = classify(const []);
    expect(empty.profile, MigrationSourceProfile.semLedger);
  });

  test('canônico: o ledger é um prefixo da lista, com os mesmos nomes', () {
    final result = classify(code.take(2).toList());
    expect(result.profile, MigrationSourceProfile.canonico);
    expect(result.reasons, isEmpty);
    expect(result.pending, ['059', '060', '063']);
    expect(result.latestExecuted, '058');
    expect(classify(code).pending, isEmpty);
    expect(result.toJson()['perfil'], 'canonico');
  });

  test('misto: versão do ledger que o código não conhece', () {
    final result = classify([
      ...code.take(2),
      (version: '061', name: 'convite_de_outra_linha'),
    ]);
    expect(result.profile, MigrationSourceProfile.misto);
    expect(result.accepted, isFalse);
    expect(result.reasons.single, contains('061'));
    expect(result.reasons.single, contains('não existe neste código'));
  });

  test('misto: mesmo número com outro nome', () {
    final result = classify([
      code.first,
      (version: '058', name: 'outra_migration_058'),
    ]);
    expect(result.profile, MigrationSourceProfile.misto);
    expect(result.reasons.single, contains('"outra_migration_058"'));
    expect(result.reasons.single, contains('"snapshot_trade_item_identity"'));
  });

  test('misto: pendente anterior à última executada', () {
    final result = classify([code[0], code[1], code[3]]);
    expect(result.profile, MigrationSourceProfile.misto);
    expect(result.reasons.single, contains('a 059'));
    expect(result.reasons.single, contains('060, posterior'));
  });

  test('misto: sem ledger, mas com contas em users', () {
    expect(classify(null, accounts: 3).profile, MigrationSourceProfile.misto);
    expect(
      classify(const [], accounts: 1).reasons.single,
      contains('schema_migrations está vazia'),
    );
    expect(
      classify(null, accounts: null).profile,
      MigrationSourceProfile.semLedger,
    );
  });

  test('lista do código fora de ordem ou repetida é erro do código', () {
    expect(
      () => classifyMigrationSource(
        code: [code[1], code[0]],
        state: const MigrationLedgerState(ledger: null, userAccounts: 0),
      ),
      throwsStateError,
    );
    expect(
      () => classifyMigrationSource(
        code: [code[0], code[0]],
        state: const MigrationLedgerState(ledger: null, userAccounts: 0),
      ),
      throwsStateError,
    );
  });

  group('runner (bin/migrate.dart)', () {
    final source = File('bin/migrate.dart').readAsStringSync();
    final main = source.substring(
      source.indexOf('void main(List<String> args)'),
    );

    test('o preflight vem antes de qualquer DDL na aplicação', () {
      final apply = main.substring(main.indexOf('// Apply mode only.'));
      final preflight = apply.indexOf('runMigrationPreflight(');
      final firstDdl = apply.indexOf(
        'CREATE TABLE IF NOT EXISTS schema_migrations',
      );
      expect(preflight, greaterThan(0));
      expect(firstDdl, greaterThan(preflight));
      expect(
        apply.substring(preflight, firstDdl),
        allOf(contains('if (!preflight.accepted)'), contains('exitCode = 3')),
      );
    });

    test('o rollback também para no perfil misto antes de escrever', () {
      final rollback = main.substring(
        main.indexOf('if (rollbackRequested) {\n      final preflight'),
      );
      final preflight = rollback.indexOf('runMigrationPreflight(');
      final firstWrite = rollback.indexOf('connection.runTx((tx)');
      expect(preflight, greaterThanOrEqualTo(0));
      expect(firstWrite, greaterThan(preflight));
    });

    test('--preflight só lê e --target exige uma versão da lista', () {
      expect(
        main,
        contains('final readOnlyRequested = showStatus || showPreflight;'),
      );
      expect(main, contains('writeRequested: !readOnlyRequested'));
      expect(
        main,
        contains("!migrations.any((item) => item.version == targetVersion)"),
      );
    });
  });
}
