import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart';
import 'package:sentry/sentry.dart';

import 'logger.dart';
import 'request_trace.dart';

final DotEnv _observabilityEnv =
    DotEnv(includePlatformEnvironment: true, quiet: true)..load();

Future<void>? _observabilityInit;

String get _sentryDsn => (_observabilityEnv['SENTRY_DSN'] ??
        Platform.environment['SENTRY_DSN'] ??
        '')
    .trim();

String get _sentryEnvironment => (_observabilityEnv['SENTRY_ENVIRONMENT'] ??
        Platform.environment['SENTRY_ENVIRONMENT'] ??
        _observabilityEnv['ENVIRONMENT'] ??
        Platform.environment['ENVIRONMENT'] ??
        'development')
    .trim();

String? get _sentryRelease {
  final value = (_observabilityEnv['SENTRY_RELEASE'] ??
          Platform.environment['SENTRY_RELEASE'] ??
          Platform.environment['APP_VERSION'])
      ?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  return value;
}

bool isSentryEnabled() => _sentryDsn.isNotEmpty;

double resolveSentryTracesSampleRate(String? raw, {double fallback = 0}) {
  final parsed = double.tryParse((raw ?? '').trim());
  if (parsed == null || parsed.isNaN || parsed < 0 || parsed > 1) {
    return fallback;
  }
  return parsed;
}

Map<String, String> sanitizeObservedHeaders(Map<String, Object?>? headers) {
  if (headers == null || headers.isEmpty) {
    return const {};
  }

  final sanitized = <String, String>{};
  for (final entry in headers.entries) {
    final value = entry.value;
    if (value == null) {
      continue;
    }
    sanitized[entry.key] = value.toString();
  }

  for (final key in sanitized.keys.toList()) {
    final normalized = key.toLowerCase();
    if (normalized == 'authorization' || normalized == 'cookie') {
      sanitized[key] = '[Filtered]';
    }
  }

  return sanitized;
}

Future<void> ensureObservabilityInitialized() {
  return _observabilityInit ??= _initializeObservability();
}

Future<void> _initializeObservability() async {
  if (!isSentryEnabled()) {
    Log.i('[observability] Sentry desabilitado: SENTRY_DSN ausente');
    return;
  }

  final tracesSampleRate = resolveSentryTracesSampleRate(
    _observabilityEnv['SENTRY_TRACES_SAMPLE_RATE'] ??
        Platform.environment['SENTRY_TRACES_SAMPLE_RATE'],
  );

  await Sentry.init((options) {
    options.dsn = _sentryDsn;
    options.environment = _sentryEnvironment;
    options.release = _sentryRelease;
    options.tracesSampleRate = tracesSampleRate;
    options.sendDefaultPii = false;
    options.enableLogs = !(_sentryEnvironment == 'production');
    options.beforeSend = (event, hint) {
      final request = event.request;
      if (request == null) {
        return event;
      }

      request.headers = sanitizeObservedHeaders(request.headers);
      return event;
    };
  });

  Log.i(
    '[observability] Sentry inicializado '
    '(env=$_sentryEnvironment, release=${_sentryRelease ?? 'n/a'})',
  );
}

Future<void> captureObservedException(
  Object error, {
  StackTrace? stackTrace,
  Request? request,
  RequestTrace? trace,
  String? userId,
  Map<String, String>? tags,
  Map<String, Object?>? extras,
}) async {
  if (!isSentryEnabled()) {
    return;
  }

  await ensureObservabilityInitialized();

  await Sentry.captureException(
    error,
    stackTrace: stackTrace,
    withScope: (scope) {
      if (trace != null) {
        scope.setTag('request_id', trace.requestId);
      }

      if (request != null) {
        scope.setTag('http_method', request.method.name.toUpperCase());
        scope.setTag('http_path', request.uri.path);
        scope.setContexts('request', <String, Object?>{
          'method': request.method.name.toUpperCase(),
          'path': request.uri.path,
          'query': request.uri.query,
          'headers': sanitizeObservedHeaders(request.headers),
        });
      }

      if (userId != null && userId.isNotEmpty) {
        scope.setUser(SentryUser(id: userId));
      }

      if (tags != null) {
        for (final entry in tags.entries) {
          scope.setTag(entry.key, entry.value);
        }
      }

      if (extras != null) {
        scope.setContexts('extras', extras);
      }
    },
  );
}

Future<void> captureRouteException(
  RequestContext context,
  Object error, {
  StackTrace? stackTrace,
  String source = 'route_handler',
  Map<String, String>? tags,
  Map<String, Object?>? extras,
}) async {
  RequestTrace? trace;
  String? userId;

  try {
    trace = context.read<RequestTrace>();
  } catch (_) {
    trace = null;
  }

  try {
    userId = context.read<String>();
  } catch (_) {
    userId = null;
  }

  await captureObservedException(
    error,
    stackTrace: stackTrace,
    request: context.request,
    trace: trace,
    userId: userId,
    tags: {
      'source': source,
      if (tags != null) ...tags,
    },
    extras: extras,
  );
}
