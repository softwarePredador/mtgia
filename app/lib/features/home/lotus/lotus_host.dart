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
  void dispose();
}
