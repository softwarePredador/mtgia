// Foco de teclado quando o prompt da mesa é substituído.
//
// Medido em 2026-09-28, no `battle-coach-web-keyboard`: depois de Enter em
// "Manter esta mão", o foco ia parar em "Abrir replays" — a barra do app. Quem
// joga por teclado perdia o lugar no meio da partida e tinha de percorrer a
// ordem de foco inteira a cada decisão. O contrato do pacote exige que o prompt
// substituído de forma assíncrona PRESERVE um halo visível numa ação legal.
//
// A conferência é pelo NÓ EXATO do foco (`FocusManager.instance.primaryFocus` e
// o `debugLabel` do próprio nó), nunca por substring de tela: o elemento de
// medição do Flutter carrega no texto a barra inteira do app e aprovaria
// qualquer rótulo.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/battle/models/interactive_battle_session.dart';
import 'package:manaloom/features/battle/screens/battle_coach_screen.dart';
import 'package:manaloom/features/battle/services/interactive_battle_service.dart';

void main() {
  testWidgets(
    'o prompt substituido preserva o foco numa acao legal, nunca na barra',
    (tester) async {
      final gateway = _GatewayComSegundoPrompt();
      await tester.pumpWidget(_assunto(gateway));
      await tester.pump();
      await tester.pump();

      final primeira = find.byKey(const Key('battle-coach-option-o_um'));
      expect(primeira, findsOneWidget);
      await tester.tap(primeira);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // O prompt novo está na tela.
      expect(find.byKey(const Key('battle-coach-option-o_dois')), findsOneWidget);

      final foco = FocusManager.instance.primaryFocus;
      expect(foco, isNotNull, reason: 'nada recebeu o foco apos a troca');
      expect(
        foco!.debugLabel,
        startsWith('Play vs AI option '),
        reason:
            'o prompt substituido tem de preservar o foco numa acao legal; '
            'foco em ${foco.debugLabel}',
      );
      expect(
        foco.debugLabel,
        isNot(contains('replays')),
        reason: 'o foco nao pode cair na barra do app',
      );

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final modo in const ['integer', 'multi_amount']) {
    testWidgets(
      'prompt $modo sem acao legal: o foco pousa no painel, nunca na barra',
      (tester) async {
        await tester.pumpWidget(_assunto(_GatewayComPromptFixo(modo)));
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Quantos?'), findsOneWidget);

        final foco = FocusManager.instance.primaryFocus;
        expect(foco, isNotNull, reason: 'nada recebeu o foco');
        expect(
          foco!.debugLabel ?? '',
          isNot(contains('replays')),
          reason: 'o foco nao pode cair em "Abrir replays"',
        );
        expect(
          foco.context,
          isNotNull,
          reason: 'o foco tem de estar numa arvore montada',
        );
        // O nó focado é o envoltório do painel do prompt: o título está dentro.
        expect(
          find.descendant(
            of: find.byWidget(foco.context!.widget),
            matching: find.text('Quantos?'),
          ),
          findsOneWidget,
          reason: 'o foco nao esta no painel do prompt; foco em '
              '${foco.debugLabel} (${foco.context!.widget.runtimeType})',
        );

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

Widget _assunto(InteractiveBattleGateway gateway) => MaterialApp(
  home: BattleCoachScreen(
    deckId: 'deck-1',
    sessionId: 'session-1',
    gateway: gateway,
  ),
);

class _GatewayComSegundoPrompt implements InteractiveBattleGateway {
  bool jaRespondeu = false;

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
  }) async => _sessao(promptId: 'p_um', opcaoId: 'o_um');

  @override
  Future<InteractiveBattleSession> get(String sessionId) async =>
      jaRespondeu
          ? _sessao(promptId: 'p_dois', opcaoId: 'o_dois')
          : _sessao(promptId: 'p_um', opcaoId: 'o_um');

  @override
  Future<InteractiveBattleSession> respond({
    required String sessionId,
    required InteractiveBattlePrompt prompt,
    required InteractiveBattleResponse response,
  }) async {
    jaRespondeu = true;
    // Um prompt DIFERENTE volta do motor: é a substituição assíncrona que o
    // checkpoint 18 do pacote de teclado prova.
    return _sessao(promptId: 'p_dois', opcaoId: 'o_dois');
  }

  @override
  Future<InteractiveBattleSession> concede(String sessionId) async =>
      _sessao(promptId: 'p_dois', opcaoId: 'o_dois');
}

InteractiveBattleSession _sessao({
  required String promptId,
  required String opcaoId,
}) => InteractiveBattleSession.fromJson({
  'schema_version': 'interactive_battle_session_v1',
  'session_id': 'session-1',
  'deck_id': 'deck-1',
  'status': 'waiting_for_input',
  'turn': 1,
  'phase': 'Início',
  'step': 'Manutenção',
  'active_player': 'Você',
  'priority_player': 'Você',
  'players': const <dynamic>[],
  'stack': const <dynamic>[],
  'hand': const <dynamic>[],
  'prompt': {
    'schema_version': 'interactive_battle_prompt_v1',
    'id': promptId,
    'state_version': promptId == 'p_um' ? 1 : 2,
    'kind': 'main_action',
    'input_mode': 'options',
    'title': 'Sua prioridade',
    'message': 'Escolha uma ação.',
    'deadline_at': '2099-07-27T15:01:00Z',
    'options': [
      {'id': opcaoId, 'label': 'Acao $opcaoId', 'role': 'action'},
    ],
  },
});

class _GatewayComPromptFixo implements InteractiveBattleGateway {
  _GatewayComPromptFixo(this.modo);

  final String modo;

  InteractiveBattleSession _fixa() => InteractiveBattleSession.fromJson({
    'schema_version': 'interactive_battle_session_v1',
    'session_id': 'session-1',
    'deck_id': 'deck-1',
    'status': 'waiting_for_input',
    'turn': 1,
    'phase': 'Início',
    'step': 'Manutenção',
    'active_player': 'Você',
    'priority_player': 'Você',
    'players': const <dynamic>[],
    'stack': const <dynamic>[],
    'hand': const <dynamic>[],
    'prompt': {
      'schema_version': 'interactive_battle_prompt_v1',
      'id': 'p_numerico',
      'state_version': 1,
      'kind': 'amount',
      'input_mode': modo,
      'title': 'Quantos?',
      'message': 'Informe a quantidade.',
      'deadline_at': '2099-07-27T15:01:00Z',
      'options': const <dynamic>[],
      'minimum': 0,
      'maximum': 3,
      'multi_amount_count': 2,
    },
  });

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
  }) async => _fixa();

  @override
  Future<InteractiveBattleSession> get(String sessionId) async => _fixa();

  @override
  Future<InteractiveBattleSession> respond({
    required String sessionId,
    required InteractiveBattlePrompt prompt,
    required InteractiveBattleResponse response,
  }) async => _fixa();

  @override
  Future<InteractiveBattleSession> concede(String sessionId) async => _fixa();
}
