import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/auth/screens/splash_screen.dart';

void main() {
  group('normalizePostSplashRedirect', () {
    test('keeps internal protected app paths', () {
      expect(normalizePostSplashRedirect('/life-counter'), '/life-counter');
      expect(
        normalizePostSplashRedirect('/decks/deck-1?tab=analysis'),
        '/decks/deck-1?tab=analysis',
      );
    });

    test('drops auth, root and external redirects', () {
      expect(normalizePostSplashRedirect('/'), isNull);
      expect(normalizePostSplashRedirect('/login'), isNull);
      expect(normalizePostSplashRedirect('/register'), isNull);
      expect(normalizePostSplashRedirect('https://example.com'), isNull);
      expect(normalizePostSplashRedirect('//example.com/path'), isNull);
    });
  });
}
