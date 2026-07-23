import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offline claims exist only on governed runtime surfaces', () {
    final claims = <String>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (RegExp(
        r'\boffline\b|sem conexão',
        caseSensitive: false,
      ).hasMatch(source)) {
        claims.add(entity.path);
      }
    }

    expect(claims, <String>{
      'lib/core/resilience/offline_capability.dart',
      'lib/features/home/onboarding_core_flow_screen.dart',
    });
  });

  test('cached reads and provider errors cannot regress to false claims', () {
    final home = File('lib/features/home/home_screen.dart').readAsStringSync();
    final scanner = File(
      'lib/features/scanner/utils/scanner_error_mapper.dart',
    ).readAsStringSync();
    final messages = File(
      'lib/features/messages/providers/message_provider.dart',
    ).readAsStringSync();

    expect(home, isNot(contains('offline-cache')));
    expect(home, contains('cached-read-only'));
    expect(scanner, contains('OfflineProductFlow.cardCatalog'));
    expect(messages, isNot(contains("_error = '\$e'")));
    expect(messages, contains('FriendlyErrorContext.directMessage'));
  });
}
