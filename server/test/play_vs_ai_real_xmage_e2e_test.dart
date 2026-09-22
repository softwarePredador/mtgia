@Tags([
  'live',
  'live_backend',
  'live_db_write',
  'live_external',
  'play_vs_ai_real_xmage_e2e',
])
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

const _xmageVersion = '1.4.60';
const _xmageCommit = '2c43ec8cdb5cd475d47e6b555a4077151f476a3b';
const _xmagePatchCommit = '991948742f840cd88493a4ea8cb3f4ed192e4742';
const _engineBuild = 'xmage-sidecar-v2@$_xmageCommit+patch.$_xmagePatchCommit';
const _humanCommander = 'Isamaru, Hound of Konda';
const _aiCommander = 'Krenko, Mob Boss';
const _aiProfile = 'computer_mad';
const _approvalPhrase = 'I_HAVE_EXPLICIT_APPROVAL';
const _httpRequestTimeout = Duration(seconds: 45);
const _pollInterval = Duration(milliseconds: 250);

void main() {
  final databaseName = Platform.environment['DB_NAME'] ?? '';
  final enabled =
      Platform.environment['RUN_INTEGRATION_TESTS'] == '1' &&
      Platform.environment['MANALOOM_ISOLATED_CONTRACT_E2E'] == '1' &&
      Platform.environment['MANALOOM_PLAY_VS_AI_REAL_XMAGE_E2E'] == '1' &&
      Platform.environment['MANALOOM_CONFIRM_POSTGRES_WRITES'] ==
          _approvalPhrase &&
      Platform.environment['MANALOOM_CONFIRM_LIVE_MUTATIONS'] ==
          _approvalPhrase &&
      Platform.environment['DB_HOST'] == '127.0.0.1' &&
      RegExp(r'^manaloom_s1_api_[A-Za-z0-9_]+$').hasMatch(databaseName);
  final baseUrl = Platform.environment['TEST_API_BASE_URL'] ?? '';

  test(
    'player controls a real pinned XMage game through the durable API',
    () async {
      final apiUri = Uri.tryParse(baseUrl);
      expect(apiUri, isNotNull, reason: 'TEST_API_BASE_URL must be valid.');
      expect(apiUri!.scheme, 'http');
      expect(apiUri.host, '127.0.0.1');
      expect(apiUri.hasPort, isTrue);
      expect(Platform.environment['DB_HOST'], '127.0.0.1');
      expect(databaseName, startsWith('manaloom_s1_api_'));

      final suffix = '${DateTime.now().microsecondsSinceEpoch}_${pid}'
          .replaceAll('-', '');
      final password = 'PlayVsAiE2E!${suffix.substring(0, 12)}';
      final token = await _register(
        baseUrl,
        email: 'play-vs-ai-$suffix@example.invalid',
        username: 'play_vs_ai_$suffix',
        password: password,
      );
      final headers = <String, String>{
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      };

      final humanDeck = await _createDeck(
        baseUrl,
        headers,
        name: 'Play E2E Isamaru $suffix',
        commander: _humanCommander,
        basicLand: 'Plains',
      );
      final aiDeck = await _createDeck(
        baseUrl,
        headers,
        name: 'Play E2E Krenko $suffix',
        commander: _aiCommander,
        basicLand: 'Mountain',
      );

      final preflightResponse = await _get(
        Uri.parse(
          '$baseUrl/decks/${humanDeck.id}/battle-preflight'
          '?opponent_deck_id=${aiDeck.id}&mode=interactive',
        ),
        headers,
      );
      expect(preflightResponse.statusCode, 200, reason: preflightResponse.body);
      final preflight = _json(preflightResponse);
      expect(preflight['schema_version'], 'battle_preflight_v1');
      expect(preflight['mode'], 'interactive');
      expect(preflight['status'], 'ready');
      expect(preflight['read_only'], isTrue);
      expect(preflight['selected_engine'], 'xmage');
      expect(preflight['blockers'], isEmpty);
      expect(preflight['unsupported_cards'], isEmpty);
      expect(preflight['card_count'], 100);
      expect(preflight['commander_count'], 1);
      expect(preflight['validation_state'], 'validated');
      final opponent = _map(preflight['opponent']);
      expect(opponent['id'], aiDeck.id);
      expect(opponent['card_count'], 100);
      expect(opponent['commander_count'], 1);
      expect(opponent['validation_state'], 'validated');
      expect(_map(preflight['engine_coverage'])['xmage'], 'ready');
      expect(_map(preflight['engine_coverage'])['forge'], 'not_selected');
      expect(_map(preflight['engine_coverage'])['native'], 'not_selected');

      final createKey = 'play-create-$suffix';
      final createBody = <String, dynamic>{
        'schema_version': 'interactive_battle_request_v1',
        'deck_id': humanDeck.id,
        'opponent_deck_id': aiDeck.id,
        'ttl_seconds': 900,
        'prompt_timeout_seconds': 300,
      };
      final createdResponse = await _post(
        '$baseUrl/ai/battle/sessions',
        headers,
        createBody,
        idempotencyKey: createKey,
      );
      expect(createdResponse.statusCode, 201, reason: createdResponse.body);
      final createdPayload = _json(createdResponse);
      expect(createdPayload['created'], isTrue);
      final created = _map(createdPayload['session']);
      final sessionId = created['id'].toString();
      _expectRuntimeIdentity(created);

      final duplicateCreateResponse = await _post(
        '$baseUrl/ai/battle/sessions',
        headers,
        createBody,
        idempotencyKey: createKey,
      );
      expect(
        duplicateCreateResponse.statusCode,
        200,
        reason: duplicateCreateResponse.body,
      );
      final duplicateCreate = _json(duplicateCreateResponse);
      expect(duplicateCreate['created'], isFalse);
      expect(_map(duplicateCreate['session'])['id'], sessionId);

      final evidence = _LiveEvidence(
        humanDeckName: humanDeck.name,
        opponentDeckName: aiDeck.name,
      );
      var state = await _waitForPrompt(baseUrl, headers, sessionId);
      var actionSequence = 0;
      var firstActionProved = false;
      var mulliganSubmitted = false;
      var keepSubmitted = false;
      var castSubmitted = false;
      var landSubmitted = false;
      var lastAttackTurn = -1;
      String? idempotentActionKey;
      int? idempotentActionStateVersion;
      String? idempotentActionPromptId;
      final playedActions = <String>[];

      for (var step = 0; step < 260; step++) {
        _expectRuntimeIdentity(state);
        evidence.observe(state);
        if (evidence.hasPlayableCombatOutcome) break;
        if (state['terminal'] == true) {
          final privateState = _map(state['private_state']);
          fail(
            'XMage ended before the player-facing use case was proven: '
            '${jsonEncode(<String, dynamic>{'status': state['status'], 'terminal_reason': state['terminal_reason'], 'turn': privateState['turn'], 'step': privateState['step'], 'evidence': evidence.toJson(), 'played_actions': playedActions})}',
          );
        }

        final prompt = _map(state['prompt']);
        final kind = prompt['kind']?.toString() ?? '';
        final options = _maps(prompt['options']);
        final inputMode = prompt['input_mode']?.toString();
        final turn = _toInt(_map(state['private_state'])['turn']);
        Map<String, dynamic> answer;
        String actionLabel;

        if (kind == 'mulligan') {
          final role = mulliganSubmitted ? 'keep' : 'mulligan';
          final option = _optionByRole(options, role);
          answer = {'option_id': option['id']};
          actionLabel = role;
          if (role == 'mulligan') {
            mulliganSubmitted = true;
            evidence.mulliganPrompt = true;
          } else {
            keepSubmitted = true;
          }
        } else if (kind == 'target') {
          Map<String, dynamic>? option;
          if (!evidence.opponentPlayerTargetSelected) {
            option = _firstWhereOrNull(
              options,
              (candidate) => candidate['label']
                  .toString()
                  .toLowerCase()
                  .contains('adversário'),
            );
            if (option != null) {
              evidence.opponentPlayerTargetSelected = true;
            }
          }
          option ??= _firstWhereOrNull(
            options,
            (candidate) =>
                candidate['card'] is Map && candidate['role'] != 'cancel',
          );
          if (option != null &&
              mulliganSubmitted &&
              _mapOrEmpty(option['card']).isNotEmpty) {
            evidence.bottomCardTarget = true;
          }
          option ??= _firstWhereOrNull(
            options,
            (candidate) => candidate['role'] != 'cancel',
          );
          option ??= options.first;
          answer = {'option_id': option['id']};
          actionLabel = 'target:${option['label']}';
        } else if (kind == 'main_action') {
          Map<String, dynamic>? option;
          if (!landSubmitted && !evidence.plainsOnBattlefield) {
            option = _cardOption(options, 'Plains');
            if (option != null) landSubmitted = true;
          }
          if (option == null &&
              !castSubmitted &&
              !evidence.isamaruOnBattlefield) {
            option = _cardOption(options, _humanCommander);
            if (option != null) {
              castSubmitted = true;
              evidence.isamaruCastOption = true;
            }
          }
          if (option == null) {
            answer = {'delegate': true};
            actionLabel = 'pass_priority';
          } else {
            answer = {'option_id': option['id']};
            actionLabel = 'main:${option['label']}';
          }
        } else if (kind == 'mana') {
          evidence.manaPrompt = true;
          final option =
              _firstWhereOrNull(
                options,
                (candidate) => candidate['role'] == 'choice',
              ) ??
              options.first;
          answer = {'option_id': option['id']};
          actionLabel = 'mana:${option['label']}';
        } else if (kind == 'combat') {
          Map<String, dynamic>? option;
          if (turn != lastAttackTurn) {
            option = _cardOption(options, _humanCommander);
            if (option != null) {
              lastAttackTurn = turn;
              evidence.isamaruAttackChosen = true;
            }
          }
          option ??= _firstWhereOrNull(
            options,
            (candidate) => candidate['label'].toString().toLowerCase().contains(
              'adversário',
            ),
          );
          if (option == null) {
            answer = {'delegate': true};
            actionLabel = 'combat_done';
          } else {
            answer = {'option_id': option['id']};
            actionLabel = 'combat:${option['label']}';
          }
        } else if (inputMode == 'integer' || inputMode == 'multi_amount') {
          answer = {'delegate': true};
          actionLabel = '$kind:safe_minimum';
        } else {
          final option = _firstWhereOrNull(
            options,
            (candidate) => candidate['role'] == 'choice',
          );
          if (option == null) {
            answer = {'delegate': true};
            actionLabel = '$kind:delegate';
          } else {
            answer = {'option_id': option['id']};
            actionLabel = '$kind:${option['label']}';
          }
        }

        actionSequence += 1;
        final key = 'play-action-$actionSequence-$suffix';
        final actionBody = <String, dynamic>{
          'schema_version': 'interactive_battle_action_v1',
          'state_version': prompt['state_version'],
          'prompt_id': prompt['id'],
          ...answer,
        };
        final actionResponse = await _post(
          '$baseUrl/ai/battle/sessions/$sessionId/actions',
          headers,
          actionBody,
          idempotencyKey: key,
        );
        expect(actionResponse.statusCode, 200, reason: actionResponse.body);
        playedActions.add(actionLabel);

        if (!firstActionProved) {
          final retry = await _post(
            '$baseUrl/ai/battle/sessions/$sessionId/actions',
            headers,
            actionBody,
            idempotencyKey: key,
          );
          expect(retry.statusCode, 200, reason: retry.body);
          final acceptedSession = _map(_json(actionResponse)['session']);
          final retriedSession = _map(_json(retry)['session']);
          _expectRuntimeIdentity(acceptedSession);
          _expectRuntimeIdentity(retriedSession);
          _expectStableSessionIdentity(
            acceptedSession,
            retriedSession,
            sessionId: sessionId,
            deckId: humanDeck.id,
            opponentDeckId: aiDeck.id,
          );
          final submittedStateVersion = _toInt(actionBody['state_version']);
          final acceptedStateVersion = _toInt(acceptedSession['state_version']);
          final retriedStateVersion = _toInt(retriedSession['state_version']);
          expect(
            acceptedStateVersion,
            greaterThanOrEqualTo(submittedStateVersion),
          );
          expect(
            retriedStateVersion,
            greaterThanOrEqualTo(acceptedStateVersion),
          );
          // XMage may advance asynchronously between the accepted response and
          // the retry. Idempotency is therefore bound to durable identities,
          // the monotonic version and the single PostgreSQL action below, not
          // to byte-for-byte equality of the two JSON session snapshots.
          idempotentActionKey = key;
          idempotentActionStateVersion = submittedStateVersion;
          idempotentActionPromptId = actionBody['prompt_id'].toString();
          final stale = await _post(
            '$baseUrl/ai/battle/sessions/$sessionId/actions',
            headers,
            actionBody,
            idempotencyKey: 'play-stale-$suffix',
          );
          // Reenvio da MESMA acao com chave de idempotencia nova, depois que
          // a primeira ja foi aceita. O servidor rejeita com 409, mas o codigo
          // depende de onde a sessao esta quando a segunda chamada chega, e os
          // dois codigos abaixo sao rejeicoes legitimas do mesmo replay:
          //
          //   interactive_battle_not_waiting  — a primeira acao ja rodou o
          //     UPDATE que poe status='action_pending' e active_prompt_id=NULL
          //     (interactive_battle_store.dart:600-626), entao a terceira
          //     checagem de reserveAction dispara antes do UPDATE condicional.
          //     E o caminho normal num teste sequencial com await.
          //   interactive_battle_action_stale — so se o XMage ja tiver
          //     produzido o PROXIMO prompt e devolvido a sessao para
          //     waiting_for_action: ai a checagem de status passa e quem falha
          //     e o UPDATE, por state_version/prompt_id velhos.
          //
          // Medido duas vezes nesta maquina: not_waiting nas duas, aos 3s. A
          // asserção original cobrava action_stale exato e nunca passou — o
          // teste nasceu em f6f791098 e as seis variaveis de ambiente que o
          // habilitam impediram que alguem descobrisse.
          expect(stale.statusCode, 409, reason: stale.body);
          expect(
            _json(stale)['error'],
            anyOf(
              'interactive_battle_not_waiting',
              'interactive_battle_action_stale',
            ),
            reason: stale.body,
          );
          firstActionProved = true;
        }

        state = await _waitForPrompt(baseUrl, headers, sessionId);
      }

      expect(mulliganSubmitted, isTrue);
      expect(keepSubmitted, isTrue);
      expect(evidence.bottomCardTarget, isTrue);
      expect(evidence.privateHandVisible, isTrue);
      expect(evidence.opponentHandProtected, isTrue);
      expect(evidence.opponentMountainOnBattlefield, isTrue);
      expect(evidence.plainsOnBattlefield, isTrue);
      expect(evidence.isamaruCastOption, isTrue);
      expect(evidence.manaPrompt, isTrue);
      expect(evidence.tappedPlains, isTrue);
      expect(evidence.isamaruStackOrBattlefield, isTrue);
      expect(evidence.isamaruOnBattlefield, isTrue);
      expect(evidence.isamaruAttackChosen, isTrue);
      expect(evidence.opponentLifeBelowForty, isTrue);
      expect(playedActions, contains('pass_priority'));

      final reconnect = await _getSession(baseUrl, headers, sessionId);
      _expectRuntimeIdentity(reconnect);
      expect(reconnect['id'], sessionId);
      expect(
        _toInt(reconnect['state_version']),
        greaterThanOrEqualTo(_toInt(state['state_version'])),
      );

      final concedeKey = 'play-concede-$suffix';
      final concedeResponse = await _post(
        '$baseUrl/ai/battle/sessions/$sessionId/concede',
        headers,
        const <String, dynamic>{},
        idempotencyKey: concedeKey,
      );
      expect(concedeResponse.statusCode, 200, reason: concedeResponse.body);
      var terminal = _map(_json(concedeResponse)['session']);
      if (terminal['terminal'] != true) {
        terminal = await _waitForTerminal(baseUrl, headers, sessionId);
      }
      final replayId = _expectConcededTerminal(terminal, sessionId: sessionId);

      final duplicateConcede = await _post(
        '$baseUrl/ai/battle/sessions/$sessionId/concede',
        headers,
        const <String, dynamic>{},
        idempotencyKey: concedeKey,
      );
      expect(duplicateConcede.statusCode, 200, reason: duplicateConcede.body);
      final duplicateTerminal = _map(_json(duplicateConcede)['session']);
      expect(
        _expectConcededTerminal(duplicateTerminal, sessionId: sessionId),
        replayId,
      );

      final rematchCreate = await _post(
        '$baseUrl/ai/battle/sessions',
        headers,
        createBody,
        idempotencyKey: 'play-rematch-$suffix',
      );
      expect(rematchCreate.statusCode, 201, reason: rematchCreate.body);
      final rematch = _map(_json(rematchCreate)['session']);
      final rematchId = rematch['id'].toString();
      expect(rematchId, isNot(sessionId));
      await _waitForPrompt(baseUrl, headers, rematchId);
      final rematchConcede = await _post(
        '$baseUrl/ai/battle/sessions/$rematchId/concede',
        headers,
        const <String, dynamic>{},
        idempotencyKey: 'play-rematch-concede-$suffix',
      );
      expect(rematchConcede.statusCode, 200, reason: rematchConcede.body);
      var rematchTerminal = _map(_json(rematchConcede)['session']);
      if (rematchTerminal['terminal'] != true) {
        rematchTerminal = await _waitForTerminal(baseUrl, headers, rematchId);
      }
      final rematchReplayId = _expectConcededTerminal(
        rematchTerminal,
        sessionId: rematchId,
      );
      expect(rematchReplayId, isNot(replayId));

      final listResponse = await _get(
        Uri.parse('$baseUrl/ai/battle/sessions?limit=10'),
        headers,
      );
      expect(listResponse.statusCode, 200, reason: listResponse.body);
      final listedIds =
          _maps(
            _json(listResponse)['sessions'],
          ).map((session) => session['id']).toSet();
      expect(listedIds, containsAll(<String>{sessionId, rematchId}));

      final replayListResponse = await _get(
        Uri.parse('$baseUrl/decks/${humanDeck.id}/battle-replays?limit=10'),
        headers,
      );
      expect(
        replayListResponse.statusCode,
        200,
        reason: replayListResponse.body,
      );
      final replayList = _json(replayListResponse);
      final replaySummaries = _maps(replayList['data']);
      final replaySummary = replaySummaries.firstWhere(
        (candidate) => candidate['id'] == replayId,
      );
      expect(replaySummary['simulation_type'], 'interactive_coach');
      expect(replaySummary['engine'], 'xmage');
      expect(replaySummary['engine_version'], _xmageVersion);
      expect(replaySummary['engine_commit'], _xmageCommit);
      expect(replaySummary['engine_build'], _engineBuild);
      expect(replaySummary['outcome'], 'cancelled');
      expect(
        RegExp(
          r'^[0-9a-f]{64}$',
        ).hasMatch(replaySummary['request_hash'].toString()),
        isTrue,
      );

      final replayResponse = await _get(
        Uri.parse('$baseUrl/decks/${humanDeck.id}/battle-replays/$replayId'),
        headers,
      );
      expect(replayResponse.statusCode, 200, reason: replayResponse.body);
      final replay = _map(_json(replayResponse)['replay']);
      expect(replay['engine'], 'xmage');
      expect(replay['engine_version'], _xmageVersion);
      expect(replay['engine_commit'], _xmageCommit);
      expect(replay['engine_patch_commit'], _xmagePatchCommit);
      expect(replay['engine_build'], _engineBuild);
      expect(replay['ai_profile'], _aiProfile);
      expect(replay['request_hash'], replaySummary['request_hash']);
      final simulationContract = _map(replay['simulation_contract']);
      expect(simulationContract['rules_execution'], isTrue);
      expect(simulationContract['canonical_rules_execution'], isTrue);
      expect(simulationContract['advisory_only'], isFalse);
      expect(simulationContract['rules_engine_priority'], 'primary');
      final security = _map(replay['replay_security']);
      expect(security['hidden_zone_policy'], 'counts_only');
      final leakedPrivatePaths = _privateReplayKeyPaths(replay);
      expect(
        leakedPrivatePaths,
        isEmpty,
        reason:
            'Replay exposed private hand/private-state keys at '
            '${leakedPrivatePaths.join(', ')}.',
      );
      final serializedReplay = jsonEncode(replay).toLowerCase();
      expect(serializedReplay, isNot(contains(password.toLowerCase())));

      final events = _maps(replay['events']);
      expect(
        events.any(
          (event) =>
              event['action'] == 'stack_entry' &&
              event['card_name'] == _humanCommander,
        ),
        isTrue,
      );
      expect(
        events.any(
          (event) =>
              event['action'] == 'battlefield_entry' &&
              event['card_name'] == _humanCommander,
        ),
        isTrue,
      );
      expect(
        events.any(
          (event) =>
              event['action'] == 'tap_change' &&
              event['card_name'] == 'Plains' &&
              event['to'] == true,
        ),
        isTrue,
      );
      expect(
        events.any(
          (event) =>
              event['action'] == 'attacker_declared' &&
              event['card_name'] == _humanCommander,
        ),
        isTrue,
      );
      expect(events.any((event) => event['action'] == 'life_change'), isTrue);
      expect(_maps(replay['visual_snapshots']), isNotEmpty);
      final decisions = _maps(replay['decision_trace']);
      expect(decisions, isNotEmpty);
      expect(
        decisions.every(
          (decision) =>
              decision['decision_origin'] == 'human_user' &&
              decision['rules_engine_explanation'] == false,
        ),
        isTrue,
      );
      final decisionKinds =
          decisions.map((decision) => decision['decision_type']).toSet();
      expect(decisionKinds, containsAll(['mulligan', 'main_action', 'mana']));

      final dbEvidence = await _verifyDatabase(
        sessionId: sessionId,
        rematchId: rematchId,
        replayId: replayId,
        rematchReplayId: rematchReplayId,
        idempotentActionKey: idempotentActionKey!,
        idempotentActionStateVersion: idempotentActionStateVersion!,
        idempotentActionPromptId: idempotentActionPromptId!,
      );
      expect(dbEvidence['session_status'], 'conceded');
      expect(dbEvidence['attempt_outcome'], 'cancelled');
      expect(dbEvidence['active_sessions'], 0);
      expect(dbEvidence['idempotent_action_submission_count'], 1);

      // Machine-readable and secret-free evidence is copied into the durable
      // runner report. It is intentionally a lower bound, not strategy proof.
      final machineEvidence = <String, dynamic>{
        'schema_version': 'play_vs_ai_e2e_evidence_v1',
        'session_id': sessionId,
        'rematch_id': rematchId,
        'replay_id': replayId,
        'rematch_replay_id': rematchReplayId,
        'engine_version': _xmageVersion,
        'engine_commit': _xmageCommit,
        'engine_patch_commit': _xmagePatchCommit,
        'engine_build': _engineBuild,
        'ai_profile': _aiProfile,
        'actions_submitted': actionSequence,
        'mulligan': mulliganSubmitted,
        'private_hand_visible': evidence.privateHandVisible,
        'opponent_hand_protected': evidence.opponentHandProtected,
        'ai_land_played': evidence.opponentMountainOnBattlefield,
        'card_first_options': true,
        'land_played': evidence.plainsOnBattlefield,
        'mana_prompt': evidence.manaPrompt,
        'mana_source_tapped': evidence.tappedPlains,
        'commander_cast': evidence.isamaruOnBattlefield,
        'pass_priority': playedActions.contains('pass_priority'),
        'combat_damage': evidence.opponentLifeBelowForty,
        'canonical_replay': simulationContract['canonical_rules_execution'],
        'idempotent_action_submission_count':
            dbEvidence['idempotent_action_submission_count'],
        'database_records': dbEvidence['record_count'],
        'played_action_labels': playedActions,
      };
      print('PLAY_VS_AI_E2E_EVIDENCE=${jsonEncode(machineEvidence)}');
    },
    skip:
        enabled ? null : 'Run only through scripts/manaloom_play_vs_ai_e2e.sh.',
    timeout: const Timeout(Duration(minutes: 8)),
  );
}

