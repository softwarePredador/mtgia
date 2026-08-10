import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/models/deck_details.dart';
import 'package:manaloom/features/retention/models/post_game_note.dart';
import 'package:manaloom/features/retention/screens/post_game_notes_screen.dart';
import 'package:manaloom/features/retention/services/post_game_note_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'structured card evidence remains exact and legacy names remain valid',
    () {
      final note = PostGameNote.fromJson({
        'id': 'note-42',
        'deck_id': 'deck-42',
        'created_at': '2026-08-05T12:00:00Z',
        'result': 'vitória',
        'table_level': 'casual',
        'notes': '',
        'performed_well': [
          {
            'card_id': '11111111-1111-4111-8111-111111111111',
            'name': 'Sol Ring',
            'image_url': 'https://cards.example/sol-ring.jpg',
            'set_code': 'cmm',
            'collector_number': '396',
            'quantity': 1,
          },
          'Legacy Signal',
        ],
        'underperformed': ['Slow Card'],
        'issues': ['speed'],
        'play_session_id': 'battle-replay:replay-42',
        'revision': 3,
      });

      expect(note.battleReplayId, 'replay-42');
      expect(note.revision, 3);
      expect(note.performedWell, ['Sol Ring', 'Legacy Signal']);
      expect(note.performedWellEvidence.first.hasExactIdentity, isTrue);
      expect(note.performedWellEvidence.last.hasExactIdentity, isFalse);

      final encoded = note.toJson();
      expect(
        encoded['performed_well'],
        contains(
          containsPair('card_id', '11111111-1111-4111-8111-111111111111'),
        ),
      );
      expect(encoded['performed_well'], contains('Legacy Signal'));
    },
  );

  testWidgets(
    'real deck cards cycle through preserve and review before saving evidence',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 1200);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final store = PostGameNoteStore();
      final deck = _evidenceDeck();
      final commanderId = deck.commander.single.id;
      final slowCardId = deck.mainBoard['Artifact']!.single.id;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: PostGameNotesScreen(
            deckId: deck.id,
            store: store,
            playSessionId: 'battle-replay:replay-42',
            deckLoader: (_) async => deck,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('post-game-card-evidence-picker')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('post-game-card-art-$commanderId')),
        findsNothing,
        reason: 'name-only cards must not manufacture reference artwork',
      );

      final commander = find.byKey(Key('post-game-card-$commanderId'));
      await tester.ensureVisible(commander);
      await tester.tap(commander);
      await tester.pump();

      final slowCard = find.byKey(Key('post-game-card-$slowCardId'));
      await tester.tap(slowCard);
      await tester.pump();
      await tester.tap(slowCard);
      await tester.pump();

      expect(find.text('1 preservar'), findsOneWidget);
      expect(find.text('1 revisar'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('post-game-result-field')),
        'vitória',
      );
      final save = find.byKey(const Key('post-game-save-button'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      final saved = (await store.loadNotes(deck.id)).single;
      expect(saved.battleReplayId, 'replay-42');
      expect(saved.performedWellEvidence.single.cardId, commanderId);
      expect(saved.performedWellEvidence.single.isCommander, isTrue);
      expect(saved.underperformedEvidence.single.cardId, slowCardId);
      expect(saved.performedWellEvidence.single.imageUrl, isNull);
      expect(saved.deckSnapshotHash, deck.deckSnapshotHash);
      expect(saved.deckVersionAt, deck.deckVersionAt);
      expect(
        find.byKey(const Key('post-game-evidence-receipt')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('post-game-optimize-evidence-button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'historical session never receives cards from the current deck revision',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final deck = _evidenceDeck();
      final commanderId = deck.commander.single.id;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: PostGameNotesScreen(
            deckId: deck.id,
            store: PostGameNoteStore(),
            playSessionId: 'battle-replay:historical-replay',
            deckSnapshotHash:
                'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
            deckVersionAt: DateTime.parse('2026-08-04T11:30:00Z'),
            deckLoader: (_) async => deck,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Esta partida usa outra revisão do deck. Para não misturar cartas, '
          'os sinais ficam bloqueados; registre o resultado e os problemas '
          'ou recarregue a revisão correta.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(Key('post-game-card-$commanderId')), findsNothing);
    },
  );
}

DeckDetails _evidenceDeck() {
  return DeckDetails(
    id: 'deck-evidence',
    name: 'Mesa de Evidência',
    format: 'commander',
    commanderName: 'Alela, Artful Provocateur',
    isPublic: false,
    createdAt: DateTime.parse('2026-08-01T12:00:00Z'),
    stats: const {'total_cards': 100},
    deckSnapshotHash:
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    deckVersionAt: DateTime.parse('2026-08-05T11:30:00Z'),
    commander: [
      DeckCardItem(
        id: '11111111-1111-4111-8111-111111111111',
        name: 'Alela, Artful Provocateur',
        typeLine: 'Legendary Creature — Faerie Warlock',
        setCode: 'eld',
        collectorNumber: '324',
        rarity: 'mythic',
        quantity: 1,
        isCommander: true,
      ),
    ],
    mainBoard: {
      'Artifact': [
        DeckCardItem(
          id: '22222222-2222-4222-8222-222222222222',
          name: 'Thought Vessel',
          typeLine: 'Artifact',
          setCode: 'cmm',
          collectorNumber: '414',
          rarity: 'uncommon',
          quantity: 1,
          isCommander: false,
        ),
      ],
    },
  );
}
