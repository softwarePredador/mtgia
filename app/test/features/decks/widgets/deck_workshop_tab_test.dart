import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/models/deck_details.dart';
import 'package:manaloom/features/decks/models/deck_optimization_event.dart';
import 'package:manaloom/features/decks/widgets/deck_workshop_tab.dart';

void main() {
  DeckDetails deck() => DeckDetails(
    id: 'deck-1',
    name: 'Lorehold Workshop',
    format: 'commander',
    archetype: 'Big spells e artefatos',
    bracket: 3,
    validationState: 'validated',
    isPublic: false,
    createdAt: DateTime(2026, 8, 5),
    cardCount: 100,
    stats: const {'total_cards': 100},
    commander: [
      DeckCardItem(
        id: 'lorehold',
        name: 'Lorehold, the Historian',
        typeLine: 'Legendary Creature — Spirit Elder',
        colors: const ['R', 'W'],
        colorIdentity: const ['R', 'W'],
        imageUrl: 'https://cards.scryfall.io/normal/front/lorehold.jpg',
        setCode: 'stx',
        rarity: 'rare',
        quantity: 1,
        isCommander: true,
      ),
    ],
    mainBoard: const {},
  );

  DeckOptimizationEvent event({bool canRollback = true}) =>
      DeckOptimizationEvent.fromJson({
        'id': 'event-1',
        'event_type': 'optimize_apply',
        'archetype': 'Big spells e artefatos',
        'bracket': 3,
        'selected_change_count': 2,
        'validation_status': 'validated',
        'battle_status': 'pending_after_apply',
        'created_at': '2026-08-05T14:20:00.000Z',
        'can_rollback': canRollback,
        'rollback_reason': canRollback ? '' : 'deck_changed_after_apply',
        'removals': const [
          {'card_id': 'old', 'name': 'Slow Artifact', 'image_url': ''},
        ],
        'additions': const [
          {'card_id': 'new', 'name': 'Arcane Signet', 'image_url': ''},
        ],
        'source_summary': const {
          'post_analysis_source': 'server_recomputed_from_persisted_selection',
        },
      });

  Widget subject({
    required List<DeckOptimizationEvent> events,
    Future<void> Function(DeckOptimizationEvent)? onRollback,
    double width = 390,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: DeckWorkshopTab(
            deck: deck(),
            events: events,
            isLoading: false,
            errorMessage: null,
            onRefresh: () async {},
            onOptimize: () {},
            onValidate: () {},
            onRollback: onRollback ?? (_) async {},
            onOpenSampleHand: () {},
            onOpenBattle: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('renders commander-led workshop and paired persistent history', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(subject(events: [event()]));
    await tester.pump();

    expect(find.byKey(const Key('deck-workshop-hero')), findsOneWidget);
    expect(find.text('Lorehold, the Historian'), findsOneWidget);
    expect(
      find.byKey(const Key('deck-workshop-decision-rail')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('deck-workshop-event-event-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('deck-workshop-history-pair-0')),
      findsOneWidget,
    );
    expect(find.text('Slow Artifact'), findsOneWidget);
    expect(find.text('Arcane Signet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps rollback in the history and dispatches the exact event', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    DeckOptimizationEvent? rolledBack;
    await tester.pumpWidget(
      subject(
        events: [event()],
        onRollback: (value) async => rolledBack = value,
        width: 1000,
      ),
    );
    await tester.pump();

    final undo = find.byKey(const Key('deck-workshop-undo-event-1'));
    await tester.ensureVisible(undo);
    await tester.tap(undo);
    await tester.pump();

    expect(rolledBack?.id, 'event-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('explains why rollback is refused after newer deck edits', (
    tester,
  ) async {
    await tester.pumpWidget(subject(events: [event(canRollback: false)]));
    await tester.pump();

    final reason = find.byKey(
      const Key('deck-workshop-rollback-reason-event-1'),
    );
    await tester.scrollUntilVisible(
      reason,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(reason, findsOneWidget);
    expect(
      find.textContaining('protege as edições mais novas'),
      findsOneWidget,
    );
  });
}
