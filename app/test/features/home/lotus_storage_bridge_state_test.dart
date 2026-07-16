import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/lotus/lotus_host_controller.dart';

void main() {
  group('isSuccessfulLotusStorageBridgeResult', () {
    test('accepts direct, JSON and double-encoded successful results', () {
      expect(isSuccessfulLotusStorageBridgeResult({'ok': true}), isTrue);
      expect(isSuccessfulLotusStorageBridgeResult('{"ok":true}'), isTrue);
      expect(isSuccessfulLotusStorageBridgeResult('"{\\"ok\\":true}"'), isTrue);
    });

    test('rejects malformed or explicitly failed results', () {
      expect(isSuccessfulLotusStorageBridgeResult('{not-json'), isFalse);
      expect(isSuccessfulLotusStorageBridgeResult('{"ok":false}'), isFalse);
      expect(isSuccessfulLotusStorageBridgeResult(null), isFalse);
    });
  });

  group('lotusStorageValuesFingerprint', () {
    test('is stable regardless of map insertion order', () {
      final first = lotusStorageValuesFingerprint(const {
        'players': '[1,2,3,4]',
        'gameSettings': '{"autoKO":true}',
      });
      final second = lotusStorageValuesFingerprint(const {
        'gameSettings': '{"autoKO":true}',
        'players': '[1,2,3,4]',
      });

      expect(first, second);
    });

    test('canonicalizes nested JSON but preserves meaningful values', () {
      final first = lotusStorageValuesFingerprint(const {
        'currentGameMeta':
            '{"id":"canonical-bootstrap","startDate":100,"name":"Game #1"}',
      });
      final reordered = lotusStorageValuesFingerprint(const {
        'currentGameMeta':
            '{"name":"Game #1","startDate":100,"id":"canonical-bootstrap"}',
      });
      final differentStartDate = lotusStorageValuesFingerprint(const {
        'currentGameMeta':
            '{"name":"Game #1","startDate":200,"id":"canonical-bootstrap"}',
      });

      expect(first, reordered);
      expect(first, isNot(differentStartDate));
    });
  });

  group('LotusStorageBridgeState', () {
    const sessionId = 'session-1';
    const requestId = 'bootstrap-1';
    const baseline = '{"players":"old"}';
    const webUpdate = '{"players":"web"}';
    const nativeUpdate = '{"players":"native"}';

    late LotusStorageBridgeState state;
    late int bootstrapRevision;

    setUp(() {
      state = LotusStorageBridgeState();
      bootstrapRevision = state.beginBootstrap(
        sessionId: sessionId,
        requestId: requestId,
        authoritativeFingerprint: baseline,
      );
    });

    test('keeps bootstrap retries idempotent', () {
      final retryRevision = state.beginBootstrap(
        sessionId: sessionId,
        requestId: requestId,
        authoritativeFingerprint: baseline,
      );

      expect(bootstrapRevision, 1);
      expect(retryRevision, bootstrapRevision);
    });

    test('starts a new revision if state changes during a bootstrap retry', () {
      final retryRevision = state.beginBootstrap(
        sessionId: sessionId,
        requestId: requestId,
        authoritativeFingerprint: nativeUpdate,
      );

      expect(retryRevision, bootstrapRevision + 1);
    });

    test('accepts ordered WebView snapshots and rejects duplicates', () {
      final accepted = state.evaluatePersist(
        sessionId: sessionId,
        sequence: 1,
        baseRevision: bootstrapRevision,
        currentAuthoritativeFingerprint: baseline,
        incomingFingerprint: webUpdate,
      );
      state.recordAcceptedSnapshot(
        webUpdate,
        sequence: 1,
        incomingFingerprint: webUpdate,
      );
      final duplicate = state.evaluatePersist(
        sessionId: sessionId,
        sequence: 1,
        baseRevision: bootstrapRevision,
        currentAuthoritativeFingerprint: webUpdate,
        incomingFingerprint: webUpdate,
      );

      expect(accepted.shouldPersist, isTrue);
      expect(duplicate.shouldPersist, isFalse);
      expect(duplicate.wasAlreadyPersisted, isTrue);
      expect(duplicate.rejection, LotusStoragePersistRejection.staleSequence);
    });

    test('rejects snapshots from an inactive page session', () {
      final decision = state.evaluatePersist(
        sessionId: 'previous-session',
        sequence: 1,
        baseRevision: bootstrapRevision,
        currentAuthoritativeFingerprint: baseline,
        incomingFingerprint: webUpdate,
      );

      expect(decision.shouldPersist, isFalse);
      expect(decision.rejection, LotusStoragePersistRejection.inactiveSession);
      expect(decision.shouldRebase, isFalse);
    });

    test('rebases when native state changed behind a stale WebView', () {
      final decision = state.evaluatePersist(
        sessionId: sessionId,
        sequence: 1,
        baseRevision: bootstrapRevision,
        currentAuthoritativeFingerprint: nativeUpdate,
        incomingFingerprint: webUpdate,
      );

      expect(decision.shouldPersist, isFalse);
      expect(
        decision.rejection,
        LotusStoragePersistRejection.authoritativeStateChanged,
      );
      expect(decision.shouldRebase, isTrue);
    });

    test('accepts a snapshot already synchronized with a native mutation', () {
      final decision = state.evaluatePersist(
        sessionId: sessionId,
        sequence: 1,
        baseRevision: bootstrapRevision,
        currentAuthoritativeFingerprint: nativeUpdate,
        incomingFingerprint: nativeUpdate,
      );

      expect(decision.shouldPersist, isTrue);
    });

    test('native patch revision invalidates an earlier queued snapshot', () {
      final didRecordPatch = state.recordNativePatch(
        sessionId: sessionId,
        revision: bootstrapRevision + 1,
        authoritativeFingerprint: nativeUpdate,
      );
      final stale = state.evaluatePersist(
        sessionId: sessionId,
        sequence: 1,
        baseRevision: bootstrapRevision,
        currentAuthoritativeFingerprint: nativeUpdate,
        incomingFingerprint: webUpdate,
      );
      final current = state.evaluatePersist(
        sessionId: sessionId,
        sequence: 2,
        baseRevision: bootstrapRevision + 1,
        currentAuthoritativeFingerprint: nativeUpdate,
        incomingFingerprint: webUpdate,
      );

      expect(didRecordPatch, isTrue);
      expect(stale.rejection, LotusStoragePersistRejection.staleRevision);
      expect(stale.shouldRebase, isTrue);
      expect(current.shouldPersist, isTrue);
    });

    test(
      'accepts the final snapshot before a duplicate native patch ack arrives',
      () {
        final patchRevision = bootstrapRevision + 1;
        final synchronousPatchResult = state.recordNativePatch(
          sessionId: sessionId,
          revision: patchRevision,
          authoritativeFingerprint: nativeUpdate,
        );
        final exitSnapshot = state.evaluatePersist(
          sessionId: sessionId,
          sequence: 1,
          baseRevision: patchRevision,
          currentAuthoritativeFingerprint: nativeUpdate,
          incomingFingerprint: webUpdate,
        );

        expect(synchronousPatchResult, isTrue);
        expect(exitSnapshot.shouldPersist, isTrue);

        state.recordAcceptedSnapshot(
          webUpdate,
          sequence: 1,
          incomingFingerprint: webUpdate,
        );
        final delayedChannelAck = state.recordNativePatch(
          sessionId: sessionId,
          revision: patchRevision,
          authoritativeFingerprint: nativeUpdate,
        );
        final directFlushDuplicate = state.evaluatePersist(
          sessionId: sessionId,
          sequence: 1,
          baseRevision: patchRevision,
          currentAuthoritativeFingerprint: webUpdate,
          incomingFingerprint: webUpdate,
        );

        expect(delayedChannelAck, isFalse);
        expect(directFlushDuplicate.wasAlreadyPersisted, isTrue);
      },
    );
  });
}
