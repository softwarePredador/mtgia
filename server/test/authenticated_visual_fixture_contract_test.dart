import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String fixtureSource;
  late String serverFixtureSource;

  setUpAll(() {
    final fixture = File(
      '../scripts/manaloom_authenticated_visual_qa_isolated.sh',
    );
    final serverFixture = File(
      '../scripts/manaloom_server_contract_e2e_isolated.sh',
    );
    expect(
      fixture.existsSync(),
      isTrue,
      reason: 'The authenticated visual fixture must remain versioned.',
    );
    expect(
      serverFixture.existsSync(),
      isTrue,
      reason: 'The isolated backend fixture must remain versioned.',
    );
    fixtureSource = fixture.readAsStringSync();
    serverFixtureSource = serverFixture.readAsStringSync();
  });

  group('authenticated visual fixture Commander contract', () {
    test('resolves Talrand and Wastes by exact card name', () {
      expect(
        fixtureSource,
        contains(
          r'$API_BASE_URL/cards?name=Talrand%2C%20Sky%20Summoner&limit=10',
        ),
      );
      expect(
        fixtureSource,
        contains(r'select(.name == "Talrand, Sky Summoner")'),
      );
      expect(
        fixtureSource,
        contains(r'$API_BASE_URL/cards?name=Wastes&limit=10'),
      );
      expect(fixtureSource, contains(r'select(.name == "Wastes")'));
      expect(
        RegExp(r'select\(\.id\s*!=\s*\$card_id\)').hasMatch(fixtureSource),
        isFalse,
        reason: 'A commander cannot be selected as an arbitrary second card.',
      );
    });

    test('builds both Commander decks as Talrand plus 99 Wastes', () {
      expect(
        RegExp(r'format:\s*"commander"').allMatches(fixtureSource).length,
        greaterThanOrEqualTo(2),
      );

      for (final deckVariable in const ['deck_id', 'peer_deck_id']) {
        expect(
          fixtureSource,
          contains(
            "(:'$deckVariable'::uuid, :'basic_land_card_id'::uuid, 99, FALSE)",
          ),
          reason: '$deckVariable must contain exactly 99 Wastes.',
        );
        expect(
          fixtureSource,
          contains(
            "(:'$deckVariable'::uuid, :'commander_card_id'::uuid, 1, TRUE)",
          ),
          reason: '$deckVariable must contain Talrand in the commander slot.',
        );
      }
    });

    test(
      'validates both decks through POST /validate and never forges state',
      () {
        for (final deckVariable in const [
          'SEED_DECK_ID',
          'SEED_PEER_DECK_ID',
        ]) {
          final apiValidationCall = RegExp(
            '-X POST[\\s\\S]{0,320}'
                    r'\$API_BASE_URL/decks/\$' +
                deckVariable +
                r'/validate',
          );
          expect(
            apiValidationCall.hasMatch(fixtureSource),
            isTrue,
            reason: '$deckVariable must be validated by the authenticated API.',
          );
        }

        expect(fixtureSource, contains(r'<<<"$deck_validation_response"'));
        expect(fixtureSource, contains(r'<<<"$peer_deck_validation_response"'));
        expect(
          RegExp(
            r'UPDATE\s+decks\b[\s\S]{0,500}?\bvalidation_state\s*=',
            caseSensitive: false,
          ).hasMatch(fixtureSource),
          isFalse,
          reason:
              'Only POST /decks/:id/validate may persist the validated state.',
        );
      },
    );
  });

  group('authenticated visual fixture interactive Battle contract', () {
    test('builds the Web fixture with the Battle Coach entry enabled', () {
      expect(
        fixtureSource,
        contains('--dart-define=ENABLE_INTERACTIVE_BATTLE=true'),
      );
    });

    test('forwards the isolated interactive runtime configuration', () {
      for (final variable in const [
        'INTERACTIVE_BATTLE_ENABLED',
        'XMAGE_SIDECAR_URL',
        'XMAGE_INTERACTIVE_SIDECAR_URL',
        'XMAGE_EXPECTED_COMMIT',
        'XMAGE_EXPECTED_VERSION',
        'BATTLE_ALLOW_LEGACY_SIDECAR_IDENTITY',
      ]) {
        expect(
          serverFixtureSource,
          contains('$variable="\${$variable:-'),
          reason:
              '$variable must reach the isolated backend process when the '
              'caller opts into the interactive runtime.',
        );
      }
    });
  });
}
