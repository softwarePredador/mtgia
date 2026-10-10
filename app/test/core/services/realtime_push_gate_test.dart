import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/config/release_capabilities.dart';
import 'package:manaloom/core/services/realtime_push_gate.dart';

/// A9: o predicado que decide o que a beta entrega por push. Duas camadas —
/// `social_push` é o portão do transporte, e cada tipo de evento responde
/// ainda à sua própria capability.
void main() {
  bool gate(
    Map<String, dynamic> data, {
    Set<ReleaseCapability> allowed = const {},
  }) => canHandleRealtimePushData(data, isAllowed: allowed.contains);

  const dm = {'type': 'direct_message', 'reference_id': 'm1'};
  const trade = {'type': 'trade_offer_received', 'reference_id': 't1'};
  const follower = {'type': 'new_follower', 'reference_id': 'u1'};
  const generic = {'type': 'deck_ready', 'reference_id': 'd1'};

  test('tudo desligado: nada passa', () {
    for (final data in [dm, trade, follower, generic]) {
      expect(gate(data), isFalse, reason: '$data');
    }
  });

  test('social_push é o portão: sem ele a capability do tipo não basta', () {
    // O caso que separa as duas camadas. Se o predicado checasse só a
    // capability do tipo, estes três passariam com o transporte desligado.
    expect(gate(dm, allowed: {ReleaseCapability.directMessages}), isFalse);
    expect(gate(trade, allowed: {ReleaseCapability.trades}), isFalse);
    expect(gate(follower, allowed: {ReleaseCapability.follows}), isFalse);
  });

  test('com social_push, cada tipo ainda exige a SUA capability', () {
    // Se as três lessem a mesma flag, qualquer um destes passaria errado.
    expect(gate(dm, allowed: {ReleaseCapability.socialPush}), isFalse);
    expect(gate(trade, allowed: {ReleaseCapability.socialPush}), isFalse);
    expect(gate(follower, allowed: {ReleaseCapability.socialPush}), isFalse);

    expect(
      gate(
        dm,
        allowed: {
          ReleaseCapability.socialPush,
          ReleaseCapability.directMessages,
        },
      ),
      isTrue,
    );
    expect(
      gate(
        trade,
        allowed: {ReleaseCapability.socialPush, ReleaseCapability.trades},
      ),
      isTrue,
    );
    expect(
      gate(
        follower,
        allowed: {ReleaseCapability.socialPush, ReleaseCapability.follows},
      ),
      isTrue,
    );
  });

  test('capability do tipo errado não destrava o tipo', () {
    expect(
      gate(
        trade,
        allowed: {
          ReleaseCapability.socialPush,
          ReleaseCapability.directMessages,
        },
      ),
      isFalse,
    );
    expect(
      gate(
        dm,
        allowed: {ReleaseCapability.socialPush, ReleaseCapability.follows},
      ),
      isFalse,
    );
  });

  test('evento sem capability própria passa só com o transporte', () {
    expect(gate(generic, allowed: {ReleaseCapability.socialPush}), isTrue);
  });

  test('payload que não parseia é recusado mesmo com tudo ligado', () {
    // Fail-closed: mensagem que o app não entende não vira notificação.
    final tudo = ReleaseCapability.values.toSet();
    expect(gate(const {}, allowed: tudo), isFalse);
    expect(gate(const {'type': ''}, allowed: tudo), isFalse);
    expect(gate(const {'type': '   '}, allowed: tudo), isFalse);
    expect(gate(const {'reference_id': 'x'}, allowed: tudo), isFalse);
  });
}
