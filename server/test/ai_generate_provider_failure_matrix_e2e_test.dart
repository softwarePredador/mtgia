import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../lib/ai_generate_performance_support.dart';
import '../lib/ai_generate_provider_abort.dart';
import '../lib/ai_provider_runtime_support.dart';
import '../routes/ai/generate/index.dart' as generate_route;

void main() {
  test(
    'S8-04 controlled transport and public response cover provider failures',
    () async {
      final fixture = await _ProviderFailureFixture.start();
      addTearDown(fixture.close);
      final measurements = <String, int>{};

      for (final scenario in <({String path, int status})>[
        (path: 'rate-limit', status: HttpStatus.tooManyRequests),
        (path: 'unauthorized', status: HttpStatus.unauthorized),
        (path: 'forbidden', status: HttpStatus.forbidden),
        (path: 'server-error', status: HttpStatus.serviceUnavailable),
      ]) {
        final stopwatch = Stopwatch()..start();
        final client = http.Client();
        addTearDown(client.close);
        final response = await executeAiGenerateProviderRequest(
          send:
              (abortTrigger) => sendAiGenerateProviderHttpRequest(
                client: client,
                uri: fixture.uri(scenario.path),
                headers: const {'content-type': 'application/json'},
                body: '{"model":"controlled-fixture"}',
                abortTrigger: abortTrigger,
              ),
          timeout: const Duration(seconds: 2),
        );
        stopwatch.stop();
        measurements['${scenario.path}_ms'] = stopwatch.elapsedMilliseconds;

        expect(response.statusCode, scenario.status);
        expect(
          response.body,
          contains(_ProviderFailureFixture.privateProviderDetail),
          reason: 'The fixture must prove that raw upstream detail existed.',
        );
        final contract = classifyAiProviderHttpFailure(response.statusCode);
        final retryAfterSeconds =
            contract.category == AiProviderFailureCategory.rateLimited
                ? parseAiProviderRetryAfterSeconds(
                  response.headers[HttpHeaders.retryAfterHeader],
                )
                : null;
        final publicResponse = generate_route
            .buildAiGenerateProviderFailureResponse(
              cacheKey: _cacheKey(scenario.path),
              timings: {
                'openai_ms': stopwatch.elapsedMilliseconds,
                'total_ms': stopwatch.elapsedMilliseconds,
              },
              contract: contract,
              retryAfterSeconds: retryAfterSeconds,
            );
        await _expectSanitizedFailure(
          publicResponse,
          expectedErrorCode:
              scenario.status == HttpStatus.tooManyRequests
                  ? 'provider_rate_limited'
                  : 'provider_unavailable',
          expectedProviderStatus:
              scenario.status == HttpStatus.tooManyRequests
                  ? 'rate_limited'
                  : 'unavailable',
          retryable:
              scenario.status == HttpStatus.tooManyRequests ||
              scenario.status >= 500,
          expectedRetryAfterSeconds:
              scenario.status == HttpStatus.tooManyRequests ? 1 : null,
        );
      }

      final dropStopwatch = Stopwatch()..start();
      final dropClient = http.Client();
      addTearDown(dropClient.close);
      Object? dropError;
      try {
        await executeAiGenerateProviderRequest(
          send:
              (abortTrigger) => sendAiGenerateProviderHttpRequest(
                client: dropClient,
                uri: fixture.uri('connection-drop'),
                headers: const {'content-type': 'application/json'},
                body: '{"model":"controlled-fixture"}',
                abortTrigger: abortTrigger,
              ),
          timeout: const Duration(seconds: 2),
        );
      } catch (error) {
        dropError = error;
      }
      dropStopwatch.stop();
      measurements['connection_drop_ms'] = dropStopwatch.elapsedMilliseconds;
      expect(dropError, anyOf(isA<http.ClientException>(), isA<IOException>()));
      await _expectSanitizedFailure(
        generate_route.buildAiGenerateProviderFailureResponse(
          cacheKey: _cacheKey('connection-drop'),
          timings: {
            'openai_ms': dropStopwatch.elapsedMilliseconds,
            'total_ms': dropStopwatch.elapsedMilliseconds,
          },
          contract: aiProviderTransportFailureContract,
        ),
        expectedErrorCode: 'provider_transport_error',
        expectedProviderStatus: 'unavailable',
        retryable: true,
      );

      final timeoutStopwatch = Stopwatch()..start();
      final timeoutClient = http.Client();
      addTearDown(timeoutClient.close);
      await expectLater(
        executeAiGenerateProviderRequest(
          send:
              (abortTrigger) => sendAiGenerateProviderHttpRequest(
                client: timeoutClient,
                uri: fixture.uri('timeout'),
                headers: const {'content-type': 'application/json'},
                body: '{"model":"controlled-fixture"}',
                abortTrigger: abortTrigger,
              ),
          timeout: const Duration(milliseconds: 150),
        ),
        throwsA(isA<TimeoutException>()),
      );
      timeoutStopwatch.stop();
      measurements['timeout_ms'] = timeoutStopwatch.elapsedMilliseconds;
      await fixture.expectPeerClosed('timeout');
      final timeoutResponse = generate_route
          .buildAiGenerateProviderTimeoutResponse(
            cacheKey: _cacheKey('timeout'),
            timings: {
              'openai_ms': timeoutStopwatch.elapsedMilliseconds,
              'openai_timeout_ms': 150,
              'total_ms': timeoutStopwatch.elapsedMilliseconds,
            },
            timeout: const Duration(milliseconds: 150),
            timeoutKey: 'CONTROLLED_FIXTURE_TIMEOUT',
            referenceGuidanceBudget: false,
          );
      await _expectSanitizedFailure(
        timeoutResponse,
        expectedErrorCode: 'provider_timeout',
        expectedProviderStatus: 'timeout',
        retryable: true,
      );

      final cancellation = Completer<void>();
      final cancelStopwatch = Stopwatch()..start();
      final cancelClient = http.Client();
      addTearDown(cancelClient.close);
      final cancelledRequest = executeAiGenerateProviderRequest(
        send:
            (abortTrigger) => sendAiGenerateProviderHttpRequest(
              client: cancelClient,
              uri: fixture.uri('cancel'),
              headers: const {'content-type': 'application/json'},
              body: '{"model":"controlled-fixture"}',
              abortTrigger: abortTrigger,
            ),
        timeout: const Duration(seconds: 2),
        cancellationTrigger: cancellation.future,
      );
      await fixture.expectRequestSeen('cancel');
      cancellation.complete();
      await expectLater(
        cancelledRequest,
        throwsA(isA<AiGenerateProviderCancelledException>()),
      );
      cancelStopwatch.stop();
      measurements['cancel_ms'] = cancelStopwatch.elapsedMilliseconds;
      await fixture.expectPeerClosed('cancel');
      await _expectSanitizedFailure(
        generate_route.buildAiGenerateProviderCancelledResponse(
          cacheKey: _cacheKey('cancel'),
          timings: {
            'openai_ms': cancelStopwatch.elapsedMilliseconds,
            'total_ms': cancelStopwatch.elapsedMilliseconds,
          },
        ),
        expectedErrorCode: 'ai_generation_cancelled',
        expectedProviderStatus: 'cancelled',
        retryable: true,
        expectedError: 'A geração foi cancelada.',
      );

      expect(measurements.values, everyElement(lessThan(2000)));
      final routeSource =
          File('routes/ai/generate/index.dart').readAsStringSync();
      expect(
        routeSource,
        contains('error is http.ClientException || error is IOException'),
      );
      expect(
        routeSource,
        contains('contract: aiProviderTransportFailureContract'),
      );
      expect(
        routeSource,
        contains('final failureContract = classifyAiProviderHttpFailure('),
      );
      expect(routeSource, contains('retryAfterSeconds:'));
      // ignore: avoid_print
      print(
        'AI_GENERATE_PROVIDER_FAILURE_MATRIX '
        '${jsonEncode({
          'schema': 'ai_generate_provider_failure_matrix_v1',
          'classification': 'controlled_loopback_provider_transport_and_public_response_contract_not_route_on_request',
          'scenarios': const ['http_429', 'http_401', 'http_403', 'http_5xx', 'connection_drop', 'timeout_with_physical_abort', 'cancellation_with_physical_abort'],
          'measurements_ms': measurements,
          'public_contract': const {'cache_control': 'no-store', 'outcome_code': 'provider_unavailable_or_cancelled', 'can_save': false, 'learning_eligible': false, 'generated_deck': null, 'raw_provider_detail_exposed': false},
        })}',
      );
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}

