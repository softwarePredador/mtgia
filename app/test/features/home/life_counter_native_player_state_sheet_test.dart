import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_native_player_state_sheet.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';

class _Host extends StatelessWidget {
  const _Host({required this.initialSession, required this.onResult});

  final LifeCounterSession initialSession;
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
                  final result = await showLifeCounterNativePlayerStateSheet(
                    context,
                    initialSession: initialSession,
                    initialTargetPlayerIndex: 0,
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
  group('LifeCounterNativePlayerStateSheet', () {
    testWidgets('opens the nested player counter hub and returns to state', (
      tester,
    ) async {
      LifeCounterSession? result;

      await tester.pumpWidget(
        _Host(
          initialSession: LifeCounterSession.initial(playerCount: 4),
          onResult: (value) => result = value,
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Player State'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(
          const Key('life-counter-native-player-state-manage-counters'),
        ),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(
          const Key('life-counter-native-player-state-manage-counters'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Player Counter'), findsOneWidget);

      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();

      expect(find.text('Player State'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('life-counter-native-player-state-apply')),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
    });

    testWidgets(
      'opens the nested commander damage hub and returns to state',
      (tester) async {
        LifeCounterSession? result;

        await tester.pumpWidget(
          _Host(
            initialSession: LifeCounterSession.initial(
              playerCount: 4,
            ).copyWith(
              partnerCommanders: const [false, true, false, false],
            ),
            onResult: (value) => result = value,
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Player State'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.byKey(
            const Key(
              'life-counter-native-player-state-manage-commander-damage',
            ),
          ),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(
          find.byKey(
            const Key(
              'life-counter-native-player-state-manage-commander-damage',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const Key('life-counter-native-commander-damage-apply'),
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('Cancel').last);
        await tester.pumpAndSettle();

        expect(find.text('Player State'), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('life-counter-native-player-state-apply')),
        );
        await tester.pumpAndSettle();

        expect(result, isNotNull);
      },
    );
  });
}
