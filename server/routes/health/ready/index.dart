import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../lib/health_readiness_support.dart';
import '../../../lib/http_responses.dart';

/// GET /health/ready - Readiness check (verifica dependências)
///
/// Usado para verificar se o servidor está pronto para receber tráfego.
/// Verifica conexão com o banco de dados.
/// Retorna 200 OK se todas as dependências estão funcionando.
/// Retorna 503 Service Unavailable se alguma dependência falhar.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return methodNotAllowed();
  }

  final checks = <String, dynamic>{};
  var allHealthy = true;

  // Check 1: Database connection
  final databaseStopwatch = Stopwatch()..start();
  try {
    final pool = context.read<Pool>();
    final result = await pool
        .execute('SELECT 1 as health_check')
        .timeout(const Duration(seconds: 5));

    if (result.isNotEmpty) {
      checks['database'] = {
        'status': 'healthy',
        'latency_ms': databaseStopwatch.elapsedMilliseconds,
      };
    } else {
      checks['database'] = {
        'status': 'unhealthy',
        'latency_ms': databaseStopwatch.elapsedMilliseconds,
        'error_code': 'database_empty_result',
      };
      allHealthy = false;
    }
  } catch (_) {
    checks['database'] = {
      'status': 'unhealthy',
      'latency_ms': databaseStopwatch.elapsedMilliseconds,
      'error_code': 'database_check_failed',
    };
    allHealthy = false;
  } finally {
    databaseStopwatch.stop();
  }

  // Check 2: Cards table has data
  final cardsStopwatch = Stopwatch()..start();
  try {
    final pool = context.read<Pool>();
    final result = await pool
        .execute('SELECT COUNT(*)::int FROM cards LIMIT 1')
        .timeout(const Duration(seconds: 5));

    final count = result.first[0] as int? ?? 0;
    checks['cards_data'] = {
      'status': count > 0 ? 'healthy' : 'warning',
      'card_count': count,
      'latency_ms': cardsStopwatch.elapsedMilliseconds,
    };

    if (count == 0) {
      checks['cards_data']['message'] = 'No cards in database - run sync_cards';
    }
  } catch (_) {
    checks['cards_data'] = {
      'status': 'unhealthy',
      'latency_ms': cardsStopwatch.elapsedMilliseconds,
      'error_code': 'cards_data_check_failed',
    };
    allHealthy = false;
  } finally {
    cardsStopwatch.stop();
  }

  final response = buildReadinessResponseBody(
    checks: checks,
    allHealthy: allHealthy,
  );

  return Response.json(
    statusCode: readinessStatusCode(allHealthy),
    body: response,
  );
}
