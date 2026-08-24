import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/config/release_capabilities.dart';

void main() {
  test('known release surfaces consume the server capability contract', () {
    const requiredTokensByFile = <String, List<String>>{
      'lib/main.dart': [
        'ReleaseCapabilityRouteGuard.redirectFor',
        '_releaseCapabilitiesProvider.refresh()',
        'ReleaseCapability.accountRegistration',
        'ReleaseCapability.socialPush',
        'ReleaseCapability.directMessages',
        '_authenticatedAccountId',
      ],
      'lib/features/home/home_screen.dart': [
        'ReleaseCapability.lifeCounterLocal',
        'ReleaseCapability.decksPrivate',
        'ReleaseCapability.learningWrites',
      ],
      'lib/features/decks/screens/deck_list_screen.dart': [
        'ReleaseCapability.aiGenerateRebuild',
        'ReleaseCapability.galleryPublic',
        'ReleaseCapability.collectionPrivate',
      ],
      'lib/features/decks/screens/deck_details_screen.dart': [
        'ReleaseCapability.aiAnalyzeOptimizeAdvisory',
        'ReleaseCapability.aiGenerateRebuild',
        'ReleaseCapability.lifeCounterLocal',
        'ReleaseCapability.battleBatch',
      ],
      'lib/features/retention/screens/post_game_notes_screen.dart': [
        'ReleaseCapability.aiAnalyzeOptimizeAdvisory',
        'ReleaseCapability.aiGenerateRebuild',
        'ReleaseCapability.battleBatch',
      ],
      'lib/features/profile/profile_screen.dart': [
        '_ProfileReleaseAccess.fromProvider',
        'ReleaseCapability.profilesPublic',
        'ReleaseCapability.collectionPrivate',
        'ReleaseCapability.binderPublic',
        'ReleaseCapability.marketplace',
        'ReleaseCapability.directMessages',
        'ReleaseCapability.trades',
        'Perfil não publicado',
      ],
      'lib/features/commercial/widgets/ai_usage_meter.dart': [
        'ReleaseCapabilitiesProvider',
        'ReleaseCapability.aiAnalyzeOptimizeAdvisory',
        'ReleaseCapability.aiGenerateRebuild',
        'if (!aiAvailable) return const SizedBox.shrink()',
      ],
      'lib/features/commercial/screens/legal_screen.dart': [
        'capability correspondente estiver liberada pelo servidor',
        'não são oferecidos nesta revisão',
        'enquanto a capability correspondente estiver OFF',
      ],
      'lib/features/collection/screens/collection_screen.dart': [
        'ReleaseCapabilitiesProvider',
        'routeId',
      ],
      'lib/features/community/screens/community_screen.dart': [
        'ReleaseCapability.galleryPublic',
        'ReleaseCapability.profilesPublic',
        'ReleaseCapability.marketplace',
      ],
      'lib/features/binder/screens/binder_screen.dart': [
        'ReleaseCapability.scanner',
        'scannerBuildSupported',
      ],
      'lib/features/battle/screens/battle_replays_screen.dart': [
        'this.battleLiveEnabled = false',
        'this.interactiveBattleEnabled = false',
      ],
    };

    for (final entry in requiredTokensByFile.entries) {
      final source = File(entry.key).readAsStringSync();
      for (final token in entry.value) {
        expect(source, contains(token), reason: '${entry.key}: $token');
      }
    }

    final legalSource = File(
      'lib/features/commercial/screens/legal_screen.dart',
    ).readAsStringSync();
    final profileSource = File(
      'lib/features/profile/profile_screen.dart',
    ).readAsStringSync();
    expect(legalSource, isNot(contains('coordena propostas e conversas')));
    expect(
      legalSource,
      isNot(contains('O app mostra motivos e preview para revisão humana')),
    );
    expect(profileSource, isNot(contains('sua identidade pública')));

    for (final hub in const [
      'lib/features/collection/screens/collection_screen.dart',
      'lib/features/community/screens/community_screen.dart',
    ]) {
      expect(
        File(hub).readAsStringSync(),
        isNot(contains('initialTab.clamp')),
        reason: '$hub must preserve stable route ids without clamp bypasses',
      );
    }
  });

  test('client enum matches the backend exact capability matrix', () {
    final policy =
        jsonDecode(
              File(
                '../server/config/release_capabilities.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final capabilities = policy['capabilities'] as Map<String, dynamic>;

    expect(
      ReleaseCapability.values.map((entry) => entry.wireName).toSet(),
      capabilities.keys.toSet(),
    );
    expect(capabilities, hasLength(29));
  });

  test('account switch and logout both reset capability authority', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(
      RegExp(r'_releaseCapabilitiesProvider\.reset\(\)').allMatches(source),
      hasLength(greaterThanOrEqualTo(2)),
    );
    expect(
      source,
      contains(
        '_hadAuthenticatedSession && _authenticatedAccountId == accountId',
      ),
    );
    expect(source, contains('status == AuthStatus.unauthenticated'));
    expect(
      source,
      contains(
        '_releaseCapabilitiesProvider.reset();\n'
        '      // Registration and the public pre-auth shell are capability-controlled.',
      ),
    );
    expect(
      source,
      contains('unawaited(_releaseCapabilitiesProvider.refresh());'),
      reason: 'an anonymous session must reacquire registration authority',
    );
  });
}
