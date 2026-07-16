import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({
    Map<String, ApiResponse Function(Map<String, dynamic>)>? postHandlers,
    Map<String, ApiResponse Function()>? getHandlers,
    Map<String, ApiResponse Function(Map<String, dynamic>)>? putHandlers,
    Map<String, ApiResponse Function()>? deleteHandlers,
  }) : _postHandlers = postHandlers ?? const {},
       _getHandlers = getHandlers ?? const {},
       _putHandlers = putHandlers ?? const {},
       _deleteHandlers = deleteHandlers ?? const {};

  final Map<String, ApiResponse Function(Map<String, dynamic>)> _postHandlers;
  final Map<String, ApiResponse Function()> _getHandlers;
  final Map<String, ApiResponse Function(Map<String, dynamic>)> _putHandlers;
  final Map<String, ApiResponse Function()> _deleteHandlers;
  final List<String> postCalls = [];
  final List<Map<String, dynamic>> postBodies = [];
  final List<String> getCalls = [];
  final List<String> putCalls = [];
  final List<Map<String, dynamic>> putBodies = [];

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    postCalls.add(endpoint);
    postBodies.add(body);
    final handler = _postHandlers[endpoint];
    if (handler == null) {
      throw UnimplementedError('No POST handler for $endpoint');
    }
    return handler(body);
  }

  @override
  Future<ApiResponse> get(String endpoint) async {
    getCalls.add(endpoint);
    final handler = _getHandlers[endpoint];
    if (handler == null) {
      throw UnimplementedError('No GET handler for $endpoint');
    }
    return handler();
  }

  @override
  Future<ApiResponse> put(String endpoint, Map<String, dynamic> body) async {
    putCalls.add(endpoint);
    putBodies.add(body);
    final handler = _putHandlers[endpoint];
    if (handler == null) {
      throw UnimplementedError('No PUT handler for $endpoint');
    }
    return handler(body);
  }

  @override
  Future<ApiResponse> delete(String endpoint) async {
    final handler = _deleteHandlers[endpoint];
    if (handler == null) {
      throw UnimplementedError('No DELETE handler for $endpoint');
    }
    return handler();
  }
}

