import 'dart:math';

import 'package:dart_frog/dart_frog.dart';

class RequestTrace {
  RequestTrace({required this.requestId});

  final String requestId;
  String? userId;
}

final Random _requestIdRandom = Random.secure();
const int requestIdMaxLength = 96;
final RegExp _requestIdPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,95}$');

bool isValidRequestId(String? value) {
  final candidate = value?.trim();
  return candidate != null &&
      candidate.isNotEmpty &&
      candidate.length <= requestIdMaxLength &&
      _requestIdPattern.hasMatch(candidate);
}

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
  final resolvedPrefix =
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,15}$').hasMatch(prefix)
          ? prefix
          : 'srv';
  final timestamp = resolvedNow.microsecondsSinceEpoch.toRadixString(16);
  final entropy = resolvedRandom.nextInt(1 << 32).toRadixString(16);
  return '$resolvedPrefix-$timestamp-$entropy';
}

String resolveRequestId(
  Map<String, String> headers, {
  String prefix = 'srv',
  DateTime? now,
  Random? random,
}) {
  final existing = headerValueIgnoreCase(headers, 'x-request-id')?.trim();
  if (isValidRequestId(existing)) {
    return existing!;
  }
  return generateRequestId(prefix: prefix, now: now, random: random);
}

RequestTrace getRequestTrace(RequestContext context) =>
    context.read<RequestTrace>();
