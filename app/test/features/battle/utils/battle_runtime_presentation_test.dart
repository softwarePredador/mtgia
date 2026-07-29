import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/battle/utils/battle_runtime_presentation.dart';

void main() {
  test('maps internal execution lanes to product language', () {
    expect(battleRuntimeUserLabel('xmage'), 'Execução principal');
    expect(battleRuntimeUserLabel('forge'), 'Execução compatível');
    expect(battleRuntimeUserLabel('native'), 'Execução revisada');
    expect(battleRuntimeUserLabel('unknown'), 'Modo não informado');
  });

  test('sanitizes vendor names received in backend errors', () {
    expect(
      sanitizeBattleUserMessage('XMage interactive connection is not ready'),
      'motor de regras interactive connection is not ready',
    );
    expect(
      sanitizeBattleUserMessage('xmage_coverage_incomplete'),
      'rules_coverage_incomplete',
    );
    expect(
      sanitizeBattleUserMessage('Battlefield Forge is unavailable'),
      'Battlefield Forge is unavailable',
    );
    expect(
      sanitizeBattleUserMessage('Purphoros, God of the Forge'),
      'Purphoros, God of the Forge',
    );
  });

  test('sanitizes engine provenance recursively in technical payloads', () {
    final payload = sanitizeBattleDiagnosticPayload({
      'engine': 'xmage',
      'engine_coverage': {'xmage': 'ready', 'forge': 'unsupported'},
      'fallback_chain': ['xmage:coverage_incomplete', 'forge'],
      'card_name': 'Battlefield Forge',
    });

    expect(payload, {
      'engine': 'Execução principal',
      'engine_coverage': {
        'Execução principal': 'ready',
        'Execução compatível': 'unsupported',
      },
      'fallback_chain': ['rules:coverage_incomplete', 'Execução compatível'],
      'card_name': 'Battlefield Forge',
    });
  });

  test('player-facing Battle sources do not expose runtime vendors', () {
    const paths = <String>[
      'lib/features/battle/screens/battle_coach_screen.dart',
      'lib/features/battle/screens/battle_live_spectator_screen.dart',
      'lib/features/battle/screens/battle_replays_screen.dart',
      'lib/features/decks/widgets/deck_analysis_tab.dart',
    ];
    final vendorPattern = RegExp(r'\b(?:XMage|Forge|ManaLoom nativo)\b');

    for (final path in paths) {
      expect(
        vendorPattern.hasMatch(File(path).readAsStringSync()),
        isFalse,
        reason: '$path contém nome interno de motor em uma superfície visível.',
      );
    }
  });
}
