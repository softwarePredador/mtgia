import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/auth/auth_redirect.dart';

void main() {
  group('post-auth redirect', () {
    test('keeps internal protected app paths', () {
      expect(normalizePostAuthRedirect('/life-counter'), '/life-counter');
      expect(
        normalizePostAuthRedirect('/decks/deck-1?tab=analysis'),
        '/decks/deck-1?tab=analysis',
      );
    });

    test('drops auth, root and external redirects', () {
      expect(normalizePostAuthRedirect('/'), isNull);
      expect(normalizePostAuthRedirect('/login'), isNull);
      expect(normalizePostAuthRedirect('/register'), isNull);
      expect(normalizePostAuthRedirect('https://example.com'), isNull);
      expect(normalizePostAuthRedirect('//example.com/path'), isNull);
    });

    test('encodes the destination on auth routes', () {
      expect(
        buildAuthLocation('/login', '/decks/deck-1?tab=analysis'),
        '/login?redirect=%2Fdecks%2Fdeck-1%3Ftab%3Danalysis',
      );
      expect(
        buildAuthLocation('/register', 'https://example.com'),
        '/register',
      );
    });
  });
}
