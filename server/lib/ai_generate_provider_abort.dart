import 'dart:async';

import 'package:http/http.dart' as http;

const aiGenerateInternalJobIdHeader = 'x-internal-ai-generate-job-id';

enum AiGenerateProviderAbortReason { timeout, jobCancelled }

class AiGenerateProviderCancelledException implements Exception {
  const AiGenerateProviderCancelledException();

  @override
  String toString() => 'AI generate provider request was cancelled.';
}

class AiGenerateJobCancellationMonitor {
  AiGenerateJobCancellationMonitor({
    required Future<bool> Function() isActive,
    this.interval = const Duration(seconds: 1),
    this.onCheckError,
  }) : _isActive = isActive {
    if (interval <= Duration.zero) {
      throw ArgumentError.value(interval, 'interval', 'Must be positive.');
    }
  }

  final Future<bool> Function() _isActive;
  final Duration interval;
  final void Function(Object error)? onCheckError;
  final Completer<void> _cancelled = Completer<void>();

  Timer? _timer;
  bool _started = false;
  bool _stopped = false;
  bool _checkInFlight = false;

  Future<void> get cancelled => _cancelled.future;

  void start() {
    if (_started || _stopped) return;
    _started = true;
    unawaited(_check());
    _timer = Timer.periodic(interval, (_) => unawaited(_check()));
  }

  void stop() {
    if (_stopped) return;
    _stopped = true;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _check() async {
    if (_stopped || _checkInFlight || _cancelled.isCompleted) return;
    _checkInFlight = true;
    try {
      final active = await _isActive();
      if (!_stopped && !active && !_cancelled.isCompleted) {
        _cancelled.complete();
        stop();
      }
    } catch (error) {
      if (!_stopped) onCheckError?.call(error);
    } finally {
      _checkInFlight = false;
    }
  }
}

Future<http.Response> executeAiGenerateProviderRequest({
  required Future<http.Response> Function(Future<void> abortTrigger) send,
  required Duration timeout,
  Future<void>? cancellationTrigger,
}) {
  if (timeout <= Duration.zero) {
    throw ArgumentError.value(timeout, 'timeout', 'Must be positive.');
  }

  final abortSignal = Completer<void>();
  final stopped = Completer<http.Response>();
  AiGenerateProviderAbortReason? abortReason;

  void abort(
    AiGenerateProviderAbortReason reason,
    Object error,
    StackTrace stackTrace,
  ) {
    if (abortReason != null) return;
    abortReason = reason;
    if (!abortSignal.isCompleted) abortSignal.complete();
    if (!stopped.isCompleted) stopped.completeError(error, stackTrace);
  }

  final timeoutTimer = Timer(
    timeout,
    () => abort(
      AiGenerateProviderAbortReason.timeout,
      TimeoutException('AI generate provider request timed out.', timeout),
      StackTrace.current,
    ),
  );

  if (cancellationTrigger != null) {
    unawaited(
      cancellationTrigger.then<void>(
        (_) => abort(
          AiGenerateProviderAbortReason.jobCancelled,
          const AiGenerateProviderCancelledException(),
          StackTrace.current,
        ),
        onError: (Object _, StackTrace __) {
          // Cancellation signals are control flow and must never fail the
          // provider request because their producer failed.
        },
      ),
    );
  }

  Future<http.Response> sendAbortable() async {
    try {
      return await send(abortSignal.future);
    } on http.RequestAbortedException {
      switch (abortReason) {
        case AiGenerateProviderAbortReason.timeout:
          throw TimeoutException(
            'AI generate provider request timed out.',
            timeout,
          );
        case AiGenerateProviderAbortReason.jobCancelled:
          throw const AiGenerateProviderCancelledException();
        case null:
          rethrow;
      }
    }
  }

  return Future.any<http.Response>([
    sendAbortable(),
    stopped.future,
  ]).whenComplete(timeoutTimer.cancel);
}

Future<http.Response> sendAiGenerateProviderHttpRequest({
  required http.Client client,
  required Uri uri,
  required Map<String, String> headers,
  required String body,
  required Future<void> abortTrigger,
}) async {
  final request =
      http.AbortableRequest('POST', uri, abortTrigger: abortTrigger)
        ..headers.addAll(headers)
        ..body = body;
  return http.Response.fromStream(await client.send(request));
}

String? normalizeInternalAiGenerateJobId(Object? raw) {
  final value = raw?.toString().trim().toLowerCase();
  if (value == null || !RegExp(r'^[a-f0-9]{32}$').hasMatch(value)) {
    return null;
  }
  return value;
}
