import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'lotus_js_bridges.dart';

typedef LotusHostFactory =
    LotusHost Function({
      required LotusAppReviewCallback onAppReviewRequested,
      required LotusShellMessageCallback onShellMessageRequested,
    });

abstract class LotusHost {
  ValueListenable<bool> get isLoading;
  ValueListenable<String?> get errorMessage;

  Widget buildView(BuildContext context);
  void suppressStaleBeforeUnloadSnapshot();
  Future<void> loadBundle();
  Future<void> runJavaScript(String script);
  Future<Object?> runJavaScriptReturningResult(String script);
  void dispose();
}

abstract interface class LotusCanonicalStorageRebaser {
  Future<bool> rebaseStorageFromCanonical({
    String reason = 'native_canonical_sync',
  });
}

typedef LotusCanonicalStorageMutation = Future<void> Function();

abstract interface class LotusCanonicalStorageMutationCoordinator {
  Future<bool> mutateCanonicalStorageAndRebase({
    required LotusCanonicalStorageMutation mutation,
    required String reason,
    bool reloadRuntime = false,
  });
}

abstract interface class LotusLiveStoragePatchCoordinator {
  Future<bool> applyLiveStoragePatch(Map<String, String?> values);
}

abstract interface class LotusStorageFlushBarrier {
  Future<bool> flushStorageSnapshot({String reason = 'flutter_exit'});
}
