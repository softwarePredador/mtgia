import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state.dart';
import 'package:manaloom/features/home/life_counter/life_counter_native_day_night_sheet.dart';

class _Host extends StatelessWidget {
  const _Host({required this.initialState, required this.onResult});

  final LifeCounterDayNightState initialState;
  final ValueChanged<LifeCounterDayNightState?> onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await showLifeCounterNativeDayNightSheet(
                    context,
                    initialState: initialState,
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
  testWidgets('returns the selected day night mode', (tester) async {
    LifeCounterDayNightState? result;

    await tester.pumpWidget(
      _Host(
        initialState: const LifeCounterDayNightState(isNight: false),
        onResult: (value) => result = value,
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Day / Night'), findsOneWidget);
    expect(
      find.byKey(const Key('life-counter-native-day-night-current-label')),
      findsOneWidget,
    );

    await tester.tap(find.text('Night'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('life-counter-native-day-night-apply')),
    );
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.isNight, isTrue);
  });
}
