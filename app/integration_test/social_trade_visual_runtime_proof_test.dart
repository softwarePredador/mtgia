import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/models/user.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/binder/screens/marketplace_screen.dart';
import 'package:manaloom/features/community/providers/community_provider.dart';
import 'package:manaloom/features/community/screens/community_deck_detail_screen.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/messages/screens/message_inbox_screen.dart';
import 'package:manaloom/features/social/providers/social_provider.dart';
import 'package:manaloom/features/social/screens/user_search_screen.dart';
import 'package:manaloom/features/trades/providers/trade_provider.dart';
import 'package:manaloom/features/trades/screens/create_trade_screen.dart';
import 'package:manaloom/features/trades/screens/trade_detail_screen.dart';
import 'package:manaloom/features/trades/screens/trade_inbox_screen.dart';
import 'package:manaloom/features/trades/screens/trade_matches_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'runtime_test_helpers.dart';
import 'visual_capture_helpers.dart';

const _captureRuntimeProof = bool.fromEnvironment(
  'MANALOOM_CAPTURE_RUNTIME_PROOF',
  defaultValue: true,
);
const _uiSourceDigest = String.fromEnvironment('MANALOOM_UI_SOURCE_DIGEST');
const _uiProofProfile = String.fromEnvironment('MANALOOM_UI_PROOF_PROFILE');
const _uiProofTarget = String.fromEnvironment('MANALOOM_UI_PROOF_TARGET');
const _uiProofDeviceContract = String.fromEnvironment(
  'MANALOOM_UI_PROOF_DEVICE_CONTRACT',
);
const _ringImageUrl = String.fromEnvironment('MANALOOM_VISUAL_RING_IMAGE_URL');
const _spellImageUrl = String.fromEnvironment(
  'MANALOOM_VISUAL_SPELL_IMAGE_URL',
);
const _visualWidth = int.fromEnvironment(
  'MANALOOM_VISUAL_WIDTH',
  defaultValue: 390,
);
const _visualHeight = int.fromEnvironment(
  'MANALOOM_VISUAL_HEIGHT',
  defaultValue: 844,
);

String get _ringFixtureUrl => _captureRuntimeProof
    ? Uri.base
          .resolve('assets/assets/branding/visual_fixture_arcane_ring.webp')
          .toString()
    : _ringImageUrl;

String get _spellFixtureUrl => _captureRuntimeProof
    ? Uri.base
          .resolve('assets/assets/branding/visual_fixture_blue_spell.webp')
          .toString()
    : _spellImageUrl;

const _viewerId = '00000000-0000-4000-8000-000000000001';
const _partnerId = '00000000-0000-4000-8000-000000000002';
const _tradeId = '00000000-0000-4000-8000-000000000101';
const _ringCardId = '91fdb56b-54d5-4272-8319-505ff987fe9b';
const _spellCardId = 'aaaaaaaa-54d5-4272-8319-505ff987fe9b';
const _ringBinderId = '10000000-0000-4000-8000-000000000001';
const _spellBinderId = '10000000-0000-4000-8000-000000000002';

const _requiredCheckpoints = <String>[
  'social_trade_00_matches_populated',
  'social_trade_01_marketplace_populated',
  'social_trade_02_marketplace_empty',
  'social_trade_03_trade_create_rehydrated',
  'social_trade_04_trade_create_review',
  'social_trade_05_trade_create_unavailable',
  'social_trade_06_trade_pending_actions',
  'social_trade_07_trade_counter_draft',
  'social_trade_08_trade_declined',
  'social_trade_09_trade_error',
  'social_trade_10_trade_completed',
  'social_trade_11_trade_inbox_empty',
  'social_trade_12_messages_empty',
  'social_trade_13_users_empty_results',
  'social_trade_14_community_context_comment',
  'social_trade_15_matches_empty',
];

enum _RuntimeMode {
  matchesPopulated,
  matchesEmpty,
  marketplacePopulated,
  marketplaceEmpty,
  createReady,
  createUnavailable,
  tradePending,
  tradeDeclined,
  tradeCompleted,
  tradeError,
  tradeInboxEmpty,
  messagesEmpty,
  usersEmpty,
  communityDetail,
}

