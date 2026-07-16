import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('activation events contract source guards', () {
    test('backend accepts all activation events emitted by app deck flows', () {
      final routeSource =
          File(
            'routes/users/me/activation-events/index.dart',
          ).readAsStringSync();
      final deckProviderSource =
          File(
            '../app/lib/features/decks/providers/deck_provider.dart',
          ).readAsStringSync();

      expect(deckProviderSource, contains("'deck_optimized'"));
      expect(routeSource, contains("'deck_optimized'"));

      expect(deckProviderSource, contains("'deck_generated'"));
      expect(routeSource, contains("'deck_generated'"));

      expect(deckProviderSource, contains("'deck_rebuild_created'"));
      expect(routeSource, contains("'deck_rebuild_created'"));
    });

    test('activation route keeps rejecting unknown event names', () {
      final routeSource =
          File(
            'routes/users/me/activation-events/index.dart',
          ).readAsStringSync();

      expect(routeSource, contains('const _allowedEvents = <String>{'));
      expect(routeSource, contains('if (!_allowedEvents.contains(eventName))'));
      expect(routeSource, contains("badRequest('event_name inválido')"));
    });
  });
}
