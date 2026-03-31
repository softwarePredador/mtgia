import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_native_set_life_sheet.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';

class _SetLifeHost extends StatelessWidget {
  const _SetLifeHost({required this.onResult});

  final ValueChanged<LifeCounterSession?> onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final result = await showLifeCounterNativeSetLifeSheet(
              context,
              initialSession: LifeCounterSession.initial(playerCount: 4),
              initialTargetPlayerIndex: 1,
            );
            onResult(result);
          },
          child: const Text('Open'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('sets life for the targeted player', (tester) async {
    LifeCounterSession? result;

    await tester.pumpWidget(
      MaterialApp(
        home: _SetLifeHost(onResult: (value) => result = value),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('life-counter-native-set-life-apply')), findsOneWidget);
    expect(
      find.byKey(const Key('life-counter-native-set-life-display')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('life-counter-native-set-life-clear')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('life-counter-native-set-life-digit-4')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('life-counter-native-set-life-digit-0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('life-counter-native-set-life-apply')),
    );
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.lives[1], 40);
    expect(result!.lastTableEvent, isNull);
  });
}