class _FlutterTesterCacheManager implements BaseCacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => Stream<FileResponse>.error(
    StateError('Network card artwork is disabled in flutter-tester.'),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> get _ringCard => <String, dynamic>{
  'id': _ringCardId,
  'oracle_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  'scryfall_id': _ringCardId,
  'name': 'Arcane Signet',
  'image_url': _ringFixtureUrl,
  'set_code': 'CMM',
  'set_name': 'Commander Masters',
  'set_release_date': '2023-08-04',
  'collector_number': '392',
  'rarity': 'common',
  'mana_cost': '{2}',
  'type_line': 'Artifact',
};

Map<String, dynamic> get _spellCard => <String, dynamic>{
  'id': _spellCardId,
  'oracle_id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  'scryfall_id': _spellCardId,
  'name': 'Counterspell',
  'image_url': _spellFixtureUrl,
  'set_code': 'DMR',
  'set_name': 'Dominaria Remastered',
  'set_release_date': '2023-01-13',
  'collector_number': '45',
  'rarity': 'uncommon',
  'mana_cost': '{U}{U}',
  'type_line': 'Instant',
};

Map<String, dynamic> _binderItem({required bool partnerCopy}) {
  final card = partnerCopy ? _ringCard : _spellCard;
  return <String, dynamic>{
    'id': partnerCopy ? _ringBinderId : _spellBinderId,
    'card_id': card['id'],
    'card': card,
    'quantity': partnerCopy ? 1 : 2,
    'available_quantity': partnerCopy ? 1 : 2,
    'condition': partnerCopy ? 'NM' : 'LP',
    'is_foil': false,
    'for_trade': true,
    'for_sale': partnerCopy,
    'price': partnerCopy ? 18.5 : 12.0,
    'currency': 'BRL',
    'language': partnerCopy ? 'pt' : 'en',
    'list_type': 'have',
    'updated_at': '2026-08-06T11:20:00.000Z',
  };
}

Map<String, dynamic> _tradeItem({required bool viewerCopy}) {
  final card = viewerCopy ? _spellCard : _ringCard;
  return <String, dynamic>{
    'id': viewerCopy
        ? '20000000-0000-4000-8000-000000000001'
        : '20000000-0000-4000-8000-000000000002',
    'binder_item_id': viewerCopy ? _spellBinderId : _ringBinderId,
    'direction': viewerCopy ? 'offering' : 'requesting',
    'quantity': 1,
    'agreed_price': viewerCopy ? 12.0 : 18.5,
    'condition': viewerCopy ? 'LP' : 'NM',
    'is_foil': false,
    'language': viewerCopy ? 'en' : 'pt',
    'snapshot_status': 'captured',
    'identity_status': 'preserved',
    'card': card,
  };
}

Map<String, dynamic> _tradePayload(String status) => <String, dynamic>{
  'id': _tradeId,
  'status': status,
  'type': 'trade',
  'message': 'Troca local; confirmamos as impressões antes de combinar.',
  'sender': <String, dynamic>{
    'id': _partnerId,
    'username': 'mesadequinta',
    'display_name': 'Mesa de Quinta',
    'trust': const <String, dynamic>{
      'completed_trades': 12,
      'cancelled_trades': 1,
      'declined_trades': 2,
      'disputed_trades': 0,
      'avg_response_hours': 2.5,
      'avg_shipping_hours': 17.0,
      'has_insufficient_history': false,
    },
  },
  'receiver': const <String, dynamic>{
    'id': _viewerId,
    'username': 'rafa_loom',
    'display_name': 'Rafa Loom',
    'trust': <String, dynamic>{
      'completed_trades': 7,
      'avg_response_hours': 4.0,
      'has_insufficient_history': false,
    },
  },
  'created_at': '2026-08-06T10:00:00.000Z',
  'updated_at': '2026-08-06T11:20:00.000Z',
  'value_summary': const <String, dynamic>{
    'offered_value': 12.0,
    'requested_value': 18.5,
    'payment_amount': 0.0,
    'total_offered_value': 12.0,
    'difference_abs': 6.5,
    'difference_pct': 35.1,
    'direction': 'requested_higher',
    'threshold_pct': 20.0,
    'threshold_abs': 5.0,
    'has_warning': true,
    'message': 'O pedido está acima da oferta; combine a diferença.',
  },
  'my_items': <Map<String, dynamic>>[_tradeItem(viewerCopy: true)],
  'their_items': <Map<String, dynamic>>[_tradeItem(viewerCopy: false)],
  'messages': const <Map<String, dynamic>>[
    <String, dynamic>{
      'id': '30000000-0000-4000-8000-000000000001',
      'sender_id': _partnerId,
      'sender_username': 'mesadequinta',
      'sender_display_name': 'Mesa de Quinta',
      'message': 'Posso encontrar na loja sábado à tarde.',
      'created_at': '2026-08-06T10:04:00.000Z',
    },
  ],
  'status_history': <Map<String, dynamic>>[
    const <String, dynamic>{
      'id': '40000000-0000-4000-8000-000000000001',
      'old_status': null,
      'new_status': 'pending',
      'notes': 'Proposta criada',
      'changed_by_username': 'mesadequinta',
      'created_at': '2026-08-06T10:00:00.000Z',
    },
    if (status != 'pending')
      <String, dynamic>{
        'id': '40000000-0000-4000-8000-000000000002',
        'old_status': 'pending',
        'new_status': status,
        'notes': status == 'completed'
            ? 'Entrega confirmada pelos dois jogadores'
            : 'Proposta recusada; nenhuma cópia foi movimentada',
        'changed_by_username': 'rafa_loom',
        'created_at': '2026-08-06T11:20:00.000Z',
      },
  ],
};

class _RuntimeApi extends ApiClient {
  _RuntimeApi(this.mode);

  final _RuntimeMode mode;

  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint.startsWith('/community/marketplace?')) {
      return ApiResponse(200, <String, dynamic>{
        'data': mode == _RuntimeMode.marketplacePopulated
            ? <Map<String, dynamic>>[
                <String, dynamic>{
                  ..._binderItem(partnerCopy: true),
                  'owner': const <String, dynamic>{
                    'id': _partnerId,
                    'username': 'mesadequinta',
                    'display_name': 'Mesa de Quinta',
                    'location_city': 'São Paulo',
                    'location_state': 'SP',
                    'trade_notes': 'Trocas presenciais em local público.',
                    'trust': <String, dynamic>{
                      'completed_trades': 12,
                      'cancelled_trades': 1,
                      'declined_trades': 2,
                      'disputed_trades': 0,
                      'avg_response_hours': 2.5,
                      'avg_shipping_hours': 17.0,
                      'has_insufficient_history': false,
                    },
                  },
                  'price_insight': const <String, dynamic>{
                    'reference_price': 3.4,
                    'reference_currency': 'USD',
                    'reference_source': 'scryfall',
                    'reference_updated_at': '2026-08-05T12:00:00.000Z',
                    'history_points': 9,
                    'trend': <String, dynamic>{
                      'status': 'available',
                      'direction': 'up',
                      'change_pct': 4.2,
                    },
                    'comparison': <String, dynamic>{
                      'status': 'within_range',
                      'direction': 'aligned',
                      'message': 'Oferta dentro da faixa de referência.',
                    },
                  },
                },
              ]
            : const <Map<String, dynamic>>[],
      });
    }

    if (endpoint.startsWith('/community/trade-matches')) {
      final populated =
          mode == _RuntimeMode.matchesPopulated ||
          mode == _RuntimeMode.communityDetail;
      return ApiResponse(200, <String, dynamic>{
        'matches': populated
            ? <Map<String, dynamic>>[
                <String, dynamic>{
                  'wanted_quantity': 1,
                  'sources': const <String>['deck_missing', 'wishlist'],
                  'card': _ringCard,
                  'owner': const <String, dynamic>{
                    'id': _partnerId,
                    'username': 'mesadequinta',
                    'display_name': 'Mesa de Quinta',
                    'location_city': 'São Paulo',
                    'location_state': 'SP',
                  },
                  'offer': const <String, dynamic>{
                    'binder_item_id': _ringBinderId,
                    'quantity': 1,
                    'condition': 'NM',
                    'is_foil': false,
                    'language': 'pt',
                    'for_trade': true,
                    'for_sale': true,
                    'price': 18.5,
                    'currency': 'BRL',
                    'updated_at': '2026-08-06T11:20:00.000Z',
                  },
                },
              ]
            : const <Map<String, dynamic>>[],
        'source': 'deck_missing_and_wishlist',
        'deck_id': 'deck-social-proof',
        if (!populated)
          'message':
              'Sua wishlist está pronta. Novas cópias públicas aparecerão aqui.',
      });
    }

    if (endpoint.startsWith('/binder?')) {
      return ApiResponse(200, <String, dynamic>{
        'data': <Map<String, dynamic>>[_binderItem(partnerCopy: false)],
      });
    }

    if (endpoint.startsWith('/community/binders/$_partnerId?')) {
      return ApiResponse(200, <String, dynamic>{
        'owner': const <String, dynamic>{
          'id': _partnerId,
          'username': 'mesadequinta',
          'display_name': 'Mesa de Quinta',
        },
        'data': mode == _RuntimeMode.createUnavailable
            ? const <Map<String, dynamic>>[]
            : <Map<String, dynamic>>[_binderItem(partnerCopy: true)],
      });
    }

    if (endpoint.startsWith('/trades?')) {
      return ApiResponse(200, const <String, dynamic>{
        'data': <Map<String, dynamic>>[],
        'total': 0,
        'page': 1,
      });
    }

    if (endpoint == '/trades/$_tradeId') {
      if (mode == _RuntimeMode.tradeError) {
        return ApiResponse(503, const <String, dynamic>{
          'error': 'trade_temporarily_unavailable',
          'message': 'Trade temporariamente indisponível.',
        });
      }
      final status = switch (mode) {
        _RuntimeMode.tradeDeclined => 'declined',
        _RuntimeMode.tradeCompleted => 'completed',
        _ => 'pending',
      };
      return ApiResponse(200, _tradePayload(status));
    }

    if (endpoint.startsWith('/conversations?')) {
      return ApiResponse(200, const <String, dynamic>{
        'data': <Map<String, dynamic>>[],
        'total': 0,
      });
    }

    if (endpoint.startsWith('/community/users?')) {
      return ApiResponse(200, const <String, dynamic>{
        'data': <Map<String, dynamic>>[],
        'total': 0,
      });
    }

    if (endpoint == '/community/decks/deck-social-proof') {
      return ApiResponse(200, <String, dynamic>{
        'id': 'deck-social-proof',
        'name': 'Alela · Mesa Aberta',
        'format': 'commander',
        'description':
            'Uma lista pública para discutir curva, interação e decisões de mesa.',
        'owner_id': _partnerId,
        'owner_username': 'mesadequinta',
        'synergy_score': 82,
        'stats': const <String, dynamic>{'total_cards': 100},
        'commander': const <Map<String, dynamic>>[],
        'main_board': <String, dynamic>{
          'Artefatos': <Map<String, dynamic>>[
            <String, dynamic>{
              ..._ringCard,
              'quantity': 1,
              'is_commander': false,
              'foil': false,
            },
          ],
        },
        'visual_analysis': const <String, dynamic>{
          'headline': 'Valor incremental com janela de interação',
          'reading':
              'A curva abre espaço para desenvolver a mesa sem perder respostas.',
          'curve_shape': <String, dynamic>{'low': 31, 'mid': 22, 'high': 8},
          'color_identity_hint': <String>['W', 'U', 'B'],
        },
      });
    }

    if (endpoint == '/community/decks/deck-social-proof/comments') {
      return ApiResponse(200, const <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': '50000000-0000-4000-8000-000000000001',
            'body':
                '[Contexto: Carta · Arcane Signet] Esta peça sustenta a curva dois sem esconder a linha de jogo.',
            'created_at': '2026-08-06T11:10:00.000Z',
            'author': <String, dynamic>{
              'id': _partnerId,
              'username': 'mesadequinta',
              'display_name': 'Mesa de Quinta',
            },
          },
        ],
      });
    }

    throw StateError('Unexpected ${mode.name} runtime GET $endpoint');
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    if (endpoint == '/community/decks/deck-social-proof/comments') {
      return ApiResponse(201, const <String, dynamic>{'ok': true});
    }
    if (endpoint == '/trades') {
      return ApiResponse(201, <String, dynamic>{'id': _tradeId, ...body});
    }
    throw StateError('Unexpected ${mode.name} runtime POST $endpoint');
  }
}

