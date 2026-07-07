import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/battle/models/battle_replay.dart';
import 'package:manaloom/features/battle/screens/battle_replays_screen.dart';
import 'package:manaloom/features/battle/services/battle_replay_service.dart';

class _FakeBattleReplayGateway implements BattleReplayGateway {
  int listCalls = 0;
  int fetchCalls = 0;

  @override
  Future<List<BattleReplaySummary>> listReplays(String deckId) async {
    listCalls += 1;
    return [
      BattleReplaySummary.fromJson(const {
        'id': 'sim-1',
        'deck_id': 'deck-1',
        'type': 'battle',
        'opponent_name': 'Atraxa Superfriends',
        'winner_name': 'Player A',
        'turns_played': 5,
        'event_count': 2,
      }, fallbackDeckId: deckId),
    ];
  }

  @override
  Future<BattleReplayDetail> fetchReplay({
    required String deckId,
    required String replayId,
  }) async {
    fetchCalls += 1;
    return BattleReplayDetail.fromJson(
      {
        'replay': {
          'id': replayId,
          'deck_id': deckId,
          'type': 'battle',
          'opponent_name': 'Atraxa Superfriends',
          'winner_name': 'Player A',
          'turns': 5,
          'events': const [
            {
              'turn': 1,
              'player': 'Player A',
              'phase': 'main',
              'action': 'casts',
              'card': 'Arcane Signet',
            },
          ],
          'decision_trace': const [
            {
              'turn': 1,
              'choice': 'Cast Arcane Signet',
              'reason': 'Fixes mana before commander turn.',
            },
          ],
        },
      },
      fallbackDeckId: deckId,
      fallbackId: replayId,
    );
  }

  @override
  Future<BattleReplayDetail> runBattleSimulation({
    required String deckId,
    required String opponentDeckId,
    int maxTurns = 30,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BattleReplayDetail> runGoldfishSimulation({
    required String deckId,
    int simulations = 1000,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('renders replay list and opens structured replay detail', (
    tester,
  ) async {
    final gateway = _FakeBattleReplayGateway();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: BattleReplaysScreen(deckId: 'deck-1', gateway: gateway),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('battle-replays-screen')), findsOneWidget);
    expect(find.text('Battle contra Atraxa Superfriends'), findsOneWidget);
    expect(find.text('Vencedor: Player A'), findsOneWidget);
    expect(find.text('2 eventos'), findsOneWidget);
    expect(gateway.listCalls, 1);

    await tester.tap(find.text('Battle contra Atraxa Superfriends'));
    await tester.pumpAndSettle();

    expect(gateway.fetchCalls, 1);
    expect(find.byKey(const Key('battle-replay-detail-pane')), findsOneWidget);
    expect(find.text('Player A casts Arcane Signet'), findsOneWidget);

    await tester.tap(find.text('Decisoes'));
    await tester.pumpAndSettle();

    expect(find.text('Cast Arcane Signet'), findsOneWidget);
    expect(find.text('Fixes mana before commander turn.'), findsOneWidget);
  });
}
