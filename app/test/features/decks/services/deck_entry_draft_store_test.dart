import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/services/deck_entry_draft_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('keeps generate drafts isolated by authenticated owner', () async {
    final store = DeckEntryDraftStore();
    await store.saveGenerate(
      'user-a',
      format: 'Commander',
      commander: 'Lorehold, the Historian',
      prompt: 'Artefatos e mágicas históricas',
      deckName: 'Lorehold Draft',
      activeJobId: 'job-1',
      requestKey: 'generate:request-1',
      preferCollection: true,
      collectionOnly: true,
      budgetLimitBrl: '250',
    );

    expect(await store.loadGenerate('user-b'), isNull);
    expect(
      await store.loadGenerate('user-a'),
      containsPair('commander', 'Lorehold, the Historian'),
    );
    final restored = await store.loadGenerate('user-a');
    expect(restored?['active_job_id'], 'job-1');
    expect(restored?['request_key'], 'generate:request-1');
    expect(restored?['prefer_collection'], 'true');
    expect(restored?['collection_only'], 'true');
    expect(restored?['budget_limit_brl'], '250');

    await store.clearGenerate('user-a');
    expect(await store.loadGenerate('user-a'), isNull);
  });

  test('round-trips and clears an import draft', () async {
    final store = DeckEntryDraftStore();
    await store.saveImport(
      'user-a',
      format: 'commander',
      name: 'Import Draft',
      description: 'Lista em revisão',
      commander: 'Lorehold, the Historian',
      cardList: '1 Sol Ring\n1 Arcane Signet',
    );

    final draft = await store.loadImport('user-a');
    expect(draft?['name'], 'Import Draft');
    expect(draft?['card_list'], contains('Arcane Signet'));

    await store.clearImport('user-a');
    expect(await store.loadImport('user-a'), isNull);
  });
}
