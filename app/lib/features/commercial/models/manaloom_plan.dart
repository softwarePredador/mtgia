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
    ManaLoomPlanTier.free => 'Beta gratuita',
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
  final ManaLoomBillingTerms billingTerms;
  final String description;
  final List<String> features;
  final List<String> limits;

  const ManaLoomPlan({
    required this.tier,
    required this.monthlyAiLimit,
    required this.billingTerms,
    required this.description,
    required this.features,
    required this.limits,
  });

  bool get isPro => tier == ManaLoomPlanTier.pro;
  String get priceLabel => billingTerms.priceLabel;

  static const free = ManaLoomPlan(
    tier: ManaLoomPlanTier.free,
    monthlyAiLimit: 120,
    billingTerms: ManaLoomBillingTerms.free,
    description:
        'Acesso aos recursos disponíveis no ManaLoom durante a beta pública.',
    features: [
      '120 ações de IA por mês',
      'Geração, análise e otimização com revisão antes de aplicar',
      'Coleção, fichário, trocas e comunidade',
      'Life Counter e acompanhamento pós-jogo',
    ],
    limits: [
      'Ações de IA param ao atingir o limite mensal',
      'O saldo de IA não é acumulado para o mês seguinte',
    ],
  );

  static const pro = ManaLoomPlan(
    tier: ManaLoomPlanTier.pro,
    monthlyAiLimit: 2500,
    billingTerms: ManaLoomBillingTerms.pro,
    description:
        'Para quem usa IA com frequência e precisa de um limite mensal maior.',
    features: [
      '2.500 ações de IA por mês',
      'Geração, análise e otimização com a mesma revisão segura',
      'Limite sincronizado com o plano da sua conta',
    ],
    limits: [
      'Social, trocas e pós-jogo continuam disponíveis no Free',
      'Ativação depende da confirmação do provedor de pagamento',
      'O saldo de IA não é acumulado para o mês seguinte',
    ],
  );

  static ManaLoomPlan forTier(ManaLoomPlanTier tier) {
    return switch (tier) {
      ManaLoomPlanTier.free => free,
      ManaLoomPlanTier.pro => pro,
    };
  }
}

/// Fonte única para preço, recorrência e condições mostradas antes do checkout.
///
/// O provedor externo continua sendo a fonte final do total e da data de
/// cobrança. Se houver divergência, a compra não deve ser concluída.
class ManaLoomBillingTerms {
  final String priceLabel;
  final String recurrenceLabel;
  final String renewalDisclosure;
  final String cancellationDisclosure;
  final String refundDisclosure;
  final String checkoutGuardrail;

  const ManaLoomBillingTerms({
    required this.priceLabel,
    required this.recurrenceLabel,
    required this.renewalDisclosure,
    required this.cancellationDisclosure,
    required this.refundDisclosure,
    required this.checkoutGuardrail,
  });

  static const free = ManaLoomBillingTerms(
    priceLabel: 'Sem custo',
    recurrenceLabel: 'Sem cobrança',
    renewalDisclosure: 'A beta gratuita não tem renovação paga.',
    cancellationDisclosure: 'Não há assinatura para cancelar durante a beta.',
    refundDisclosure: 'Não há cobrança da beta para reembolsar.',
    checkoutGuardrail: 'A beta gratuita não exige checkout.',
  );

  static const pro = ManaLoomBillingTerms(
    priceLabel: 'R\$ 19,90/mês',
    recurrenceLabel: 'Assinatura mensal recorrente',
    renewalDisclosure:
        'Renovação automática a cada mês até o cancelamento. O checkout confirma a próxima cobrança antes do pagamento.',
    cancellationDisclosure:
        'Cancelamento: esta versão ainda não oferece gestão dentro do app. Solicite pelo canal indicado pelo provedor antes da próxima cobrança.',
    refundDisclosure:
        'Reembolso: não é automático; solicitações seguem a legislação aplicável e as regras informadas pelo provedor no checkout.',
    checkoutGuardrail:
        'Confira preço, periodicidade e total no checkout externo. Se houver divergência, não conclua a compra.',
  );
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
