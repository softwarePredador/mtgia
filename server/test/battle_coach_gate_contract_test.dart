import 'dart:io';

import 'package:test/test.dart';

void main() {
  final repositoryRoot = Directory.current.parent;

  test('BL7 GO remains limited to default-off BL8 engineering', () {
    final decision =
        File(
          '${repositoryRoot.path}/docs/adr/0004-xmage-human-spike-go.md',
        ).readAsStringSync();
    final spike =
        File(
          '${repositoryRoot.path}/services/xmage-sidecar/bin/human_vs_ai_spike.sh',
        ).readAsStringSync();
    final runtimeSpike =
        File(
          '${repositoryRoot.path}/services/xmage-sidecar/bin/'
          'human_vs_ai_runtime_spike.sh',
        ).readAsStringSync();

    expect(decision, contains('Decisão: `GO`'));
    expect(decision, contains('desabilitados por padrão'));
    expect(decision, contains('não autoriza migration live, deploy ou rollout'));
    expect(spike, contains('BL7_SPIKE_DECISION=GO'));
    expect(
      spike,
      contains('BL7_GO_SCOPE=local_BL8_engineering_default_off_no_live_authority'),
    );
    expect(
      runtimeSpike,
      contains('BL7 runtime spike only accepts a loopback XMage server'),
    );
    expect(
      File(
        '${repositoryRoot.path}/services/xmage-sidecar/src/test/java/'
        'com/manaloom/xmage/HumanVsAiRuntimeSpikeMain.java',
      ).existsSync(),
      isTrue,
      reason: 'The runtime probe must remain test-only.',
    );
  });

  test('typed callback families remain explicit in the GO decision', () {
    final decision =
        File(
          '${repositoryRoot.path}/docs/adr/0004-xmage-human-spike-go.md',
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
