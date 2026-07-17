import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/collection/models/mtg_set.dart';
import 'package:manaloom/features/collection/screens/set_cards_screen.dart';
import 'package:manaloom/features/collection/screens/sets_catalog_screen.dart';

import '../../support/list_tile_material_test_support.dart';

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
            'representative_image_url':
                'https://cards.scryfall.io/normal/front/a/b/sample.jpg',
            'icon_svg_uri': 'https://svgs.scryfall.io/sets/msh.svg?v=1',
            'status': 'future',
          },
          {
            'code': 'TMT',
            'name': 'Teenage Mutant Ninja Turtles',
            'release_date': '2026-03-06',
            'type': 'expansion',
            'card_count': 195,
            'representative_image_url': null,
            'icon_svg_uri': 'https://svgs.scryfall.io/sets/tmt.svg?v=1',
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

class _FailingApiClient extends ApiClient {
  @override
  Future<ApiResponse> get(String endpoint) async {
    return ApiResponse(500, {
      'error': 'Exception: statusCode=500 RequestOptions /sets stackTrace',
    });
  }
}

void main() {
  Future<void> setViewport(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  test(
    'set visual contract parses artwork and derives legacy icon fallback',
    () {
      final set = MtgSet.fromJson({
        'code': 'MSH',
        'name': 'Marvel Super Heroes',
        'status': 'future',
        'representative_image_url': ' https://example.test/art.jpg ',
        'icon_svg_uri': ' https://example.test/icon.svg ',
      });
      final legacy = MtgSet.fromJson({
        'code': 'HOB',
        'name': 'The Hobbit',
        'status': 'future',
      });

      expect(set.representativeImageUrl, 'https://example.test/art.jpg');
      expect(set.resolvedIconSvgUri, 'https://example.test/icon.svg');
      expect(
        legacy.resolvedIconSvgUri,
        'https://svgs.scryfall.io/sets/hob.svg?v=1',
      );
    },
  );

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
    expect(find.byKey(const Key('set-artwork-frame-MSH')), findsOneWidget);
    expect(find.byKey(const Key('set-artwork-image-MSH')), findsOneWidget);
    expect(find.byKey(const Key('set-icon-request-TMT')), findsOneWidget);
    expect(find.byKey(const Key('set-code-badge-MSH')), findsOneWidget);
    expect(find.byKey(const Key('set-code-badge-TMT')), findsOneWidget);

    final artwork = tester.widget<CachedNetworkImage>(
      find.byKey(const Key('set-artwork-image-MSH')),
    );
    expect(artwork.imageUrl, contains('/art_crop/'));
    expect(artwork.fit, BoxFit.cover);

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

  testWidgets('set artwork keeps a fixed landscape frame on compact catalog', (
    tester,
  ) async {
    await setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: SetsCatalogScreen(apiClient: _FakeApiClient()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('setsCatalogList')), findsOneWidget);
    expect(find.byKey(const Key('setsCatalogGrid')), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('set-artwork-frame-MSH'))),
      const Size(84, 56),
    );
    expect(find.byKey(const Key('set-code-badge-MSH')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog and set cards use bounded two-column desktop canvases', (
    tester,
  ) async {
    await setViewport(tester, const Size(1280, 900));
    final apiClient = _FakeApiClient();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: SetsCatalogScreen(apiClient: apiClient),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('setsCatalogGrid')), findsOneWidget);
    expectListTileInkIsUnobscured(tester);
    expect(find.byKey(const Key('setsCatalogList')), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('sets-catalog-hero'))).width,
      lessThanOrEqualTo(960),
    );
    expect(
      tester
          .getSize(find.byKey(const Key('sets-catalog-responsive-canvas')))
          .width,
      lessThanOrEqualTo(1280),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const Key('set-artwork-frame-MSH'))),
      const Size(84, 56),
    );
    expect(
      tester.getSize(find.byKey(const Key('set-tile-MSH'))).height,
      closeTo(104, 1.1),
    );

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

    expect(find.byKey(const Key('setCardsGrid')), findsOneWidget);
    expectListTileInkIsUnobscured(tester);
    expect(find.byKey(const Key('setCardsList')), findsNothing);
    final thumbnailSize = tester.getSize(
      find.byKey(const Key('set-card-thumbnail-card-1')),
    );
    expect(
      thumbnailSize.width / thumbnailSize.height,
      closeTo(488 / 680, 0.02),
    );
    expect(
      tester
          .getSize(find.byKey(const Key('set-cards-responsive-canvas')))
          .width,
      lessThanOrEqualTo(1280),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('set cards preserve the compact mobile list at 390px', (
    tester,
  ) async {
    await setViewport(tester, const Size(390, 844));
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
        home: SetCardsScreen(initialSet: set, apiClient: _FakeApiClient()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('setCardsList')), findsOneWidget);
    expect(find.byKey(const Key('setCardsGrid')), findsNothing);
    expect(tester.takeException(), isNull);
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

    expect(find.text('Dados parciais de coleção futura'), findsOneWidget);
    expect(find.textContaining('próximo sync do MTGJSON'), findsOneWidget);
  });

  testWidgets('sets catalog error state hides technical backend details', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: SetsCatalogScreen(apiClient: _FailingApiClient()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Falha ao carregar coleções'), findsOneWidget);
    expect(
      find.text(
        'Servidor indisponível no momento. Tente novamente em instantes.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('RequestOptions'), findsNothing);
    expect(find.textContaining('500'), findsNothing);
  });

  testWidgets('set detail error state hides technical backend details', (
    tester,
  ) async {
    const set = MtgSet(
      code: 'ERR',
      name: 'Erro Controlado',
      releaseDate: '2026-01-23',
      type: 'expansion',
      cardCount: 1,
      status: 'current',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: SetCardsScreen(initialSet: set, apiClient: _FailingApiClient()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Falha ao carregar coleção'), findsOneWidget);
    expect(
      find.text(
        'Servidor indisponível no momento. Tente novamente em instantes.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('RequestOptions'), findsNothing);
    expect(find.textContaining('500'), findsNothing);
  });
}