String _cacheKey(String scenario) => buildAiGenerateCacheKey(
  prompt: 'controlled failure matrix $scenario',
  format: 'commander',
);

Future<void> _expectSanitizedFailure(
  dynamic response, {
  required String expectedErrorCode,
  required String expectedProviderStatus,
  required bool retryable,
  String expectedError = aiProviderUnavailableMessage,
  int? expectedRetryAfterSeconds,
}) async {
  final body = jsonDecode(await response.body()) as Map<String, dynamic>;
  final provider = (body['provider'] as Map).cast<String, dynamic>();
  final encoded = jsonEncode(body);

  expect(response.statusCode, isNot(HttpStatus.ok));
  expect(response.headers['cache-control'], 'no-store');
  expect(body['error'], expectedError);
  expect(body['error_code'], expectedErrorCode);
  expect(body['outcome_code'], anyOf('provider_unavailable', 'cancelled'));
  expect(body['retryable'], retryable);
  expect(body['can_save'], isFalse);
  expect(body['learning_eligible'], isFalse);
  expect(body['generated_deck'], isNull);
  expect(body['retry_after_seconds'], expectedRetryAfterSeconds);
  expect(
    response.headers[HttpHeaders.retryAfterHeader],
    expectedRetryAfterSeconds?.toString(),
  );
  expect(provider['operation'], 'generate');
  expect(provider['status'], expectedProviderStatus);
  expect(
    encoded,
    isNot(contains(_ProviderFailureFixture.privateProviderDetail)),
  );
  expect(encoded, isNot(contains('127.0.0.1')));
  expect(encoded, isNot(contains('connection-drop')));
  expect(encoded, isNot(contains('SocketException')));
  expect(encoded, isNot(contains('ClientException')));
}

