import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/config/release_capabilities.dart';
import 'package:manaloom/core/config/release_identity_gate.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/release_update_banner.dart';

final _digestA = List.filled(64, 'a').join();
final _digestB = List.filled(64, 'b').join();
final _sha = List.filled(40, '1').join();

Map<String, Object?> _entry(bool allowed) => {
  'implementation_status': 'implemented_guarded',
  'release_capability': allowed ? 'on' : 'off',
  'allowed': allowed,
  'live_verified_as_of': null,
};

Map<String, Object?> _body({
  required String digest,
  Set<ReleaseCapability> allowed = const {},
  Map<String, Object?> extra = const {},
  Set<ReleaseCapability> omit = const {},
}) => {
  'schema_version': 'release_capabilities_v1',
  'policy_version': '2026-10-05.1',
  'product': 'brewtact',
  'release_channel': 'free_beta',
  'offer_mode': 'free_beta_no_commerce',
  'implementation_status': 'implemented_guarded',
  'live_verified_as_of': null,
  'policy_digest_sha256': digest,
  'configuration_status': 'valid',
  'capabilities': {
    for (final capability in ReleaseCapability.values)
      if (!omit.contains(capability))
        capability.wireName: _entry(allowed.contains(capability)),
    ...extra,
  },
};

CompiledReleaseIdentity _release(String allowed, {String? digest}) =>
    CompiledReleaseIdentity.parse(
      gitSha: _sha,
      surface: 'app',
      capabilitiesDigest: digest ?? _digestA,
      allowedCapabilities: allowed,
    );

class _FixedApi extends ApiClient {
  _FixedApi(this.body);

  final Map<String, Object?> body;

  @override
  Future<ApiResponse> get(String endpoint) async => ApiResponse(200, body);
}

Future<ReleaseCapabilitiesProvider> _load(
  ReleaseIdentityGate gate,
  Map<String, Object?> body,
) async {
  final provider = ReleaseCapabilitiesProvider(
    fetcher: (endpoint) async => gate.apply(ApiResponse(200, body)),
  );
  await provider.refresh();
  return provider;
}

