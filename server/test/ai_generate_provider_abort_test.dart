import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../lib/ai_generate_provider_abort.dart';
import '../routes/ai/generate/index.dart' as generate_route;

void main() {
  group('AI generate provider physical abort', () {
    test('builds an AbortableRequest with the supplied trigger', () async {
      final client = _RecordingClient();
      final abortTrigger = Completer<void>();

      final response = await sendAiGenerateProviderHttpRequest(
        client: client,
        uri: Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: const {'content-type': 'application/json'},
        body: '{"model":"test"}',
        abortTrigger: abortTrigger.future,
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(client.request, isA<http.AbortableRequest>());
      final request = client.request! as http.AbortableRequest;
      expect(identical(request.abortTrigger, abortTrigger.future), isTrue);
      expect(request.headers['content-type'], 'application/json');
      expect(request.body, '{"model":"test"}');
    });

    test('maps a job cancellation to a typed terminal exception', () async {
      final jobCancelled = Completer<void>();
      var providerAbortObserved = false;

      final result = executeAiGenerateProviderRequest(
        send: (abortTrigger) async {
          await abortTrigger;
          providerAbortObserved = true;
          throw http.RequestAbortedException(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
          );
        },
        timeout: const Duration(seconds: 1),
        cancellationTrigger: jobCancelled.future,
      );
      jobCancelled.complete();

      await expectLater(
        result,
        throwsA(isA<AiGenerateProviderCancelledException>()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(providerAbortObserved, isTrue);
    });

    test('polls durable job state and signals cancellation', () async {
      var checks = 0;
      final monitor = AiGenerateJobCancellationMonitor(
        isActive: () async {
          checks += 1;
          return checks < 2;
        },
        interval: const Duration(milliseconds: 1),
      );
      addTearDown(monitor.stop);

      monitor.start();
      await monitor.cancelled.timeout(const Duration(seconds: 1));

      expect(checks, greaterThanOrEqualTo(2));
    });

    test('accepts only canonical internal generate job ids', () {
      expect(
        normalizeInternalAiGenerateJobId(' AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA '),
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      );
      for (final value in <Object?>[
        null,
        '',
        'job-1',
        'g' * 32,
        'a' * 31,
        'a' * 33,
      ]) {
        expect(normalizeInternalAiGenerateJobId(value), isNull);
      }
    });

    test('returns a non-cacheable cancellation contract', () async {
      final response = generate_route.buildAiGenerateProviderCancelledResponse(
        cacheKey: 'cancelled-cache-key',
        timings: const {
          'openai_ms': 12,
          'openai_timeout_ms': 120000,
          'total_ms': 20,
        },
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.conflict);
      expect(response.headers['cache-control'], 'no-store');
      expect(body['error_code'], 'ai_generation_cancelled');
      expect(body['outcome_code'], 'cancelled');
      expect(body['retryable'], isTrue);
      expect(body['can_save'], isFalse);
      expect(body['learning_eligible'], isFalse);
      expect(body['generated_deck'], isNull);
      expect((body['provider'] as Map)['status'], 'cancelled');
    });

    test('wires durable cancellation from the worker to the provider', () {
      final routeSource =
          File('routes/ai/generate/index.dart').readAsStringSync();
      final jobStoreSource =
          File('lib/ai_generate_job.dart').readAsStringSync();

      expect(routeSource, contains('aiGenerateInternalJobIdHeader: jobId'));
      expect(
        routeSource,
        contains('InternalAiRequestToken.matches(context.request.headers)'),
      );
      expect(
        routeSource,
        contains('AiGenerateJobStore.isActive(pool, internalJobId)'),
      );
      expect(jobStoreSource, contains("status IN ('pending', 'processing')"));
    });
  });
}

class _RecordingClient extends http.BaseClient {
  http.BaseRequest? request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request;
    return http.StreamedResponse(
      Stream.value(utf8.encode('{}')),
      HttpStatus.ok,
      request: request,
    );
  }
}
