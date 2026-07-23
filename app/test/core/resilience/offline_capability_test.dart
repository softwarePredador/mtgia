import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/resilience/offline_capability.dart';

void main() {
  test('declares exactly one contract for every product flow', () {
    expect(offlineFlowContracts, hasLength(OfflineProductFlow.values.length));
    expect(
      offlineFlowContracts.map((contract) => contract.flow).toSet(),
      OfflineProductFlow.values.toSet(),
    );
    expect(
      offlineFlowContracts.map((contract) => contract.key).toSet(),
      hasLength(offlineFlowContracts.length),
    );
  });

  test('every contract declares the complete reconnect matrix', () {
    for (final contract in offlineFlowContracts) {
      expect(contract.cachePolicy, isNotEmpty, reason: contract.key);
      expect(contract.queuePolicy, isNotEmpty, reason: contract.key);
      expect(contract.retryPolicy, isNotEmpty, reason: contract.key);
      expect(contract.conflictPolicy, isNotEmpty, reason: contract.key);
      expect(contract.reconciliationPolicy, isNotEmpty, reason: contract.key);
      expect(contract.implementation, isNotEmpty, reason: contract.key);
      expect(contract.disconnectedMessage, isNotEmpty, reason: contract.key);
    }
  });

  test('only real server queues may claim offline server mutations', () {
    final offlineServerMutations = offlineFlowContracts.where(
      (contract) =>
          contract.capability == OfflineCapability.offlineSupported &&
          contract.mutable &&
          contract.serverBacked,
    );

    expect(
      offlineServerMutations.map((contract) => contract.flow),
      <OfflineProductFlow>[OfflineProductFlow.postGameNotes],
    );
    for (final contract in offlineServerMutations) {
      expect(contract.queuesRemoteMutations, isTrue, reason: contract.key);
      expect(contract.reconcilesAutomatically, isTrue, reason: contract.key);
      expect(
        contract.inputPreservation,
        OfflineInputPreservation.durable,
        reason: contract.key,
      );
    }
  });

  test('online-required flows never imply a background mutation queue', () {
    for (final contract in offlineFlowContracts.where(
      (item) => item.capability == OfflineCapability.onlineRequired,
    )) {
      expect(contract.queuesRemoteMutations, isFalse, reason: contract.key);
      expect(
        contract.disconnectedMessage,
        contains('reconecte'),
        reason: contract.key,
      );
    }
  });
}
