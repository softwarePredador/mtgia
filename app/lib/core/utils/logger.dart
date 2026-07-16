import 'dart:async';

import 'package:flutter/foundation.dart';

import '../observability/app_observability.dart';

/// Logger centralizado que só exibe logs em modo debug/development.
/// Em produção (release mode), os logs são silenciados.
class AppLogger {
  /// Log apenas em modo debug (kDebugMode)
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint(sanitizeAppLogMessage(message));
    }
  }

  /// Log de erro - sempre exibe (útil para tracking)
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    final safeMessage = sanitizeAppLogMessage(message);
    final safeError =
        error == null
            ? null
            : _SanitizedAppLogError(
              error.runtimeType.toString(),
              sanitizeAppLogMessage(error.toString()),
            );
    if (kDebugMode) {
      debugPrint('❌ ERROR: $safeMessage');
      if (safeError != null) debugPrint('  -> $safeError');
      if (stackTrace != null) debugPrint('  -> $stackTrace');
    }

    if (safeError != null) {
      unawaited(
        AppObservability.instance.captureException(
          safeError,
          stackTrace: stackTrace,
          tags: const {'source': 'app_logger'},
          extras: {'message': safeMessage},
        ),
      );
    }
  }

  /// Log de warning
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ WARNING: ${sanitizeAppLogMessage(message)}');
    }
  }

  /// Log de info
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ ${sanitizeAppLogMessage(message)}');
    }
  }
}

String sanitizeAppLogMessage(String message) {
  var redacted = message;
  final patterns = <MapEntry<RegExp, String>>[
    MapEntry(
      RegExp(
        r'(authorization\s*:?\s*bearer\s+)[A-Za-z0-9\-._~+/=]+',
        caseSensitive: false,
      ),
      r'$1[REDACTED]',
    ),
    MapEntry(
      RegExp(
        r'((?:api[_-]?key|openai[_-]?api[_-]?key|jwt[_-]?secret|password|fcm[_-]?token)\s*[=:]\s*)[^\s,;&]+',
        caseSensitive: false,
      ),
      r'$1[REDACTED]',
    ),
    MapEntry(RegExp(r'\bsk-[A-Za-z0-9_-]{8,}\b'), '[REDACTED_OPENAI_KEY]'),
    MapEntry(
      RegExp(
        r'([?&](?:access_token|token|api_key|key|password|secret)=)[^&#\s]+',
        caseSensitive: false,
      ),
      r'$1[REDACTED]',
    ),
    MapEntry(
      RegExp(
        r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
        caseSensitive: false,
      ),
      '[REDACTED_EMAIL]',
    ),
  ];

  for (final entry in patterns) {
    redacted = redacted.replaceAllMapped(entry.key, (match) {
      if (entry.value.contains(r'$1') && match.groupCount >= 1) {
        return entry.value.replaceFirst(r'$1', match.group(1) ?? '');
      }
      return entry.value;
    });
  }
  return redacted;
}

final class _SanitizedAppLogError implements Exception {
  const _SanitizedAppLogError(this.type, this.message);

  final String type;
  final String message;

  @override
  String toString() => '$type: $message';
}
