import 'edhrec_service.dart';

const commanderStapleImpactPolicyVersion =
    'commander_staple_impact_policy_v1_2026-06-30';

const commanderStructuralStapleCategories = <String>{
  'ramp',
  'card_draw',
  'removal',
  'board_wipe',
  'lands',
  'protection',
  'tutors',
};

const commanderStapleImpactPolicyDiagnostics = {
  'version': commanderStapleImpactPolicyVersion,
  'principle':
      'Staples are consistency and floor signals, not automatic deck truth.',
  'tiers': {
    'structural_foundation': {
      'meaning':
          'High commander inclusion in a structural role such as ramp, fixing, draw, removal, protection, tutors, wipes, or lands.',
      'use':
          'Protect as deck floor unless a same-role replacement or battle-proven package beats it.',
    },
    'commander_contextual_staple': {
      'meaning':
          'High commander-specific adoption or synergy that supports the commander plan.',
      'use':
          'Treat as a preferred package card, but still validate lane density and pressure matchups.',
    },
    'commander_synergy_candidate': {
      'meaning': 'Strong synergy signal with lower adoption or narrower usage.',
      'use':
          'Queue as a hypothesis; do not promote without functional cut and card-use evidence.',
    },
    'generic_or_low_context_signal': {
      'meaning':
          'Global staple, weak commander inclusion, or unclear role fit.',
      'use':
          'Use as filler or comparison candidate only after the commander-specific package is satisfied.',
    },
  },
  'guardrails': [
    'Do not cut a structural foundation staple across lanes.',
    'Do not let global staple rank override commander intent.',
    'Use inclusionRate, not absolute inclusion count, when scoring commander adoption.',
    'A staple must still obey color identity, legality, bracket, role density, and battle gate evidence.',
  ],
};

bool isCommanderStructuralStaple(EdhrecCard card) {
  return commanderStructuralStapleCategories.contains(card.category) &&
      card.inclusionRate >= 0.5;
}

String commanderStapleImpactTier(EdhrecCard card) {
  if (isCommanderStructuralStaple(card) && card.inclusionRate >= 0.75) {
    return 'structural_foundation';
  }
  if (card.inclusionRate >= 0.5) {
    return 'commander_contextual_staple';
  }
  if (card.synergy >= 0.15) {
    return 'commander_synergy_candidate';
  }
  return 'generic_or_low_context_signal';
}

double commanderStapleWeaknessMultiplier(EdhrecCard card) {
  var multiplier = 1.0;

  if (card.synergy > 0.3) {
    multiplier *= 0.25;
  } else if (card.synergy > 0.15) {
    multiplier *= 0.4;
  } else if (card.synergy > 0) {
    multiplier *= 0.67;
  }

  final structural = commanderStructuralStapleCategories.contains(
    card.category,
  );
  final rate = card.inclusionRate;
  if (rate >= 0.75) {
    multiplier *= structural ? 0.45 : 0.65;
  } else if (rate >= 0.5) {
    multiplier *= structural ? 0.6 : 0.8;
  } else if (rate >= 0.25 && structural) {
    multiplier *= 0.85;
  }

  return multiplier.clamp(0.1, 1.0);
}
