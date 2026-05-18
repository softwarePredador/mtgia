import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';

import 'runtime_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('localized Portuguese import resolves through public backend',
      (tester) async {
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
        'list': '1 Dragão Pira Funesta\n1 Kaalia da Vastidão',
      });

      expect(validateResponse.statusCode, 200);
      final validateBody = validateResponse.data as Map<String, dynamic>;
      final foundNames = ((validateBody['found_cards'] as List?) ?? const [])
          .map((card) => (card as Map)['name']?.toString())
          .whereType<String>()
          .toList();

      expect(foundNames, contains('Balefire Dragon'));
      expect(foundNames, contains('Kaalia of the Vast'));
      expect(validateBody['not_found_lines'], isEmpty);
      expect(validateBody['localized_matches_count'], greaterThanOrEqualTo(2));

      final importResponse = await api.post('/import', {
        'name': 'Localized Import Runtime',
        'format': 'commander',
        'commander': 'Kaalia da Vastidão',
        'list': '1 Dragão Pira Funesta\n1 Kaalia da Vastidão',
      });

      expect(importResponse.statusCode, 200);
      final importBody = importResponse.data as Map<String, dynamic>;
      deckId = (importBody['deck'] as Map?)?['id']?.toString();
      expect(deckId, isNotNull);
      expect(importBody['not_found_lines'], isEmpty);
      expect(importBody['localized_matches_count'], greaterThanOrEqualTo(2));
      expect(importBody['commander_detected'], isTrue);
      expect(importBody['missing_commander'], isFalse);

      // ignore: avoid_print
      print('LOCALIZED_IMPORT_RUNTIME_SUMMARY {'
          '"user_id":"${session.userId}",'
          '"deck_id":"$deckId",'
          '"found_count":${foundNames.length},'
          '"localized_matches_count":${importBody['localized_matches_count']},'
          '"commander_detected":${importBody['commander_detected']},'
          '"missing_commander":${importBody['missing_commander']}'
          '}');
    } finally {
      if (deckId != null) {
        await api.delete('/decks/$deckId');
      }
      await clearRuntimeAuth();
    }
  });
}
