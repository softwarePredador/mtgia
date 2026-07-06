enum ManaLoomPlanTier { free, pro }

enum AiUsageKind {
  deckGeneration,
  deckOptimization,
  deckAnalysis,
  cardExplanation,
  guidedRebuild,
}

extension ManaLoomPlanTierLabel on ManaLoomPlanTier {
  String get id => switch (this) {
    ManaLoomPlanTier.free => 'free',
    ManaLoomPlanTier.pro => 'pro',
  };

  String get label => switch (this) {
    ManaLoomPlanTier.free => 'Free',
    ManaLoomPlanTier.pro => 'Pro',
  };

  static ManaLoomPlanTier fromId(String? id) {
    return switch (id) {
      'pro' => ManaLoomPlanTier.pro,
      _ => ManaLoomPlanTier.free,
    };
  }
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
  final ManaLoomPlanTier tier;
  final int monthlyAiLimit;
  final String priceLabel;
  final String description;
  final List<String> features;
  final List<String> limits;

  const ManaLoomPlan({
    required this.tier,
    required this.monthlyAiLimit,
    required this.priceLabel,
    required this.description,
    required this.features,
    required this.limits,
  });

  bool get isPro => tier == ManaLoomPlanTier.pro;

  static const free = ManaLoomPlan(
    tier: ManaLoomPlanTier.free,
    monthlyAiLimit: 120,
    priceLabel: 'R\$ 0',
    description:
        'Para testar ManaLoom, criar listas iniciais e validar se o fluxo serve para sua mesa.',
    features: [
      '120 ações de IA por mês',
      'Gerador de decks revisável',
      'Otimização com preview antes de aplicar',
      'Coleção, fichário e trocas básicos',
    ],
    limits: [
      'Sem excedente de IA depois do limite mensal',
      'Relatórios e recomendações avançadas limitados',
      'Checkout Pro necessário para uso contínuo',
    ],
  );

  static const pro = ManaLoomPlan(
    tier: ManaLoomPlanTier.pro,
    monthlyAiLimit: 2500,
    priceLabel: 'R\$ 19,90/mês',
    description:
        'Para acompanhar decks vivos, otimizar por coleção/orçamento e voltar depois de cada partida.',
    features: [
      '2.500 ações de IA por mês',
      'Otimização por coleção e orçamento',
      'Relatório antes/depois compartilhável',
      'Histórico pós-jogo e alertas de evolução',
      'Camada social, fichário público e trade matching',
    ],
    limits: [
      'Uso sujeito a política de fair use',
      'Pagamento real depende do provedor configurado no backend',
    ],
  );

  static ManaLoomPlan forTier(ManaLoomPlanTier tier) {
    return switch (tier) {
      ManaLoomPlanTier.free => free,
      ManaLoomPlanTier.pro => pro,
    };
  }
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
