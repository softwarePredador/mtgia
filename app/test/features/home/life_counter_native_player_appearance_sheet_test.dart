import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_native_player_appearance_sheet.dart';
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
          builder:
              (context) => Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final result =
                        await showLifeCounterNativePlayerAppearanceSheet(
                          context,
                          initialSession: initialSession,
                          initialTargetPlayerIndex: 0,
                        );
                    onResult(result);
                  },
                  child: const Text('Open'),
                ),
              ),
        ),
      ),
    );
  }
}

void main() {
  group('LifeCounterNativePlayerAppearanceSheet', () {
    testWidgets('keeps per-player drafts and updates nickname preview live', (
      tester,
    ) async {
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

      final nickname = find.byKey(
        const Key('life-counter-native-player-appearance-nickname'),
      );
      final preview = find.byKey(
        const Key('life-counter-native-player-appearance-preview-nickname'),
      );
      final playerOne = find.byKey(
        const Key('life-counter-native-player-appearance-target-0'),
      );
      final playerTwo = find.byKey(
        const Key('life-counter-native-player-appearance-target-1'),
      );
      final scrollable = find.byType(Scrollable).first;

      Future<void> selectPlayer(Finder player) async {
        await Scrollable.ensureVisible(
          tester.element(player),
          alignment: 0.5,
          duration: Duration.zero,
        );
        await tester.pump();
        await tester.tap(player);
        await tester.pump();
      }

      await tester.scrollUntilVisible(nickname, 250, scrollable: scrollable);
      await tester.enterText(nickname, 'Alpha Pilot');
      await tester.pump();
      await tester.scrollUntilVisible(preview, 250, scrollable: scrollable);
      expect(tester.widget<Text>(preview).data, 'Alpha Pilot');

      await selectPlayer(playerTwo);
      await tester.scrollUntilVisible(nickname, 250, scrollable: scrollable);
      await tester.enterText(nickname, 'Bravo Pilot');
      await tester.pump();

      await selectPlayer(playerOne);
      await tester.scrollUntilVisible(preview, 250, scrollable: scrollable);
      expect(tester.widget<Text>(preview).data, 'Alpha Pilot');

      await tester.tap(
        find.byKey(const Key('life-counter-native-player-appearance-apply')),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.resolvedPlayerAppearances[0].nickname, 'Alpha Pilot');
      expect(result!.resolvedPlayerAppearances[1].nickname, 'Bravo Pilot');
    });
  });
}