class _RuntimeAuthProvider extends AuthProvider {
  _RuntimeAuthProvider(ApiClient api) : super(apiClient: api);

  @override
  User? get user => User(
    id: _viewerId,
    username: 'rafa_loom',
    email: 'runtime@example.invalid',
    displayName: 'Rafa Loom',
    locationState: 'SP',
    locationCity: 'São Paulo',
    binderVisibility: 'public',
    locationVisibility: 'private',
  );

  @override
  AuthStatus get status => AuthStatus.authenticated;
}

Widget _runtimeApp({required _RuntimeApi api, required Widget home}) {
  return MultiProvider(
    key: ValueKey<String>('social-trade-${api.mode.name}'),
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => _RuntimeAuthProvider(api),
      ),
      ChangeNotifierProvider<BinderProvider>(
        create: (_) => BinderProvider(apiClient: api),
      ),
      ChangeNotifierProvider<CommunityProvider>(
        create: (_) => CommunityProvider(apiClient: api),
      ),
      ChangeNotifierProvider<DeckProvider>(
        create: (_) => DeckProvider(apiClient: api),
      ),
      ChangeNotifierProvider<MessageProvider>(
        create: (_) => MessageProvider(apiClient: api),
      ),
      ChangeNotifierProvider<SocialProvider>(
        create: (_) => SocialProvider(apiClient: api),
      ),
      ChangeNotifierProvider<TradeProvider>(
        create: (_) => TradeProvider(apiClient: api),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(splashFactory: NoSplash.splashFactory),
      home: home,
    ),
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'real Web surfaces prove the complete social discovery and trade journey',
    (tester) async {
      if (!_captureRuntimeProof) {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        CachedNetworkImageProvider.defaultCacheManager =
            _FlutterTesterCacheManager();
      }
      _expectRuntimeContract();
      _emitRuntimeContext();

      await binding.setSurfaceSize(
        Size(_visualWidth.toDouble(), _visualHeight.toDouble()),
      );
      addTearDown(() => binding.setSurfaceSize(null));

      await _pumpSurface(
        tester,
        mode: _RuntimeMode.matchesPopulated,
        home: const TradeMatchesScreen(deckId: 'deck-social-proof'),
        ready: find.byKey(const Key('trade-matches-content')),
      );
      final matchCard = find.byKey(
        const Key('trade-match-card-$_ringBinderId'),
      );
      await _waitForArtwork(
        tester,
        matchCard,
        description: 'the actionable trade match artwork',
      );
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[0],
        focus: matchCard,
      );

      await _pumpSurface(
        tester,
        mode: _RuntimeMode.marketplacePopulated,
        home: const Scaffold(body: MarketplaceTabContent()),
        ready: find.byKey(const Key('marketplace-list')),
      );
      final marketCard = find.byKey(
        const Key('marketplace-item-card-$_ringBinderId'),
      );
      await _waitForArtwork(
        tester,
        marketCard,
        description: 'the Marketplace printing artwork',
      );
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[1],
        focus: marketCard,
      );

      await _pumpSurface(
        tester,
        mode: _RuntimeMode.marketplaceEmpty,
        home: const Scaffold(body: MarketplaceTabContent()),
        ready: find.byKey(const Key('marketplace-list-empty')),
      );
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[2],
        focus: find.byKey(const Key('marketplace-list-empty')),
      );

      await _pumpSurface(
        tester,
        mode: _RuntimeMode.createReady,
        home: const CreateTradeScreen(
          receiverId: _partnerId,
          initialType: 'trade',
          initialBinderItemId: _ringBinderId,
          source: 'deck_missing',
          sourceDeckId: 'deck-social-proof',
        ),
        ready: find.byKey(const Key('create-trade-origin-ready')),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const Key('create-trade-selected-item-requested-0')),
      );
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[3],
        focus: find.byKey(const Key('create-trade-origin-context')),
      );

      final addOffered = find.byKey(const Key('create-trade-add-item-offered'));
      await tester.ensureVisible(addOffered);
      await tester.tap(addOffered);
      await tester.pump(const Duration(milliseconds: 350));
      final spellChoice = find.text('Counterspell').last;
      await pumpUntilFound(tester, spellChoice);
      await tester.tap(spellChoice);
      await tester.pump(const Duration(milliseconds: 350));
      await pumpUntilFound(
        tester,
        find.byKey(const Key('create-trade-selected-item-offered-0')),
      );
      final submit = find.byKey(const Key('create-trade-submit-button'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await pumpUntilFound(
        tester,
        find.byKey(const Key('create-trade-review-dialog')),
      );
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[4],
        focus: find.byKey(const Key('create-trade-review-dialog')),
      );

      await _pumpSurface(
        tester,
        mode: _RuntimeMode.createUnavailable,
        home: const CreateTradeScreen(
          receiverId: _partnerId,
          initialType: 'trade',
          initialBinderItemId: _ringBinderId,
          source: 'marketplace',
        ),
        ready: find.byKey(const Key('create-trade-origin-error')),
      );
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[5],
        focus: find.byKey(const Key('create-trade-origin-context')),
      );

      await _pumpSurface(
        tester,
        mode: _RuntimeMode.tradePending,
        home: const TradeDetailScreen(tradeId: _tradeId),
        ready: find.byKey(const Key('trade-status-header-pending')),
      );
      expect(find.byKey(const Key('trade-action-counter')), findsOneWidget);
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[6],
        focus: find.byKey(const Key('trade-status-header-pending')),
      );

      await _pumpSurface(
        tester,
        mode: _RuntimeMode.tradePending,
        home: const CreateTradeScreen(
          receiverId: _partnerId,
          initialType: 'trade',
          source: 'counter',
          counterTradeId: _tradeId,
        ),
        ready: find.byKey(const Key('create-trade-origin-ready')),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const Key('create-trade-selected-item-requested-0')),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const Key('create-trade-selected-item-offered-0')),
      );
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[7],
        focus: find.byKey(const Key('create-trade-origin-context')),
      );

      await _pumpSurface(
        tester,
        mode: _RuntimeMode.tradeDeclined,
        home: const TradeDetailScreen(tradeId: _tradeId),
        ready: find.byKey(const Key('trade-status-header-declined')),
      );
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[8],
        focus: find.byKey(const Key('trade-status-header-declined')),
      );

      await _pumpSurface(
        tester,
        mode: _RuntimeMode.tradeError,
        home: const TradeDetailScreen(tradeId: _tradeId),
        ready: find.byKey(const Key('trade-detail-error-state')),
      );
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[9],
        focus: find.byKey(const Key('trade-detail-error-state')),
      );

      await _pumpSurface(
        tester,
        mode: _RuntimeMode.tradeCompleted,
        home: const TradeDetailScreen(tradeId: _tradeId),
        ready: find.byKey(const Key('trade-status-header-completed')),
      );
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[10],
        focus: find.byKey(const Key('trade-status-header-completed')),
      );

      await _pumpSurface(
        tester,
        mode: _RuntimeMode.tradeInboxEmpty,
        home: const TradeInboxScreen(),
        ready: find.byKey(const Key('trade-inbox-empty-active')),
      );
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[11],
        focus: find.byKey(const Key('trade-inbox-empty-active')),
      );

      await _pumpSurface(
        tester,
        mode: _RuntimeMode.messagesEmpty,
        home: const MessageInboxScreen(),
        ready: find.byKey(const Key('messages-inbox-empty')),
      );
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[12],
        focus: find.byKey(const Key('messages-inbox-empty')),
      );

      await _pumpSurface(
        tester,
        mode: _RuntimeMode.usersEmpty,
        home: const UserSearchScreen(
          initialQuery: 'planeswalker_sem_resultado',
        ),
        ready: find.byKey(const Key('user-search-empty-results')),
      );
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[13],
        focus: find.byKey(const Key('user-search-empty-results')),
      );

      await _pumpSurface(
        tester,
        mode: _RuntimeMode.communityDetail,
        home: const CommunityDeckDetailScreen(deckId: 'deck-social-proof'),
        ready: find.byKey(const Key('community-deck-feedback-panel')),
      );
      final contextualComment = find.byKey(
        const Key(
          'community-comment-context-50000000-0000-4000-8000-000000000001',
        ),
      );
      await pumpUntilFound(tester, contextualComment);
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[14],
        focus: find.byKey(const Key('community-deck-feedback-panel')),
      );

      await _pumpSurface(
        tester,
        mode: _RuntimeMode.matchesEmpty,
        home: const TradeMatchesScreen(),
        ready: find.byKey(const Key('trade-matches-empty')),
      );
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[15],
        focus: find.byKey(const Key('trade-matches-empty')),
      );
    },
  );
}