class _DeckReceipt {
  const _DeckReceipt(this.id, this.name);

  final String id;
  final String name;
}

class _LiveEvidence {
  _LiveEvidence({required this.humanDeckName, required this.opponentDeckName});

  final String humanDeckName;
  final String opponentDeckName;
  bool opponentPlayerTargetSelected = false;
  bool mulliganPrompt = false;
  bool bottomCardTarget = false;
  bool privateHandVisible = false;
  bool opponentHandProtected = false;
  bool opponentMountainOnBattlefield = false;
  bool plainsOnBattlefield = false;
  bool tappedPlains = false;
  bool isamaruCastOption = false;
  bool manaPrompt = false;
  bool isamaruOnStack = false;
  bool isamaruOnBattlefield = false;
  bool isamaruAttackChosen = false;
  bool opponentLifeBelowForty = false;

  bool get isamaruStackOrBattlefield => isamaruOnStack || isamaruOnBattlefield;

  bool get hasPlayableCombatOutcome =>
      plainsOnBattlefield &&
      tappedPlains &&
      manaPrompt &&
      opponentMountainOnBattlefield &&
      isamaruOnBattlefield &&
      isamaruAttackChosen &&
      opponentLifeBelowForty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'opponent_player_target_selected': opponentPlayerTargetSelected,
    'mulligan_prompt': mulliganPrompt,
    'bottom_card_target': bottomCardTarget,
    'private_hand_visible': privateHandVisible,
    'opponent_hand_protected': opponentHandProtected,
    'opponent_mountain_on_battlefield': opponentMountainOnBattlefield,
    'plains_on_battlefield': plainsOnBattlefield,
    'tapped_plains': tappedPlains,
    'isamaru_cast_option': isamaruCastOption,
    'mana_prompt': manaPrompt,
    'isamaru_on_stack': isamaruOnStack,
    'isamaru_on_battlefield': isamaruOnBattlefield,
    'isamaru_attack_chosen': isamaruAttackChosen,
    'opponent_life_below_forty': opponentLifeBelowForty,
  };

  void observe(Map<String, dynamic> session) {
    final state = _map(session['private_state']);
    final hand = _maps(state['own_hand']);
    if (hand.isNotEmpty &&
        hand.every((card) => card['name']?.toString().isNotEmpty == true)) {
      privateHandVisible = true;
    }
    for (final player in _maps(state['players'])) {
      expect(player, isNot(contains('hand')));
      expect(player, isNot(contains('hand_cards')));
      expect(player, isNot(contains('private_hand')));
      expect(player, isNot(contains('own_hand')));
      final name = player['name']?.toString();
      final battlefield = _maps(player['battlefield']);
      if (name == humanDeckName) {
        plainsOnBattlefield |= battlefield.any(
          (card) => card['name'] == 'Plains',
        );
        tappedPlains |= battlefield.any(
          (card) => card['name'] == 'Plains' && card['tapped'] == true,
        );
        isamaruOnBattlefield |= battlefield.any(
          (card) => card['name'] == _humanCommander,
        );
      }
      if (name == opponentDeckName) {
        opponentHandProtected =
            player['hand_count'] is int && player['hand_size'] is int;
        opponentMountainOnBattlefield |= battlefield.any(
          (card) => card['name'] == 'Mountain',
        );
        final life = _toInt(player['life']);
        if (life < 40) opponentLifeBelowForty = true;
      }
    }
    isamaruOnStack |= _maps(state['stack']).any(
      (card) =>
          card['name'] == _humanCommander ||
          card['source_card_name'] == _humanCommander,
    );
    for (final group in _maps(state['combat'])) {
      if (_maps(
        group['attackers'],
      ).any((card) => card['name'] == _humanCommander)) {
        isamaruAttackChosen = true;
      }
    }
  }
}

