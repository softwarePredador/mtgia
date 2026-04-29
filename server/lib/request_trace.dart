import 'dart:math';

import 'package:dart_frog/dart_frog.dart';

class RequestTrace {
  RequestTrace({required this.requestId});

  final String requestId;
  String? userId;
}

final Random _requestIdRandom = Random.secure();

String? headerValueIgnoreCase(Map<String, String> headers, String key) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == key.toLowerCase()) {
      return entry.value;
    }
  }
  return null;
}

String generateRequestId({
  String prefix = 'srv',
  DateTime? now,
  Random? random,
}) {
  final resolvedNow = now ?? DateTime.now();
  final resolvedRandom = random ?? _requestIdRandom;
  final timestamp = resolvedNow.microsecondsSinceEpoch.toRadixString(16);
  final entropy = resolvedRandom.nextInt(1 << 32).toRadixString(16);
  return '$prefix-$timestamp-$entropy';
}

String resolveRequestId(
  Map<String, String> headers, {
  String prefix = 'srv',
  DateTime? now,
  Random? random,
}) {
  final existing = headerValueIgnoreCase(headers, 'x-request-id')?.trim();
  if (existing != null && existing.isNotEmpty) {
    return existing;
  }
  return generateRequestId(prefix: prefix, now: now, random: random);
}

RequestTrace getRequestTrace(RequestContext context) =>
    context.read<RequestTrace>();

String? tryGetRequestId(RequestContext context) {
  try {
    return getRequestTrace(context).requestId;
  } catch (_) {
    return null;
  }
}
