import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state.dart';
import 'package:manaloom/features/home/life_counter/life_counter_native_game_timer_sheet.dart';

class _Host extends StatelessWidget {
  const _Host({
    required this.initialState,
    required this.nowProvider,
    required this.onResult,
  });

  final LifeCounterGameTimerState initialState;
  final DateTime Function() nowProvider;
  final ValueChanged<LifeCounterGameTimerState?> onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await showLifeCounterNativeGameTimerSheet(
                    context,
                    initialState: initialState,
                    nowProvider: nowProvider,
                  );
                  onResult(result);
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );
  }
}

void main() {
  group('LifeCounterNativeGameTimerSheet', () {
    testWidgets('starts a new timer and returns an active state', (
      tester,
    ) async {
      LifeCounterGameTimerState? result;

      await tester.pumpWidget(
        _Host(
          initialState: const LifeCounterGameTimerState(
            startTimeEpochMs: null,
            isPaused: false,
            pausedTimeEpochMs: null,
          ),
          nowProvider: () => DateTime.fromMillisecondsSinceEpoch(10_000),
          onResult: (value) => result = value,
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Game Timer'), findsOneWidget);
      expect(find.text('Idle'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('life-counter-native-game-timer-start')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(const Key('life-counter-native-game-timer-start')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Running'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('life-counter-native-game-timer-apply')),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.isActive, isTrue);
      expect(result!.isPaused, isFalse);
      expect(result!.startTimeEpochMs, 10_000);
      expect(result!.pausedTimeEpochMs, isNull);
    });

    testWidgets('pauses resumes and resets an existing timer', (tester) async {
      LifeCounterGameTimerState? result;
      var nowEpochMs = 6_000;

      await tester.pumpWidget(
        _Host(
          initialState: const LifeCounterGameTimerState(
            startTimeEpochMs: 1_000,
            isPaused: false,
            pausedTimeEpochMs: null,
          ),
          nowProvider: () => DateTime.fromMillisecondsSinceEpoch(nowEpochMs),
          onResult: (value) => result = value,
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Running'), findsOneWidget);
      expect(find.text('0:05'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('life-counter-native-game-timer-pause')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(const Key('life-counter-native-game-timer-pause')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Paused'), findsOneWidget);

      nowEpochMs = 12_000;
      await tester.tap(
        find.byKey(const Key('life-counter-native-game-timer-resume')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Running'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('life-counter-native-game-timer-reset')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Idle'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('life-counter-native-game-timer-apply')),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.isActive, isFalse);
      expect(result!.isPaused, isFalse);
      expect(result!.startTimeEpochMs, isNull);
      expect(result!.pausedTimeEpochMs, isNull);
    });
  });
}
