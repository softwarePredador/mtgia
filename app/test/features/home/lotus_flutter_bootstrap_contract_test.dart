import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String bootstrapSource;

  setUpAll(() {
    bootstrapSource =
        File('assets/lotus/flutter_bootstrap.js').readAsStringSync();
  });

  test('does not release app boot from the 500ms retry timer', () {
    expect(bootstrapSource, contains('storageBootstrapRetryDelayMs = 500'));
    expect(bootstrapSource, contains('storageBootstrapMaxAttempts = 8'));
    expect(
      bootstrapSource,
      isNot(contains('setTimeout(resolveStorageBootstrapHandshake')),
    );
    expect(
      bootstrapSource,
      contains("failStorageBootstrapHandshake('bootstrap_timeout')"),
    );
    expect(bootstrapSource, contains("type: 'bootstrap_failed'"));
  });

  test('versions every persisted snapshot inside its page session', () {
    expect(bootstrapSource, contains('sessionId: storageBridgeSessionId'));
    expect(bootstrapSource, contains('sequence: storageSnapshotSequence'));
    expect(bootstrapSource, contains('baseRevision: storageRevision'));
  });

  test('flushes lifecycle snapshots immediately without the debounce', () {
    final flushStart = bootstrapSource.indexOf(
      'function flushStorageSnapshot(reason)',
    );
    final queueStart = bootstrapSource.indexOf(
      'function queueStorageSnapshot(reason)',
    );
    expect(flushStart, greaterThanOrEqualTo(0));
    expect(queueStart, greaterThan(flushStart));

    final flushFunction = bootstrapSource.substring(flushStart, queueStart);
    expect(flushFunction, contains('clearTimeout(storagePersistTimer)'));
    expect(flushFunction, contains('postStorageBridgeMessage(payload)'));
    expect(flushFunction, isNot(contains('setTimeout')));

    for (final reason in const [
      'document_hidden',
      'pagehide',
      'beforeunload',
    ]) {
      expect(bootstrapSource, contains("flushStorageSnapshot('$reason')"));
      expect(
        bootstrapSource,
        isNot(contains("queueStorageSnapshot('$reason')")),
      );
    }
    expect(bootstrapSource, contains('flushSnapshot: function (reason)'));
  });

  test('removes the hidden Lotus timer state when the feature is disabled', () {
    expect(
      bootstrapSource,
      contains('function removeInactiveGameTimerState()'),
    );
    expect(bootstrapSource, contains("settings.gameTimer !== false"));
    expect(
      bootstrapSource,
      contains("window.localStorage.removeItem('gameTimerState')"),
    );

    final deviceReadyStart = bootstrapSource.indexOf(
      'function fireDeviceReady()',
    );
    final runtimeLoaderStart = bootstrapSource.indexOf(
      'function ensureLotusRuntimeScriptLoaded()',
    );
    expect(deviceReadyStart, greaterThanOrEqualTo(0));
    expect(runtimeLoaderStart, greaterThan(deviceReadyStart));

    final deviceReadyFunction = bootstrapSource.substring(
      deviceReadyStart,
      runtimeLoaderStart,
    );
    final dispatchIndex = deviceReadyFunction.indexOf(
      "document.dispatchEvent(new Event('deviceready'))",
    );
    final cleanupIndex = deviceReadyFunction.indexOf(
      'removeInactiveGameTimerState()',
    );
    expect(dispatchIndex, greaterThanOrEqualTo(0));
    expect(cleanupIndex, greaterThan(dispatchIndex));
    expect(
      deviceReadyFunction,
      contains('setTimeout(removeInactiveGameTimerState, 0)'),
    );
  });

  test('cancels pending Web snapshots before native patch or rebase', () {
    expect(bootstrapSource, contains("type: 'native_patch_applied'"));
    expect(bootstrapSource, contains('receiveRebase: function (payload)'));
    expect(
      RegExp(
        r'clearTimeout\(storagePersistTimer\);\s*storagePersistTimer = null;',
      ).allMatches(bootstrapSource).length,
      greaterThanOrEqualTo(2),
    );
  });

  test(
    'reloads the Lotus runtime only when a canonical rebase requests it',
    () {
      expect(bootstrapSource, contains('decoded.reloadRuntime === true'));
      expect(bootstrapSource, contains('result.reloadScheduled = true'));
      expect(bootstrapSource, contains('window.location.reload()'));
    },
  );
}
