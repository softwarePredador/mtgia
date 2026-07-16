import 'dart:async';
import 'dart:io';

import 'package:sentry/sentry.dart';

import '../lib/runtime_environment.dart';

Future<void> main(List<String> args) async {
  final env = loadRuntimeEnvironment();
  final dsn = (env['SENTRY_DSN'] ?? '').trim();

  if (dsn.isEmpty) {
    stderr.writeln('SENTRY_DSN ausente; smoke cancelado.');
    exitCode = 1;
    return;
  }

  final environment =
      (env['SENTRY_ENVIRONMENT'] ?? env['ENVIRONMENT'] ?? 'development').trim();
  final release = (env['SENTRY_RELEASE'] ?? env['APP_VERSION'])?.trim();
  final sampleRateRaw = (env['SENTRY_TRACES_SAMPLE_RATE'] ?? '0').trim();
  final tracesSampleRate = double.tryParse(sampleRateRaw) ?? 0;
  final smokeId =
      'mtgia-smoke-${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';

  await Sentry.init((options) {
    options.dsn = dsn;
    options.environment = environment;
    if (release != null && release.isNotEmpty) {
      options.release = release;
    }
    options.sendDefaultPii = false;
    options.enableLogs = false;
    options.tracesSampleRate =
        tracesSampleRate < 0 || tracesSampleRate > 1 ? 0 : tracesSampleRate;
  });

  final eventId = await Sentry.captureException(
    Exception('MTGIA backend sentry smoke'),
    withScope: (scope) {
      scope.setTag('source', 'manual_smoke');
      scope.setTag('smoke_id', smokeId);
      scope.setContexts('smoke', {
        'runner': 'server/bin/sentry_smoke.dart',
        'smoke_id': smokeId,
        'environment': environment,
      });
    },
  );

  await Sentry.close();

  stdout.writeln('SENTRY_SMOKE_EVENT_ID=$eventId');
  stdout.writeln('SENTRY_SMOKE_TAG=smoke_id:$smokeId');
}
