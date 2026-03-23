import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/home/life_counter_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget createSubject() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: const LifeCounterScreen(),
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
      expect(find.byKey(const Key('life-counter-hub-tools')), findsOneWidget);
      expect(find.byKey(const Key('life-counter-hub-undo')), findsOneWidget);
      expect(find.byKey(const Key('life-counter-hub-reset')), findsOneWidget);

      await tester.tap(find.byKey(const Key('life-counter-hub-settings')));
      await tester.pumpAndSettle();

      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Jogadores'), findsOneWidget);
      expect(find.text('Vida Inicial'), findsOneWidget);
    });

    testWidgets(
      'rotates upper players when switching to four-player tabletop',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(createSubject());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('life-counter-hub-settings')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ChoiceChip, '4'));
        await tester.pumpAndSettle();

        expect(find.text('P4'), findsOneWidget);
        expect(find.byType(RotatedBox), findsNWidgets(2));
      },
    );

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

    testWidgets('manages tabletop tools from the central hub', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('life-counter-hub-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-hub-tools')));
      await tester.pumpAndSettle();

      expect(find.text('Ferramentas de Mesa'), findsOneWidget);

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
      expect(find.text('Storm 3'), findsOneWidget);
      expect(find.text('Monarca Jogador 1'), findsOneWidget);
      expect(find.text('Iniciativa Jogador 2'), findsOneWidget);
      expect(find.text('1º Jogador 2'), findsOneWidget);
    });
  });
}
