import '../generated_deck_validation_service.dart';

const aiGenerateProviderRepairMaxInvalidEntries = 3;
const aiGenerateProviderRepairMaxRemovedCards = 4;
const aiGenerateProviderRepairMinResolvedCardRatio = 0.95;

class AiGenerateProviderRepairDecision {
  const AiGenerateProviderRepairDecision({
    required this.eligible,
    required this.reason,
    required this.invalidEntryCount,
    required this.removedCardCount,
    required this.resolvedCardRatio,
  });

  final bool eligible;
  final String reason;
  final int invalidEntryCount;
  final int removedCardCount;
  final double resolvedCardRatio;

  Map<String, dynamic> toJson() => {
    'eligible': eligible,
    'reason': reason,
    'invalid_entry_count': invalidEntryCount,
    'removed_card_count': removedCardCount,
    'resolved_card_ratio': resolvedCardRatio,
    'limits': {
      'max_invalid_entries': aiGenerateProviderRepairMaxInvalidEntries,
      'max_removed_cards': aiGenerateProviderRepairMaxRemovedCards,
      'min_resolved_card_ratio': aiGenerateProviderRepairMinResolvedCardRatio,
    },
  };
}

AiGenerateProviderRepairDecision evaluateAiGenerateProviderRepair(
  GeneratedDeckValidationResult validation,
) {
  final invalidEntryCount = validation.invalidCards.length;
  final removedCardCount =
      validation.totalSuggestedCards > validation.totalResolvedCards
          ? validation.totalSuggestedCards - validation.totalResolvedCards
          : 0;
  final resolvedCardRatio =
      validation.totalSuggestedCards <= 0
          ? 0.0
          : validation.totalResolvedCards / validation.totalSuggestedCards;

  AiGenerateProviderRepairDecision decision(bool eligible, String reason) {
    return AiGenerateProviderRepairDecision(
      eligible: eligible,
      reason: reason,
      invalidEntryCount: invalidEntryCount,
      removedCardCount: removedCardCount,
      resolvedCardRatio: resolvedCardRatio,
    );
  }

  if (invalidEntryCount == 0) {
    return decision(false, 'no_provider_repair_required');
  }
  if (!validation.isValid) {
    return decision(false, 'final_deck_failed_strict_validation');
  }
  if (invalidEntryCount > aiGenerateProviderRepairMaxInvalidEntries) {
    return decision(false, 'too_many_unresolved_entries');
  }
  if (removedCardCount <= 0 ||
      removedCardCount > aiGenerateProviderRepairMaxRemovedCards) {
    return decision(false, 'removed_card_count_outside_policy');
  }
  if (resolvedCardRatio < aiGenerateProviderRepairMinResolvedCardRatio) {
    return decision(false, 'resolved_card_ratio_below_policy');
  }

  return decision(true, 'strictly_valid_bounded_provider_repair');
}