Future<String> _register(
  String baseUrl, {
  required String email,
  required String username,
  required String password,
}) async {
  final register = await _postJson(
    Uri.parse('$baseUrl/auth/register'),
    const {'content-type': 'application/json'},
    {'email': email, 'username': username, 'password': password},
  );
  expect(register.statusCode, anyOf(200, 201), reason: register.body);
  final login = await _postJson(
    Uri.parse('$baseUrl/auth/login'),
    const {'content-type': 'application/json'},
    {'email': email, 'password': password},
  );
  expect(login.statusCode, 200, reason: login.body);
  return _json(login)['token'].toString();
}

Future<_DeckReceipt> _createDeck(
  String baseUrl,
  Map<String, String> headers, {
  required String name,
  required String commander,
  required String basicLand,
}) async {
  final response = await _postJson(Uri.parse('$baseUrl/decks'), headers, {
    'name': name,
    'format': 'commander',
    'is_public': false,
    'cards': [
      {'name': commander, 'quantity': 1, 'is_commander': true},
      {'name': basicLand, 'quantity': 99, 'is_commander': false},
    ],
  });
  expect(response.statusCode, anyOf(200, 201), reason: response.body);
  final payload = _json(response);
  expect(payload['deck_state'], 'validated', reason: response.body);
  expect(payload['requires_review'], isFalse, reason: response.body);
  expect(payload['review_reasons'], isEmpty, reason: response.body);
  expect(
    _map(payload['e2e_validation'])['product_learning_writes_suppressed'],
    isTrue,
  );
  return _DeckReceipt(payload['id'].toString(), name);
}

