/// Política de lançamento do cliente.
///
/// A beta pública é gratuita por padrão. A arquitetura de checkout permanece
/// compilável, mas só volta a ser acionável em um build futuro que habilite a
/// flag depois de o fluxo de pagamento e seus contratos serem aprovados.
abstract final class CommercialLaunchPolicy {
  static const bool paidCheckoutEnabled = bool.fromEnvironment(
    'ENABLE_PAID_CHECKOUT',
    defaultValue: false,
  );

  static const bool isFreeBeta = !paidCheckoutEnabled;

  static const String betaLabel = 'Beta gratuita';
  static const String betaCheckoutMessage =
      'A beta gratuita não aceita pagamentos. Os recursos disponíveis agora '
      'continuam sem cobrança.';
}
