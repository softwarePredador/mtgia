import '../../../core/branding/product_identity.dart';

enum ManaLoomPlanTier { free }

enum AiUsageKind {
  deckGeneration,
  deckOptimization,
  deckAnalysis,
  cardExplanation,
  guidedRebuild,
}

extension ManaLoomPlanTierLabel on ManaLoomPlanTier {
  String get id => 'free';

  String get label => 'Beta gratuita';

  /// Legacy/local values (including `pro`) never create an entitlement.
  static ManaLoomPlanTier fromId(String? _) => ManaLoomPlanTier.free;
}

extension AiUsageKindLabel on AiUsageKind {
  String get label => switch (this) {
    AiUsageKind.deckGeneration => 'Gerar deck',
    AiUsageKind.deckOptimization => 'Otimizar deck',
    AiUsageKind.deckAnalysis => 'Analisar deck',
    AiUsageKind.cardExplanation => 'Explicar carta',
    AiUsageKind.guidedRebuild => 'Rebuild guiado',
  };
}

class ManaLoomPlan {
  static const operationalAiMonthlyCeiling = 120;

  final ManaLoomPlanTier tier;
  final int monthlyAiLimit;
  final String description;
  final List<String> features;
  final List<String> limits;

  const ManaLoomPlan({
    required this.tier,
    required this.monthlyAiLimit,
    required this.description,
    required this.features,
    required this.limits,
  });

  String get priceLabel => 'Sem cobrança';

  static const free = ManaLoomPlan(
    tier: ManaLoomPlanTier.free,
    monthlyAiLimit: operationalAiMonthlyCeiling,
    description:
        'Acesso gratuito somente aos recursos liberados pelo servidor durante a beta controlada do ${ProductIdentity.displayName}.',
    features: [
      'Sem assinatura, checkout, renovação ou cobrança',
      'Disponibilidade de cada recurso confirmada pelo servidor',
      'Ações de IA revisáveis quando o recurso correspondente estiver liberado',
    ],
    limits: [
      'Até 120 ações de IA elegíveis por mês UTC como teto operacional',
      'O teto não garante que um recurso de IA esteja disponível',
      'O teto não define preço nem direito permanente de uso',
      'O saldo de IA não é acumulado para o mês seguinte',
    ],
  );

  static ManaLoomPlan forTier(ManaLoomPlanTier _) => free;
}

class AiUsageSnapshot {
  final ManaLoomPlan plan;
  final String periodKey;
  final int used;
  final int? limitOverride;

  const AiUsageSnapshot({
    required this.plan,
    required this.periodKey,
    required this.used,
    this.limitOverride,
  });

  int get limit => limitOverride ?? plan.monthlyAiLimit;
  int get remaining => (limit - used).clamp(0, limit);
  bool get isExhausted => remaining <= 0;
  bool get isNearLimit => !isExhausted && remaining <= 2;
  double get ratio => limit <= 0 ? 1 : (used / limit).clamp(0.0, 1.0);
}
