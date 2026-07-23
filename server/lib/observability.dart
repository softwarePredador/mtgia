import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart';
import 'package:sentry/sentry.dart';

import 'log_sanitizer.dart';
import 'logger.dart';
import 'request_trace.dart';
import 'runtime_environment.dart';

final DotEnv _observabilityEnv = loadRuntimeEnvironment();

Future<void>? _observabilityInit;

String get _sentryDsn => (_observabilityEnv['SENTRY_DSN'] ?? '').trim();

String get _sentryEnvironment =>
    (_observabilityEnv['SENTRY_ENVIRONMENT'] ??
            _observabilityEnv['ENVIRONMENT'] ??
            'development')
        .trim();

String? get _sentryRelease {
  final value =
      (_observabilityEnv['SENTRY_RELEASE'] ?? _observabilityEnv['APP_VERSION'])
          ?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  return value;
}

bool isSentryEnabled() => _sentryDsn.isNotEmpty;

const String observedFilteredValue = '[Filtered]';
const int _observedMaxDepth = 6;
const int _observedMaxCollectionLength = 100;
const int _observedMaxStringLength = 4096;
const Set<String> _sensitiveObservedKeys = {
  'authorization',
  'cookie',
  'cookies',
  'set_cookie',
  'proxy_authorization',
  'password',
  'passphrase',
  'secret',
  'api_key',
  'apikey',
  'access_token',
  'refresh_token',
  'id_token',
  'fcm_token',
  'x_api_key',
  'x_manaloom_ops_key',
  'x_internal_ai_request_token',
  'database_url',
  'postgres_url',
  'sentry_dsn',
};

double resolveSentryTracesSampleRate(String? raw, {double fallback = 0}) {
  final parsed = double.tryParse((raw ?? '').trim());
  if (parsed == null || parsed.isNaN || parsed < 0 || parsed > 1) {
    return fallback;
  }
  return parsed;
}

bool isSensitiveObservedKey(String key) {
  final normalized = key
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return _sensitiveObservedKeys.contains(normalized) ||
      normalized == 'token' ||
      normalized.endsWith('_token') ||
      normalized.endsWith('_secret') ||
      normalized.endsWith('_password');
}

String sanitizeObservedText(String value) {
  var sanitized = sanitizeLogMessage(value);
  final patterns = <MapEntry<RegExp, String>>[
    MapEntry(
      RegExp(
        r'((?:access[_-]?token|refresh[_-]?token|id[_-]?token|token|secret|passphrase|password|cookie|sentry[_-]?dsn)\s*[=:]\s*)[^\s,;&#]+',
        caseSensitive: false,
      ),
      r'$1[Filtered]',
    ),
    MapEntry(
      RegExp(
        r'([?&](?:access_token|refresh_token|id_token|token|secret|password|api_key)=)[^&#\s]*',
        caseSensitive: false,
      ),
      r'$1[Filtered]',
    ),
    MapEntry(
      RegExp(r'([a-z][a-z0-9+.-]*://)[^/@\s]+:[^/@\s]+@', caseSensitive: false),
      r'$1[Filtered]:[Filtered]@',
    ),
    MapEntry(
      RegExp(r'\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b'),
      '[Filtered_JWT]',
    ),
  ];
  for (final pattern in patterns) {
    sanitized = sanitized.replaceAllMapped(pattern.key, (match) {
      final replacement = pattern.value;
      if (replacement.contains(r'$1') && match.groupCount >= 1) {
        return replacement.replaceFirst(r'$1', match.group(1) ?? '');
      }
      return replacement;
    });
  }
  if (sanitized.length > _observedMaxStringLength) {
    return '${sanitized.substring(0, _observedMaxStringLength)}...[Truncated]';
  }
  return sanitized;
}

String sanitizeObservedQuery(String query) {
  if (query.trim().isEmpty) {
    return '';
  }
  return query
      .split('&')
      .take(_observedMaxCollectionLength)
      .map((part) {
        final separator = part.indexOf('=');
        final rawKey = separator >= 0 ? part.substring(0, separator) : part;
        final key = sanitizeObservedText(rawKey);
        return separator >= 0 ? '$key=$observedFilteredValue' : key;
      })
      .join('&');
}

String? sanitizeObservedUrl(String? value) {
  if (value == null || value.isEmpty) {
    return value;
  }
  final queryIndex = value.indexOf('?');
  final fragmentIndex = value.indexOf('#');
  final boundaryCandidates = [
    if (queryIndex >= 0) queryIndex,
    if (fragmentIndex >= 0) fragmentIndex,
  ];
  final boundary =
      boundaryCandidates.isEmpty
          ? value.length
          : boundaryCandidates.reduce(
            (left, right) => left < right ? left : right,
          );
  return sanitizeObservedText(value.substring(0, boundary));
}

Object? sanitizeObservedValue(Object? value, {String? key, int depth = 0}) {
  if (key != null && isSensitiveObservedKey(key)) {
    return observedFilteredValue;
  }
  if (value == null || value is num || value is bool) {
    return value;
  }
  if (value is String) {
    return sanitizeObservedText(value);
  }
  if (value is DateTime) {
    return value.toUtc().toIso8601String();
  }
  if (depth >= _observedMaxDepth) {
    return '[DepthLimited]';
  }
  if (value is Map) {
    final sanitized = <String, Object?>{};
    for (final entry in value.entries.take(_observedMaxCollectionLength)) {
      final entryKey = sanitizeObservedText(entry.key.toString());
      sanitized[entryKey] = sanitizeObservedValue(
        entry.value,
        key: entryKey,
        depth: depth + 1,
      );
    }
    return sanitized;
  }
  if (value is Iterable) {
    return value
        .take(_observedMaxCollectionLength)
        .map((item) => sanitizeObservedValue(item, depth: depth + 1))
        .toList(growable: false);
  }
  return sanitizeObservedText(value.toString());
}

