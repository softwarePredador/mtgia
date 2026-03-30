import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_native_player_counter_sheet.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';

class _Host extends StatelessWidget {
  const _Host({
    required this.initialSession,
    required this.initialTargetPlayerIndex,
    required this.counterKey,
    required this.onResult,
  });

  final LifeCounterSession initialSession;
  final int initialTargetPlayerIndex;
  final String counterKey;
  final ValueChanged<LifeCounterSession?> onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await showLifeCounterNativePlayerCounterSheet(
                    context,
                    initialSession: initialSession,
                    initialTargetPlayerIndex: initialTargetPlayerIndex,
                    counterKey: counterKey,
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
  group('LifeCounterNativePlayerCounterSheet', () {
    testWidgets('adds a custom counter and returns it in the draft session', (
      tester,
    ) async {
      LifeCounterSession? result;

      await tester.pumpWidget(
        _Host(
          initialSession: LifeCounterSession.initial(playerCount: 4),
          initialTargetPlayerIndex: 0,
          counterKey: 'poison',
          onResult: (value) => result = value,
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Player Counter'), findsOneWidget);

      await tester.enterText(
        find.byKey(
          const Key('life-counter-native-player-counter-custom-name'),
        ),
        'Quest Counter',
      );
      await tester.ensureVisible(
        find.byKey(
          const Key('life-counter-native-player-counter-custom-add'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('life-counter-native-player-counter-custom-add'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('life-counter-native-player-counter-plus')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('life-counter-native-player-counter-plus')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('life-counter-native-player-counter-apply')),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.resolvedPlayerExtraCounters[0]['quest-counter'], 2);
    });

    testWidgets('removes a custom counter when its value reaches zero', (
      tester,
    ) async {
      LifeCounterSession? result;

      await tester.pumpWidget(
        _Host(
          initialSession: LifeCounterSession.initial(
            playerCount: 4,
          ).copyWith(
            playerExtraCounters: const [
              {'rad': 3},
              {},
              {},
              {},
            ],
          ),
          initialTargetPlayerIndex: 0,
          counterKey: 'rad',
          onResult: (value) => result = value,
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('life-counter-native-player-counter-chip-rad'),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(
          const Key('life-counter-native-player-counter-chip-rad'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('life-counter-native-player-counter-minus')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(
        find.byKey(const Key('life-counter-native-player-counter-minus')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('life-counter-native-player-counter-minus')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('life-counter-native-player-counter-minus')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('life-counter-native-player-counter-minus')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('life-counter-native-player-counter-apply')),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.resolvedPlayerExtraCounters[0].containsKey('rad'), isFalse);
    });
  });
}