Future<http.Response> _post(
  String url,
  Map<String, String> headers,
  Map<String, dynamic> body, {
  required String idempotencyKey,
}) => _postJson(Uri.parse(url), {
  ...headers,
  'Idempotency-Key': idempotencyKey,
}, body);

Future<http.Response> _postJson(
  Uri uri,
  Map<String, String> headers,
  Map<String, dynamic> body,
) => http
    .post(uri, headers: headers, body: jsonEncode(body))
    .timeout(_httpRequestTimeout);

Future<http.Response> _get(Uri uri, Map<String, String> headers) =>
    http.get(uri, headers: headers).timeout(_httpRequestTimeout);

Future<Map<String, dynamic>> _getSession(
  String baseUrl,
  Map<String, String> headers,
  String sessionId,
) async {
  final response = await _get(
    Uri.parse('$baseUrl/ai/battle/sessions/$sessionId'),
    headers,
  );
  expect(response.statusCode, 200, reason: response.body);
  return _json(response);
}

Future<Map<String, dynamic>> _waitForPrompt(
  String baseUrl,
  Map<String, String> headers,
  String sessionId,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  Map<String, dynamic>? last;
  while (DateTime.now().isBefore(deadline)) {
    last = await _getSession(baseUrl, headers, sessionId);
    if (last['terminal'] == true) return last;
    if (last['status'] == 'waiting_for_action' && last['prompt'] is Map) {
      return last;
    }
    await Future<void>.delayed(_pollInterval);
  }
  fail('Timed out waiting for a real XMage prompt: ${jsonEncode(last)}');
}

