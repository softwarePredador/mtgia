import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/collection/models/mtg_set.dart';
import 'package:manaloom/features/collection/screens/set_cards_screen.dart';
import 'package:manaloom/features/collection/screens/sets_catalog_screen.dart';

class _FakeApiClient extends ApiClient {
  final List<String> requests = [];

  @override
  Future<ApiResponse> get(String endpoint) async {
    requests.add(endpoint);

    if (endpoint.startsWith('/sets?') && endpoint.contains('q=soc')) {
      return ApiResponse(200, {
        'data': [
          {
            'code': 'SOC',
            'name': 'Secrets of Strixhaven Commander',
            'release_date': '2026-04-24',
            'type': 'commander',
            'card_count': 11,
            'status': 'new',
          },
        ],
        'page': 1,
        'limit': 50,
        'total_returned': 1,
      });
    }

    if (endpoint.startsWith('/sets?')) {
      return ApiResponse(200, {
        'data': [
          {
            'code': 'MSH',
            'name': 'Marvel Super Heroes',
            'release_date': '2026-06-26',
            'type': 'expansion',
            'card_count': 14,
            'status': 'future',
          },
          {
            'code': 'TMT',
            'name': 'Teenage Mutant Ninja Turtles',
            'release_date': '2026-03-06',
            'type': 'expansion',
            'card_count': 195,
            'status': 'current',
          },
        ],
        'page': 1,
        'limit': 50,
        'total_returned': 2,
      });
    }

    if (endpoint.startsWith('/cards?set=OM2')) {
      return ApiResponse(200, {
        'data': <Map<String, dynamic>>[],
        'page': 1,
        'limit': 100,
        'total_returned': 0,
      });
    }

    if (endpoint.startsWith('/cards?set=ECC')) {
      return ApiResponse(200, {
        'data': [
          {
            'id': 'card-1',
            'name': 'Aberrant Return',
            'mana_cost': '{4}{B}{B}',
            'type_line': 'Sorcery',
            'oracle_text': 'Return creatures.',
            'colors': ['B'],
            'color_identity': ['B'],
            'image_url': null,
            'set_code': 'ecc',
            'set_name': 'Lorwyn Eclipsed Commander',
            'set_release_date': '2026-01-23',
            'rarity': 'rare',
          },
        ],
        'page': 1,
        'limit': 100,
        'total_returned': 1,
      });
    }

    return ApiResponse(404, {'error': 'not found'});
  }
}

void main() {
  testWidgets('sets catalog lists statuses and searches by code/name', (
    tester,
  ) async {
    final apiClient = _FakeApiClient();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: SetsCatalogScreen(apiClient: apiClient),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coleções MTG'), findsOneWidget);
    expect(find.text('Marvel Super Heroes'), findsOneWidget);
    expect(find.text('MSH'), findsOneWidget);
    expect(find.text('Futura'), findsOneWidget);
    expect(find.text('14 cartas'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('setsSearchField')), 'soc');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Secrets of Strixhaven Commander'), findsOneWidget);
    expect(find.text('SOC'), findsOneWidget);
    expect(find.text('Nova'), findsOneWidget);
    expect(apiClient.requests.any((r) => r.contains('q=soc')), isTrue);
  });

  testWidgets('set detail renders cards from cards set endpoint', (
    tester,
  ) async {
    final apiClient = _FakeApiClient();
    const set = MtgSet(
      code: 'ECC',
      name: 'Lorwyn Eclipsed Commander',
      releaseDate: '2026-01-23',
      type: 'commander',
      cardCount: 1,
      status: 'current',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: SetCardsScreen(initialSet: set, apiClient: apiClient),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lorwyn Eclipsed Commander'), findsOneWidget);
    expect(find.text('Aberrant Return'), findsOneWidget);
    expect(
      apiClient.requests.any((r) => r.startsWith('/cards?set=ECC')),
      isTrue,
    );
  });

  testWidgets('future set without local cards shows explicit partial state', (
    tester,
  ) async {
    final apiClient = _FakeApiClient();
    const set = MtgSet(
      code: 'OM2',
      name: 'Through the Omenpaths 2',
      releaseDate: '2026-06-26',
      type: 'expansion',
      cardCount: 0,
      status: 'future',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: SetCardsScreen(initialSet: set, apiClient: apiClient),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dados parciais de set futuro'), findsOneWidget);
    expect(find.textContaining('próximo sync do MTGJSON'), findsOneWidget);
  });
}