Map<String, Object?> sanitizeObservedMap(Map<Object?, Object?> values) {
  return Map<String, Object?>.from(
    sanitizeObservedValue(values) as Map<String, Object?>,
  );
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
    sanitized[entry.key] =
        isSensitiveObservedKey(entry.key)
            ? observedFilteredValue
            : sanitizeObservedText(value.toString());
  }

  return sanitized;
}

SentryRequest? sanitizeObservedRequest(SentryRequest? request) {
  if (request == null) {
    return null;
  }
  return SentryRequest(
    url: sanitizeObservedUrl(request.url),
    method: request.method,
    queryString:
        request.queryString == null
            ? null
            : sanitizeObservedQuery(request.queryString!),
    data: sanitizeObservedValue(request.data),
    headers: sanitizeObservedHeaders(request.headers),
    apiTarget: request.apiTarget,
  );
}

Breadcrumb sanitizeObservedBreadcrumb(Breadcrumb breadcrumb) {
  breadcrumb.message =
      breadcrumb.message == null
          ? null
          : sanitizeObservedText(breadcrumb.message!);
  final data = breadcrumb.data;
  if (data != null) {
    breadcrumb.data = Map<String, dynamic>.from(sanitizeObservedMap(data));
  }
  return breadcrumb;
}

SentryEvent sanitizeObservedEvent(SentryEvent event) {
  event.request = sanitizeObservedRequest(event.request);
  final message = event.message;
  if (message != null) {
    message.formatted = sanitizeObservedText(message.formatted);
    message.template =
        message.template == null
            ? null
            : sanitizeObservedText(message.template!);
    message.params = message.params
        ?.map((value) => sanitizeObservedValue(value))
        .toList(growable: false);
  }
  for (final exception in event.exceptions ?? const <SentryException>[]) {
    exception.value =
        exception.value == null ? null : sanitizeObservedText(exception.value!);
    exception.throwable = null;
  }
  for (final breadcrumb in event.breadcrumbs ?? const <Breadcrumb>[]) {
    sanitizeObservedBreadcrumb(breadcrumb);
  }
  final tags = event.tags;
  if (tags != null) {
    event.tags = {
      for (final entry in tags.entries)
        sanitizeObservedText(entry.key):
            (isSensitiveObservedKey(entry.key)
                ? observedFilteredValue
                : sanitizeObservedText(entry.value)),
    };
  }
  // Legacy SDK integrations can still populate `extra`; sanitize before send.
  // ignore: deprecated_member_use
  final extra = event.extra;
  if (extra != null) {
    // ignore: deprecated_member_use
    event.extra = Map<String, dynamic>.from(sanitizeObservedMap(extra));
  }
  for (final key in event.contexts.keys.toList(growable: false)) {
    final value = event.contexts[key];
    if (value is Map || value is Iterable || value is String) {
      event.contexts[key] = sanitizeObservedValue(value, key: key);
    }
  }
  final userId = event.user?.id?.trim();
  event.user =
      userId == null || userId.isEmpty
          ? null
          : SentryUser(id: sanitizeObservedText(userId));
  return event;
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
    _observabilityEnv['SENTRY_TRACES_SAMPLE_RATE'],
  );

  await Sentry.init((options) {
    options.dsn = _sentryDsn;
    options.environment = _sentryEnvironment;
    options.release = _sentryRelease;
    options.tracesSampleRate = tracesSampleRate;
    options.sendDefaultPii = false;
    options.enableLogs = !(_sentryEnvironment == 'production');
    options.beforeSend = (event, hint) => sanitizeObservedEvent(event);
    options.beforeBreadcrumb =
        (breadcrumb, hint) =>
            breadcrumb == null ? null : sanitizeObservedBreadcrumb(breadcrumb);
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
          'query': sanitizeObservedQuery(request.uri.query),
          'headers': sanitizeObservedHeaders(request.headers),
        });
      }

      if (userId != null && userId.isNotEmpty) {
        scope.setUser(SentryUser(id: userId));
      }

      if (tags != null) {
        for (final entry in tags.entries) {
          scope.setTag(
            sanitizeObservedText(entry.key),
            isSensitiveObservedKey(entry.key)
                ? observedFilteredValue
                : sanitizeObservedText(entry.value),
          );
        }
      }

      if (extras != null) {
        scope.setContexts('extras', sanitizeObservedMap(extras));
      }
    },
  );
}

Future<void> captureObservedMessage(
  String message, {
  Request? request,
  RequestTrace? trace,
  String? userId,
  SentryLevel level = SentryLevel.info,
  Map<String, String>? tags,
  Map<String, Object?>? extras,
}) async {
  if (!isSentryEnabled()) {
    return;
  }

  await ensureObservabilityInitialized();

  await Sentry.captureMessage(
    sanitizeObservedText(message),
    level: level,
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
          'query': sanitizeObservedQuery(request.uri.query),
          'headers': sanitizeObservedHeaders(request.headers),
        });
      }

      if (userId != null && userId.isNotEmpty) {
        scope.setUser(SentryUser(id: userId));
      }

      if (tags != null) {
        for (final entry in tags.entries) {
          scope.setTag(
            sanitizeObservedText(entry.key),
            isSensitiveObservedKey(entry.key)
                ? observedFilteredValue
                : sanitizeObservedText(entry.value),
          );
        }
      }

      if (extras != null) {
        scope.setContexts('extras', sanitizeObservedMap(extras));
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
    tags: {'source': source, if (tags != null) ...tags},
    extras: extras,
  );
}