Future<Map<String, dynamic>> _waitForTerminal(
  String baseUrl,
  Map<String, String> headers,
  String sessionId,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  Map<String, dynamic>? last;
  while (DateTime.now().isBefore(deadline)) {
    last = await _getSession(baseUrl, headers, sessionId);
    if (last['terminal'] == true) return last;
    await Future<void>.delayed(_pollInterval);
  }
  fail('Timed out waiting for terminal XMage state: ${jsonEncode(last)}');
}

Future<Map<String, dynamic>> _verifyDatabase({
  required String sessionId,
  required String rematchId,
  required String replayId,
  required String rematchReplayId,
  required String idempotentActionKey,
  required int idempotentActionStateVersion,
  required String idempotentActionPromptId,
}) async {
  final pool = Pool.withEndpoints([
    Endpoint(
      host: Platform.environment['DB_HOST']!,
      port: int.parse(Platform.environment['DB_PORT']!),
      database: Platform.environment['DB_NAME']!,
      username: Platform.environment['DB_USER']!,
      password: Platform.environment['DB_PASS'] ?? '',
    ),
  ], settings: const PoolSettings(sslMode: SslMode.disable));
  try {
    final joined = await pool.execute(
      Sql.named('''
        SELECT
          s.status,
          s.terminal_reason,
          s.replay_id::text,
          s.engine_version AS session_engine_version,
          s.engine_commit AS session_engine_commit,
          s.engine_build AS session_engine_build,
          s.request_payload->>'expected_engine_patch_commit'
            AS expected_engine_patch_commit,
          s.request_payload->>'ai_profile' AS ai_profile,
          s.request_hash AS session_request_hash,
          a.outcome,
          a.engine,
          a.engine_version AS attempt_engine_version,
          a.engine_commit AS attempt_engine_commit,
          a.engine_build AS attempt_engine_build,
          a.request_hash AS attempt_request_hash,
          bs.simulation_type
        FROM interactive_battle_sessions s
        JOIN battle_simulation_attempts a ON a.id = s.attempt_id
        JOIN battle_simulations bs ON bs.id = s.replay_id
        WHERE s.id = CAST(@session_id AS uuid)
      '''),
      parameters: {'session_id': sessionId},
    );
    expect(joined, hasLength(1));
    final row = joined.single.toColumnMap();
    expect(row['status'], 'conceded');
    expect(row['terminal_reason'], 'user_conceded');
    expect(row['replay_id'].toString(), replayId);
    expect(row['session_engine_version'], _xmageVersion);
    expect(row['session_engine_commit'], _xmageCommit);
    expect(row['session_engine_build'], _engineBuild);
    expect(row['attempt_engine_version'], _xmageVersion);
    expect(row['attempt_engine_commit'], _xmageCommit);
    expect(row['attempt_engine_build'], _engineBuild);
    expect(row['expected_engine_patch_commit'], _xmagePatchCommit);
    expect(row['ai_profile'], _aiProfile);
    expect(row['outcome'], 'cancelled');
    expect(row['engine'], 'xmage');
    expect(row['simulation_type'], 'interactive_coach');
    expect(row['session_request_hash'], row['attempt_request_hash']);

    final idempotentSubmissions = await pool.execute(
      Sql.named('''
        SELECT
          state_version,
          prompt_id,
          request_fingerprint
        FROM interactive_battle_records
        WHERE session_id = CAST(@session_id AS uuid)
          AND record_kind = 'action_submitted'
          AND idempotency_key = @idempotency_key
      '''),
      parameters: {
        'session_id': sessionId,
        'idempotency_key': idempotentActionKey,
      },
    );
    expect(idempotentSubmissions, hasLength(1));
    final submittedAction = idempotentSubmissions.single;
    expect(submittedAction[0], idempotentActionStateVersion);
    expect(submittedAction[1]?.toString(), idempotentActionPromptId);
    expect(
      RegExp(r'^[0-9a-f]{64}$').hasMatch(submittedAction[2].toString()),
      isTrue,
    );

    final idempotentAcceptances = await pool.execute(
      Sql.named('''
        SELECT state_version
        FROM interactive_battle_records
        WHERE session_id = CAST(@session_id AS uuid)
          AND record_kind = 'action_accepted'
          AND payload->>'action_id' = @idempotency_key
        ORDER BY sequence
      '''),
      parameters: {
        'session_id': sessionId,
        'idempotency_key': idempotentActionKey,
      },
    );
    expect(idempotentAcceptances, isNotEmpty);
    final acceptedStateVersions = [
      for (final acceptance in idempotentAcceptances)
        acceptance[0] as int? ?? -1,
    ];
    expect(
      acceptedStateVersions,
      orderedEquals([...acceptedStateVersions]..sort()),
    );
    expect(
      acceptedStateVersions,
      everyElement(greaterThanOrEqualTo(idempotentActionStateVersion)),
    );

    final records = await pool.execute(
      Sql.named('''
        SELECT record_kind, COUNT(*)::int AS count
        FROM interactive_battle_records
        WHERE session_id = CAST(@session_id AS uuid)
        GROUP BY record_kind
      '''),
      parameters: {'session_id': sessionId},
    );
    final counts = <String, int>{
      for (final record in records)
        record[0].toString(): (record[1] as int? ?? 0),
    };
    for (final kind in const [
      'prompt_opened',
      'private_state',
      'action_submitted',
      'action_accepted',
      'terminal',
    ]) {
      expect(counts[kind] ?? 0, greaterThan(0), reason: kind);
    }

    final active = await pool.execute(
      Sql.named('''
        SELECT COUNT(*)::int
        FROM interactive_battle_sessions
        WHERE id IN (CAST(@session_id AS uuid), CAST(@rematch_id AS uuid))
          AND status IN ('starting', 'running', 'waiting_for_action', 'action_pending')
      '''),
      parameters: {'session_id': sessionId, 'rematch_id': rematchId},
    );
    final rematchTerminal = await pool.execute(
      Sql.named('''
        SELECT status, terminal_reason, replay_id::text
        FROM interactive_battle_sessions
        WHERE id = CAST(@rematch_id AS uuid)
      '''),
      parameters: {'rematch_id': rematchId},
    );
    expect(rematchTerminal, hasLength(1));
    expect(rematchTerminal.single[0], 'conceded');
    expect(rematchTerminal.single[1], 'user_conceded');
    expect(rematchTerminal.single[2]?.toString(), rematchReplayId);
    return {
      'session_status': row['status'],
      'attempt_outcome': row['outcome'],
      'record_count': counts.values.fold<int>(0, (sum, count) => sum + count),
      'active_sessions': active.single[0] as int? ?? -1,
      'idempotent_action_submission_count': idempotentSubmissions.length,
    };
  } finally {
    await pool.close();
  }
}

