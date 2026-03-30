import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens the ManaLoom-owned native history on the live WebView path', (
    tester,
  ) async {
    await LifeCounterSessionStore().save(
      LifeCounterSession.tryFromJson({
        ...LifeCounterSession.initial(playerCount: 4).toJson(),
        'last_table_event': 'Player 1 lost 3 life',
      })!,
    );
    await LotusStorageSnapshotStore().save(
      const LotusStorageSnapshot(
        values: {
          'currentGameMeta': '{"name":"Game #12"}',
          'gameHistory':
              '[{"message":"Player 2 gained 2 life","timestamp":1711800000000}]',
          'allGamesHistory':
              '[{"name":"Game #11","history":[{"message":"Player 3 was eliminated"}]}]',
        },
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: LotusLifeCounterScreen()));
    await tester.pump();

    final dynamic state = tester.state(find.byType(LotusLifeCounterScreen));
    await state.debugHandleShellMessage(
      '{"type":"open-native-history","source":"history_shortcut_pressed"}',
    );
    await tester.pumpAndSettle();

    expect(find.text('Life Counter History'), findsOneWidget);
    expect(find.text('Player 1 lost 3 life'), findsOneWidget);
    expect(find.text('Player 2 gained 2 life'), findsOneWidget);
    expect(find.text('Player 3 was eliminated'), findsOneWidget);
  });
}
