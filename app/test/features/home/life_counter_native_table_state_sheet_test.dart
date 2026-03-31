import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_native_table_state_sheet.dart';
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
                  final result = await showLifeCounterNativeTableStateSheet(
                    context,
                    initialSession: initialSession,
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
  testWidgets('updates monarch initiative and storm state', (tester) async {
    LifeCounterSession? result;
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _Host(
        initialSession: LifeCounterSession.initial(playerCount: 4),
        onResult: (value) => result = value,
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Table State'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const Key('life-counter-native-table-state-monarch-player-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(
        const Key('life-counter-native-table-state-initiative-player-2'),
      ),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(
        const Key('life-counter-native-table-state-initiative-player-2'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('life-counter-native-table-state-storm-plus')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.byKey(const Key('life-counter-native-table-state-storm-plus')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('life-counter-native-table-state-storm-plus')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('life-counter-native-table-state-storm-plus')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('life-counter-native-table-state-apply')),
    );
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.monarchPlayer, 1);
    expect(result!.initiativePlayer, 2);
    expect(result!.stormCount, 2);
  });
}
