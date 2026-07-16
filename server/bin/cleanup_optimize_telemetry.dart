// ignore_for_file: avoid_print

import 'dart:io';

import 'package:postgres/postgres.dart';

import '../lib/runtime_environment.dart';

void main(List<String> args) async {
  final env = loadRuntimeEnvironment();

  final retentionArg = args.firstWhere(
    (a) => a.startsWith('--retention-days='),
    orElse: () => '',
  );
  final dryRun = args.contains('--dry-run');
  final reservationTtlArg = args.firstWhere(
    (a) => a.startsWith('--reservation-ttl-minutes='),
    orElse: () => '',
  );
  final rateLimitRetentionArg = args.firstWhere(
    (a) => a.startsWith('--rate-limit-retention-hours='),
    orElse: () => '',
  );
  final aiLogRetentionArg = args.firstWhere(
    (a) => a.startsWith('--ai-log-retention-days='),
    orElse: () => '',
  );
  final jobRetentionArg = args.firstWhere(
    (a) => a.startsWith('--job-retention-minutes='),
    orElse: () => '',
  );

  final retentionFromArg =
      retentionArg.isNotEmpty
          ? int.tryParse(retentionArg.split('=').last.trim())
          : null;
  final retentionFromEnv = int.tryParse(env['TELEMETRY_RETENTION_DAYS'] ?? '');
  final retentionDays = retentionFromArg ?? retentionFromEnv ?? 180;
  final reservationTtlFromArg =
      reservationTtlArg.isNotEmpty
          ? int.tryParse(reservationTtlArg.split('=').last.trim())
          : null;
  final reservationTtlFromEnv = int.tryParse(
    env['AI_PLAN_RESERVATION_TTL_MINUTES'] ?? '',
  );
  final reservationTtlMinutes =
      reservationTtlFromArg ?? reservationTtlFromEnv ?? 10;
  final rateLimitRetentionFromArg =
      rateLimitRetentionArg.isNotEmpty
          ? int.tryParse(rateLimitRetentionArg.split('=').last.trim())
          : null;
  final rateLimitRetentionFromEnv = int.tryParse(
    env['RATE_LIMIT_EVENT_RETENTION_HOURS'] ?? '',
  );
  final rateLimitRetentionHours =
      rateLimitRetentionFromArg ?? rateLimitRetentionFromEnv ?? 24;
  final aiLogRetentionFromArg =
      aiLogRetentionArg.isNotEmpty
          ? int.tryParse(aiLogRetentionArg.split('=').last.trim())
          : null;
  final aiLogRetentionFromEnv = int.tryParse(
    env['AI_LOG_RETENTION_DAYS'] ?? '',
  );
  final aiLogRetentionDays =
      aiLogRetentionFromArg ?? aiLogRetentionFromEnv ?? 180;
  final jobRetentionFromArg =
      jobRetentionArg.isNotEmpty
          ? int.tryParse(jobRetentionArg.split('=').last.trim())
          : null;
  final jobRetentionFromEnv = int.tryParse(
    env['AI_JOB_RETENTION_MINUTES'] ?? '',
  );
  final jobRetentionMinutes = jobRetentionFromArg ?? jobRetentionFromEnv ?? 30;

  if (retentionDays < 1) {
    print('❌ retention-days inválido. Use um inteiro >= 1.');
    exit(1);
  }
  if (reservationTtlMinutes < 1) {
    print('❌ reservation-ttl-minutes inválido. Use um inteiro >= 1.');
    exit(1);
  }
  if (rateLimitRetentionHours < 1) {
    print('❌ rate-limit-retention-hours inválido. Use um inteiro >= 1.');
    exit(1);
  }
  if (aiLogRetentionDays < 1) {
    print('❌ ai-log-retention-days inválido. Use um inteiro >= 1.');
    exit(1);
  }
  if (jobRetentionMinutes < 1) {
    print('❌ job-retention-minutes inválido. Use um inteiro >= 1.');
    exit(1);
  }

  final host = env['DB_HOST'];
  final port = int.tryParse(env['DB_PORT'] ?? '');
  final database = env['DB_NAME'];
  final username = env['DB_USER'];
  final password = env['DB_PASS'];

  if (host == null ||
      port == null ||
      database == null ||
      username == null ||
      password == null) {
    print(
      '❌ Variáveis de DB ausentes (DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS).',
    );
    exit(1);
  }

  final connection = await Connection.open(
    Endpoint(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    print(
      '🧹 Cleanup AI runtime '
      '(retention_days=$retentionDays, '
      'ai_log_retention_days=$aiLogRetentionDays, '
      'job_retention_minutes=$jobRetentionMinutes, '
      'reservation_ttl_minutes=$reservationTtlMinutes, '
      'rate_limit_retention_hours=$rateLimitRetentionHours, '
      'dry_run=$dryRun)',
    );

    final countResult = await connection.execute(
      Sql.named('''
        SELECT COUNT(*)::int AS c
        FROM ai_optimize_fallback_telemetry
        WHERE created_at < NOW() - (CAST(@days AS int) * INTERVAL '1 day')
      '''),
      parameters: {'days': retentionDays},
    );

    final toDelete = _toInt(countResult.first.toColumnMap()['c']);
    final staleReservationResult = await connection.execute(
      Sql.named('''
        SELECT COUNT(*)::int AS c
        FROM ai_logs
        WHERE endpoint LIKE 'plan-reservation:%'
          AND success = FALSE
          AND created_at <
            NOW() - (CAST(@minutes AS int) * INTERVAL '1 minute')
      '''),
      parameters: {'minutes': reservationTtlMinutes},
    );
    final staleReservations = _toInt(
      staleReservationResult.first.toColumnMap()['c'],
    );
    final staleRateLimitResult = await connection.execute(
      Sql.named('''
        SELECT COUNT(*)::int AS c
        FROM rate_limit_events
        WHERE created_at <
          NOW() - (CAST(@hours AS int) * INTERVAL '1 hour')
      '''),
      parameters: {'hours': rateLimitRetentionHours},
    );
    final staleRateLimitEvents = _toInt(
      staleRateLimitResult.first.toColumnMap()['c'],
    );
    final staleAiLogResult = await connection.execute(
      Sql.named('''
        SELECT COUNT(*)::int AS c
        FROM ai_logs
        WHERE endpoint NOT LIKE 'plan-reservation:%'
          AND created_at <
            NOW() - (CAST(@days AS int) * INTERVAL '1 day')
      '''),
      parameters: {'days': aiLogRetentionDays},
    );
    final staleAiLogs = _toInt(staleAiLogResult.first.toColumnMap()['c']);
    final staleGenerateJobResult = await connection.execute(
      Sql.named('''
        SELECT COUNT(*)::int AS c
        FROM ai_generate_jobs
        WHERE created_at <
          NOW() - (CAST(@minutes AS int) * INTERVAL '1 minute')
      '''),
      parameters: {'minutes': jobRetentionMinutes},
    );
    final staleGenerateJobs = _toInt(
      staleGenerateJobResult.first.toColumnMap()['c'],
    );
    final staleOptimizeJobResult = await connection.execute(
      Sql.named('''
        SELECT COUNT(*)::int AS c
        FROM ai_optimize_jobs
        WHERE created_at <
          NOW() - (CAST(@minutes AS int) * INTERVAL '1 minute')
      '''),
      parameters: {'minutes': jobRetentionMinutes},
    );
    final staleOptimizeJobs = _toInt(
      staleOptimizeJobResult.first.toColumnMap()['c'],
    );
    print(
      '📊 Elegíveis: optimize_telemetry=$toDelete '
      'ai_logs=$staleAiLogs '
      'generate_jobs=$staleGenerateJobs '
      'optimize_jobs=$staleOptimizeJobs '
      'stale_plan_reservations=$staleReservations '
      'stale_rate_limit_events=$staleRateLimitEvents',
    );

    if (dryRun ||
        (toDelete == 0 &&
            staleAiLogs == 0 &&
            staleGenerateJobs == 0 &&
            staleOptimizeJobs == 0 &&
            staleReservations == 0 &&
            staleRateLimitEvents == 0)) {
      print('✅ Nenhuma remoção executada.');
      return;
    }

    final deleted = await connection.runTx((session) async {
      final telemetryDeleteResult = await session.execute(
        Sql.named('''
          DELETE FROM ai_optimize_fallback_telemetry
          WHERE created_at < NOW() - (CAST(@days AS int) * INTERVAL '1 day')
        '''),
        parameters: {'days': retentionDays},
      );
      final aiLogDeleteResult = await session.execute(
        Sql.named('''
          DELETE FROM ai_logs
          WHERE endpoint NOT LIKE 'plan-reservation:%'
            AND created_at <
              NOW() - (CAST(@days AS int) * INTERVAL '1 day')
        '''),
        parameters: {'days': aiLogRetentionDays},
      );
      final reservationDeleteResult = await session.execute(
        Sql.named('''
          DELETE FROM ai_logs
          WHERE endpoint LIKE 'plan-reservation:%'
            AND success = FALSE
            AND created_at <
              NOW() - (CAST(@minutes AS int) * INTERVAL '1 minute')
        '''),
        parameters: {'minutes': reservationTtlMinutes},
      );
      final rateLimitDeleteResult = await session.execute(
        Sql.named('''
          DELETE FROM rate_limit_events
          WHERE created_at <
            NOW() - (CAST(@hours AS int) * INTERVAL '1 hour')
        '''),
        parameters: {'hours': rateLimitRetentionHours},
      );
      final generateJobDeleteResult = await session.execute(
        Sql.named('''
          DELETE FROM ai_generate_jobs
          WHERE created_at <
            NOW() - (CAST(@minutes AS int) * INTERVAL '1 minute')
        '''),
        parameters: {'minutes': jobRetentionMinutes},
      );
      final optimizeJobDeleteResult = await session.execute(
        Sql.named('''
          DELETE FROM ai_optimize_jobs
          WHERE created_at <
            NOW() - (CAST(@minutes AS int) * INTERVAL '1 minute')
        '''),
        parameters: {'minutes': jobRetentionMinutes},
      );
      return (
        telemetry: telemetryDeleteResult.affectedRows,
        aiLogs: aiLogDeleteResult.affectedRows,
        generateJobs: generateJobDeleteResult.affectedRows,
        optimizeJobs: optimizeJobDeleteResult.affectedRows,
        reservations: reservationDeleteResult.affectedRows,
        rateLimitEvents: rateLimitDeleteResult.affectedRows,
      );
    });

    print(
      '✅ Remoção concluída: optimize_telemetry=${deleted.telemetry} '
      'ai_logs=${deleted.aiLogs} '
      'generate_jobs=${deleted.generateJobs} '
      'optimize_jobs=${deleted.optimizeJobs} '
      'stale_plan_reservations=${deleted.reservations} '
      'stale_rate_limit_events=${deleted.rateLimitEvents}',
    );
  } catch (e) {
    print('❌ Falha no cleanup: $e');
    exit(1);
  } finally {
    await connection.close();
  }
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
