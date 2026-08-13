import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/config/release_capabilities.dart';

Map<String, dynamic> _validPayload({
  Set<ReleaseCapability> allowed = const {},
}) {
  return {
    'schema_version': ReleaseCapabilitiesSnapshot.schemaVersion,
    'policy_version': 'brewtact_free_beta_test',
    'product': 'brewtact',
    'release_channel': 'free_beta',
    'offer_mode': 'free_beta_no_commerce',
    'implementation_status': 'implemented_guarded',
    'live_verified_as_of': null,
    'policy_digest_sha256': List.filled(64, 'a').join(),
    'configuration_status': 'valid',
    'capabilities': {
      for (final capability in ReleaseCapability.values)
        capability.wireName: {
          'implementation_status': 'implemented_guarded',
          'release_capability': allowed.contains(capability) ? 'on' : 'off',
          'allowed': allowed.contains(capability),
          'live_verified_as_of': null,
        },
    },
  };
}

void main() {
  group('ReleaseCapabilitiesSnapshot', () {
    test('parses the complete versioned contract', () {
      final payload = _validPayload(
        allowed: const {ReleaseCapability.catalogPrivate},
      );

      final snapshot = ReleaseCapabilitiesSnapshot.fromJson(payload);

      expect(snapshot.isValid, isTrue);
      expect(snapshot.isAllowed(ReleaseCapability.catalogPrivate), isTrue);
      expect(snapshot.isAllowed(ReleaseCapability.scanner), isFalse);
      expect(ReleaseCapability.values, hasLength(29));
      expect(
        ReleaseCapability.values.map((capability) => capability.wireName),
        containsAll(const ['account_registration', 'life_counter_local']),
      );
    });

    test(
      'rejects a contradiction between policy state and effective allowed',
      () {
        final payload = _validPayload();
        final capabilities = payload['capabilities'] as Map<String, dynamic>;
        capabilities[ReleaseCapability.aiGenerateRebuild.wireName] = {
          'implementation_status': 'not_implemented',
          'release_capability': 'off',
          'allowed': true,
          'live_verified_as_of': null,
        };

        final snapshot = ReleaseCapabilitiesSnapshot.fromJson(payload);

        expect(snapshot.isValid, isFalse);
        expect(
          snapshot.isAllowed(ReleaseCapability.aiGenerateRebuild),
          isFalse,
        );
      },
    );

    test('fails closed for an unknown schema or invalid envelope', () {
      for (final mutation in <void Function(Map<String, dynamic>)>[
        (payload) => payload['schema_version'] = 'release_capabilities_v2',
        (payload) => payload['configuration_status'] = 'invalid_fail_closed',
        (payload) => payload['product'] = 'another_product',
        (payload) => payload['policy_digest_sha256'] = 'not-a-sha256',
        (payload) => payload.remove('capabilities'),
        (payload) => payload['unexpected'] = true,
      ]) {
        final payload = _validPayload(
          allowed: const {ReleaseCapability.catalogPrivate},
        );
        mutation(payload);

        final snapshot = ReleaseCapabilitiesSnapshot.fromJson(payload);

        expect(snapshot.isValid, isFalse);
        expect(snapshot.isAllowed(ReleaseCapability.catalogPrivate), isFalse);
      }
    });

    test(
      'rejects the whole matrix for missing, extra or malformed entries',
      () {
        final payloadMissing = _validPayload(
          allowed: const {ReleaseCapability.catalogPrivate},
        );
        (payloadMissing['capabilities'] as Map<String, dynamic>).remove(
          ReleaseCapability.scanner.wireName,
        );

        final missing = ReleaseCapabilitiesSnapshot.fromJson(payloadMissing);
        expect(missing.isValid, isFalse);
        expect(missing.isAllowed(ReleaseCapability.catalogPrivate), isFalse);

        final payload = _validPayload(
          allowed: const {
            ReleaseCapability.catalogPrivate,
            ReleaseCapability.scanner,
          },
        );
        final capabilities = payload['capabilities'] as Map<String, dynamic>;
        capabilities[ReleaseCapability.scanner.wireName] = {'allowed': 'true'};

        final snapshot = ReleaseCapabilitiesSnapshot.fromJson(payload);

        expect(snapshot.isValid, isFalse);
        expect(snapshot.isAllowed(ReleaseCapability.catalogPrivate), isFalse);
        expect(snapshot.isAllowed(ReleaseCapability.scanner), isFalse);

        final payloadExtra = _validPayload();
        (payloadExtra['capabilities'] as Map<String, dynamic>)['future_key'] = {
          'implementation_status': 'implemented_guarded',
          'release_capability': 'off',
          'allowed': false,
          'live_verified_as_of': null,
        };
        expect(
          ReleaseCapabilitiesSnapshot.fromJson(payloadExtra).isValid,
          isFalse,
        );
      },
    );
  });

  group('ReleaseCapabilitiesProvider', () {
    test('loads GET /capabilities and exposes a valid snapshot', () async {
      String? requestedEndpoint;
      final provider = ReleaseCapabilitiesProvider(
        fetcher: (endpoint) async {
          requestedEndpoint = endpoint;
          return ApiResponse(
            200,
            _validPayload(allowed: const {ReleaseCapability.aiGenerateRebuild}),
          );
        },
      );
      addTearDown(provider.dispose);

      final loaded = await provider.refresh();

      expect(loaded, isTrue);
      expect(requestedEndpoint, ReleaseCapabilitiesProvider.endpoint);
      expect(provider.loadState, ReleaseCapabilitiesLoadState.ready);
      expect(provider.isAllowed(ReleaseCapability.aiGenerateRebuild), isTrue);
    });

    test(
      'HTTP failure and network failure both replace access with all-off',
      () async {
        final httpFailure = ReleaseCapabilitiesProvider(
          fetcher: (_) async => ApiResponse(503, _validPayload()),
        );
        addTearDown(httpFailure.dispose);

        expect(await httpFailure.refresh(), isFalse);
        expect(httpFailure.loadState, ReleaseCapabilitiesLoadState.unavailable);
        expect(
          httpFailure.isAllowed(ReleaseCapability.catalogPrivate),
          isFalse,
        );

        final networkFailure = ReleaseCapabilitiesProvider(
          fetcher: (_) async => throw StateError('offline'),
        );
        addTearDown(networkFailure.dispose);

        expect(await networkFailure.refresh(), isFalse);
        expect(
          networkFailure.loadState,
          ReleaseCapabilitiesLoadState.unavailable,
        );
        expect(
          networkFailure.isAllowed(ReleaseCapability.catalogPrivate),
          isFalse,
        );
      },
    );

    test('build support is an AND and never overrides server denial', () {
      final denied = ReleaseCapabilitiesProvider.seeded(const {});
      final allowed = ReleaseCapabilitiesProvider.seeded(const {
        ReleaseCapability.scanner,
      });
      addTearDown(denied.dispose);
      addTearDown(allowed.dispose);

      expect(
        denied.isAllowed(ReleaseCapability.scanner, buildSupported: true),
        isFalse,
      );
      expect(
        allowed.isAllowed(ReleaseCapability.scanner, buildSupported: false),
        isFalse,
      );
      expect(
        allowed.isAllowed(ReleaseCapability.scanner, buildSupported: true),
        isTrue,
      );
    });

    test(
      'reset denies immediately and invalidates an in-flight account load',
      () async {
        final response = Completer<ApiResponse>();
        final provider = ReleaseCapabilitiesProvider(
          fetcher: (_) => response.future,
        );
        addTearDown(provider.dispose);

        final pendingRefresh = provider.refresh();
        expect(provider.loadState, ReleaseCapabilitiesLoadState.loading);

        provider.reset();
        expect(provider.loadState, ReleaseCapabilitiesLoadState.initial);
        expect(
          provider.isAllowed(ReleaseCapability.aiGenerateRebuild),
          isFalse,
        );

        response.complete(
          ApiResponse(
            200,
            _validPayload(allowed: const {ReleaseCapability.aiGenerateRebuild}),
          ),
        );

        expect(await pendingRefresh, isFalse);
        expect(provider.loadState, ReleaseCapabilitiesLoadState.initial);
        expect(
          provider.isAllowed(ReleaseCapability.aiGenerateRebuild),
          isFalse,
        );
      },
    );
  });

  group('ReleaseCapabilityRouteGuard', () {
    final denied = ReleaseCapabilitiesSnapshot.forTesting(const {});
    const supported = ReleaseRouteBuildSupport(
      scanner: true,
      battleLive: true,
      battleCoach: true,
      billingCheckout: true,
    );

    test('redirects every deferred route family when denied', () {
      final cases = <String, String>{
        '/register': '/login',
        '/decks/generate?format=commander': '/decks',
        '/decks/deck-1?optimize=rebuild&postGameNoteId=note-1':
            '/decks/deck-1?postGameNoteId=note-1',
        '/decks/deck-1/scan?mode=add': '/decks/deck-1/search?mode=add',
        '/decks/deck-1/search?mode=add': '/decks/deck-1',
        '/decks/deck-1/battle-replays': '/decks/deck-1',
        '/decks/deck-1/battle-live/job-1': '/decks/deck-1',
        '/decks/deck-1/battle-coach/session-1': '/decks/deck-1',
        '/life-counter?deckId=deck-1': '/home',
        '/community': '/home',
        '/community/search-users?q=ana': '/home',
        '/community/user/user-1': '/home',
        '/community/decks/deck-2': '/home',
        '/messages/conversation-1': '/home',
        '/notifications': '/home',
        '/trades/trade-1': '/collection?tab=0',
        '/collection/matches?deck=deck-1': '/home',
        '/collection?tab=1': '/home',
        '/collection?tab=2': '/home',
        '/collection?tab=3': '/home',
        '/collection?tab=99': '/home',
        '/collection/sets/fin': '/home',
        '/collection/latest-set': '/home',
        '/marketplace': '/collection?tab=0',
        '/upgrade': '/plans',
        '/checkout': '/plans',
        '/decks': '/home',
        '/cards/card-1': '/home',
        '/sets/set-1': '/home',
      };

      for (final entry in cases.entries) {
        expect(
          ReleaseCapabilityRouteGuard.redirectFor(
            uri: Uri.parse(entry.key),
            capabilities: denied,
            buildSupport: supported,
          ),
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('allows a route only when server and artifact both support it', () {
      final allowed = ReleaseCapabilitiesSnapshot.forTesting(const {
        ReleaseCapability.accountRegistration,
        ReleaseCapability.aiGenerateRebuild,
        ReleaseCapability.aiAnalyzeOptimizeAdvisory,
        ReleaseCapability.decksPrivate,
        ReleaseCapability.scanner,
        ReleaseCapability.battleBatch,
        ReleaseCapability.battleLive,
        ReleaseCapability.battleCoach,
        ReleaseCapability.billingCheckout,
        ReleaseCapability.lifeCounterLocal,
      });

      for (final path in const [
        '/register',
        '/decks/generate',
        '/decks/deck-1?optimize=rebuild',
        '/decks/deck-1/scan',
        '/decks/deck-1/battle-replays',
        '/decks/deck-1/battle-live/job-1',
        '/decks/deck-1/battle-coach',
        '/decks/deck-1?optimize=post_game',
        '/life-counter',
        '/checkout',
      ]) {
        expect(
          ReleaseCapabilityRouteGuard.redirectFor(
            uri: Uri.parse(path),
            capabilities: allowed,
            buildSupport: supported,
          ),
          isNull,
          reason: path,
        );
      }

      expect(
        ReleaseCapabilityRouteGuard.redirectFor(
          uri: Uri.parse('/decks/deck-1/scan'),
          capabilities: allowed,
          buildSupport: const ReleaseRouteBuildSupport(),
        ),
        '/decks/deck-1/search',
      );
      expect(
        ReleaseCapabilityRouteGuard.redirectFor(
          uri: Uri.parse('/checkout'),
          capabilities: allowed,
          buildSupport: const ReleaseRouteBuildSupport(),
        ),
        '/plans',
      );
    });

    test('normalizes unknown hub tabs without authorizing another surface', () {
      final galleryOnly = ReleaseCapabilitiesSnapshot.forTesting(const {
        ReleaseCapability.galleryPublic,
      });
      final marketOnly = ReleaseCapabilitiesSnapshot.forTesting(const {
        ReleaseCapability.marketplace,
      });

      expect(
        ReleaseCapabilityRouteGuard.redirectFor(
          uri: Uri.parse('/community?tab=99'),
          capabilities: galleryOnly,
          buildSupport: supported,
        ),
        isNull,
      );
      expect(
        ReleaseCapabilityRouteGuard.redirectFor(
          uri: Uri.parse('/community?tab=99'),
          capabilities: marketOnly,
          buildSupport: supported,
        ),
        '/community?tab=3',
      );
    });

    test('collection tabs keep stable route ids and compose capabilities', () {
      final privateOnly = ReleaseCapabilitiesSnapshot.forTesting(const {
        ReleaseCapability.collectionPrivate,
      });
      final withCatalog = ReleaseCapabilitiesSnapshot.forTesting(const {
        ReleaseCapability.collectionPrivate,
        ReleaseCapability.catalogPrivate,
      });

      expect(
        ReleaseCapabilityRouteGuard.redirectFor(
          uri: Uri.parse('/collection?tab=3'),
          capabilities: privateOnly,
          buildSupport: supported,
        ),
        '/collection?tab=0',
      );
      expect(
        ReleaseCapabilityRouteGuard.redirectFor(
          uri: Uri.parse('/collection?tab=3'),
          capabilities: withCatalog,
          buildSupport: supported,
        ),
        isNull,
      );
      expect(
        ReleaseCapabilityRouteGuard.redirectFor(
          uri: Uri.parse('/collection?tab=99'),
          capabilities: privateOnly,
          buildSupport: supported,
        ),
        isNull,
      );
    });
  });
}
