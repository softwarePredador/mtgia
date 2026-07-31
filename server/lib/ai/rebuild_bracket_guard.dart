import '../commander_bracket.dart';
import '../edh_bracket_policy.dart';

class RebuildBracketGuardDecision {
  const RebuildBracketGuardDecision({
    required this.applies,
    required this.assessment,
    required this.errorCode,
    required this.message,
  });

  final bool applies;
  final BracketDeckAssessment? assessment;
  final String? errorCode;
  final String? message;

  bool get allowed => errorCode == null;
}

RebuildBracketGuardDecision assessFinalRebuildCommanderBracket({
  required String deckFormat,
  required int? bracket,
  required Iterable<Map<String, dynamic>> cards,
}) {
  if (deckFormat.trim().toLowerCase() != 'commander') {
    return const RebuildBracketGuardDecision(
      applies: false,
      assessment: null,
      errorCode: null,
      message: null,
    );
  }

  if (bracket == null) {
    return const RebuildBracketGuardDecision(
      applies: true,
      assessment: null,
      errorCode: 'rebuild_commander_bracket_required',
      message:
          'O rebuild Commander exige um bracket entre 1 e 5 antes de gerar '
          'preview ou salvar draft.',
    );
  }
  if (bracket < commanderBracketMin || bracket > commanderBracketMax) {
    return RebuildBracketGuardDecision(
      applies: true,
      assessment: null,
      errorCode: 'rebuild_commander_bracket_invalid',
      message:
          'O rebuild Commander recebeu Bracket $bracket; informe um valor '
          'entre $commanderBracketMin e $commanderBracketMax.',
    );
  }

  final normalizedCards = cards
      .map((card) => Map<String, dynamic>.from(card))
      .toList(growable: false);
  if (normalizedCards.isEmpty) {
    return const RebuildBracketGuardDecision(
      applies: true,
      assessment: null,
      errorCode: 'rebuild_commander_bracket_cards_required',
      message:
          'O rebuild Commander não possui cartas para comprovar o bracket '
          'selecionado.',
    );
  }

  final unresolvedNames =
      normalizedCards.where((card) {
        final quantity = switch (card['quantity']) {
          int value => value,
          num value => value.toInt(),
          String value => int.tryParse(value.trim()) ?? 1,
          _ => 1,
        };
        if (quantity <= 0) return false;
        return card['name']?.toString().trim().isEmpty ?? true;
      }).length;
  if (unresolvedNames > 0) {
    return RebuildBracketGuardDecision(
      applies: true,
      assessment: null,
      errorCode: 'rebuild_commander_bracket_card_identity_required',
      message:
          'O rebuild Commander não pôde comprovar o bracket: '
          '$unresolvedNames carta(s) não possuem nome resolvido.',
    );
  }

  final assessment = assessDeckAgainstBracketPolicy(
    bracket: bracket,
    cards: normalizedCards,
  );
  if (assessment.hardCompliant) {
    return RebuildBracketGuardDecision(
      applies: true,
      assessment: assessment,
      errorCode: null,
      message: null,
    );
  }

  final count = assessment.counts[BracketCategory.gameChanger] ?? 0;
  final cap = assessment.policy.maxCounts[BracketCategory.gameChanger] ?? 0;
  final names = assessment.violations
      .map((violation) => violation['name']?.toString().trim() ?? '')
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList(growable: false);
  final violatingCards = names.isEmpty ? '' : ' Remova: ${names.join(', ')}.';
  return RebuildBracketGuardDecision(
    applies: true,
    assessment: assessment,
    errorCode: 'rebuild_commander_bracket_violation',
    message:
        'O rebuild Commander foi bloqueado: o Bracket '
        '${assessment.policy.bracket} permite até $cap Game Changer(s), '
        'mas o deck final contém $count.$violatingCards',
  );
}