void _expectRuntimeIdentity(Map<String, dynamic> session) {
  expect(session['schema_version'], 'interactive_battle_session_v1');
  expect(session['engine'], 'xmage');
  expect(session['engine_version'], _xmageVersion);
  expect(session['engine_commit'], _xmageCommit);
  expect(session['engine_build'], _engineBuild);
  expect(
    _map(session['deck_hashes'])['schema_version'],
    'external_battle_deck_hash_v1',
  );
}

void _expectStableSessionIdentity(
  Map<String, dynamic> accepted,
  Map<String, dynamic> retried, {
  required String sessionId,
  required String deckId,
  required String opponentDeckId,
}) {
  for (final snapshot in [accepted, retried]) {
    expect(snapshot['id'], sessionId);
    expect(snapshot['deck_id'], deckId);
    expect(snapshot['opponent_deck_id'], opponentDeckId);
    expect(snapshot['attempt_id']?.toString(), matches(_uuidPattern));
    final hashes = _map(snapshot['deck_hashes']);
    expect(hashes['deck_a']?.toString(), matches(_sha256Pattern));
    expect(hashes['deck_b']?.toString(), matches(_sha256Pattern));
  }
  expect(retried['attempt_id'], accepted['attempt_id']);
  expect(retried['deck_hashes'], accepted['deck_hashes']);
  expect(retried['ttl_seconds'], accepted['ttl_seconds']);
  expect(retried['expires_at'], accepted['expires_at']);
  expect(retried['created_at'], accepted['created_at']);
}

