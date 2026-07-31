import '../edh_bracket_policy.dart';

const aiGenerateCommanderBracketContractVersion =
    'ai_generate_commander_bracket_v1';

class AiGenerateCommanderBracketEvaluation {
  const AiGenerateCommanderBracketEvaluation({
    required this.applicable,
    required this.hardCompliant,
    required this.requestedBracket,
    this.assessment,
    this.failureReason,
  });

  final bool applicable;
  final bool hardCompliant;
  final int? requestedBracket;
  final BracketDeckAssessment? assessment;
  final String? failureReason;

  Map<String, dynamic> toJson() {
    final policy = assessment?.toJson();
    return {
      'contract_version': aiGenerateCommanderBracketContractVersion,
      'policy_version': commanderBracketPolicyVersion,
      'source': 'official_wizards_commander_brackets',
      'enforcement': 'fail_closed_on_game_changer_cap',
      'applicable': applicable,
      'requested_bracket': requestedBracket,
      'hard_compliant': hardCompliant,
      if (failureReason != null) 'failure_reason': failureReason,
      if (policy != null) ...policy,
      if (applicable && requestedBracket != null)
        'numeric_game_changer_cap_applies': requestedBracket! <= 3,
      if (applicable && requestedBracket != null && requestedBracket! >= 4)
        'game_changer_cap': null,
    };
  }
}

bool isAiGenerateCommanderFormat(String format) {
  final normalized = format.trim().toLowerCase();
  return normalized == 'commander' || normalized == 'edh';
}

String buildAiGenerateCommanderBracketPrompt({
  required String format,
  required int? requestedBracket,
}) {
  if (!isAiGenerateCommanderFormat(format) || requestedBracket == null) {
    return '';
  }

  final profile = commanderBracketIntentProfile(requestedBracket);
  final turnGuidance =
      profile.minimumTurnsPlayed == null
          ? 'No minimum-turn expectation; build for the current cEDH metagame.'
          : 'Intended decisive turn: turn ${profile.minimumTurnsPlayed} or '
              'later (advisory).';
  final intent = switch (profile.bracket) {
    1 =>
      'Favor theme, spectacle, and deliberately suboptimal wins over raw power.',
    2 =>
      'Build a straightforward, non-optimized deck with incremental, '
          'telegraphed, and interruptible wins.',
    3 =>
      'Use strong synergy and card quality, with major turns earned through '
          'accumulated resources.',
    4 =>
      'Build for speed, consistency, and lethality without assuming the cEDH '
          'metagame.',
    _ => 'Build for the cEDH metagame and maximize the probability of winning.',
  };
  final gameChangerRule =
      profile.bracket >= 4
          ? 'No numeric Game Changer cap applies at B${profile.bracket} '
              '(sem limite numérico).'
          : 'Hard cap: at most ${profile.gameChangerCap} cards from the '
              'official Commander Game Changers list across the commander '
              'slot and main deck. Exceeding this cap makes the generated '
              'deck invalid.';

  return '''
Commander Bracket intent (mandatory):
- Requested bracket: B${profile.bracket} — ${profile.label}.
- Intent: $intent
- $turnGuidance
- $gameChangerRule
- Other power signals (tutors, fast mana, free interaction, combos, stax, and extra turns) are advisory intent signals, not separate hard bans.
''';
}

