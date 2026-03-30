// Legacy parity suite kept for historical visual comparison only.
// The live counter coverage now targets `LotusLifeCounterScreen`.
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

const _referencePhoneSize = Size(590, 1280);
const _proofSurfaceSize = Size(1280, 1420);

void main() {
  group('Life counter clone proof board', () {
    Future<void> pumpProofBoard(
      WidgetTester tester, {
      Random? randomOverride,
      Map<String, Object?>? persistedSession,
      bool hubInitiallyExpanded = false,
    }) async {
      SharedPreferences.setMockInitialValues({
        if (persistedSession != null)
          'life_counter_session_v1': jsonEncode(persistedSession),
      });
      await tester.binding.setSurfaceSize(_proofSurfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _CloneProofBoard(
          randomOverride: randomOverride,
          hubInitiallyExpanded: hubInitiallyExpanded,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('captures the four-player base table proof', (tester) async {
      await pumpProofBoard(
        tester,
        persistedSession: _buildPersistedSession(lives: const [40, 31, 1, 23]),
      );

      expect(find.byKey(const Key('life-counter-life-core-3')), findsOneWidget);
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const Key('life-counter-clone-current-frame')),
        matchesGoldenFile('goldens/life_counter_clone_current_normal_4p.png'),
      );
    });

    testWidgets('captures the open hub proof board', (tester) async {
      await pumpProofBoard(
        tester,
        persistedSession: _buildPersistedSession(lives: const [5, 31, 1, 23]),
        hubInitiallyExpanded: true,
      );

      expect(find.byKey(const Key('life-counter-bottom-rail')), findsOneWidget);
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const Key('life-counter-clone-current-frame')),
        matchesGoldenFile('goldens/life_counter_clone_current_hub_open.png'),
      );
    });

    testWidgets('captures the settings overlay proof board', (tester) async {
      await pumpProofBoard(
        tester,
        persistedSession: _buildPersistedSession(lives: const [40, 31, 1, 23]),
        hubInitiallyExpanded: true,
      );

      final settingsButton = tester.widget<InkWell>(
        find.descendant(
          of: find.byKey(const Key('life-counter-hub-settings')),
          matching: find.byType(InkWell),
        ),
      );
      settingsButton.onTap!.call();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('life-counter-settings-overlay')),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(const Key('life-counter-clone-current-frame')),
        matchesGoldenFile('goldens/life_counter_clone_current_settings.png'),
      );
    });

    testWidgets('captures the set life overlay proof board', (tester) async {
      await pumpProofBoard(
        tester,
        persistedSession: _buildPersistedSession(lives: const [40, 31, 1, 23]),
      );

      await tester.tap(find.byKey(const Key('life-counter-life-core-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-set-life-clear')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('life-counter-set-life-digit-4')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('life-counter-set-life-overlay')), findsOneWidget);
      expect(find.text('4'), findsWidgets);

      await expectLater(
        find.byKey(const Key('life-counter-clone-current-frame')),
        matchesGoldenFile('goldens/life_counter_clone_current_set_life.png'),
      );
    });

    testWidgets('captures the high roll takeover proof board', (tester) async {
      await pumpProofBoard(
        tester,
        randomOverride: _SequenceRandom([14, 13, 19, 10]),
        persistedSession: _buildPersistedSession(
          lives: const [40, 40, 40, 40],
          lastHighRolls: const [15, 14, 20, 11],
          firstPlayerIndex: 2,
          lastTableEvent: 'High Roll: Jogador 3 venceu com 20',
        ),
      );

      expect(
        find.byKey(const Key('life-counter-player-high-roll-event-2')),
        findsOneWidget,
      );
      expect(find.text('WINNER'), findsOneWidget);
      await expectLater(
        find.byKey(const Key('life-counter-clone-current-frame')),
        matchesGoldenFile('goldens/life_counter_clone_current_high_roll.png'),
      );
    });
  });
}

Map<String, Object?> _buildPersistedSession({
  required List<int> lives,
  List<int>? poison,
  List<int>? energy,
  List<int>? experience,
  List<int>? commanderCasts,
  List<String>? playerSpecialStates,
  List<int?>? lastPlayerRolls,
  List<int?>? lastHighRolls,
  int? firstPlayerIndex,
  String? lastTableEvent,
}) {
  return {
    'player_count': 4,
    'starting_life': 40,
    'starting_life_two_player': 20,
    'starting_life_multi_player': 40,
    'lives': lives,
    'poison': poison ?? const [0, 0, 0, 0],
    'energy': energy ?? const [0, 0, 0, 0],
    'experience': experience ?? const [0, 0, 0, 0],
    'commander_casts': commanderCasts ?? const [0, 0, 0, 0],
    'player_special_states':
        playerSpecialStates ?? const ['none', 'none', 'none', 'none'],
    'last_player_rolls': lastPlayerRolls ?? const [null, null, null, null],
    'last_high_rolls': lastHighRolls ?? const [null, null, null, null],
    'commander_damage': const [
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ],
    'storm_count': 0,
    'monarch_player': null,
    'initiative_player': null,
    'first_player_index': firstPlayerIndex,
    'last_table_event': lastTableEvent,
  };
}

class _CloneProofBoard extends StatelessWidget {
  final Random? randomOverride;
  final bool hubInitiallyExpanded;

  const _CloneProofBoard({
    this.randomOverride,
    this.hubInitiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF050505),
      child: Center(
        child: SizedBox(
          key: const Key('life-counter-clone-current-frame'),
          width: _referencePhoneSize.width,
          height: _referencePhoneSize.height,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _buildProofTheme(),
            home: LifeCounterScreen(
              randomOverride: randomOverride,
              initialHubExpanded: hubInitiallyExpanded,
            ),
          ),
        ),
      ),
    );
  }
}

ThemeData _buildProofTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppTheme.backgroundAbyss,
    colorScheme: const ColorScheme.dark(
      primary: AppTheme.manaViolet,
      secondary: AppTheme.primarySoft,
      surface: AppTheme.surfaceSlate,
      onSurface: AppTheme.textPrimary,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppTheme.textPrimary,
      displayColor: AppTheme.textPrimary,
    ),
    cardTheme: CardThemeData(
      color: AppTheme.surfaceSlate,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppTheme.surfaceSlate,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: const BorderSide(color: AppTheme.manaViolet, width: 1.5),
      ),
    ),
  );
}
