import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/decks/providers/deck_provider_support_ai.dart';
import 'package:manaloom/features/decks/providers/deck_provider_support_generation.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({required this.response});

  final ApiResponse response;

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async => response;

  @override
  Future<ApiResponse> get(String endpoint) async => response;
}

void main() {
  group('AI runtime contracts', () {
    test('generate polling honors the backend one-second interval', () {
      expect(
        pollIntervalFromGenerateAccepted({'poll_interval_ms': 1000}),
        const Duration(seconds: 1),
      );
      expect(
        pollIntervalFromGenerateAccepted({'poll_interval_ms': '2500'}),
        const Duration(milliseconds: 2500),
      );
    });

    test('generate polling rejects invalid hints and bounds unsafe values', () {
      expect(pollIntervalFromGenerateAccepted(const {}), isNull);
      expect(pollIntervalFromGenerateAccepted({'poll_interval_ms': 0}), isNull);
      expect(
        pollIntervalFromGenerateAccepted({'poll_interval_ms': 1}),
        const Duration(seconds: 1),
      );
      expect(
        pollIntervalFromGenerateAccepted({'poll_interval_ms': 12000}),
        const Duration(seconds: 10),
      );
    });

    test('invalid optimize async contract stays player-facing', () async {
      final client = _FakeApiClient(
        response: ApiResponse(202, {'status': 'pending'}),
      );

      await expectLater(
        requestOptimizeDeck(
          client,
          deckId: 'deck-1',
          archetype: 'control',
          keepTheme: true,
        ),
        throwsA(
          isA<Exception>()
              .having(
                (error) => error.toString(),
                'message',
                contains('Não foi possível iniciar a otimização'),
              )
              .having(
                (error) => error.toString().toLowerCase(),
                'technical wording',
                isNot(contains('job')),
              ),
        ),
      );
    });

    test('rebuild server failures do not expose raw status codes', () async {
      final client = _FakeApiClient(
        response: ApiResponse(503, {'error': 'database unavailable'}),
      );

      await expectLater(
        requestRebuildDeck(
          client,
          deckId: 'deck-1',
          rebuildScope: 'auto',
          saveMode: 'draft_clone',
          mustKeep: const [],
          mustAvoid: const [],
        ),
        throwsA(
          isA<Exception>()
              .having(
                (error) => error.toString(),
                'message',
                contains('indisponível'),
              )
              .having(
                (error) => error.toString(),
                'raw status',
                isNot(contains('503')),
              ),
        ),
      );
    });

    test('expired optimize polling stays player-facing', () async {
      final client = _FakeApiClient(
        response: ApiResponse(404, {'error': 'job not found'}),
      );

      await expectLater(
        pollOptimizeJobRequest(client, 'job-1'),
        throwsA(
          isA<Exception>()
              .having(
                (error) => error.toString(),
                'message',
                contains('demorou mais que o esperado'),
              )
              .having(
                (error) => error.toString().toLowerCase(),
                'technical wording',
                isNot(contains('job')),
              ),
        ),
      );
    });
  });
}
