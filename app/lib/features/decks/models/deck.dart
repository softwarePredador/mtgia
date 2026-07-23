/// Deck Model - Representa um deck do usuário
class Deck {
  static const validationStateUnknown = 'unknown';
  static const validationStateDraft = 'draft';
  static const validationStateValidated = 'validated';

  final String id;
  final String name;
  final String format;
  final String? description;
  final String?
  archetype; // Arquétipo do deck (aggro, control, midrange, combo, etc)
  final int? bracket; // 1..5 (Commander bracket)
  final int? synergyScore;
  final String? strengths;
  final String? weaknesses;
  final String? commanderName;
  final String? commanderImageUrl;
  final String? pricingCurrency;
  final double? pricingTotal;
  final int? pricingMissingCards;
  final String? pricingSource;
  final DateTime? pricingUpdatedAt;
  final bool isPublic;
  final DateTime createdAt;
  final int cardCount;
  final List<String> colorIdentity;
  final bool colorIdentityKnown;
  final String validationState;
  final List<String> reviewReasons;
  final DateTime? validationUpdatedAt;

  bool get requiresReview => validationState != validationStateValidated;
  bool get isValidated => validationState == validationStateValidated;

  Deck({
    required this.id,
    required this.name,
    required this.format,
    this.description,
    this.archetype,
    this.bracket,
    this.synergyScore,
    this.strengths,
    this.weaknesses,
    this.commanderName,
    this.commanderImageUrl,
    this.pricingCurrency,
    this.pricingTotal,
    this.pricingMissingCards,
    this.pricingSource,
    this.pricingUpdatedAt,
    required this.isPublic,
    required this.createdAt,
    this.cardCount = 0,
    this.colorIdentity = const [],
    bool? colorIdentityKnown,
    this.validationState = validationStateUnknown,
    this.reviewReasons = const ['validation_not_recorded'],
    this.validationUpdatedAt,
  }) : colorIdentityKnown = colorIdentityKnown ?? colorIdentity.isNotEmpty;

  /// Factory para criar Deck a partir de JSON (API response)
  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id'] as String,
      name: json['name'] as String,
      format: json['format'] as String,
      description: json['description'] as String?,
      archetype: json['archetype'] as String?,
      bracket: json['bracket'] as int?,
      synergyScore: json['synergy_score'] as int?,
      strengths: json['strengths'] as String?,
      weaknesses: json['weaknesses'] as String?,
      commanderName: json['commander_name'] as String?,
      commanderImageUrl: json['commander_image_url'] as String?,
      pricingCurrency: json['pricing_currency'] as String?,
      pricingTotal: (json['pricing_total'] as num?)?.toDouble(),
      pricingMissingCards: json['pricing_missing_cards'] as int?,
      pricingSource: json['pricing_source'] as String?,
      pricingUpdatedAt: (json['pricing_updated_at'] != null)
          ? DateTime.tryParse(json['pricing_updated_at'] as String)
          : null,
      isPublic: json['is_public'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      cardCount: json['card_count'] as int? ?? 0,
      colorIdentity:
          (json['color_identity'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      colorIdentityKnown:
          json['color_identity_known'] as bool? ??
          json['color_identity'] is List,
      validationState: _normalizeValidationState(json['deck_state']),
      reviewReasons: _normalizeReviewReasons(json['review_reasons']),
      validationUpdatedAt: _parseDateTime(json['validation_updated_at']),
    );
  }

  /// Converte o Deck para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'format': format,
      'description': description,
      'archetype': archetype,
      'bracket': bracket,
      'synergy_score': synergyScore,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'commander_name': commanderName,
      'commander_image_url': commanderImageUrl,
      'pricing_currency': pricingCurrency,
      'pricing_total': pricingTotal,
      'pricing_missing_cards': pricingMissingCards,
      'pricing_source': pricingSource,
      'pricing_updated_at': pricingUpdatedAt?.toIso8601String(),
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'card_count': cardCount,
      'color_identity': colorIdentity,
      'deck_state': validationState,
      'requires_review': requiresReview,
      'review_reasons': reviewReasons,
      'validation_updated_at': validationUpdatedAt?.toIso8601String(),
    };
  }

  /// Cria uma cópia do Deck com modificações
  Deck copyWith({
    String? id,
    String? name,
    String? format,
    String? description,
    String? archetype,
    int? bracket,
    int? synergyScore,
    String? strengths,
    String? weaknesses,
    String? commanderName,
    String? commanderImageUrl,
    String? pricingCurrency,
    double? pricingTotal,
    int? pricingMissingCards,
    String? pricingSource,
    DateTime? pricingUpdatedAt,
    bool? isPublic,
    DateTime? createdAt,
    int? cardCount,
    List<String>? colorIdentity,
    bool? colorIdentityKnown,
    String? validationState,
    List<String>? reviewReasons,
    DateTime? validationUpdatedAt,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      format: format ?? this.format,
      description: description ?? this.description,
      archetype: archetype ?? this.archetype,
      bracket: bracket ?? this.bracket,
      synergyScore: synergyScore ?? this.synergyScore,
      strengths: strengths ?? this.strengths,
      weaknesses: weaknesses ?? this.weaknesses,
      commanderName: commanderName ?? this.commanderName,
      commanderImageUrl: commanderImageUrl ?? this.commanderImageUrl,
      pricingCurrency: pricingCurrency ?? this.pricingCurrency,
      pricingTotal: pricingTotal ?? this.pricingTotal,
      pricingMissingCards: pricingMissingCards ?? this.pricingMissingCards,
      pricingSource: pricingSource ?? this.pricingSource,
      pricingUpdatedAt: pricingUpdatedAt ?? this.pricingUpdatedAt,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      cardCount: cardCount ?? this.cardCount,
      colorIdentity: colorIdentity ?? this.colorIdentity,
      colorIdentityKnown: colorIdentityKnown ?? this.colorIdentityKnown,
      validationState: validationState ?? this.validationState,
      reviewReasons: reviewReasons ?? this.reviewReasons,
      validationUpdatedAt: validationUpdatedAt ?? this.validationUpdatedAt,
    );
  }
}

String _normalizeValidationState(Object? value) {
  return switch (value?.toString().trim().toLowerCase()) {
    Deck.validationStateDraft => Deck.validationStateDraft,
    Deck.validationStateValidated => Deck.validationStateValidated,
    _ => Deck.validationStateUnknown,
  };
}

List<String> _normalizeReviewReasons(Object? value) {
  if (value is! List) {
    return const ['validation_not_recorded'];
  }
  final reasons = <String>[];
  for (final entry in value) {
    final reason = entry?.toString().trim() ?? '';
    if (reason.isNotEmpty && !reasons.contains(reason)) {
      reasons.add(reason);
    }
  }
  return List<String>.unmodifiable(reasons);
}

DateTime? _parseDateTime(Object? value) {
  if (value is DateTime) return value;
  return value == null ? null : DateTime.tryParse(value.toString());
}
