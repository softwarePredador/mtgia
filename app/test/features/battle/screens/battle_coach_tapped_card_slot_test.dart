// Rastro de layout da carta virada na mesa.
//
// Medido em 2026-09-29, abrindo as capturas do `play-vs-ai-web-real`: virar a
// carta é `AnimatedRotation`, que gira na PINTURA e não no layout. Com slot de
// 96 de largura e carta de 134 de altura, a carta girada pintava 134 dentro de
// 96 — 19 sobrando de cada lado, contra 8 de respiro entre as cartas. No
// checkpoint 07 a única carta virada cobria cerca de um terço de cada vizinha;
// no 04 a primeira da fileira era cortada pela borda esquerda.
//
// A conferência é pela GEOMETRIA de verdade, não por presença de widget: o
// retângulo ocupado por cada carta é medido na tela e o da virada não pode
// alcançar o da vizinha.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/battle/models/interactive_battle_session.dart';
import 'package:manaloom/features/battle/screens/battle_coach_screen.dart';
import 'package:manaloom/features/battle/services/interactive_battle_service.dart';

void main() {
  testWidgets('a carta virada reserva o rastro deitado e nao invade a vizinha', (
    tester,
  ) async {
    await _abrirMesa(tester);

    final virada = _retangulo(tester, 'Plains, virada');
    final emPe = _retangulo(tester, 'Isamaru, Hound of Konda');

    expect(
      virada.width,
      greaterThan(emPe.width),
      reason:
          'a carta virada tem de reservar mais espaco horizontal que a em pe; '
          'virada ${virada.width}, em pe ${emPe.width}',
    );
    expect(
      virada.width,
      greaterThanOrEqualTo(emPe.height),
      reason:
          'deitada, a carta ocupa a altura dela em largura; '
          'slot ${virada.width}, altura da carta ${emPe.height}',
    );
    expect(
      virada.right,
      lessThanOrEqualTo(emPe.left),
      reason:
          'a carta virada alcanca a vizinha: termina em ${virada.right} '
          'e a vizinha comeca em ${emPe.left}',
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a carta em pe continua com o slot em pe', (tester) async {
    await _abrirMesa(tester);

    final emPe = _retangulo(tester, 'Isamaru, Hound of Konda');
    expect(
      emPe.height,
      greaterThan(emPe.width),
      reason:
          'carta nao virada nao pode ganhar largura de carta deitada; '
          'medido ${emPe.width}x${emPe.height}',
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _abrirMesa(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_assunto(_GatewayComMesa()));
  await tester.pump();
  await tester.pump();
}

// O rotulo vem do widget `Semantics` que embrulha o slot da carta. Ler a
// propriedade do widget, e nao a arvore de semantica, mantem a medida valendo
// sem depender de handle de acessibilidade no teste.
Rect _retangulo(WidgetTester tester, String rotulo) {
  final alvo = find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.label == rotulo,
  );
  expect(alvo, findsOneWidget, reason: 'nao achei a carta "$rotulo" na mesa');
  return tester.getTopLeft(alvo) & tester.getSize(alvo);
}

Widget _assunto(InteractiveBattleGateway gateway) => MaterialApp(
  home: BattleCoachScreen(
    deckId: 'deck-1',
    sessionId: 'session-1',
    gateway: gateway,
  ),
);

class _GatewayComMesa implements InteractiveBattleGateway {
  @override
  Future<List<InteractiveBattleSession>> list({
    required String deckId,
    int limit = 20,
  }) async => const [];

  @override
  Future<InteractiveBattleSession> create({
    required String deckId,
    required String opponentDeckId,
    int ttlSeconds = 1800,
    int promptTimeoutSeconds = 90,
  }) async => _sessao();

  @override
  Future<InteractiveBattleSession> get(String sessionId) async => _sessao();

  @override
  Future<InteractiveBattleSession> respond({
    required String sessionId,
    required InteractiveBattlePrompt prompt,
    required InteractiveBattleResponse response,
  }) async => _sessao();

  @override
  Future<InteractiveBattleSession> concede(String sessionId) async => _sessao();
}

// A mesa do checkpoint 04: um Plains virado para pagar o mana e o comandante
// em pe logo ao lado. É a dupla que aparecia sobreposta na captura.
InteractiveBattleSession _sessao() => InteractiveBattleSession.fromJson({
  'id': 'session-1',
  'status': 'waiting_for_action',
  'state_version': 1,
  'deck_id': 'deck-1',
  'private_state': {
    'turn': 1,
    'phase': 'Combate',
    'step': 'Declarar atacantes',
    'active_player': 'Você',
    'priority_player': 'Você',
    'own_player': 'Você',
    'players': [
      {
        'name': 'Adversário',
        'life': 40,
        'library_count': 94,
        'hand_count': 5,
        'battlefield': const <dynamic>[],
      },
      {
        'name': 'Você',
        'life': 40,
        'library_count': 91,
        'hand_count': 7,
        'battlefield': [
          {
            'id': 'c-plains',
            'name': 'Plains',
            'set_code': 'FDN',
            'collector_number': '276',
            'tapped': true,
          },
          {
            'id': 'c-isamaru',
            'name': 'Isamaru, Hound of Konda',
            'set_code': 'CHK',
            'collector_number': '10',
            'tapped': false,
          },
        ],
      },
    ],
    'stack': const <dynamic>[],
    'own_hand': const <dynamic>[],
  },
  'prompt': {
    'schema_version': 'interactive_battle_prompt_v1',
    'id': 'p_um',
    'state_version': 1,
    'kind': 'main_action',
    'input_mode': 'options',
    'title': 'Sua prioridade',
    'message': 'Escolha uma ação.',
    'deadline_at': '2099-07-27T15:01:00Z',
    'options': [
      {'id': 'o_passar', 'label': 'Passar prioridade', 'role': 'pass'},
    ],
  },
});
