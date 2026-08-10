import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('collection scanner session queues cards without closing each scan', () {
    final scanner = File(
      'lib/features/scanner/screens/card_scanner_screen.dart',
    ).readAsStringSync();
    final importScreen = File(
      'lib/features/binder/screens/binder_import_screen.dart',
    ).readAsStringSync();

    expect(scanner, contains('final bool continuousBinderSession'));
    expect(scanner, contains('if (widget.continuousBinderSession)'));
    expect(scanner, contains("entrou na fila de revisão"));
    expect(scanner, contains('_scannerProvider.reset()'));
    expect(scanner, contains('_startLiveStream()'));
    expect(importScreen, contains('continuousBinderSession: true'));
    expect(importScreen, contains('addScannedCard'));
    expect(importScreen, contains('LaunchFeatures.scannerEnabled'));
  });
}
