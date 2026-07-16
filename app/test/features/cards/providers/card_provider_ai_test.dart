import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/cards/providers/card_provider.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.handler);

  final Future<ApiResponse> Function() handler;

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) {
    expect(endpoint, '/ai/explain');
    return handler();
  }
}

DeckCardItem _card() => DeckCardItem(
  id: 'card-1',
  name: 'Sol Ring',
  manaCost: '{1}',
  typeLine: 'Artifact',
  oracleText: '{T}: Add {C}{C}.',
  colors: [],
  colorIdentity: [],
  setCode: 'tst',
  rarity: 'uncommon',
  quantity: 1,
  isCommander: false,
);

void main() {
  test('returns a valid AI explanation', () async {
    final provider = CardProvider(
      apiClient: _FakeApiClient(
        () async => ApiResponse(200, {'explanation': 'Gera duas manas.'}),
      ),
    );

    expect(await provider.explainCard(_card()), 'Gera duas manas.');
  });

  test('does not expose transport exceptions as card explanations', () async {
    final provider = CardProvider(
      apiClient: _FakeApiClient(
        () => Future<ApiResponse>.error(
          StateError('Authorization: Bearer sk-test-secret-value'),
        ),
      ),
    );

    expect(await provider.explainCard(_card()), isNull);
  });

  test('rejects malformed successful responses', () async {
    final provider = CardProvider(
      apiClient: _FakeApiClient(() async => ApiResponse(200, const {})),
    );

    expect(await provider.explainCard(_card()), isNull);
  });
}
