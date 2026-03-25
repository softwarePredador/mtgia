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
        find.byKey(const Key('life-counter-hub-quick-d20')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-hub-quick-high-roll')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-hub-quick-coin')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-hub-quick-first-player')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('life-counter-hub-tools')), findsOneWidget);
      expect(find.byKey(const Key('life-counter-hub-undo')), findsOneWidget);
      expect(find.byKey(const Key('life-counter-hub-reset')), findsOneWidget);
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

      await tester.tap(find.byKey(const Key('life-counter-hub-settings')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-settings-overlay')),
        findsOneWidget,
      );
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('MULTI-PLAYER STARTING LIFE'), findsOneWidget);
      expect(find.text('TWO-PLAYER STARTING LIFE'), findsOneWidget);
      expect(find.text('GAME MODES'), findsOneWidget);
      expect(find.text('GAMEPLAY'), findsOneWidget);
    });

    testWidgets('runs D20 directly from mesa commander hub', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-hub-quick-d20')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('life-counter-hub-last-event')), findsOneWidget);
      expect(find.textContaining('D20:'), findsOneWidget);
    });

    testWidgets('runs High Roll directly from mesa commander hub', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-hub-quick-high-roll')));
      await tester.pumpAndSettle();

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
    });

    testWidgets('rotates upper players when switching to four-player tabletop', (
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
      expect(find.byType(RotatedBox), findsNWidgets(2));
    });

    testWidgets('shows commander casts with current tax in counters sheet', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-counters-1')));
      await tester.pumpAndSettle();

      expect(find.text('Commander casts'), findsOneWidget);
      expect(
        find.byKey(const Key('life-counter-commander-casts-sublabel')),
        findsOneWidget,
      );
      expect(find.text('Taxa atual: 0 mana'), findsOneWidget);
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
      expect(find.text('D20'), findsOneWidget);
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
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('life-counter-player-poison-badge-1')),
          matching: find.text('1'),
        ),
        findsOneWidget,
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
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('life-counter-player-tax-badge-1')),
          matching: find.text('Tax +2'),
        ),
        findsOneWidget,
      );
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
        find.byKey(const Key('life-counter-commander-damage-quick-sheet')),
        findsOneWidget,
      );
      expect(find.text('Dano de comandante rapido'), findsOneWidget);

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
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const Key('life-counter-player-commander-damage-badge-1'),
          ),
          matching: find.text('1'),
        ),
        findsOneWidget,
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

    testWidgets('manages tabletop tools from the central hub', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        createSubject(randomOverride: _SequenceRandom([0])),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-hub-tools')));
      await tester.pumpAndSettle();

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

      expect(
        find.byKey(const Key('life-counter-hub-status-storm')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-hub-status-monarch')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-hub-status-initiative')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-hub-status-first-player')),
        findsOneWidget,
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

    testWidgets('roll-off shows one result card per player', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-hub-tools')));
      await tester.pumpAndSettle();

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
      await tester.tap(find.byKey(const Key('life-counter-hub-quick-high-roll')));
      await tester.pumpAndSettle();

      expect(find.textContaining('empatado'), findsOneWidget);
      await tester.tap(find.byKey(const Key('life-counter-hub-tools')));
      await tester.pumpAndSettle();

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
      expect(find.text('WINNER'), findsOneWidget);
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
      expect(find.text('Tax +4'), findsOneWidget);

      await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-hub-status-storm')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-hub-status-monarch')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-hub-status-initiative')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('life-counter-hub-status-first-player')),
        findsOneWidget,
      );
    });
  });
}
