import 'package:sentry_flutter/sentry_flutter.dart';

const String appObservedFilteredValue = '[Filtered]';
const int _maxDepth = 6;
const int _maxCollectionLength = 100;
const int _maxStringLength = 4096;
const Set<String> _sensitiveKeys = {
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

bool isSensitiveAppObservedKey(String key) {
  final normalized = key
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return _sensitiveKeys.contains(normalized) ||
      normalized == 'token' ||
      normalized.endsWith('_token') ||
      normalized.endsWith('_secret') ||
      normalized.endsWith('_password');
}

String sanitizeAppObservedText(String value) {
  var sanitized = value;
  final patterns = <MapEntry<RegExp, String>>[
    MapEntry(
      RegExp(
        r'(authorization\s*:\s*bearer\s+)[A-Za-z0-9\-._~+/=]+',
        caseSensitive: false,
      ),
      r'$1[Filtered]',
    ),
    MapEntry(
      RegExp(
        r'((?:access[_-]?token|refresh[_-]?token|id[_-]?token|fcm[_-]?token|api[_-]?key|openai[_-]?api[_-]?key|jwt[_-]?secret|token|secret|passphrase|password|cookie|sentry[_-]?dsn)\s*[=:]\s*)[^\s,;&#]+',
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
    MapEntry(RegExp(r'\bsk-[A-Za-z0-9_-]{10,}\b'), '[Filtered_OPENAI_KEY]'),
    MapEntry(
      RegExp(r'\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b'),
      '[Filtered_JWT]',
    ),
    MapEntry(
      RegExp(
        r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
        caseSensitive: false,
      ),
      '[Filtered_EMAIL]',
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
  if (sanitized.length > _maxStringLength) {
    return '${sanitized.substring(0, _maxStringLength)}...[Truncated]';
  }
  return sanitized;
}

String sanitizeAppObservedQuery(String query) {
  if (query.trim().isEmpty) {
    return '';
  }
  return query
      .split('&')
      .take(_maxCollectionLength)
      .map((part) {
        final separator = part.indexOf('=');
        final rawKey = separator >= 0 ? part.substring(0, separator) : part;
        final key = sanitizeAppObservedText(rawKey);
        return separator >= 0 ? '$key=$appObservedFilteredValue' : key;
      })
      .join('&');
}

String? sanitizeAppObservedUrl(String? value) {
  if (value == null || value.isEmpty) {
    return value;
  }
  final queryIndex = value.indexOf('?');
  final fragmentIndex = value.indexOf('#');
  final boundaries = [
    if (queryIndex >= 0) queryIndex,
    if (fragmentIndex >= 0) fragmentIndex,
  ];
  final boundary = boundaries.isEmpty
      ? value.length
      : boundaries.reduce((left, right) => left < right ? left : right);
  return sanitizeAppObservedText(value.substring(0, boundary));
}

Object? sanitizeAppObservedValue(Object? value, {String? key, int depth = 0}) {
  if (key != null && isSensitiveAppObservedKey(key)) {
    return appObservedFilteredValue;
  }
  if (value == null || value is num || value is bool) {
    return value;
  }
  if (value is String) {
    return sanitizeAppObservedText(value);
  }
  if (value is DateTime) {
    return value.toUtc().toIso8601String();
  }
  if (depth >= _maxDepth) {
    return '[DepthLimited]';
  }
  if (value is Map) {
    final sanitized = <String, Object?>{};
    for (final entry in value.entries.take(_maxCollectionLength)) {
      final entryKey = sanitizeAppObservedText(entry.key.toString());
      sanitized[entryKey] = sanitizeAppObservedValue(
        entry.value,
        key: entryKey,
        depth: depth + 1,
      );
    }
    return sanitized;
  }
  if (value is Iterable) {
    return value
        .take(_maxCollectionLength)
        .map((item) => sanitizeAppObservedValue(item, depth: depth + 1))
        .toList(growable: false);
  }
  return sanitizeAppObservedText(value.toString());
}

Map<String, Object?> sanitizeAppObservedMap(Map<Object?, Object?> values) {
  return Map<String, Object?>.from(
    sanitizeAppObservedValue(values) as Map<String, Object?>,
  );
}

Map<String, String> sanitizeAppObservedHeaders(Map<String, Object?>? headers) {
  if (headers == null || headers.isEmpty) {
    return const {};
  }
  return {
    for (final entry in headers.entries)
      entry.key: isSensitiveAppObservedKey(entry.key)
          ? appObservedFilteredValue
          : sanitizeAppObservedText(entry.value?.toString() ?? ''),
  };
}

SentryRequest? sanitizeAppObservedRequest(SentryRequest? request) {
  if (request == null) {
    return null;
  }
  return SentryRequest(
    url: sanitizeAppObservedUrl(request.url),
    method: request.method,
    queryString: request.queryString == null
        ? null
        : sanitizeAppObservedQuery(request.queryString!),
    data: sanitizeAppObservedValue(request.data),
    headers: sanitizeAppObservedHeaders(request.headers),
    apiTarget: request.apiTarget,
  );
}

Breadcrumb sanitizeAppObservedBreadcrumb(Breadcrumb breadcrumb) {
  breadcrumb.message = breadcrumb.message == null
      ? null
      : sanitizeAppObservedText(breadcrumb.message!);
  final data = breadcrumb.data;
  if (data != null) {
    breadcrumb.data = Map<String, dynamic>.from(sanitizeAppObservedMap(data));
  }
  return breadcrumb;
}

SentryEvent sanitizeAppObservedEvent(SentryEvent event) {
  event.request = sanitizeAppObservedRequest(event.request);
  final message = event.message;
  if (message != null) {
    message.formatted = sanitizeAppObservedText(message.formatted);
    message.template = message.template == null
        ? null
        : sanitizeAppObservedText(message.template!);
    message.params = message.params
        ?.map((value) => sanitizeAppObservedValue(value))
        .toList(growable: false);
  }
  for (final exception in event.exceptions ?? const <SentryException>[]) {
    exception.value = exception.value == null
        ? null
        : sanitizeAppObservedText(exception.value!);
    exception.throwable = null;
  }
  for (final breadcrumb in event.breadcrumbs ?? const <Breadcrumb>[]) {
    sanitizeAppObservedBreadcrumb(breadcrumb);
  }
  final tags = event.tags;
  if (tags != null) {
    event.tags = {
      for (final entry in tags.entries)
        sanitizeAppObservedText(
          entry.key,
        ): (isSensitiveAppObservedKey(entry.key)
            ? appObservedFilteredValue
            : sanitizeAppObservedText(entry.value)),
    };
  }
  // Legacy SDK integrations can still populate `extra`; sanitize before send.
  // ignore: deprecated_member_use
  final extra = event.extra;
  if (extra != null) {
    // ignore: deprecated_member_use
    event.extra = Map<String, dynamic>.from(sanitizeAppObservedMap(extra));
  }
  for (final key in event.contexts.keys.toList(growable: false)) {
    final value = event.contexts[key];
    if (value is Map || value is Iterable || value is String) {
      event.contexts[key] = sanitizeAppObservedValue(value, key: key);
    }
  }
  final userId = event.user?.id?.trim();
  event.user = userId == null || userId.isEmpty
      ? null
      : SentryUser(id: sanitizeAppObservedText(userId));
  return event;
}