AiGenerateCommanderBracketEvaluation evaluateAiGenerateCommanderBracket({
  required String format,
  required int? requestedBracket,
  required Map<String, dynamic>? generatedDeck,
}) {
  if (!isAiGenerateCommanderFormat(format) || requestedBracket == null) {
    return AiGenerateCommanderBracketEvaluation(
      applicable: false,
      hardCompliant: true,
      requestedBracket: requestedBracket,
    );
  }

  if (generatedDeck == null) {
    return AiGenerateCommanderBracketEvaluation(
      applicable: true,
      hardCompliant: false,
      requestedBracket: requestedBracket,
      failureReason: 'generated_deck_missing',
    );
  }

  final cards = <Map<String, dynamic>>[];
  final commander = generatedDeck['commander'];
  if (commander is Map) {
    final normalizedCommander = Map<String, dynamic>.from(commander);
    final name = normalizedCommander['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) {
      cards.add({...normalizedCommander, 'name': name, 'quantity': 1});
    }
  } else {
    final commanderName = commander?.toString().trim() ?? '';
    if (commanderName.isNotEmpty) {
      cards.add({'name': commanderName, 'quantity': 1});
    }
  }

  final mainDeck = generatedDeck['cards'];
  if (mainDeck is Iterable) {
    for (final rawCard in mainDeck) {
      if (rawCard is! Map) continue;
      final card = Map<String, dynamic>.from(rawCard);
      final name = card['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      cards.add({...card, 'name': name});
    }
  }

  final assessment = assessDeckAgainstBracketPolicy(
    bracket: requestedBracket,
    cards: cards,
  );
  return AiGenerateCommanderBracketEvaluation(
    applicable: true,
    hardCompliant: assessment.hardCompliant,
    requestedBracket: requestedBracket,
    assessment: assessment,
  );
}

Map<String, dynamic> applyAiGenerateCommanderBracketContract({
  required String format,
  required int? requestedBracket,
  required Map<String, dynamic> responseBody,
}) {
  if (!isAiGenerateCommanderFormat(format) || requestedBracket == null) {
    return Map<String, dynamic>.from(responseBody);
  }

  final rawGeneratedDeck = responseBody['generated_deck'];
  final generatedDeck =
      rawGeneratedDeck is Map
          ? Map<String, dynamic>.from(rawGeneratedDeck)
          : null;
  final evaluation = evaluateAiGenerateCommanderBracket(
    format: format,
    requestedBracket: requestedBracket,
    generatedDeck: generatedDeck,
  );
  final bracketPolicy = evaluation.toJson();

  final rawContract = responseBody['deckbuilding_contract'];
  final deckbuildingContract =
      rawContract is Map
          ? Map<String, dynamic>.from(rawContract)
          : <String, dynamic>{};
  final rawGates = deckbuildingContract['gates'];
  final gates =
      rawGates is Map
          ? Map<String, dynamic>.from(rawGates)
          : <String, dynamic>{};
  final blockers = <String>{
    if (deckbuildingContract['blockers'] is Iterable)
      for (final blocker in deckbuildingContract['blockers'] as Iterable)
        if (blocker.toString().trim().isNotEmpty &&
            blocker.toString().trim() != 'commander_bracket_policy_violation')
          blocker.toString().trim(),
    if (!evaluation.hardCompliant) 'commander_bracket_policy_violation',
  }.toList(growable: false)..sort();

  final result = <String, dynamic>{
    ...responseBody,
    'bracket': requestedBracket,
    'bracket_policy': bracketPolicy,
    'deckbuilding_contract': {
      ...deckbuildingContract,
      if (!evaluation.hardCompliant) 'status': 'blocked',
      'power_bracket_target': requestedBracket,
      'bracket_policy': bracketPolicy,
      'gates': {
        ...gates,
        'power_bracket_requested': true,
        'power_bracket_hard_compliant': evaluation.hardCompliant,
      },
      'blockers': blockers,
    },
  };

  if (!evaluation.hardCompliant) {
    result
      ..['can_save'] = false
      ..['learning_eligible'] = false
      ..['learning_exclusion_reason'] = 'commander_bracket_policy_violation';
  }
  return result;
}

bool aiGenerateCommanderBracketMustReject(Map<String, dynamic> responseBody) {
  final policy = responseBody['bracket_policy'];
  return policy is Map &&
      policy['applicable'] == true &&
      policy['hard_compliant'] != true;
}

Map<String, dynamic> buildAiGenerateCommanderBracketViolationPayload(
  Map<String, dynamic> responseBody,
) {
  final policy = responseBody['bracket_policy'];
  return {
    ...responseBody,
    'error_code': 'ai_generate_bracket_violation',
    'outcome_code': 'generated_deck_rejected',
    'error':
        'O deck gerado não respeita o limite de Game Changers do bracket '
        'selecionado.',
    'quality_error': {
      'code': 'AI_GENERATE_BRACKET_VIOLATION',
      'message':
          'A lista precisa ser regenerada sem exceder o limite estrito do '
          'bracket escolhido.',
      if (policy is Map) 'bracket_policy': Map<String, dynamic>.from(policy),
    },
    'can_save': false,
    'learning_eligible': false,
    'learning_exclusion_reason': 'commander_bracket_policy_violation',
  };
}
