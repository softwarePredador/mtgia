import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';

import 'runtime_test_helpers.dart';

const _localizedPortugueseValidationList = '''
1 Kaalia da Vastidão
1 Dragão Pira Funesta
1 Sol Ring
1 Arcane Signet
31 Planície
30 Pântano
30 Montanha
1 Necropotência
1 Espadas em Arados
1 Capela Isolada
1 Retiro da Falésia
1 Memorial de Akroma
''';

const _localizedPortugueseImportList = '''
1 Dragão Pira Funesta
1 Sol Ring
1 Arcane Signet
31 Planície
30 Pântano
30 Montanha
1 Necropotência
1 Espadas em Arados
1 Capela Isolada
1 Retiro da Falésia
1 Memorial de Akroma
''';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('localized Portuguese import resolves through public backend', (
    tester,
  ) async {
    await clearRuntimeAuth();
    final api = ApiClient();
    final session = await seedAuthenticatedSession(
      api,
      usernamePrefix: 'localized_import',
    );

    String? deckId;
    try {
      final validateResponse = await api.post('/import/validate', {
        'format': 'commander',
        'list': _localizedPortugueseValidationList,
      });

      expect(validateResponse.statusCode, 200);
      final validateBody = validateResponse.data as Map<String, dynamic>;
      final foundNames =
          ((validateBody['found_cards'] as List?) ?? const [])
              .map((card) => (card as Map)['name']?.toString())
              .whereType<String>()
              .toList();
      bool foundName(String expected) => foundNames.any(
        (name) => name == expected || name.startsWith('$expected //'),
      );

      expect(foundNames, contains('Balefire Dragon'));
      expect(foundNames, contains('Kaalia of the Vast'));
      expect(foundName('Plains'), isTrue);
      expect(foundName('Swamp'), isTrue);
      expect(foundName('Mountain'), isTrue);
      expect(foundNames, contains('Necropotence'));
      expect(foundNames, contains('Swords to Plowshares'));
      expect(foundNames, contains('Isolated Chapel'));
      expect(foundNames, contains('Clifftop Retreat'));
      expect(foundNames, contains("Akroma's Memorial"));
      expect(validateBody['not_found_lines'], isEmpty);
      expect(foundNames.length, greaterThanOrEqualTo(12));
      expect(validateBody['localized_matches_count'], greaterThanOrEqualTo(10));

      final importResponse = await api.post('/import', {
        'name': 'Localized Import Runtime',
        'format': 'commander',
        'commander': 'Kaalia da Vastidão',
        'list': _localizedPortugueseImportList,
      });

      expect(importResponse.statusCode, 200);
      final importBody = importResponse.data as Map<String, dynamic>;
      deckId = (importBody['deck'] as Map?)?['id']?.toString();
      expect(deckId, isNotNull);
      expect(importBody['not_found_lines'], isEmpty);
      expect(importBody['cards_imported'], greaterThanOrEqualTo(100));
      expect(importBody['localized_matches_count'], greaterThanOrEqualTo(9));
      expect(importBody['commander_detected'], isTrue);
      expect(importBody['missing_commander'], isFalse);

      // ignore: avoid_print
      print(
        'LOCALIZED_IMPORT_RUNTIME_SUMMARY {'
        '"user_id":"${session.userId}",'
        '"deck_id":"$deckId",'
        '"found_count":${foundNames.length},'
        '"localized_matches_count":${importBody['localized_matches_count']},'
        '"commander_detected":${importBody['commander_detected']},'
        '"missing_commander":${importBody['missing_commander']}'
        '}',
      );
    } finally {
      if (deckId != null) {
        await api.delete('/decks/$deckId');
      }
      await clearRuntimeAuth();
    }
  });
}