String _expectConcededTerminal(
  Map<String, dynamic> session, {
  required String sessionId,
}) {
  _expectRuntimeIdentity(session);
  expect(session['id'], sessionId);
  expect(session['terminal'], isTrue);
  expect(session['status'], 'conceded');
  expect(session['terminal_reason'], 'user_conceded');
  final replayId = session['replay_id']?.toString() ?? '';
  expect(replayId, matches(_uuidPattern));
  return replayId;
}

List<String> _privateReplayKeyPaths(Object? value, [String path = r'$']) {
  final paths = <String>[];
  if (value is Map) {
    for (final entry in value.entries) {
      final key = entry.key.toString();
      final normalized = key.trim().toLowerCase().replaceAll(
        RegExp(r'[-\s]+'),
        '_',
      );
      final childPath = '$path.$key';
      if (_privateReplayKeys.contains(normalized)) paths.add(childPath);
      paths.addAll(_privateReplayKeyPaths(entry.value, childPath));
    }
  } else if (value is List) {
    for (var index = 0; index < value.length; index++) {
      paths.addAll(_privateReplayKeyPaths(value[index], '$path[$index]'));
    }
  }
  return paths;
}

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);
final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
const _privateReplayKeys = <String>{
  'hand',
  'hand_cards',
  'handcards',
  'own_hand',
  'private_hand',
  'private_state',
};

