import 'dart:io';

Map<String, dynamic> buildReadinessResponseBody({
  required Map<String, dynamic> checks,
  required bool allHealthy,
  DateTime? now,
  String? environment,
}) {
  return {
    'status': allHealthy ? 'ready' : 'not_ready',
    'service': 'mtgia-server',
    'timestamp': (now ?? DateTime.now()).toIso8601String(),
    'environment':
        environment ?? Platform.environment['ENVIRONMENT'] ?? 'development',
    'checks': checks,
  };
}

int readinessStatusCode(bool allHealthy) =>
    allHealthy ? HttpStatus.ok : HttpStatus.serviceUnavailable;