class _ProviderFailureFixture {
  _ProviderFailureFixture._(this._server);

  static const privateProviderDetail =
      'PRIVATE_UPSTREAM_DETAIL_MUST_NEVER_REACH_THE_APP';

  final HttpServer _server;
  final Map<String, Completer<void>> _requestSeen = {};
  final Map<String, Completer<void>> _peerClosed = {};
  final List<Socket> _detachedSockets = [];

  static Future<_ProviderFailureFixture> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fixture = _ProviderFailureFixture._(server);
    server.listen(fixture._handle);
    return fixture;
  }

  Uri uri(String scenario) =>
      Uri.parse('http://127.0.0.1:${_server.port}/$scenario');

  Future<void> expectRequestSeen(String scenario) => _signal(
    _requestSeen,
    scenario,
  ).future.timeout(const Duration(seconds: 2));

  Future<void> expectPeerClosed(String scenario) =>
      _signal(_peerClosed, scenario).future.timeout(const Duration(seconds: 2));

  Future<void> close() async {
    for (final socket in _detachedSockets) {
      socket.destroy();
    }
    await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    final scenario = request.uri.pathSegments.single;
    await request.drain<void>();
    _complete(_requestSeen, scenario);

    if (scenario == 'rate-limit') {
      request.response
        ..statusCode = HttpStatus.tooManyRequests
        ..headers.contentType = ContentType.json
        ..headers.set(HttpHeaders.retryAfterHeader, '1')
        ..write(
          jsonEncode({
            'error': privateProviderDetail,
            'provider_request_id': 'private-request-id',
          }),
        );
      await request.response.close();
      return;
    }
    if (scenario == 'server-error') {
      request.response
        ..statusCode = HttpStatus.serviceUnavailable
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'error': privateProviderDetail,
            'provider_trace': 'private-trace',
          }),
        );
      await request.response.close();
      return;
    }
    if (scenario == 'unauthorized' || scenario == 'forbidden') {
      request.response
        ..statusCode =
            scenario == 'unauthorized'
                ? HttpStatus.unauthorized
                : HttpStatus.forbidden
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'error': privateProviderDetail,
            'provider_credential': 'private-credential-detail',
          }),
        );
      await request.response.close();
      return;
    }

    final socket = await request.response.detachSocket(writeHeaders: false);
    _detachedSockets.add(socket);
    if (scenario == 'connection-drop') {
      socket.destroy();
      return;
    }
    socket.listen(
      (_) {},
      onDone: () => _complete(_peerClosed, scenario),
      onError: (_) => _complete(_peerClosed, scenario),
      cancelOnError: true,
    );
  }

  Completer<void> _signal(
    Map<String, Completer<void>> signals,
    String scenario,
  ) => signals.putIfAbsent(scenario, Completer<void>.new);

  void _complete(Map<String, Completer<void>> signals, String scenario) {
    final signal = _signal(signals, scenario);
    if (!signal.isCompleted) signal.complete();
  }
}