Future<void> _pumpSurface(
  WidgetTester tester, {
  required _RuntimeMode mode,
  required Widget home,
  required Finder ready,
}) async {
  // Dispose timers, routes and provider callbacks from the prior checkpoint
  // before mounting the next controlled surface.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
  expect(
    tester.takeException(),
    isNull,
    reason: 'while closing the surface before ${mode.name}',
  );
  await tester.pumpWidget(
    _runtimeApp(
      api: _RuntimeApi(mode),
      home: KeyedSubtree(key: ValueKey<String>(mode.name), child: home),
    ),
  );
  await tester.pump();
  await pumpUntilFound(
    tester,
    ready,
    attempts: 40,
    step: const Duration(milliseconds: 100),
  );
  expect(tester.takeException(), isNull, reason: 'while opening ${mode.name}');
}

void _expectRuntimeContract() {
  if (!_captureRuntimeProof) return;
  expect(_uiSourceDigest, matches(RegExp(r'^[0-9a-f]{64}$')));
  expect(_uiProofProfile, isNotEmpty);
  expect(_uiProofTarget, 'web_real_build');
  expect(_uiProofDeviceContract.toLowerCase(), contains('chrome'));
  expect(_ringImageUrl, startsWith('http://127.0.0.1:'));
  expect(_spellImageUrl, startsWith('http://127.0.0.1:'));
  expect(
    Uri.parse(_ringFixtureUrl).path,
    endsWith('/assets/assets/branding/visual_fixture_arcane_ring.webp'),
  );
  expect(
    Uri.parse(_spellFixtureUrl).path,
    endsWith('/assets/assets/branding/visual_fixture_blue_spell.webp'),
  );
}

