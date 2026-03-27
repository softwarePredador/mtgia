import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/home/life_counter_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SequenceRandom implements Random {
  final List<int> _values;

  _SequenceRandom(this._values);

  @override
  bool nextBool() => nextInt(2) == 0;

  @override
  double nextDouble() => nextInt(1000) / 1000;

  @override
  int nextInt(int max) {
    if (_values.isEmpty) {
      throw StateError('No more seeded random values');
    }
    return _values.removeAt(0) % max;
  }
}

void main() {
  Widget createSubject({Random? randomOverride}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: LifeCounterScreen(randomOverride: randomOverride),
    );
  }

  Future<void> triggerHubPetal(WidgetTester tester, Key key) async {
    final inkWellFinder = find.descendant(
      of: find.byKey(key),
      matching: find.byType(InkWell),
    );
    expect(inkWellFinder, findsOneWidget);
    final inkWell = tester.widget<InkWell>(inkWellFinder);
    expect(inkWell.onTap, isNotNull);
    inkWell.onTap!.call();
    await tester.pump();
    await tester.pumpAndSettle();
  }

  group('LifeCounterScreen tabletop UX', () {
    testWidgets('uses a central control hub to open table settings', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('life-counter-control-hub')), findsOneWidget);
      expect(find.byKey(const Key('life-counter-hub-toggle')), findsOneWidget);

      await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-hub-settings')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-hub-quick-high-roll')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('life-counter-hub-tools')), findsOneWidget);
      expect(find.byKey(const Key('life-counter-hub-reset')), findsOneWidget);
      expect(
        find.byKey(const Key('life-counter-hub-quick-d20')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('life-counter-hub-quick-coin')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('life-counter-hub-quick-first-player')),
        findsNothing,
      );
      expect(find.byKey(const Key('life-counter-hub-undo')), findsNothing);
      expect(find.byKey(const Key('life-counter-bottom-rail')), findsOneWidget);
      expect(find.byKey(const Key('life-counter-rail-dice')), findsOneWidget);
      expect(
        find.byKey(const Key('life-counter-rail-history')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-rail-card-search')),
        findsOneWidget,
      );

      await triggerHubPetal(
        tester,
        const Key('life-counter-hub-settings'),
      );

      expect(
        find.byKey(const Key('life-counter-settings-overlay')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('life-counter-settings-overlay')),
          matching: find.text('SETTINGS'),
        ),
        findsOneWidget,
      );
      expect(find.text('MULTI-PLAYER STARTING LIFE'), findsOneWidget);
      expect(find.text('TWO-PLAYER STARTING LIFE'), findsOneWidget);
      expect(find.text('GAME MODES'), findsOneWidget);
      expect(find.text('GAMEPLAY'), findsOneWidget);
    });

    testWidgets('runs D20 from the dice rail instead of a second hub', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-rail-dice')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('life-counter-dice-overlay')), findsOneWidget);
      await tester.tap(find.byKey(const Key('life-counter-dice-roll-d20')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('life-counter-dice-overlay')), findsNothing);
    });

    testWidgets('quick life controls stay left and right in two-player tabletop', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      final topMinusCenter = tester.getCenter(
        find.byKey(const Key('life-counter-quick-minus-0')),
      );
      final topPlusCenter = tester.getCenter(
        find.byKey(const Key('life-counter-quick-plus-0')),
      );
      final bottomMinusCenter = tester.getCenter(
        find.byKey(const Key('life-counter-quick-minus-1')),
      );
      final bottomPlusCenter = tester.getCenter(
        find.byKey(const Key('life-counter-quick-plus-1')),
      );

      expect((topPlusCenter.dy - topMinusCenter.dy).abs(), lessThan(18));
      expect(topPlusCenter.dx, greaterThan(topMinusCenter.dx));

      expect((bottomPlusCenter.dy - bottomMinusCenter.dy).abs(), lessThan(18));
      expect(bottomPlusCenter.dx, greaterThan(bottomMinusCenter.dx));
    });

    testWidgets('shows +5 and -5 labels on quick life controls', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('+5'), findsNWidgets(2));
      expect(find.text('-5'), findsNWidgets(2));
    });

    testWidgets('uses left side for -1 and right side for +1 on player panels', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      final decrementZone = tester.widget<InkWell>(
        find.byKey(const Key('life-counter-decrement-zone-1')),
      );
      decrementZone.onTap!.call();
      await tester.pumpAndSettle();

      expect(find.text('19'), findsOneWidget);

      final incrementZone = tester.widget<InkWell>(
        find.byKey(const Key('life-counter-increment-zone-1')),
      );
      incrementZone.onTap!.call();
      await tester.pumpAndSettle();

      expect(find.text('20'), findsNWidgets(2));
    });

    testWidgets('shows -1 and +1 indicators in left and right screen space', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'life_counter_session_v1': jsonEncode({
          'player_count': 4,
          'starting_life': 40,
          'starting_life_two_player': 20,
          'starting_life_multi_player': 40,
          'lives': [40, 40, 40, 40],
          'poison': [0, 0, 0, 0],
          'energy': [0, 0, 0, 0],
          'experience': [0, 0, 0, 0],
          'commander_casts': [0, 0, 0, 0],
          'player_special_states': ['none', 'none', 'none', 'none'],
          'last_player_rolls': [null, null, null, null],
          'last_high_rolls': [null, null, null, null],
          'commander_damage': [
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
          ],
          'storm_count': 0,
          'monarch_player': null,
          'initiative_player': null,
          'first_player_index': null,
          'last_table_event': null,
        }),
      });
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      for (final index in [0, 1, 2, 3]) {
        final minusCenter = tester.getCenter(
          find.byKey(Key('life-counter-step-minus-$index')),
        );
        final plusCenter = tester.getCenter(
          find.byKey(Key('life-counter-step-plus-$index')),
        );

        expect((plusCenter.dy - minusCenter.dy).abs(), lessThan(18));
        expect(plusCenter.dx, greaterThan(minusCenter.dx));
      }
    });

    testWidgets('quick life controls stay left and right in four-player tabletop', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'life_counter_session_v1': jsonEncode({
          'player_count': 4,
          'starting_life': 40,
          'starting_life_two_player': 20,
          'starting_life_multi_player': 40,
          'lives': [40, 40, 40, 40],
          'poison': [0, 0, 0, 0],
          'energy': [0, 0, 0, 0],
          'experience': [0, 0, 0, 0],
          'commander_casts': [0, 0, 0, 0],
          'player_special_states': ['none', 'none', 'none', 'none'],
          'last_player_rolls': [null, null, null, null],
          'last_high_rolls': [null, null, null, null],
          'commander_damage': [
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
          ],
          'storm_count': 0,
          'monarch_player': null,
          'initiative_player': null,
          'first_player_index': null,
          'last_table_event': null,
        }),
      });
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      final player0Minus = tester.getCenter(
        find.byKey(const Key('life-counter-quick-minus-0')),
      );
      final player0Plus = tester.getCenter(
        find.byKey(const Key('life-counter-quick-plus-0')),
      );
      final player1Minus = tester.getCenter(
        find.byKey(const Key('life-counter-quick-minus-1')),
      );
      final player1Plus = tester.getCenter(
        find.byKey(const Key('life-counter-quick-plus-1')),
      );
      final player2Minus = tester.getCenter(
        find.byKey(const Key('life-counter-quick-minus-2')),
      );
      final player2Plus = tester.getCenter(
        find.byKey(const Key('life-counter-quick-plus-2')),
      );
      final player3Minus = tester.getCenter(
        find.byKey(const Key('life-counter-quick-minus-3')),
      );
      final player3Plus = tester.getCenter(
        find.byKey(const Key('life-counter-quick-plus-3')),
      );

      expect((player0Plus.dy - player0Minus.dy).abs(), lessThan(18));
      expect(player0Plus.dx, greaterThan(player0Minus.dx));

      expect((player1Plus.dy - player1Minus.dy).abs(), lessThan(18));
      expect(player1Plus.dx, greaterThan(player1Minus.dx));

      expect((player2Plus.dy - player2Minus.dy).abs(), lessThan(18));
      expect(player2Plus.dx, greaterThan(player2Minus.dx));

      expect((player3Plus.dy - player3Minus.dy).abs(), lessThan(18));
      expect(player3Plus.dx, greaterThan(player3Minus.dx));
    });

    testWidgets('runs High Roll directly from mesa commander hub', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createSubject(randomOverride: _SequenceRandom([2, 10])),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
      await tester.pumpAndSettle();
      await triggerHubPetal(
        tester,
        const Key('life-counter-hub-quick-high-roll'),
      );

      expect(find.byKey(const Key('life-counter-hub-last-event')), findsOneWidget);
      expect(find.textContaining('High Roll'), findsWidgets);
      expect(
        find.byKey(const Key('life-counter-player-high-roll-event-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-player-high-roll-event-1')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('life-counter-player-high-roll-event-0')),
          matching: find.text('HIGH ROLL'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('life-counter-player-high-roll-event-1')),
          matching: find.text('WINNER'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('rotates players by side when switching to four-player tabletop', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-hub-players')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-players-option-4')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('life-counter-life-core-3')), findsOneWidget);
      expect(find.byType(RotatedBox), findsNWidgets(4));
    });

    testWidgets('uses a wide bottom lane for three-player tabletop', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-hub-players')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-players-option-3')));
      await tester.pumpAndSettle();

      final topSlotSize = tester.getSize(
        find.byKey(const Key('life-counter-player-slot-0')),
      );
      final bottomSlotSize = tester.getSize(
        find.byKey(const Key('life-counter-player-slot-2')),
      );

      expect(find.byType(RotatedBox), findsNWidgets(3));
      expect(bottomSlotSize.width, greaterThan(topSlotSize.width * 1.8));
      expect(bottomSlotSize.height, greaterThan(topSlotSize.height));
    });

    testWidgets('offers five-player tabletop with a centered hub well', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-hub-players')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-players-option-5')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-players-option-6')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('life-counter-players-option-5')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('life-counter-player-slot-4')), findsOneWidget);
      expect(find.byType(RotatedBox), findsNWidgets(5));
    });

    testWidgets('supports six-player tabletop and shrinks the central hub', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      final initialHubSize = tester.getSize(
        find.byKey(const Key('life-counter-hub-toggle')),
      );

      await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-hub-players')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('life-counter-players-option-6')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-players-option-6')));
      await tester.pumpAndSettle();

      final denseHubSize = tester.getSize(
        find.byKey(const Key('life-counter-hub-toggle')),
      );

      expect(find.byKey(const Key('life-counter-player-slot-5')), findsOneWidget);
      expect(find.byType(RotatedBox), findsAtLeastNWidgets(5));
      expect(denseHubSize.width, lessThan(initialHubSize.width));
      expect(denseHubSize.height, lessThan(initialHubSize.height));
    });

    testWidgets('shows a compact counter console in six-player dense mode', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-hub-players')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('life-counter-players-option-6')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-players-option-6')));
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('life-counter-life-core-0')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-player-quick-actions-0')),
        findsOneWidget,
      );
      expect(find.text('TOX'), findsWidgets);
      expect(find.text('TAX'), findsWidgets);
      expect(find.text('MARKS'), findsWidgets);
    });

    testWidgets('shows commander casts with current tax in counters sheet', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('life-counter-life-core-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-counters-1')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-counters-overlay')),
        findsOneWidget,
      );
      expect(find.text('TRACKERS'), findsOneWidget);
      expect(find.text('CAST TAX'), findsOneWidget);
      expect(
        find.byKey(const Key('life-counter-commander-casts-sublabel')),
        findsOneWidget,
      );
      expect(find.text('Current tax: 0 mana'), findsOneWidget);
    });

    testWidgets('applies quick +5 and -5 adjustments on player panels', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      final quickPlus = tester.widget<InkWell>(
        find.byKey(const Key('life-counter-quick-plus-1')),
      );
      quickPlus.onTap!.call();
      await tester.pumpAndSettle();

      expect(find.text('25'), findsOneWidget);

      final quickMinus = tester.widget<InkWell>(
        find.byKey(const Key('life-counter-quick-minus-1')),
      );
      quickMinus.onTap!.call();
      await tester.pumpAndSettle();

      expect(find.text('20'), findsNWidgets(2));
    });

    testWidgets('reveals player quick actions from a long press on the life total core', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('life-counter-life-core-1')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-player-quick-actions-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-player-roll-d20-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-player-poison-plus-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-player-poison-minus-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-player-tax-plus-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-player-tax-minus-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-counters-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-player-toggle-dead-1')),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('life-counter-player-toggle-dead-1')),
        120,
        scrollable: find.descendant(
          of: find.byKey(const Key('life-counter-player-quick-actions-1')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(
        find.byKey(const Key('life-counter-player-toggle-dead-1')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-player-defeated-1')),
        findsOneWidget,
      );
      expect(find.text('KO\'D!'), findsOneWidget);
    });

    testWidgets('opens set life overlay from the player life core', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-life-core-1')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-set-life-overlay')),
        findsOneWidget,
      );
      expect(find.text('SET LIFE'), findsOneWidget);

      await tester.tap(find.byKey(const Key('life-counter-set-life-clear')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-set-life-digit-4')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-set-life-digit-0')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('life-counter-set-life-apply')),
      );
      await tester.tap(find.byKey(const Key('life-counter-set-life-apply')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-set-life-overlay')),
        findsNothing,
      );
      expect(find.text('40'), findsOneWidget);
    });

    testWidgets('shows player d20 result on the player card', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('life-counter-life-core-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-player-roll-d20-1')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-player-roll-event-1')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('life-counter-player-roll-event-1')),
          matching: find.text('D20'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('updates poison inline from the player life hub', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('life-counter-life-core-1')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('life-counter-player-poison-plus-1')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-player-poison-badge-1')),
        findsNothing,
      );
      await tester.longPress(find.byKey(const Key('life-counter-life-core-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-counters-1')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('life-counter-poison-value')),
        findsOneWidget,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('life-counter-poison-value'))).data,
        '1',
      );
    });

    testWidgets('updates commander tax inline from the player life hub', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('life-counter-life-core-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-player-tax-plus-1')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-player-tax-badge-1')),
        findsNothing,
      );
      await tester.longPress(find.byKey(const Key('life-counter-life-core-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-counters-1')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('life-counter-commander-casts-sublabel')),
        findsOneWidget,
      );
      expect(find.text('Current tax: +2 mana'), findsOneWidget);
    });

    testWidgets('opens quick commander damage flow from the life hub', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('life-counter-life-core-1')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-player-commander-damage-1')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('life-counter-player-commander-damage-1')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-commander-damage-quick-overlay')),
        findsOneWidget,
      );
      expect(find.text('COMMANDER DAMAGE'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('life-counter-quick-commander-damage-plus-0')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-quick-commander-damage-value-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-player-commander-damage-badge-1')),
        findsNothing,
      );
    });

    testWidgets('highlights commander lethal on player card and quick sheet', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'life_counter_session_v1': jsonEncode({
          'player_count': 2,
          'starting_life': 40,
          'lives': [40, 40],
          'poison': [0, 0],
          'energy': [0, 0],
          'experience': [0, 0],
          'commander_casts': [0, 0],
          'last_player_rolls': [null, null],
          'last_high_rolls': [null, null],
          'commander_damage': [
            [0, 0],
            [21, 0],
          ],
          'storm_count': 0,
          'monarch_player': null,
          'initiative_player': null,
          'first_player_index': null,
          'last_table_event': null,
        }),
      });

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-player-commander-lethal-1')),
        findsOneWidget,
      );
      expect(find.text('COMMANDER DOWN.'), findsOneWidget);

      await tester.longPress(find.byKey(const Key('life-counter-life-core-1')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('life-counter-player-commander-damage-1')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('life-counter-quick-commander-damage-lethal-summary'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('LETAL por dano de comandante'), findsOneWidget);
    });

    testWidgets('shows poison lethal as a panel takeover state', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'life_counter_session_v1': jsonEncode({
          'player_count': 2,
          'starting_life': 40,
          'lives': [40, 40],
          'poison': [10, 0],
          'energy': [0, 0],
          'experience': [0, 0],
          'commander_casts': [0, 0],
          'last_player_rolls': [null, null],
          'last_high_rolls': [null, null],
          'commander_damage': [
            [0, 0],
            [0, 0],
          ],
          'storm_count': 0,
          'monarch_player': null,
          'initiative_player': null,
          'first_player_index': null,
          'last_table_event': null,
        }),
      });

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-player-poison-lethal-0')),
        findsOneWidget,
      );
      expect(find.text('TOXIC OUT.'), findsOneWidget);
    });

    testWidgets('shows decked out and answer left as full panel takeovers', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'life_counter_session_v1': jsonEncode({
          'player_count': 2,
          'starting_life': 40,
          'lives': [40, 40],
          'poison': [0, 0],
          'energy': [0, 0],
          'experience': [0, 0],
          'commander_casts': [0, 0],
          'player_special_states': ['decked_out', 'answer_left'],
          'last_player_rolls': [null, null],
          'last_high_rolls': [null, null],
          'commander_damage': [
            [0, 0],
            [0, 0],
          ],
          'storm_count': 0,
          'monarch_player': null,
          'initiative_player': null,
          'first_player_index': null,
          'last_table_event': null,
        }),
      });

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-player-decked-out-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-player-answer-left-1')),
        findsOneWidget,
      );
      expect(find.text('DECKED OUT.'), findsOneWidget);
      expect(find.text('ANSWER LEFT.'), findsOneWidget);
    });

    testWidgets('revives a player back to normal actions from a takeover state', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'life_counter_session_v1': jsonEncode({
          'player_count': 2,
          'starting_life': 40,
          'lives': [40, 40],
          'poison': [0, 0],
          'energy': [0, 0],
          'experience': [0, 0],
          'commander_casts': [0, 0],
          'player_special_states': ['decked_out', 'none'],
          'last_player_rolls': [null, null],
          'last_high_rolls': [null, null],
          'commander_damage': [
            [0, 0],
            [0, 0],
          ],
          'storm_count': 0,
          'monarch_player': null,
          'initiative_player': null,
          'first_player_index': null,
          'last_table_event': null,
        }),
      });

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-player-decked-out-0')),
        findsOneWidget,
      );

      await tester.longPress(find.byKey(const Key('life-counter-life-core-0')));
      await tester.pumpAndSettle();
      final reviveButton = tester.widget<InkWell>(
        find.descendant(
          of: find.byKey(const Key('life-counter-player-toggle-dead-0')),
          matching: find.byType(InkWell),
        ),
      );
      reviveButton.onTap!.call();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-player-decked-out-0')),
        findsNothing,
      );

      await tester.longPress(find.byKey(const Key('life-counter-life-core-0')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-player-mark-decked-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-player-mark-left-0')),
        findsOneWidget,
      );
    });

    testWidgets('manages tabletop tools from the central hub', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createSubject(randomOverride: _SequenceRandom([0])),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
      await tester.pumpAndSettle();
      await triggerHubPetal(
        tester,
        const Key('life-counter-hub-tools'),
      );

      expect(find.byKey(const Key('life-counter-tools-overlay')), findsOneWidget);
      expect(find.text('TABLE TOOLS'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('life-counter-storm-row')),
          matching: find.byIcon(Icons.add),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('life-counter-monarch-0')),
      );
      await tester.tap(find.byKey(const Key('life-counter-monarch-0')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('life-counter-initiative-1')),
      );
      await tester.tap(find.byKey(const Key('life-counter-initiative-1')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('life-counter-tool-first-player')),
      );
      await tester.tap(find.byKey(const Key('life-counter-tool-first-player')));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(12, 12));
      await tester.pumpAndSettle();
      final hubToggle = tester.widget<InkWell>(
        find.byKey(const Key('life-counter-hub-toggle')),
      );
      hubToggle.onTap!.call();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('life-counter-hub-last-event')), findsOneWidget);
      final hubLastEvent = tester.widget<Text>(
        find.byKey(const Key('life-counter-hub-last-event')),
      );
      expect(hubLastEvent.data, contains('Primeiro jogador'));
      expect(
        find.byKey(const Key('life-counter-hub-status-storm')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('life-counter-hub-status-monarch')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('life-counter-hub-status-initiative')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('life-counter-hub-status-first-player')),
        findsNothing,
      );
    });

    testWidgets('opens dice overlay from the bottom rail', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-rail-dice')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('life-counter-dice-overlay')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('life-counter-dice-overlay')),
          matching: find.text('DICE'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-dice-roll-high-roll')),
        findsOneWidget,
      );
    });

    testWidgets('opens card search overlay from the bottom rail', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-rail-card-search')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-card-search-overlay')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-card-search-input')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key(
            'life-counter-card-search-suggestion-sol-ring',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('roll-off shows one result card per player', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
      await tester.pumpAndSettle();
      await triggerHubPetal(
        tester,
        const Key('life-counter-hub-tools'),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('life-counter-tool-rolloff')),
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const Key('life-counter-tool-rolloff')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('life-counter-rolloff-results')),
        160,
        scrollable: find.byType(Scrollable).last,
      );

      expect(
        find.byKey(const Key('life-counter-rolloff-results')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-rolloff-player-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-rolloff-player-1')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('life-counter-rolloff-results')),
          matching: find.text('HIGH ROLL'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('rerolls only tied players in High Roll', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createSubject(
          randomOverride: _SequenceRandom([4, 4, 9, 2]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
      await tester.pumpAndSettle();
      await triggerHubPetal(
        tester,
        const Key('life-counter-hub-quick-high-roll'),
      );

      expect(find.textContaining('empatado'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('life-counter-player-high-roll-event-0')),
          matching: find.text('TIE'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('life-counter-player-high-roll-event-1')),
          matching: find.text('TIE'),
        ),
        findsOneWidget,
      );
      await triggerHubPetal(
        tester,
        const Key('life-counter-hub-tools'),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('life-counter-rolloff-reroll-ties')),
        160,
        scrollable: find.byType(Scrollable).last,
      );

      expect(
        find.byKey(const Key('life-counter-rolloff-reroll-ties')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('life-counter-rolloff-reroll-ties')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('life-counter-rolloff-results')), findsOneWidget);
      expect(
        find.byKey(const Key('life-counter-rolloff-player-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-rolloff-player-1')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('life-counter-rolloff-player-0')),
          matching: find.text('10'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('life-counter-rolloff-player-1')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-player-high-roll-event-0')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('life-counter-player-high-roll-event-0')),
          matching: find.text('WINNER'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Desempate do High Roll'), findsWidgets);
    });

    testWidgets('restores persisted tabletop session', (tester) async {
      SharedPreferences.setMockInitialValues({
        'life_counter_session_v1': jsonEncode({
          'player_count': 2,
          'starting_life': 40,
          'lives': [31, 27],
          'poison': [1, 0],
          'energy': [0, 0],
          'experience': [0, 0],
          'commander_casts': [2, 0],
          'commander_damage': [
            [0, 0],
            [0, 0],
          ],
          'storm_count': 3,
          'monarch_player': 0,
          'initiative_player': 1,
          'first_player_index': 1,
          'last_table_event': 'Primeiro jogador: Jogador 2',
        }),
      });

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('31'), findsOneWidget);
      expect(find.text('27'), findsOneWidget);
      expect(
        find.byKey(const Key('life-counter-player-tax-badge-0')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('life-counter-player-poison-badge-0')),
        findsNothing,
      );

      await tester.longPress(find.byKey(const Key('life-counter-life-core-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-counters-0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('life-counter-poison-value')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('life-counter-poison-value'))).data,
        '1',
      );
      expect(find.text('Current tax: +4 mana'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded).last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('life-counter-hub-last-event')), findsOneWidget);
      final restoredHubLastEvent = tester.widget<Text>(
        find.byKey(const Key('life-counter-hub-last-event')),
      );
      expect(restoredHubLastEvent.data, contains('Primeiro jogador: Jogador 2'));
      expect(
        find.byKey(const Key('life-counter-hub-status-storm')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('life-counter-hub-status-monarch')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('life-counter-hub-status-initiative')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('life-counter-hub-status-first-player')),
        findsNothing,
      );
    });
  });
}