Map<String, dynamic> _buildDeckDetailsJson(
  Map<String, int> cardsById, {
  String deckId = 'deck-1',
  List<String> deckColorIdentity = const ['U'],
  List<String> commanderColors = const ['U'],
  List<String> commanderColorIdentity = const ['U'],
  String commanderName = 'Talrand, Sky Summoner',
  String commanderManaCost = '{2}{U}{U}',
  String commanderTypeLine = 'Legendary Creature — Merfolk Wizard',
}) {
  Map<String, dynamic> card(
    String id,
    String name, {
    required int quantity,
    bool isCommander = false,
    List<String> colors = const <String>[],
    List<String> colorIdentity = const <String>[],
    String typeLine = 'Artifact',
    String manaCost = '{2}',
  }) => {
    'id': id,
    'name': name,
    'mana_cost': manaCost,
    'type_line': typeLine,
    'oracle_text': '',
    'colors': colors,
    'color_identity': colorIdentity,
    'image_url': null,
    'set_code': 'tst',
    'set_name': 'Test Set',
    'set_release_date': '2026-01-01',
    'rarity': 'rare',
    'quantity': quantity,
    'is_commander': isCommander,
    'condition': 'NM',
  };

  return {
    'id': deckId,
    'name': 'Smoke Deck',
    'format': 'commander',
    'description': 'Deck para smoke do fluxo core',
    'is_public': false,
    'created_at': '2026-03-23T00:00:00.000Z',
    'color_identity': deckColorIdentity,
    'stats': {
      'total_cards': cardsById.values.fold<int>(0, (sum, qty) => sum + qty),
    },
    'commander': [
      card(
        'cmd-1',
        commanderName,
        quantity: 1,
        isCommander: true,
        colors: commanderColors,
        colorIdentity: commanderColorIdentity,
        typeLine: commanderTypeLine,
        manaCost: commanderManaCost,
      ),
    ],
    'main_board': {
      'Artifacts': [
        if ((cardsById['remove-1'] ?? 0) > 0)
          card('remove-1', 'Mind Stone', quantity: cardsById['remove-1']!),
        if ((cardsById['add-1'] ?? 0) > 0)
          card('add-1', 'Arcane Signet', quantity: cardsById['add-1']!),
      ],
      'Instants': [
        card(
          'spell-1',
          'Opt',
          quantity: cardsById['spell-1'] ?? 1,
          colors: const ['U'],
          colorIdentity: const ['U'],
          typeLine: 'Instant',
          manaCost: '{U}',
        ),
      ],
      'Lands': List.generate(
        cardsById['land-1'] ?? 36,
        (index) => card(
          'land-$index',
          'Island',
          quantity: 1,
          colors: const <String>[],
          colorIdentity: const <String>[],
          typeLine: 'Basic Land — Island',
          manaCost: '',
        ),
      ),
    },
  };
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.resetForTesting();
  });

  group('DeckProvider.createDeck', () {
    test('fails when batch resolve endpoint fails', () async {
      final apiClient = _FakeApiClient(
        postHandlers: {
          '/cards/resolve/batch':
              (_) => ApiResponse(500, {'error': 'resolve failed'}),
        },
      );
      final provider = DeckProvider(apiClient: apiClient);

      final created = await provider.createDeck(
        name: 'Test Deck',
        format: 'commander',
        cards: const [
          {'name': 'Sol Ring', 'quantity': 1, 'is_commander': false},
        ],
      );

      expect(created, isFalse);
      expect(
        provider.errorMessage,
        'Não foi possível encontrar todas as cartas. Revise a lista e tente novamente.',
      );
      expect(apiClient.postCalls, equals(['/cards/resolve/batch']));
    });

    test('fails when batch resolve returns unresolved names', () async {
      final apiClient = _FakeApiClient(
        postHandlers: {
          '/cards/resolve/batch':
              (_) => ApiResponse(200, {
                'data': const [],
                'unresolved': const ['Unknown Card'],
                'total_input': 1,
                'total_resolved': 0,
              }),
        },
      );
      final provider = DeckProvider(apiClient: apiClient);

      final created = await provider.createDeck(
        name: 'Test Deck',
        format: 'commander',
        cards: const [
          {'name': 'Unknown Card', 'quantity': 1, 'is_commander': false},
        ],
      );

      expect(created, isFalse);
      expect(
        provider.errorMessage,
        'Não foi possível encontrar todas as cartas. Revise a lista e tente novamente.',
      );
      expect(apiClient.postCalls, equals(['/cards/resolve/batch']));
    });

    test('fails when batch resolve returns ambiguous names', () async {
      final apiClient = _FakeApiClient(
        postHandlers: {
          '/cards/resolve/batch':
              (_) => ApiResponse(200, {
                'data': const [],
                'unresolved': const [],
                'ambiguous': const [
                  {
                    'input_name': 'Lightning',
                    'candidates': ['Lightning Bolt', 'Lightning Helix'],
                  },
                ],
                'total_input': 1,
                'total_resolved': 0,
                'total_ambiguous': 1,
              }),
        },
      );
      final provider = DeckProvider(apiClient: apiClient);

      final created = await provider.createDeck(
        name: 'Test Deck',
        format: 'commander',
        cards: const [
          {'name': 'Lightning', 'quantity': 1, 'is_commander': false},
        ],
      );

      expect(created, isFalse);
      expect(
        provider.errorMessage,
        'Não foi possível encontrar todas as cartas. Revise a lista e tente novamente.',
      );
      expect(apiClient.postCalls, equals(['/cards/resolve/batch']));
    });

    test(
      'keeps direct card ids and resolved names when creating deck',
      () async {
        final apiClient = _FakeApiClient(
          postHandlers: {
            '/cards/resolve/batch': (body) {
              expect(body['names'], equals(['Sol Ring']));
              return ApiResponse(200, {
                'data': const [
                  {
                    'input_name': 'Sol Ring',
                    'card_id': 'sol-ring-id',
                    'matched_name': 'Sol Ring',
                  },
                ],
                'unresolved': const [],
                'total_input': 1,
                'total_resolved': 1,
              });
            },
            '/decks': (body) {
              expect(body['is_public'], isTrue);
              expect(body['archetype'], 'spellslinger');
              expect(body['bracket'], 3);
              expect(
                body['cards'],
                equals([
                  {
                    'card_id': 'commander-id',
                    'quantity': 1,
                    'is_commander': true,
                  },
                  {
                    'card_id': 'sol-ring-id',
                    'quantity': 2,
                    'is_commander': false,
                  },
                ]),
              );
              return ApiResponse(201, {
                'id': 'deck-1',
                'name': 'Test Deck',
                'format': 'commander',
                'description': null,
                'is_public': true,
                'created_at': '2026-06-20T12:00:00.000Z',
                'card_count': 0,
                'color_identity': const <String>[],
              });
            },
          },
          getHandlers: {'/decks': () => ApiResponse(200, const [])},
        );
        final provider = DeckProvider(
          apiClient: apiClient,
          trackActivationEvent:
              (
                String eventName, {
                String? format,
                String? deckId,
                String source = 'app',
                Map<String, dynamic>? metadata,
              }) async {},
        );

        final created = await provider.createDeck(
          name: 'Test Deck',
          format: 'commander',
          archetype: ' spellslinger ',
          bracket: 3,
          isPublic: true,
          cards: const [
            {'card_id': 'commander-id', 'quantity': 1, 'is_commander': true},
            {'name': 'Sol Ring', 'quantity': 2, 'is_commander': false},
          ],
        );

        expect(created, isTrue);
        expect(apiClient.postCalls, equals(['/cards/resolve/batch', '/decks']));
        expect(provider.decks.single.archetype, 'spellslinger');
        expect(provider.decks.single.bracket, 3);
      },
    );
  });

  group('DeckProvider AI deck flows', () {
    Map<String, dynamic> generatedDeckPayload() => {
      'generated_deck': {
        'commander': {'name': 'Talrand, Sky Summoner'},
        'cards': const [
          {'name': 'Opt', 'quantity': 1},
          {'name': 'Mind Stone', 'quantity': 1},
        ],
      },
      'validation': const {'is_valid': true, 'errors': <String>[]},
    };

    test(
      'fetchCommanderLearningDecks lists active learned commanders',
      () async {
        final apiClient = _FakeApiClient(
          getHandlers: {
            '/ai/commander-learning':
                () => ApiResponse(200, {
                  'available': true,
                  'count': 1,
                  'commanders': const [
                    {
                      'commander': 'Lorehold, the Historian',
                      'source_ref': 'learned_deck:82',
                    },
                  ],
                }),
          },
        );
        final provider = DeckProvider(apiClient: apiClient);

        final decks = await provider.fetchCommanderLearningDecks();

        expect(apiClient.getCalls, equals(['/ai/commander-learning']));
        expect(decks, hasLength(1));
        expect(decks.first['commander'], equals('Lorehold, the Historian'));
        expect(decks.first['source_ref'], equals('learned_deck:82'));
      },
    );

    test('learned deck failures do not expose raw status codes', () async {
      final apiClient = _FakeApiClient(
        getHandlers: {
          '/ai/commander-learning':
              () => ApiResponse(503, {'error': 'database stack trace'}),
        },
      );
      final provider = DeckProvider(apiClient: apiClient);

      await expectLater(
        provider.fetchCommanderLearningDecks(),
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

    test(
      'generateDeck uses async by default and completes via polling',
      () async {
        var pollCount = 0;
        final progressMessages = <String>[];
        final trackedEvents = <String>[];
        Map<String, dynamic>? trackedMetadata;
        final apiClient = _FakeApiClient(
          postHandlers: {
            '/ai/generate': (body) {
              expect(body['prompt'], 'Talrand spellslinger');
              expect(body['format'], 'commander');
              expect(body['async'], isTrue);
              return ApiResponse(202, {
                'job_id': 'job-async-1',
                'status': 'pending',
                'poll_url': '/ai/generate/jobs/job-async-1',
                'poll_interval_ms': 1,
              }, durationMs: 123);
            },
          },
          getHandlers: {
            '/ai/generate/jobs/job-async-1': () {
              pollCount += 1;
              if (pollCount == 1) {
                return ApiResponse(200, {
                  'job_id': 'job-async-1',
                  'status': 'processing',
                  'stage': 'validation',
                  'stage_number': 2,
                  'total_stages': 4,
                });
              }
              return ApiResponse(200, {
                'job_id': 'job-async-1',
                'status': 'completed',
                'result_status_code': 200,
                'result': generatedDeckPayload(),
              });
            },
          },
        );
        final provider = DeckProvider(
          apiClient: apiClient,
          pollDelay: (_) async {},
          trackActivationEvent: (
            String eventName, {
            String? format,
            String? deckId,
            String source = 'app',
            Map<String, dynamic>? metadata,
          }) async {
            trackedEvents.add(eventName);
            trackedMetadata = metadata;
            expect(format, 'commander');
            expect(source, 'deck_provider.generateDeck');
          },
        );

        final result = await provider.generateDeck(
          prompt: 'Talrand spellslinger',
          format: 'Commander',
          pollInterval: Duration.zero,
          onProgress: (progress) => progressMessages.add(progress.message),
        );

        expect(result['generated_deck'], isA<Map>());
        expect(apiClient.postCalls, equals(['/ai/generate']));
        expect(apiClient.getCalls, [
          '/ai/generate/jobs/job-async-1',
          '/ai/generate/jobs/job-async-1',
        ]);
        expect(progressMessages, contains('Pronto para revisar.'));
        expect(
          progressMessages.any((message) => message.contains('Pedido aceito')),
          isTrue,
        );
        expect(trackedEvents, ['deck_generated']);
        expect(trackedMetadata?['prompt_length'], 20);
        expect(trackedMetadata?['commander_selected'], isFalse);
      },
    );

    test(
      'generateDeck sends optional commander_name to async and sync fallback',
      () async {
        var postCount = 0;
        final apiClient = _FakeApiClient(
          postHandlers: {
            '/ai/generate': (body) {
              postCount += 1;
              expect(body['prompt'], 'Boros miracle big spells');
              expect(body['format'], 'commander');
              expect(body['commander_name'], 'Lorehold, the Historian');
              if (postCount == 1) {
                expect(body['async'], isTrue);
                return ApiResponse(400, {'error': 'async unsupported'});
              }
              expect(body.containsKey('async'), isFalse);
              return ApiResponse(200, generatedDeckPayload());
            },
          },
        );
        final provider = DeckProvider(
          apiClient: apiClient,
          pollDelay: (_) async {},
        );

        final result = await provider.generateDeck(
          prompt: 'Boros miracle big spells',
          format: 'Commander',
          commanderName: '  Lorehold, the Historian  ',
        );

        expect(result['generated_deck'], isA<Map>());
        expect(apiClient.postCalls, equals(['/ai/generate', '/ai/generate']));
      },
    );

    test('generateDeck retries async polling after 429 rate limit', () async {
      var pollCount = 0;
      final progressMessages = <String>[];
      final apiClient = _FakeApiClient(
        postHandlers: {
          '/ai/generate': (body) {
            expect(body['async'], isTrue);
            return ApiResponse(202, {
              'job_id': 'job-rate-limit',
              'status': 'pending',
              'poll_url': '/ai/generate/jobs/job-rate-limit',
              'poll_interval_ms': 1,
            });
          },
        },
        getHandlers: {
          '/ai/generate/jobs/job-rate-limit': () {
            pollCount += 1;
            if (pollCount == 1) {
              return ApiResponse(429, {'error': 'too many requests'});
            }
            return ApiResponse(200, {
              'job_id': 'job-rate-limit',
              'status': 'completed',
              'result_status_code': 200,
              'result': generatedDeckPayload(),
            });
          },
        },
      );
      final provider = DeckProvider(apiClient: apiClient);

      final result = await provider.generateDeck(
        prompt: 'Talrand spellslinger',
        format: 'Commander',
        pollInterval: Duration.zero,
        onProgress: (progress) => progressMessages.add(progress.message),
      );

      expect(result['generated_deck'], isA<Map>());
      expect(apiClient.getCalls, [
        '/ai/generate/jobs/job-rate-limit',
        '/ai/generate/jobs/job-rate-limit',
      ]);
      expect(
        progressMessages,
        contains('Aguardando limite do servidor antes de continuar...'),
      );
      expect(progressMessages, contains('Pronto para revisar.'));
    });

    test('generateDeck rejects an async job completed with 422', () async {
      final progressMessages = <String>[];
      final apiClient = _FakeApiClient(
        postHandlers: {
          '/ai/generate':
              (_) => ApiResponse(202, {
                'job_id': 'job-invalid-deck',
                'status': 'pending',
                'poll_url': '/ai/generate/jobs/job-invalid-deck',
                'poll_interval_ms': 1,
              }),
        },
        getHandlers: {
          '/ai/generate/jobs/job-invalid-deck':
              () => ApiResponse(200, {
                'job_id': 'job-invalid-deck',
                'status': 'completed',
                'result_status_code': 422,
                'result': {
                  'error': 'Generated deck failed validation',
                  'generated_deck': {'cards': const <Map<String, dynamic>>[]},
                },
              }),
        },
      );
      final provider = DeckProvider(apiClient: apiClient);

      await expectLater(
        provider.generateDeck(
          prompt: 'invalid commander list',
          format: 'Commander',
          pollInterval: Duration.zero,
          onProgress: (progress) => progressMessages.add(progress.message),
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Não conseguimos gerar um deck válido'),
          ),
        ),
      );
      expect(progressMessages, isNot(contains('Pronto para revisar.')));
    });

    test('generateDeck rejects a malformed async success payload', () async {
      final progressMessages = <String>[];
      final apiClient = _FakeApiClient(
        postHandlers: {
          '/ai/generate':
              (_) => ApiResponse(202, {
                'job_id': 'job-malformed-deck',
                'status': 'pending',
                'poll_url': '/ai/generate/jobs/job-malformed-deck',
                'poll_interval_ms': 1,
              }),
        },
        getHandlers: {
          '/ai/generate/jobs/job-malformed-deck':
              () => ApiResponse(200, {
                'job_id': 'job-malformed-deck',
                'status': 'completed',
                'result_status_code': 200,
                'result': {
                  'generated_deck': {
                    'cards': const <Map<String, dynamic>>[],
                  },
                  'validation': const {'is_valid': true},
                },
              }),
        },
      );
      final provider = DeckProvider(apiClient: apiClient);

      await expectLater(
        provider.generateDeck(
          prompt: 'malformed async fixture',
          format: 'Commander',
          pollInterval: Duration.zero,
          onProgress: (progress) => progressMessages.add(progress.message),
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('não devolveu um deck válido para revisão'),
          ),
        ),
      );
      expect(progressMessages, isNot(contains('Pronto para revisar.')));
    });

    test(
      'generateDeck preserves fallback sync when async is unsupported',
      () async {
        var postCount = 0;
        final apiClient = _FakeApiClient(
          postHandlers: {
            '/ai/generate': (body) {
              postCount += 1;
              if (postCount == 1) {
                expect(body['async'], isTrue);
                return ApiResponse(400, {'error': 'async unsupported'});
              }
              expect(body.containsKey('async'), isFalse);
              return ApiResponse(200, generatedDeckPayload());
            },
          },
        );
        final provider = DeckProvider(apiClient: apiClient);

        final result = await provider.generateDeck(
          prompt: 'Talrand spellslinger',
          format: 'Commander',
        );

        expect(result['generated_deck'], isA<Map>());
        expect(apiClient.postCalls, equals(['/ai/generate', '/ai/generate']));
      },
    );

    test(
      'generateDeck accepts legacy 200 response from async request',
      () async {
        final apiClient = _FakeApiClient(
          postHandlers: {
            '/ai/generate': (body) {
              expect(body['async'], isTrue);
              return ApiResponse(200, generatedDeckPayload());
            },
          },
        );
        final provider = DeckProvider(apiClient: apiClient);

        final result = await provider.generateDeck(
          prompt: 'Talrand spellslinger',
          format: 'Commander',
        );

        expect(result['generated_deck'], isA<Map>());
        expect(apiClient.postCalls, equals(['/ai/generate']));
        expect(apiClient.getCalls, isEmpty);
      },
    );

    test(
      'generateDeck never submits a second action after invalid 202 contract',
      () async {
        final apiClient = _FakeApiClient(
          postHandlers: {
            '/ai/generate':
                (_) => ApiResponse(202, {
                  'job_id': 'job-without-poll-url',
                  'status': 'pending',
                }),
          },
        );
        final provider = DeckProvider(apiClient: apiClient);

        await expectLater(
          provider.generateDeck(
            prompt: 'Talrand spellslinger',
            format: 'Commander',
          ),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              contains('acompanhamento'),
            ),
          ),
        );
        expect(apiClient.postCalls, equals(['/ai/generate']));
        expect(apiClient.getCalls, isEmpty);
      },
    );

    test(
      'generateDeck never falls back to a second action after polling starts',
      () async {
        final apiClient = _FakeApiClient(
          postHandlers: {
            '/ai/generate':
                (_) => ApiResponse(202, {
                  'job_id': 'job-expired',
                  'status': 'pending',
                  'poll_url': '/ai/generate/jobs/job-expired',
                  'poll_interval_ms': 1,
                }),
          },
          getHandlers: {
            '/ai/generate/jobs/job-expired':
                () => ApiResponse(404, {'error': 'async job not found'}),
          },
        );
        final provider = DeckProvider(apiClient: apiClient);

        await expectLater(
          provider.generateDeck(
            prompt: 'Talrand spellslinger',
            format: 'Commander',
            pollInterval: Duration.zero,
          ),
          throwsA(isA<Exception>()),
        );
        expect(apiClient.postCalls, equals(['/ai/generate']));
        expect(apiClient.getCalls, equals(['/ai/generate/jobs/job-expired']));
      },
    );

    test('generateDeck surfaces friendly polling timeout', () async {
      final apiClient = _FakeApiClient(
        postHandlers: {
          '/ai/generate':
              (_) => ApiResponse(202, {
                'job_id': 'job-timeout',
                'status': 'pending',
                'poll_url': '/ai/generate/jobs/job-timeout',
                'poll_interval_ms': 1,
              }),
        },
        getHandlers: {
          '/ai/generate/jobs/job-timeout':
              () => ApiResponse(200, {
                'job_id': 'job-timeout',
                'status': 'processing',
                'stage': 'generation',
              }),
        },
      );
      final provider = DeckProvider(apiClient: apiClient);

      expect(
        () => provider.generateDeck(
          prompt: 'Talrand spellslinger',
          format: 'Commander',
          pollTimeout: const Duration(milliseconds: 1),
          pollInterval: const Duration(milliseconds: 1),
        ),
        throwsA(isA<GenerateDeckTimeoutException>()),
      );
    });

    test('generateDeck maps 4xx failure to friendly message', () async {
      final apiClient = _FakeApiClient(
        postHandlers: {
          '/ai/generate':
              (_) => ApiResponse(400, {
                'error': 'FormatException: /ai/generate stack trace',
              }),
        },
      );
      final provider = DeckProvider(apiClient: apiClient);

      expect(
        () => provider.generateDeck(
          prompt: 'Talrand spellslinger',
          format: 'Commander',
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Não conseguimos gerar uma lista'),
          ),
        ),
      );
    });

    test('generateDeck maps 5xx failure to friendly message', () async {
      final apiClient = _FakeApiClient(
        postHandlers: {
          '/ai/generate': (_) => ApiResponse(500, {'error': 'db exploded'}),
        },
      );
      final provider = DeckProvider(apiClient: apiClient);

      expect(
        () => provider.generateDeck(
          prompt: 'Talrand spellslinger',
          format: 'Commander',
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('A IA ficou indisponível'),
          ),
        ),
      );
    });

    test(
      'generateDeck stops polling when cancelled after async acceptance',
      () async {
        final cancellation = GenerateDeckCancellation();
        final apiClient = _FakeApiClient(
          postHandlers: {
            '/ai/generate':
                (_) => ApiResponse(202, {
                  'job_id': 'job-cancel',
                  'status': 'pending',
                  'poll_url': '/ai/generate/jobs/job-cancel',
                  'poll_interval_ms': 1,
                }),
          },
          getHandlers: {
            '/ai/generate/jobs/job-cancel':
                () => ApiResponse(200, {
                  'job_id': 'job-cancel',
                  'status': 'processing',
                }),
          },
        );
        final provider = DeckProvider(apiClient: apiClient);

        expect(
          () => provider.generateDeck(
            prompt: 'Talrand spellslinger',
            format: 'Commander',
            cancellation: cancellation,
            onProgress: (progress) {
              if (progress.step == 1) {
                cancellation.cancel();
              }
            },
          ),
          throwsA(isA<GenerateDeckCancelledException>()),
        );
        expect(apiClient.getCalls, isEmpty);
      },
    );

    test(
      'optimizeDeck surfaces structured needs_repair payload on 422',
      () async {
        final apiClient = _FakeApiClient(
          postHandlers: {
            '/ai/optimize':
                (_) => ApiResponse(422, {
                  'error': 'O deck precisa de reparo estrutural.',
                  'outcome_code': 'needs_repair',
                  'quality_error': {
                    'code': 'OPTIMIZE_NEEDS_REPAIR',
                    'message': 'O deck atual está fora da faixa de optimize.',
                    'reasons': ['Poucas mágicas relevantes para o comandante.'],
                    'repair_plan': {'target_land_count': 36},
                  },
                  'next_action': {
                    'type': 'rebuild_guided',
                    'endpoint': '/ai/rebuild',
                    'payload': {
                      'deck_id': 'deck-1',
                      'rebuild_scope': 'auto',
                      'save_mode': 'draft_clone',
                    },
                  },
                }),
          },
        );
        final provider = DeckProvider(apiClient: apiClient);

        expect(
          () => provider.optimizeDeck('deck-1', 'control'),
          throwsA(
            isA<DeckAiFlowException>()
                .having((e) => e.code, 'code', 'OPTIMIZE_NEEDS_REPAIR')
                .having((e) => e.outcomeCode, 'outcomeCode', 'needs_repair')
                .having(
                  (e) => e.nextAction['type'],
                  'nextAction.type',
                  'rebuild_guided',
                ),
          ),
        );
      },
    );

    test(
      'optimizeDeck shows aggressive async progress and returns polled result',
      () async {
        var pollCount = 0;
        final progress = <String>[];
        final trackedEvents = <String>[];
        final apiClient = _FakeApiClient(
          postHandlers: {
            '/ai/optimize': (body) {
              expect(body['intensity'], 'aggressive');
              return ApiResponse(202, {
                'job_id': 'job-aggressive',
                'status': 'pending',
                'poll_interval_ms': 1,
                'total_stages': 6,
              });
            },
          },
          getHandlers: {
            '/ai/optimize/jobs/job-aggressive': () {
              pollCount += 1;
              if (pollCount == 1) {
                return ApiResponse(200, {
                  'status': 'processing',
                  'stage': 'Gerando preview seguro...',
                  'stage_number': 2,
                  'total_stages': 6,
                });
              }
              return ApiResponse(200, {
                'status': 'completed',
                'result': {
                  'mode': 'optimize',
                  'intensity': 'aggressive',
                  'removals': const ['Mind Stone'],
                  'additions': const ['Arcane Signet'],
                },
              });
            },
          },
        );
        final provider = DeckProvider(
          apiClient: apiClient,
          pollDelay: (_) async {},
          trackActivationEvent: (
            String eventName, {
            String? format,
            String? deckId,
            String source = 'app',
            Map<String, dynamic>? metadata,
          }) async {
            trackedEvents.add(eventName);
            expect(deckId, 'deck-1');
            expect(source, 'deck_provider.optimizeDeck');
          },
        );

        final result = await provider.optimizeDeck(
          'deck-1',
          'control',
          intensity: OptimizeIntensity.aggressive,
          onProgress: (stage, _, __) => progress.add(stage),
        );

        expect(result['intensity'], 'aggressive');
        expect(progress, contains('Optimize agressivo em background...'));
        expect(progress, contains('Gerando preview seguro...'));
        expect(apiClient.getCalls, [
          '/ai/optimize/jobs/job-aggressive',
          '/ai/optimize/jobs/job-aggressive',
        ]);
        expect(trackedEvents, ['deck_optimized']);
      },
    );

    test('telemetry failure never breaks a successful optimize flow', () async {
      final apiClient = _FakeApiClient(
        postHandlers: {
          '/ai/optimize':
              (_) => ApiResponse(200, {
                'mode': 'optimize',
                'removals': const <String>[],
                'additions': const <String>[],
              }),
        },
      );
      final provider = DeckProvider(
        apiClient: apiClient,
        trackActivationEvent:
            (
              String eventName, {
              String? format,
              String? deckId,
              String source = 'app',
              Map<String, dynamic>? metadata,
            }) => Future<void>.error(StateError('telemetry offline')),
      );

      final result = await provider.optimizeDeck('deck-1', 'control');
      await Future<void>.delayed(Duration.zero);

      expect(result['mode'], 'optimize');
    });

    test(
      'optimizeDeck polling timeout remains five minutes for one-second intervals',
      () async {
        var pollCount = 0;
        final apiClient = _FakeApiClient(
          postHandlers: {
            '/ai/optimize':
                (_) => ApiResponse(202, {
                  'job_id': 'job-long-aggressive',
                  'status': 'pending',
                  'poll_interval_ms': 1,
                  'total_stages': 6,
                }),
          },
          getHandlers: {
            '/ai/optimize/jobs/job-long-aggressive': () {
              pollCount += 1;
              if (pollCount < 65) {
                return ApiResponse(200, {
                  'status': 'processing',
                  'stage': 'Gerando preview seguro...',
                  'stage_number': 2,
                  'total_stages': 6,
                });
              }
              return ApiResponse(200, {
                'status': 'completed',
                'result': {
                  'mode': 'optimize',
                  'intensity': 'aggressive',
                  'removals': const ['Mind Stone'],
                  'additions': const ['Arcane Signet'],
                },
              });
            },
          },
        );
        final provider = DeckProvider(
          apiClient: apiClient,
          pollDelay: (_) async {},
        );

        final result = await provider.optimizeDeck(
          'deck-1',
          'control',
          intensity: OptimizeIntensity.aggressive,
        );

        expect(result['intensity'], 'aggressive');
        expect(pollCount, 65);
      },
    );

    test('rebuildDeck returns saved draft payload on success', () async {
      final apiClient = _FakeApiClient(
        postHandlers: {
          '/ai/rebuild': (body) {
            expect(body['deck_id'], 'deck-1');
            expect(body['save_mode'], 'draft_clone');
            expect(body['rebuild_scope'], 'auto');
            return ApiResponse(200, {
              'mode': 'rebuild_guided',
              'outcome_code': 'rebuild_created',
              'draft_deck_id': 'draft-1',
              'rebuild_scope_selected': 'full_non_commander_rebuild',
            });
          },
        },
      );
      final trackedEvents = <String>[];
      final provider = DeckProvider(
        apiClient: apiClient,
        trackActivationEvent: (
          String eventName, {
          String? format,
          String? deckId,
          String source = 'app',
          Map<String, dynamic>? metadata,
        }) async {
          trackedEvents.add(eventName);
        },
      );

      final result = await provider.rebuildDeck('deck-1');

      expect(result['draft_deck_id'], 'draft-1');
      expect(trackedEvents, contains('deck_rebuild_created'));
    });

    test(
      'core smoke: deck details -> optimize -> apply with ids -> validate',
      () async {
        final currentCards = <String, int>{
          'remove-1': 1,
          'spell-1': 1,
          'land-1': 36,
        };

        final apiClient = _FakeApiClient(
          getHandlers: {
            '/decks/deck-1':
                () => ApiResponse(200, _buildDeckDetailsJson(currentCards)),
            '/cards?name=Arcane+Signet&limit=1':
                () => ApiResponse(200, {
                  'data': const [
                    {
                      'id': 'add-1',
                      'name': 'Arcane Signet',
                      'type_line': 'Artifact',
                      'color_identity': <String>[],
                    },
                  ],
                }),
          },
          postHandlers: {
            '/ai/optimize':
                (_) => ApiResponse(200, {
                  'mode': 'optimize',
                  'removals': const ['Mind Stone'],
                  'additions': const ['Arcane Signet'],
                  'removals_detailed': const [
                    {
                      'card_id': 'remove-1',
                      'name': 'Mind Stone',
                      'type_line': 'Artifact',
                      'color_identity': <String>[],
                    },
                  ],
                  'additions_detailed': const [
                    {
                      'card_id': 'add-1',
                      'name': 'Arcane Signet',
                      'type_line': 'Artifact',
                      'color_identity': <String>[],
                    },
                  ],
                }),
            '/decks/deck-1/validate':
                (_) => ApiResponse(200, {
                  'valid': true,
                  'ok': true,
                  'errors': const <String>[],
                }),
          },
          putHandlers: {
            '/decks/deck-1': (body) {
              final cards =
                  (body['cards'] as List).cast<Map<String, dynamic>>();
              expect(cards.any((entry) => entry['card_id'] == 'add-1'), isTrue);
              expect(
                cards.any((entry) => entry['card_id'] == 'remove-1'),
                isFalse,
              );

              currentCards
                ..remove('remove-1')
                ..['add-1'] = 1;

              return ApiResponse(200, {'ok': true});
            },
          },
        );

        final provider = DeckProvider(
          apiClient: apiClient,
          trackActivationEvent:
              (
                String eventName, {
                String? format,
                String? deckId,
                String source = 'app',
                Map<String, dynamic>? metadata,
              }) async {},
        );

        await provider.fetchDeckDetails('deck-1');

        final optimizeResult = await provider.optimizeDeck('deck-1', 'control');
        final applied = await provider.applyOptimizationWithIds(
          deckId: 'deck-1',
          removalsDetailed:
              (optimizeResult['removals_detailed'] as List)
                  .cast<Map<String, dynamic>>(),
          additionsDetailed:
              (optimizeResult['additions_detailed'] as List)
                  .cast<Map<String, dynamic>>(),
        );
        final validation = await provider.validateDeck('deck-1');

        expect(applied, isTrue);
        expect(validation['valid'], isTrue);
        expect(apiClient.postCalls, contains('/ai/optimize'));
        expect(apiClient.postCalls, contains('/decks/deck-1/validate'));
        expect(apiClient.putCalls, contains('/decks/deck-1'));
      },
    );

    test(
      'applyOptimizationWithIds rejects stale deck signature before PUT',
      () async {
        final apiClient = _FakeApiClient(
          getHandlers: {
            '/decks/deck-1':
                () => ApiResponse(200, _buildDeckDetailsJson({'remove-1': 1})),
          },
          putHandlers: {
            '/decks/deck-1': (_) {
              fail('PUT should not be called when deck signature is stale');
            },
          },
        );

        final provider = DeckProvider(apiClient: apiClient);
        await provider.fetchDeckDetails('deck-1');

        expect(
          () => provider.applyOptimizationWithIds(
            deckId: 'deck-1',
            removalsDetailed: const [
              {'card_id': 'remove-1', 'name': 'Mind Stone'},
            ],
            additionsDetailed: const [
              {'card_id': 'add-1', 'name': 'Arcane Signet'},
            ],
            expectedDeckSignature: 'stale-signature',
          ),
          throwsA(
            predicate(
              (error) => error.toString().contains(
                'O deck mudou desde que a otimização foi gerada',
              ),
            ),
          ),
        );
        expect(apiClient.putCalls, isEmpty);
      },
    );

    test(
      'applyOptimizationWithIds rejects signature when only condition changed',
      () async {
        final apiClient = _FakeApiClient(
          getHandlers: {
            '/decks/deck-1':
                () => ApiResponse(200, _buildDeckDetailsJson({'remove-1': 1})),
          },
          putHandlers: {
            '/decks/deck-1': (_) {
              fail(
                'PUT should not be called when deck condition signature is stale',
              );
            },
          },
        );

        final provider = DeckProvider(apiClient: apiClient);
        await provider.fetchDeckDetails('deck-1');

        expect(
          () => provider.applyOptimizationWithIds(
            deckId: 'deck-1',
            removalsDetailed: const [
              {'card_id': 'remove-1', 'name': 'Mind Stone'},
            ],
            additionsDetailed: const [
              {'card_id': 'add-1', 'name': 'Arcane Signet'},
            ],
            expectedDeckSignature: 'cmd-1:1:LP|remove-1:1:NM',
          ),
          throwsA(
            predicate(
              (error) => error.toString().contains(
                'O deck mudou desde que a otimização foi gerada',
              ),
            ),
          ),
        );
        expect(apiClient.putCalls, isEmpty);
      },
    );

    test(
      'applyOptimizationWithIds returns false when post-save validation fails',
      () async {
        final currentCards = <String, int>{'remove-1': 1, 'land-1': 36};

        final apiClient = _FakeApiClient(
          getHandlers: {
            '/decks/deck-1':
                () => ApiResponse(200, _buildDeckDetailsJson(currentCards)),
            '/cards?name=Arcane+Signet&limit=1':
                () => ApiResponse(200, {
                  'data': const [
                    {
                      'id': 'add-1',
                      'name': 'Arcane Signet',
                      'type_line': 'Artifact',
                      'color_identity': <String>[],
                    },
                  ],
                }),
          },
          putHandlers: {
            '/decks/deck-1': (body) {
              final cards =
                  (body['cards'] as List).cast<Map<String, dynamic>>();
              expect(
                cards.any((entry) => entry['card_id'] == 'remove-1'),
                isFalse,
              );
              expect(cards.any((entry) => entry['card_id'] == 'add-1'), isTrue);

              currentCards
                ..remove('remove-1')
                ..['add-1'] = 1;

              return ApiResponse(200, {'ok': true});
            },
          },
          postHandlers: {
            '/decks/deck-1/validate':
                (_) => ApiResponse(400, {
                  'ok': false,
                  'error': 'Commander deck must contain exactly 100 cards.',
                }),
          },
        );

        final provider = DeckProvider(apiClient: apiClient);
        await provider.fetchDeckDetails('deck-1');

        final applied = await provider.applyOptimizationWithIds(
          deckId: 'deck-1',
          removalsDetailed: const [
            {'card_id': 'remove-1', 'name': 'Mind Stone'},
          ],
          additionsDetailed: const [
            {'card_id': 'add-1', 'name': 'Arcane Signet'},
          ],
        );

        expect(applied, isFalse);
        expect(apiClient.putCalls, contains('/decks/deck-1'));
        expect(apiClient.postCalls, contains('/decks/deck-1/validate'));
        expect(
          apiClient.getCalls.where((call) => call == '/decks/deck-1'),
          hasLength(2),
        );
      },
    );

    test(
      'applyOptimizationWithIds filters additions outside commander identity',
      () async {
        final currentCards = <String, int>{'remove-1': 1, 'land-1': 36};

        final apiClient = _FakeApiClient(
          getHandlers: {
            '/decks/deck-1':
                () => ApiResponse(
                  200,
                  _buildDeckDetailsJson(
                    currentCards,
                    deckColorIdentity: const <String>[],
                    commanderColors: const <String>[],
                    commanderColorIdentity: const <String>[],
                    commanderName: 'Kozilek, the Great Distortion',
                    commanderManaCost: '{8}{C}{C}',
                    commanderTypeLine: 'Legendary Creature — Eldrazi',
                  ),
                ),
            '/cards?name=Sol%20Ring&limit=1':
                () => ApiResponse(200, {
                  'data': const [
                    {
                      'id': 'add-1',
                      'name': 'Sol Ring',
                      'type_line': 'Artifact',
                      'color_identity': <String>[],
                    },
                  ],
                }),
            '/cards?name=Sol+Ring&limit=1':
                () => ApiResponse(200, {
                  'data': const [
                    {
                      'id': 'add-1',
                      'name': 'Sol Ring',
                      'type_line': 'Artifact',
                      'color_identity': <String>[],
                    },
                  ],
                }),
            '/cards?name=Swan+Song&limit=1':
                () => ApiResponse(200, {
                  'data': const [
                    {
                      'id': 'illegal-1',
                      'name': 'Swan Song',
                      'type_line': 'Instant',
                      'color_identity': <String>['U'],
                    },
                  ],
                }),
          },
          putHandlers: {
            '/decks/deck-1': (body) {
              final cards =
                  (body['cards'] as List).cast<Map<String, dynamic>>();
              expect(cards.any((entry) => entry['card_id'] == 'add-1'), isTrue);
              expect(
                cards.any((entry) => entry['card_id'] == 'illegal-1'),
                isFalse,
              );
              expect(
                cards.any((entry) => entry['card_id'] == 'remove-1'),
                isFalse,
              );

              currentCards
                ..remove('remove-1')
                ..['add-1'] = 1;

              return ApiResponse(200, {'ok': true});
            },
          },
          postHandlers: {
            '/decks/deck-1/validate':
                (_) => ApiResponse(200, {
                  'valid': true,
                  'ok': true,
                  'errors': const <String>[],
                }),
          },
        );

        final provider = DeckProvider(apiClient: apiClient);

        await provider.fetchDeckDetails('deck-1');

        final applied = await provider.applyOptimizationWithIds(
          deckId: 'deck-1',
          removalsDetailed: const [
            {'card_id': 'remove-1', 'name': 'Mind Stone'},
          ],
          additionsDetailed: const [
            {'card_id': 'add-1', 'name': 'Sol Ring'},
            {'card_id': 'illegal-1', 'name': 'Swan Song'},
          ],
        );

        expect(applied, isTrue);
        expect(apiClient.putCalls, contains('/decks/deck-1'));
      },
    );
  });

  group('DeckProvider incremental mutations', () {
    test(
      'addCardToDeck increments local count and refreshes details',
      () async {
        final currentCards = <String, int>{'spell-1': 1, 'land-1': 36};

        final apiClient = _FakeApiClient(
          getHandlers: {
            '/decks':
                () => ApiResponse(200, [
                  {
                    'id': 'deck-1',
                    'name': 'Smoke Deck',
                    'format': 'commander',
                    'is_public': false,
                    'created_at': '2026-03-23T00:00:00.000Z',
                    'card_count': 37,
                    'color_identity': ['W'],
                  },
                ]),
            '/decks/deck-1':
                () => ApiResponse(200, _buildDeckDetailsJson(currentCards)),
          },
          postHandlers: {
            '/decks/deck-1/cards': (_) => ApiResponse(200, {'ok': true}),
          },
        );

        final provider = DeckProvider(apiClient: apiClient);
        await provider.fetchDecks();
        await provider.fetchDeckDetails('deck-1');

        final added = await provider.addCardToDeck(
          'deck-1',
          provider.selectedDeck!.mainBoard['Instants']!.first,
          2,
        );

        expect(added, isTrue);
        expect(provider.decks.single.cardCount, 39);
      },
    );

    test(
      'deleteDeck removes item from list and clears selected deck',
      () async {
        final apiClient = _FakeApiClient(
          getHandlers: {
            '/decks':
                () => ApiResponse(200, [
                  {
                    'id': 'deck-1',
                    'name': 'Smoke Deck',
                    'format': 'commander',
                    'is_public': false,
                    'created_at': '2026-03-23T00:00:00.000Z',
                    'card_count': 37,
                    'color_identity': ['W'],
                  },
                ]),
            '/decks/deck-1':
                () => ApiResponse(
                  200,
                  _buildDeckDetailsJson({'spell-1': 1, 'land-1': 36}),
                ),
          },
          deleteHandlers: {'/decks/deck-1': () => ApiResponse(204, const {})},
        );

        final provider = DeckProvider(apiClient: apiClient);
        await provider.fetchDecks();
        await provider.fetchDeckDetails('deck-1');

        final deleted = await provider.deleteDeck('deck-1');

        expect(deleted, isTrue);
        expect(provider.decks, isEmpty);
        expect(provider.selectedDeck, isNull);
      },
    );

    test('refreshAiAnalysis updates selected deck and list', () async {
      final apiClient = _FakeApiClient(
        getHandlers: {
          '/decks':
              () => ApiResponse(200, [
                {
                  'id': 'deck-1',
                  'name': 'Smoke Deck',
                  'format': 'commander',
                  'is_public': false,
                  'created_at': '2026-03-23T00:00:00.000Z',
                  'card_count': 37,
                },
              ]),
          '/decks/deck-1':
              () => ApiResponse(
                200,
                _buildDeckDetailsJson({'spell-1': 1, 'land-1': 36}),
              ),
        },
        postHandlers: {
          '/decks/deck-1/ai-analysis':
              (_) => ApiResponse(200, {
                'synergy_score': 87,
                'strengths': 'draw',
                'weaknesses': 'ramp',
              }),
        },
      );

      final provider = DeckProvider(apiClient: apiClient);
      await provider.fetchDecks();
      await provider.fetchDeckDetails('deck-1');

      final result = await provider.refreshAiAnalysis('deck-1');

      expect(result['synergy_score'], 87);
      expect(provider.selectedDeck?.synergyScore, 87);
      expect(provider.decks.single.synergyScore, 87);
    });

    test(
      'fetchDeckAnalysis caches payload and card mutations invalidate it',
      () async {
        final currentCards = <String, int>{'spell-1': 1, 'land-1': 36};
        var analysisFetchCount = 0;
        final apiClient = _FakeApiClient(
          getHandlers: {
            '/decks':
                () => ApiResponse(200, [
                  {
                    'id': 'deck-1',
                    'name': 'Smoke Deck',
                    'format': 'commander',
                    'is_public': false,
                    'created_at': '2026-03-23T00:00:00.000Z',
                    'card_count': 37,
                    'color_identity': ['W'],
                  },
                ]),
            '/decks/deck-1':
                () => ApiResponse(200, _buildDeckDetailsJson(currentCards)),
            '/decks/deck-1/analysis': () {
              analysisFetchCount += 1;
              return ApiResponse(200, {
                'deck_id': 'deck-1',
                'format': 'commander',
                'stats': {
                  'composition': {
                    'ramp': 1,
                    'draw': 1,
                    'removal': 0,
                    'board_wipes': 0,
                    'protection': 0,
                  },
                },
                'functional_tags': {
                  'schema_version': 'functional_card_tags_v1_2026_05_18',
                  'counts': {'ramp': 1, 'draw': 1},
                  'samples': {
                    'ramp': ['Mind Stone'],
                  },
                  'coverage': {
                    'card_rows': 2,
                    'card_copies': 37,
                    'tagged_rows': 2,
                    'tagged_copies': 2,
                    'other_rows': 0,
                    'other_copies': 35,
                  },
                },
              });
            },
          },
          postHandlers: {
            '/decks/deck-1/cards': (_) => ApiResponse(200, {'ok': true}),
          },
        );

        final provider = DeckProvider(apiClient: apiClient);
        await provider.fetchDeckDetails('deck-1');

        final first = await provider.fetchDeckAnalysis('deck-1');
        final second = await provider.fetchDeckAnalysis('deck-1');
        expect(first, same(second));
        expect(analysisFetchCount, 1);
        expect(provider.deckAnalysisFor('deck-1'), isNotNull);

        final added = await provider.addCardToDeck(
          'deck-1',
          provider.selectedDeck!.mainBoard['Instants']!.first,
          1,
        );

        expect(added, isTrue);
        expect(provider.deckAnalysisFor('deck-1'), isNull);
      },
    );

    test('copyPublicDeck refreshes deck list on success', () async {
      var decksFetchCount = 0;
      final apiClient = _FakeApiClient(
        getHandlers: {
          '/decks': () {
            decksFetchCount += 1;
            return ApiResponse(200, [
              {
                'id': 'deck-copy',
                'name': 'Copied Deck',
                'format': 'commander',
                'is_public': false,
                'created_at': '2026-03-23T00:00:00.000Z',
                'card_count': 37,
                'color_identity': ['W', 'R'],
              },
            ]);
          },
        },
        postHandlers: {
          '/community/decks/public-1':
              (_) => ApiResponse(201, {
                'deck': {'id': 'deck-copy'},
              }),
        },
      );

      final provider = DeckProvider(apiClient: apiClient);

      final result = await provider.copyPublicDeck('public-1');

      expect(result['success'], isTrue);
      expect(decksFetchCount, 1);
      expect(provider.decks.single.id, 'deck-copy');
    });

    test(
      'importListToDeck refreshes selected deck details on success',
      () async {
        var detailsFetchCount = 0;
        final apiClient = _FakeApiClient(
          getHandlers: {
            '/decks/deck-1': () {
              detailsFetchCount += 1;
              final cards =
                  detailsFetchCount == 1
                      ? {'spell-1': 1, 'land-1': 36}
                      : {'spell-1': 1, 'imported-1': 2, 'land-1': 36};
              return ApiResponse(200, _buildDeckDetailsJson(cards));
            },
            '/decks':
                () => ApiResponse(200, [
                  {
                    'id': 'deck-1',
                    'name': 'Smoke Deck',
                    'format': 'commander',
                    'is_public': false,
                    'created_at': '2026-03-23T00:00:00.000Z',
                    'card_count': 39,
                  },
                ]),
          },
          postHandlers: {
            '/import/to-deck':
                (_) => ApiResponse(200, {
                  'success': true,
                  'deck_id': 'deck-1',
                  'cards_imported': 2,
                  'total_cards': 39,
                  'not_found_lines': [],
                  'warnings': [],
                }),
          },
        );
        final provider = DeckProvider(apiClient: apiClient);

        await provider.fetchDeckDetails('deck-1');
        expect(provider.selectedDeck?.cardCount, 37);

        final result = await provider.importListToDeck(
          deckId: 'deck-1',
          list: '2 Counterspell',
        );

        expect(result['success'], isTrue);
        expect(result['deck_id'], 'deck-1');
        expect(result['total_cards'], 39);
        expect(provider.selectedDeck?.cardCount, 39);
        expect(detailsFetchCount, 2);
      },
    );
  });
}
