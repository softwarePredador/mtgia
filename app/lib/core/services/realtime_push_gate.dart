import '../config/release_capabilities.dart';
import 'realtime_notification_coordinator.dart';

/// Decide se uma mensagem de push pode ser entregue à UI.
///
/// Extraído de `main.dart` (A9). Lá era um método privado de uma `State`, e um
/// predicado que decide o que a beta entrega ao usuário precisa de teste
/// próprio — construir a árvore do app inteira para exercitar um `if` não é
/// prova, é cerimônia.
///
/// São DUAS camadas, e a ordem importa. `social_push` é o portão do transporte:
/// desligado, nada passa, nem mesmo um tipo de evento cuja capability própria
/// esteja ligada. Passado o transporte, cada tipo responde à SUA capability —
/// mensagem direta a `direct_messages`, evento de troca a `trades`, seguidor a
/// `follows`.
///
/// Payload que não parseia é recusado. É a leitura fail-closed de sempre: uma
/// mensagem que o app não entende não vira notificação.
bool canHandleRealtimePushData(
  Map<String, dynamic> data, {
  required bool Function(ReleaseCapability capability) isAllowed,
}) {
  if (!isAllowed(ReleaseCapability.socialPush)) return false;

  final payload = PushNotificationPayload.fromData(data);
  if (payload == null) return false;

  if (payload.isDirectMessage) {
    return isAllowed(ReleaseCapability.directMessages);
  }
  if (payload.isTradeEvent) {
    return isAllowed(ReleaseCapability.trades);
  }
  if (payload.isFollower) {
    return isAllowed(ReleaseCapability.follows);
  }
  return true;
}