Map<String, dynamic> _optionByRole(
  List<Map<String, dynamic>> options,
  String role,
) => options.firstWhere(
  (option) => option['role'] == role,
  orElse: () => throw StateError('Prompt does not expose role $role.'),
);

Map<String, dynamic>? _cardOption(
  List<Map<String, dynamic>> options,
  String name,
) => _firstWhereOrNull(options, (option) {
  final card = _mapOrEmpty(option['card']);
  return card['name'] == name;
});

T? _firstWhereOrNull<T>(Iterable<T> values, bool Function(T value) predicate) {
  for (final value in values) {
    if (predicate(value)) return value;
  }
  return null;
}

Map<String, dynamic> _json(http.Response response) =>
    _map(jsonDecode(response.body));

Map<String, dynamic> _map(Object? value) {
  if (value is! Map) throw StateError('Expected object, got $value.');
  return value.map((key, entry) => MapEntry(key.toString(), entry));
}

Map<String, dynamic> _mapOrEmpty(Object? value) =>
    value is Map
        ? value.map((key, entry) => MapEntry(key.toString(), entry))
        : <String, dynamic>{};

List<Map<String, dynamic>> _maps(Object? value) =>
    value is List ? value.whereType<Map>().map(_map).toList() : const [];

int _toInt(Object? value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
