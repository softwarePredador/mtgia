import 'dart:async';
import 'dart:math';

const aiJobRequestKeyMaxLength = 128;
const aiJobHeartbeatInterval = Duration(seconds: 10);

class AiJobExecutionTimeoutException implements Exception {
  const AiJobExecutionTimeoutException();

  @override
  String toString() => 'AI job exceeded its total execution deadline.';
}

class AiJobNoLongerActiveException implements Exception {
  const AiJobNoLongerActiveException();

  @override
  String toString() => 'AI job is no longer active.';
}

class AiJobRequestKeyException implements Exception {
  const AiJobRequestKeyException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AiJobIdempotencyConflict implements Exception {
  const AiJobIdempotencyConflict();

  @override
  String toString() => 'A chave de idempotencia ja foi usada com outro pedido.';
}

class AiJobCreation {
  const AiJobCreation({
    required this.jobId,
    required this.requestKey,
    required this.isNew,
  });

  final String jobId;
  final String requestKey;
  final bool isNew;
}

String? normalizeOptionalAiJobRequestKey(Object? raw) {
  if (raw == null) return null;
  if (raw is! String) {
    throw const AiJobRequestKeyException('request_key precisa ser uma string.');
  }
  final value = raw.trim();
  if (value.isEmpty || value.length > aiJobRequestKeyMaxLength) {
    throw const AiJobRequestKeyException(
      'request_key precisa ter entre 1 e 128 caracteres.',
    );
  }
  if (!RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(value)) {
    throw const AiJobRequestKeyException(
      'request_key contem caracteres invalidos.',
    );
  }
  return value;
}

String createServerAiJobRequestKey(String prefix) {
  final random = Random.secure();
  final suffix =
      List.generate(
        16,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
  return '$prefix:$suffix';
}

Future<T> runAiJobExecution<T>({
  required Future<T> Function() operation,
  required Future<bool> Function() heartbeat,
  required Duration timeout,
  Duration heartbeatInterval = aiJobHeartbeatInterval,
}) async {
  if (timeout <= Duration.zero) {
    throw ArgumentError.value(timeout, 'timeout', 'Must be positive.');
  }
  if (heartbeatInterval <= Duration.zero) {
    throw ArgumentError.value(
      heartbeatInterval,
      'heartbeatInterval',
      'Must be positive.',
    );
  }

  if (!await heartbeat()) {
    throw const AiJobNoLongerActiveException();
  }

  final inactive = Completer<T>();
  var heartbeatInFlight = false;

  Future<void> sendHeartbeat() async {
    if (heartbeatInFlight || inactive.isCompleted) return;
    heartbeatInFlight = true;
    try {
      if (!await heartbeat() && !inactive.isCompleted) {
        inactive.completeError(const AiJobNoLongerActiveException());
      }
    } catch (error, stackTrace) {
      if (!inactive.isCompleted) {
        inactive.completeError(error, stackTrace);
      }
    } finally {
      heartbeatInFlight = false;
    }
  }

  final timer = Timer.periodic(
    heartbeatInterval,
    (_) => unawaited(sendHeartbeat()),
  );
  final deadline = Future<T>.delayed(
    timeout,
    () => throw const AiJobExecutionTimeoutException(),
  );

  try {
    return await Future.any<T>([
      Future<T>.sync(operation),
      inactive.future,
      deadline,
    ]);
  } finally {
    timer.cancel();
  }
}
