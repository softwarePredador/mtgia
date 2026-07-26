import 'dart:io';

import 'package:test/test.dart';

void main() {
  final repositoryRoot = Directory.current.parent;

  test('BL7 NO-GO keeps interactive Battle routes fail-closed', () {
    final decision =
        File(
          '${repositoryRoot.path}/docs/adr/0003-xmage-human-spike-no-go.md',
        ).readAsStringSync();
    final spike =
        File(
          '${repositoryRoot.path}/services/xmage-sidecar/bin/human_vs_ai_spike.sh',
        ).readAsStringSync();

    expect(decision, contains('Decisão: `NO_GO`'));
    expect(decision, contains('BL8 permanece `BLOCKED`'));
    expect(decision, contains('BL9/BL10 ficam'));
    expect(spike, contains('BL7_SPIKE_DECISION=NO_GO'));
    expect(
      Directory(
        '${Directory.current.path}/routes/ai/battle/sessions',
      ).existsSync(),
      isFalse,
      reason: 'BL8 cannot expose an interactive route after a BL7 NO-GO.',
    );
    expect(
      File(
        '${repositoryRoot.path}/app/lib/features/battle/screens/'
        'battle_coach_screen.dart',
      ).existsSync(),
      isFalse,
      reason: 'Coach UI must remain absent while BL8 is dependency-blocked.',
    );
  });

  test('unhandled callback families remain explicit in the decision', () {
    final decision =
        File(
          '${repositoryRoot.path}/docs/adr/0003-xmage-human-spike-no-go.md',
        ).readAsStringSync();
    for (final callback in const [
      'GAME_CHOOSE_ABILITY',
      'GAME_CHOOSE_PILE',
      'GAME_CHOOSE_CHOICE',
      'GAME_PLAY_MANA',
      'GAME_PLAY_XMANA',
      'GAME_GET_AMOUNT',
      'GAME_GET_MULTI_AMOUNT',
    ]) {
      expect(decision, contains(callback));
    }
  });
}
