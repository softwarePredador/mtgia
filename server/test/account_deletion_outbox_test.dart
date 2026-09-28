import 'dart:io';

import 'package:test/test.dart';

import '../bin/migrate.dart' as migrate;
import '../lib/battle/interactive_battle_contract.dart';
import '../lib/endpoint_cache.dart';
import '../lib/privacy/account_deletion_outbox.dart';
import '../lib/user_data_privacy_service.dart';

/// D-68 (BT-PRIV-002), sem banco: a migration 060 cria o outbox com o DDL
/// aprovado, o baseline acompanha, a lista de consumidores do código é a do
/// CHECK, e a exclusão grava o outbox na transação do recibo.
void main() {
  final migration060 = migrate.migrations.singleWhere(
    (migration) => migration.version == '060',
  );
  final bootstrap = File('database_setup.sql').readAsStringSync();
  final service = File('lib/user_data_privacy_service.dart').readAsStringSync();

  Set<String> checkedConsumers(String sql) {
    final match = RegExp(
      r'consumer TEXT NOT NULL CHECK \(consumer IN \(([^)]*)\)\)',
    ).firstMatch(sql);
    expect(match, isNotNull, reason: 'CHECK de consumer');
    return RegExp(
      r"'([a-z_]+)'",
    ).allMatches(match!.group(1)!).map((value) => value.group(1)!).toSet();
  }

  group('migration 060', () {
    test('cria account_deletion_outbox com o DDL aprovado na D-68', () {
      expect(migration060.name, 'create_account_deletion_outbox');
      for (final fragment in const [
        'CREATE TABLE IF NOT EXISTS account_deletion_outbox (',
        'REFERENCES account_deletion_receipts(id) ON DELETE RESTRICT',
        'REFERENCES privacy_keyring(key_version) ON DELETE RESTRICT',
        "deck_tokens TEXT[] NOT NULL DEFAULT '{}'",
        "CHECK (status IN ('pending', 'processing', 'done', 'failed'))",
        'CHECK (attempts BETWEEN 0 AND 100)',
        'CONSTRAINT uq_account_deletion_outbox_consumer '
            'UNIQUE (receipt_id, consumer)',
        "CHECK ((status = 'done') = (completed_at IS NOT NULL))",
        "CHECK ((status = 'processing') = "
            '(lease_owner IS NOT NULL AND lease_expires_at IS NOT NULL))',
        'CREATE INDEX IF NOT EXISTS idx_account_deletion_outbox_due',
        "WHERE status IN ('pending', 'failed')",
      ]) {
        expect(_normalized(migration060.up), contains(fragment));
        expect(_normalized(bootstrap), contains(fragment));
      }
      expect(
        migration060.down!.trim(),
        'DROP TABLE IF EXISTS account_deletion_outbox;',
      );
      expect(
        migrate.migrationRollbackPolicy('060'),
        migrate.MigrationRollbackPolicy.emptyOnly,
      );
    });

    test('o CHECK de consumer é a lista do código, na migration e no '
        'baseline', () {
      final names = {
        for (final consumer in accountDeletionOutboxConsumers) consumer.name,
      };
      expect(names, {
        'hermes_learning_sqlite',
        'interactive_battle_sidecar',
        'endpoint_cache',
        'sentry',
        'backups',
      });
      expect(checkedConsumers(migration060.up), names);
      expect(
        bootstrap,
        contains('CREATE TABLE IF NOT EXISTS account_deletion_outbox ('),
      );
      expect(checkedConsumers(bootstrap), names);
    });
  });

  group('consumidores', () {
    test('bloqueado tem motivo blocked_; o resto diz por que conclui', () {
      for (final consumer in accountDeletionOutboxConsumers) {
        expect(
          consumer.code.startsWith('blocked_'),
          consumer.handling == AccountDeletionOutboxHandling.blocked,
          reason: consumer.name,
        );
      }
      expect(defaultAccountDeletionOutboxHandlers().keys.toSet(), {
        'endpoint_cache',
        'interactive_battle_sidecar',
        'sentry',
      });
    });

    test('só quem precisa achar decks recebe os tokens', () {
      expect(
        {
          for (final consumer in accountDeletionOutboxConsumers)
            if (consumer.carriesDeckTokens) consumer.name,
        },
        {'hermes_learning_sqlite'},
      );
    });

    test('endpoint_cache só conclui depois do teto do EndpointCache e da '
        'varredura', () {
      final endpointCache = accountDeletionOutboxConsumers.singleWhere(
        (consumer) => consumer.name == 'endpoint_cache',
      );
      expect(
        endpointCache.handling,
        AccountDeletionOutboxHandling.expiresByTtl,
      );
      expect(
        endpointCache.firstAttemptDelay,
        greaterThanOrEqualTo(
          EndpointCache.maxTtl + EndpointCache.sweepInterval,
        ),
      );
    });

    test('interactive_battle_sidecar fecha pelo tempo máximo da sessão mais a '
        'retenção terminal do sidecar, contados da exclusão (D-77)', () {
      final sidecar = accountDeletionOutboxConsumers.singleWhere(
        (consumer) => consumer.name == 'interactive_battle_sidecar',
      );
      expect(sidecar.handling, AccountDeletionOutboxHandling.expiresByTtl);
      expect(sidecar.code, 'expired_by_max_session_lifetime');
      expect(sidecar.carriesDeckTokens, isFalse);
      expect(
        sidecar.firstAttemptDelay,
        const Duration(seconds: 7200) + const Duration(minutes: 10),
      );

      // O prazo acompanha o sidecar: o maior TTL aceito e a retenção
      // terminal vêm do próprio código dele.
      final registry =
          File(
            '../services/xmage-sidecar/src/main/java/com/manaloom/xmage/'
            'InteractiveBattleRegistry.java',
          ).readAsStringSync();
      final retention = RegExp(
        r'TERMINAL_RETENTION_MS\s*=\s*TimeUnit\.MINUTES\.toMillis\((\d+)\)',
      ).firstMatch(registry);
      final ttl = RegExp(
        r'"ttl_seconds",\s*(\d+),\s*(\d+)\s*\)',
      ).firstMatch(registry);
      expect(retention, isNotNull, reason: 'TERMINAL_RETENTION_MS');
      expect(ttl, isNotNull, reason: 'limite de ttl_seconds');
      final sidecarMaximumTtl = int.parse(ttl!.group(2)!);
      expect(sidecarMaximumTtl, interactiveBattleMaximumTtlSeconds);
      expect(
        sidecar.firstAttemptDelay,
        greaterThanOrEqualTo(
          Duration(seconds: sidecarMaximumTtl) +
              Duration(minutes: int.parse(retention!.group(1)!)),
        ),
      );
    });

    test('nova tentativa cresce e para em 24 h', () {
      var previous = Duration.zero;
      for (var attempts = 0; attempts <= 30; attempts++) {
        final delay = AccountDeletionOutboxWorker.retryDelay(attempts);
        expect(delay, greaterThanOrEqualTo(previous));
        expect(delay, lessThanOrEqualTo(const Duration(hours: 24)));
        previous = delay;
      }
      expect(AccountDeletionOutboxWorker.retryDelay(1).inMinutes, 2);
      expect(
        AccountDeletionOutboxWorker.retryDelay(30),
        const Duration(hours: 24),
      );
    });
  });

  group('exclusão', () {
    test('o outbox é relação obrigatória e entra depois do recibo, na mesma '
        'transação', () {
      expect(accountDeletionRelations, contains('account_deletion_outbox'));
      final receipt = service.indexOf('INSERT INTO account_deletion_receipts');
      final enqueue = service.indexOf('enqueueAccountDeletionOutbox(');
      expect(receipt, greaterThan(0));
      expect(enqueue, greaterThan(receipt));
      expect(
        service.substring(receipt, enqueue),
        contains('RETURNING id::text'),
      );
    });

    test('a linha de recibo do job tem o marcador', () {
      expect(
        accountDeletionOutboxReceiptLine({'status': 'ok'}),
        '$accountDeletionOutboxReceiptMarker {"status":"ok"}',
      );
    });
  });
}

/// Espaços colapsados e sem espaço logo depois de `(` ou antes de `)`.
String _normalized(String sql) => sql
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll('( ', '(')
    .replaceAll(' )', ')');
