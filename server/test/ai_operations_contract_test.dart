import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('operational dashboard reports persisted async job health', () {
    final source =
        File('routes/health/dashboard/index.dart').readAsStringSync();

    expect(source, contains("'ai_jobs': aiJobs"));
    expect(source, contains("status IN ('pending', 'processing')"));
    expect(source, contains("'oldest_active_seconds'"));
    expect(source, contains('ai_generate_jobs'));
    expect(source, contains('ai_optimize_jobs'));
  });

  test('backend deploy drains async jobs before service update', () {
    final source =
        File('../scripts/manaloom_deploy_backend_image.sh').readAsStringSync();
    final drain = source.indexOf('drain_timeout_seconds=');
    final generateJobs = source.indexOf('ai_generate_jobs', drain);
    final optimizeJobs = source.indexOf('ai_optimize_jobs', drain);
    final serviceUpdate = source.indexOf('docker service update', drain);

    expect(drain, greaterThanOrEqualTo(0));
    expect(generateJobs, greaterThan(drain));
    expect(optimizeJobs, greaterThan(drain));
    expect(serviceUpdate, greaterThan(optimizeJobs));
    expect(source, contains('with_new_server_pg.sh'));
    expect(source, contains('MANALOOM_DEPLOY_AI_DRAIN_TIMEOUT_SECONDS'));
    expect(source, contains('deploy recusado:'));
  });

  test('backend deploy proves migrations 038-040 before remote mutation', () {
    final source =
        File('../scripts/manaloom_deploy_backend_image.sh').readAsStringSync();
    final guard =
        File('../scripts/lib/manaloom_mutation_guard.sh').readAsStringSync();
    final preflightDefinition = source.indexOf(
      'require_migration_038_contract() {',
    );
    final preflightCall = source.indexOf(
      '\nrequire_migration_038_contract\n',
      preflightDefinition + 1,
    );
    final migration039Definition = source.indexOf(
      'require_migration_039_contract() {',
    );
    final migration039Call = source.indexOf(
      '\nrequire_migration_039_contract\n',
      migration039Definition + 1,
    );
    final migration040Definition = source.indexOf(
      'require_migration_040_contract() {',
    );
    final migration040Call = source.indexOf(
      '\nrequire_migration_040_contract\n',
      migration040Definition + 1,
    );
    final environmentSource = source.indexOf(
      r'load_manaloom_env_keys "$ENV_FILE"',
    );
    final guardSource = source.indexOf(
      'source "\$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"',
    );
    final approval = source.indexOf(
      'require_live_mutation_approval "deploy do backend ManaLoom"',
    );
    final mutationStart = source.indexOf('DEPLOY_MUTATION_STARTED=1');
    final firstServiceUpdate = source.indexOf(
      'docker service update',
      mutationStart,
    );
    final firstRemoteFilesystemMutation = source.indexOf('git archive HEAD');

    expect(preflightDefinition, greaterThanOrEqualTo(0));
    expect(preflightCall, greaterThan(preflightDefinition));
    expect(migration039Call, greaterThan(migration039Definition));
    expect(migration040Call, greaterThan(migration040Definition));
    expect(migration039Call, greaterThan(preflightCall));
    expect(migration040Call, greaterThan(migration039Call));
    expect(approval, greaterThan(guardSource));
    expect(
      source.lastIndexOf(
        'require_live_mutation_approval "deploy do backend ManaLoom"',
      ),
      approval,
    );
    expect(environmentSource, greaterThan(approval));
    expect(
      source,
      contains(r'source "$ROOT_DIR/scripts/lib/manaloom_safe_env.sh"'),
    );
    expect(source, isNot(contains(r'. "$ENV_FILE"')));
    expect(preflightCall, greaterThan(environmentSource));
    expect(mutationStart, greaterThan(migration040Call));
    expect(firstServiceUpdate, greaterThan(migration040Call));
    expect(firstRemoteFilesystemMutation, greaterThan(migration040Call));
    expect(
      source,
      contains('source "\$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"'),
    );
    expect(source, contains('readonly LIVE_MUTATION_APPROVED=1'));
    expect(
      guard,
      contains('MANALOOM_EXPLICIT_APPROVAL_PHRASE="I_HAVE_EXPLICIT_APPROVAL"'),
    );
    expect(guard, contains(r'[[ "${MANALOOM_CONFIRM_LIVE_MUTATIONS:-}" == '));

    expect(source, contains('BEGIN TRANSACTION READ ONLY;'));
    expect(source, contains('with_new_server_pg.sh" --read-only'));
    expect(source, contains("current_setting('transaction_read_only') = 'on'"));
    expect(source, contains("version = '038'"));
    expect(source, contains("version = '039'"));
    expect(source, contains("version = '040'"));
    expect(
      source,
      contains("name = 'add_privacy_and_post_game_sync_contracts'"),
    );
    expect(source, contains("name = 'persist_deck_validation_review_state'"));
    expect(source, contains("name = 'align_cards_reserved_runtime_schema'"));
    for (final contractObject in const [
      'pgcrypto',
      'post_game_sync_state',
      'account_deletion_receipts',
      'privacy_keyring',
      'privacy_deleted_deck_tombstones',
      'manaloom_require_active_user',
      'manaloom_guard_deck_learning_event',
      'manaloom_guard_battle_simulation',
      'trade_items_binder_item_id_fkey',
      'migration_038_ready',
      'migration_039_ready',
      'migration_040_ready',
      'manaloom_deck_cards_require_review',
      'manaloom_deck_format_require_review',
      'idx_decks_user_validation_state',
      'cards_is_reserved_column',
    ]) {
      expect(source, contains(contractObject), reason: contractObject);
    }
    expect(source, contains("trigger_row.tgenabled IN ('O', 'A')"));
    expect(source, contains("constraint_row.confdeltype = 'n'"));
    expect(source, contains("column_default IN ('1', '1::bigint')"));
    expect(source, contains('ROLLBACK;'));
    expect(source, isNot(contains('dart run bin/migrate.dart')));
  });

  test(
    'backend deploy rejects approval persisted only in the env file',
    () async {
      final temporary = Directory.systemTemp.createTempSync(
        'manaloom-backend-approval-contract.',
      );
      try {
        final environmentFile = File('${temporary.path}/server.env')
          ..writeAsStringSync('''
MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL
SSH_HOST=contract.invalid
SSH_KEY=/tmp/not-used
EASYPANEL_BASE_URL=https://contract.invalid
EASYPANEL_API_TOKEN=not-used
DB_HOST=evolution_manaloom-postgres
DB_PORT=5432
DB_NAME=halder
DB_USER=not-used
DB_PASS=not-used
DB_SSL_MODE=disable
DATABASE_URL=postgresql://not-used:not-used@evolution_manaloom-postgres:5432/halder
MANALOOM_ALLOWED_ORIGINS=https://evolution-manaloom-web-public.2ta7qx.easypanel.host
''');
        final marker = File('${temporary.path}/tool-called');
        final fakeBin = Directory('${temporary.path}/bin')..createSync();
        final toolStub = File('${fakeBin.path}/tool-stub')
          ..writeAsStringSync('''#!/bin/sh
printf '%s\\n' "\$0" >> "\$MANALOOM_TEST_TOOL_MARKER"
exit 97
''');
        final chmod = Process.runSync('/bin/chmod', ['+x', toolStub.path]);
        expect(chmod.exitCode, 0);
        for (final tool in const [
          'git',
          'curl',
          'jq',
          'python3',
          'shasum',
          'ssh',
          'psql',
          'pg_isready',
        ]) {
          Link('${fakeBin.path}/$tool').createSync(toolStub.path);
        }

        final result = await Process.run(
          '/bin/bash',
          ['../scripts/manaloom_deploy_backend_image.sh'],
          workingDirectory: Directory.current.path,
          environment: {
            'MANALOOM_NEW_SERVER_ENV': environmentFile.path,
            'MANALOOM_CONFIRM_LIVE_MUTATIONS': '',
            'MANALOOM_TEST_TOOL_MARKER': marker.path,
            'PATH': '${fakeBin.path}:${Platform.environment['PATH'] ?? ''}',
          },
        );

        expect(result.exitCode, 2);
        expect(
          result.stderr.toString(),
          contains(
            'Set MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL',
          ),
        );
        expect(
          result.stderr.toString(),
          isNot(contains('ferramenta obrigatoria ausente')),
        );
        expect(marker.existsSync(), isFalse);
      } finally {
        temporary.deleteSync(recursive: true);
      }
    },
  );

  test('backend deploy retries readiness during proxy convergence', () {
    final source =
        File('../scripts/manaloom_deploy_backend_image.sh').readAsStringSync();

    expect(source, contains('MANALOOM_DEPLOY_READINESS_ATTEMPTS'));
    expect(source, contains(r'for attempt in $(seq 1 "$readiness_attempts")'));
    expect(source, contains('readiness ainda indisponivel apos deploy'));
    expect(source, contains(r'sleep "$((attempt * 2))"'));
    expect(source, contains(r'if [[ -z "$readiness_payload" ]]'));
  });

  test('backend deploy propagates and verifies exact production CORS', () {
    final source =
        File('../scripts/manaloom_deploy_backend_image.sh').readAsStringSync();

    expect(source, contains('MANALOOM_ALLOWED_ORIGINS'));
    expect(
      source,
      contains('https://evolution-manaloom-web-public.2ta7qx.easypanel.host'),
    );
    expect(source, contains('manaloom_validate_production_origins.py'));
    expect(source, contains('--env-add MANALOOM_ALLOWED_ORIGINS='));
    expect(source, contains('spec_allowed_origins_sha256'));
    expect(source, contains('runtime_allowed_origins_sha256'));
    expect(source, contains('cors_allowlist: "verified"'));
  });
}