void _emitRuntimeContext() {
  if (!_captureRuntimeProof) return;
  // ignore: avoid_print
  print(
    'VISUAL_PROOF_CONTEXT ${jsonEncode(<String, Object>{'schema_version': 'manaloom_ui_runtime_context_v1', 'surface': 'social_trade', 'source_digest': _uiSourceDigest, 'profile': _uiProofProfile, 'runtime': 'flutter_drive', 'target': _uiProofTarget, 'device_contract': _uiProofDeviceContract, 'required_checkpoints': _requiredCheckpoints})}',
  );
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String checkpoint, {
  Finder? focus,
}) async {
  if (focus != null) {
    await tester.ensureVisible(focus);
  }
  await tester.pump(const Duration(milliseconds: 450));
  expect(tester.takeException(), isNull, reason: 'Before $checkpoint');
  expectNoRawTechnicalErrorText(tester);
  if (_captureRuntimeProof) {
    await captureVisualProof(binding, tester, checkpoint);
  }
  expect(tester.takeException(), isNull, reason: 'After $checkpoint');
}

Future<void> _waitForArtwork(
  WidgetTester tester,
  Finder scope, {
  required String description,
}) async {
  if (!_captureRuntimeProof) return;
  final loading = find.descendant(
    of: scope,
    matching: find.byKey(const Key('cached-card-image-loading')),
  );
  final error = find.descendant(
    of: scope,
    matching: find.byKey(const Key('cached-card-image-error')),
  );
  final missing = find.descendant(
    of: scope,
    matching: find.byKey(const Key('cached-card-image-placeholder')),
  );
  await pumpUntil(
    tester,
    () => loading.evaluate().isEmpty,
    description: description,
    attempts: 60,
    step: const Duration(milliseconds: 100),
  );
  expect(error, findsNothing, reason: '$description must not be an error.');
  expect(
    missing,
    findsNothing,
    reason: '$description must have an exact image URL.',
  );
}
