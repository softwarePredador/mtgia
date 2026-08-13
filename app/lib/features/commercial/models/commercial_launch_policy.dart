/// Política de lançamento do cliente.
///
/// A oferta corrente é uma beta gratuita única. Não existe flag de build para
/// reativar checkout: monetização exige uma nova decisão de produto e uma nova
/// implementação revisada de ponta a ponta.
abstract final class CommercialLaunchPolicy {
  static const bool paidCheckoutEnabled = false;
  static const bool isFreeBeta = true;

  static const String betaLabel = 'Beta gratuita';
  static const String betaCheckoutMessage =
      'A beta gratuita não aceita pagamentos, assinatura ou upgrade. Somente '
      'os recursos liberados pelo servidor ficam disponíveis nesta fase.';
}