void main() {
  group('CompiledReleaseIdentity (BT-REL-002)', () {
    test('no digest and no list is a development build', () {
      final identity = CompiledReleaseIdentity.parse(
        gitSha: '',
        surface: '',
        capabilitiesDigest: '',
        allowedCapabilities: '',
      );
      expect(identity.kind, CompiledReleaseIdentityKind.development);
    });

    test('a release build carries the compiled matrix', () {
      final identity = _release('decks_private,catalog_private');
      expect(identity.kind, CompiledReleaseIdentityKind.release);
      expect(identity.allowedCapabilities, {
        ReleaseCapability.decksPrivate,
        ReleaseCapability.catalogPrivate,
      });
    });

    test('anything outside the contract is invalid', () {
      for (final identity in [
        _release('decks_private', digest: 'short'),
        _release('decks_private,unknown_capability'),
        _release('decks_private,decks_private'),
        CompiledReleaseIdentity.parse(
          gitSha: 'abc',
          surface: 'app',
          capabilitiesDigest: _digestA,
          allowedCapabilities: '',
        ),
        CompiledReleaseIdentity.parse(
          gitSha: _sha,
          surface: 'site',
          capabilitiesDigest: _digestA,
          allowedCapabilities: '',
        ),
        CompiledReleaseIdentity.parse(
          gitSha: _sha,
          surface: 'app',
          capabilitiesDigest: '',
          allowedCapabilities: 'decks_private',
        ),
      ]) {
        expect(identity.kind, CompiledReleaseIdentityKind.invalid);
      }
    });
  });

  group('ReleaseIdentityGate (D-13)', () {
    test('the same release passes through and asks nothing', () async {
      final gate = ReleaseIdentityGate(
        identity: _release('decks_private'),
        apiClient: ApiClient(),
      );
      addTearDown(gate.dispose);

      final provider = await _load(
        gate,
        _body(digest: _digestA, allowed: {ReleaseCapability.decksPrivate}),
      );
      addTearDown(provider.dispose);

      expect(provider.isAllowed(ReleaseCapability.decksPrivate), isTrue);
      expect(gate.updateAvailable.value, isFalse);
    });

    test(
      'a newer backend never turns on what this build did not ship',
      () async {
        final gate = ReleaseIdentityGate(
          identity: _release('decks_private'),
          apiClient: ApiClient(),
        );
        addTearDown(gate.dispose);

        final provider = await _load(
          gate,
          _body(
            digest: _digestB,
            allowed: {
              ReleaseCapability.decksPrivate,
              ReleaseCapability.scanner,
            },
          ),
        );
        addTearDown(provider.dispose);

        expect(provider.snapshot.isValid, isTrue);
        expect(provider.isAllowed(ReleaseCapability.decksPrivate), isTrue);
        expect(provider.isAllowed(ReleaseCapability.scanner), isFalse);
        expect(gate.updateAvailable.value, isTrue);
      },
    );

    test('unknown capabilities are dropped and omitted ones denied', () async {
      final gate = ReleaseIdentityGate(
        identity: _release('decks_private,catalog_private'),
        apiClient: ApiClient(),
      );
      addTearDown(gate.dispose);

      final provider = await _load(
        gate,
        _body(
          digest: _digestA,
          allowed: {ReleaseCapability.decksPrivate},
          omit: {ReleaseCapability.catalogPrivate},
          extra: {'future_capability': _entry(true)},
        ),
      );
      addTearDown(provider.dispose);

      expect(provider.snapshot.isValid, isTrue);
      expect(provider.isAllowed(ReleaseCapability.decksPrivate), isTrue);
      expect(provider.isAllowed(ReleaseCapability.catalogPrivate), isFalse);
      // A new capability offered as allowed means a newer release.
      expect(gate.updateAvailable.value, isTrue);
    });

    test('an invalid compiled identity denies everything', () async {
      final gate = ReleaseIdentityGate(
        identity: _release('decks_private', digest: 'not-a-digest'),
        apiClient: ApiClient(),
      );
      addTearDown(gate.dispose);

      final provider = await _load(
        gate,
        _body(digest: _digestA, allowed: {ReleaseCapability.decksPrivate}),
      );
      addTearDown(provider.dispose);

      expect(provider.snapshot.isValid, isFalse);
      expect(provider.isAllowed(ReleaseCapability.decksPrivate), isFalse);
    });

    test('a development build trusts the backend as before', () async {
      final gate = ReleaseIdentityGate(
        identity: CompiledReleaseIdentity.parse(
          gitSha: '',
          surface: '',
          capabilitiesDigest: '',
          allowedCapabilities: '',
        ),
        apiClient: ApiClient(),
      );
      addTearDown(gate.dispose);

      final provider = await _load(
        gate,
        _body(digest: _digestB, allowed: {ReleaseCapability.scanner}),
      );
      addTearDown(provider.dispose);

      expect(provider.isAllowed(ReleaseCapability.scanner), isTrue);
      expect(gate.updateAvailable.value, isFalse);
    });

    test('fetch reads /capabilities through the gate', () async {
      final gate = ReleaseIdentityGate(
        identity: _release(''),
        apiClient: _FixedApi(
          _body(digest: _digestA, allowed: {ReleaseCapability.decksPrivate}),
        ),
      );
      addTearDown(gate.dispose);
      final provider = ReleaseCapabilitiesProvider(fetcher: gate.fetch);
      addTearDown(provider.dispose);

      expect(await provider.refresh(), isTrue);
      expect(provider.isAllowed(ReleaseCapability.decksPrivate), isFalse);
    });
  });

  group('ReleaseUpdateBannerHost', () {
    Future<void> pump(
      WidgetTester tester,
      ValueNotifier<bool> update, {
      required bool canReload,
      VoidCallback? onReload,
    }) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        builder: (context, child) => ReleaseUpdateBannerHost(
          updateAvailable: update,
          canReload: canReload,
          onReload: onReload,
          child: child!,
        ),
        home: const Scaffold(body: Text('tela')),
      ),
    );

    testWidgets('shows only while a newer release runs', (tester) async {
      final update = ValueNotifier(false);
      addTearDown(update.dispose);
      var reloads = 0;
      await pump(tester, update, canReload: true, onReload: () => reloads++);

      expect(find.byKey(const Key('release-update-banner')), findsNothing);
      update.value = true;
      await tester.pump();

      expect(find.byKey(const Key('release-update-banner')), findsOneWidget);
      expect(find.text('tela'), findsOneWidget);
      await tester.tap(find.byKey(const Key('release-update-reload')));
      expect(reloads, 1);
    });

    testWidgets('Android asks to install, with no reload button', (
      tester,
    ) async {
      final update = ValueNotifier(true);
      addTearDown(update.dispose);
      await pump(tester, update, canReload: false);

      expect(find.textContaining('Instale a versão nova'), findsOneWidget);
      expect(find.byKey(const Key('release-update-reload')), findsNothing);
    });

    testWidgets('"Agora não" hides the strip for the session', (tester) async {
      final update = ValueNotifier(true);
      addTearDown(update.dispose);
      await pump(tester, update, canReload: true);

      await tester.tap(find.byKey(const Key('release-update-dismiss')));
      await tester.pump();
      expect(find.byKey(const Key('release-update-banner')), findsNothing);

      update.value = false;
      update.value = true;
      await tester.pump();
      expect(find.byKey(const Key('release-update-banner')), findsNothing);
    });
  });
}
